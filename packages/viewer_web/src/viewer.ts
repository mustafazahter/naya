import CameraControls from "camera-controls";
import * as THREE from "three";
import { DRACOLoader } from "three/examples/jsm/loaders/DRACOLoader.js";
import { GLTFLoader } from "three/examples/jsm/loaders/GLTFLoader.js";
import { MeshoptDecoder } from "three/examples/jsm/libs/meshopt_decoder.module.js";
import { RoomEnvironment } from "three/examples/jsm/environments/RoomEnvironment.js";

import { explodeOffsets, groupNodes, type PartsMap } from "./assembly";
import { Glow, scanBand } from "./glow";

CameraControls.install({ THREE });

/** Modeldeki tek bir parça: seçilebilen, parçalara ayırmada hareket eden düğüm. */
interface Part {
  id: string;
  node: THREE.Object3D;
  home: THREE.Vector3;
  /** Parçalara ayırırken gideceği yer, modelin yerel koordinatlarında. */
  away: THREE.Vector3;
  glow: Glow;
  /** `normal`: kendi malzemesinin parlayabilen kopyası. */
  meshes: { mesh: THREE.Mesh; normal: THREE.Material | THREE.Material[] }[];
}

/** Olasılık ağırlığı: düğüm adı → 0-1. */
export type Weights = Map<string, number>;

interface Scan {
  start: number;
  weights: Weights;
  axis: "x" | "z";
  from: number;
  to: number;
  centers: Map<Part, number>;
  band: THREE.Mesh;
  done: () => void;
}

/** Tarama süresi; uygulamadaki tarama animasyonuyla aynı (NayaMotion.scan). */
const SCAN_SECONDS = 3.4;

/**
 * Açılış: parçalar dağınık ve CAD görünümünde başlar, içten dışa sırayla
 * yerine oturur, oturan parça kendi malzemesine geçip kısa bir an parlar.
 * Kamera da uzaktan ve yandan gelir.
 */
const INTRO_FLIGHT = 1.15; // bir parçanın uçuşu (sn)
const INTRO_STAGGER = 1.1; // ilk ve son parçanın kalkışı arası (sn)
const INTRO_SPREAD = 2.2; // başlangıçta parçalara ayırmanın kaç katı dağınık

interface Intro {
  start: number;
  delays: Map<Part, number>;
  done: () => void;
}

const easeOutExpo = (t: number) => (t >= 1 ? 1 : 1 - Math.pow(2, -10 * t));

/**
 * Seçili parça dışındakiler bu "CAD" görünümüne geçer: açık gri, yarı saydam.
 * Böylece seçili parça yerini kaybetmeden öne çıkar.
 */
function ghostMaterial(): THREE.MeshStandardMaterial {
  return new THREE.MeshStandardMaterial({
    color: 0xc4ccd6,
    metalness: 0,
    roughness: 0.9,
    transparent: true,
    opacity: 0.07,
    depthWrite: false,
  });
}

export interface ViewerOptions {
  canvas: HTMLCanvasElement;
  onPartTap?: (id: string | null) => void;
}

/**
 * NAYA 3D görüntüleyicisi. Modeli yükler, elle döndürme ve yakınlaşmayı
 * camera-controls'a bırakır; parça seçme, parçalara ayırma ve X-ışını kendi.
 */
export class NayaViewer {
  private readonly renderer: THREE.WebGLRenderer;
  private readonly scene = new THREE.Scene();
  private readonly camera = new THREE.PerspectiveCamera(35, 1, 0.01, 200);
  private readonly controls: CameraControls;
  private readonly clock = new THREE.Clock();
  private readonly raycaster = new THREE.Raycaster();
  /** Parlama rengi: uygulamanın vurgu renginin (#8db8f2) daha doygun hâli;
   * açık mavi sarı yüzeyde beyaza dönüyordu. */
  private readonly glowColor = new THREE.Color("#3f86ff");
  private readonly ghost = ghostMaterial();

  private model: THREE.Object3D | null = null;
  private parts: Part[] = [];
  private selected: Part | null = null;
  private isolated: Part | null = null;
  private weights: Weights = new Map();
  private scanning: Scan | null = null;
  private intro: Intro | null = null;
  /** Tarama bandı. Model yüklenirken kurulur ve sahnede saydam bekler; böylece
   * shader'ı taramanın ilk karesinde derlenip takılma yapmaz. */
  private band: THREE.Mesh | null = null;
  private ground: THREE.Mesh | null = null;
  private explodeTarget = 0;
  private explodeValue = 0;
  private xray = false;

  constructor(private readonly options: ViewerOptions) {
    const { canvas } = options;
    this.renderer = new THREE.WebGLRenderer({ canvas, antialias: true, alpha: true });
    this.renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
    this.renderer.toneMapping = THREE.ACESFilmicToneMapping;
    this.renderer.toneMappingExposure = 1.05;
    this.renderer.shadowMap.enabled = true;
    this.renderer.shadowMap.type = THREE.PCFSoftShadowMap;

    const pmrem = new THREE.PMREMGenerator(this.renderer);
    this.scene.environment = pmrem.fromScene(new RoomEnvironment(), 0.04).texture;

    const sun = new THREE.DirectionalLight(0xffffff, 1.6);
    sun.position.set(2, 4, 3);
    sun.castShadow = true;
    sun.shadow.mapSize.set(2048, 2048);
    sun.shadow.radius = 6;
    this.scene.add(sun, new THREE.HemisphereLight(0xdfe8f5, 0x0a0c0f, 0.35));
    this.sun = sun;

    this.controls = new CameraControls(this.camera, canvas);
    this.controls.smoothTime = 0.35;
    this.controls.draggingSmoothTime = 0.12;
    this.controls.minPolarAngle = 0.15;
    this.controls.maxPolarAngle = Math.PI / 2 - 0.04;

    this.listenForTaps(canvas);
    new ResizeObserver(() => this.resize()).observe(canvas);
    this.resize();
    this.renderer.setAnimationLoop(() => this.frame());
  }

  private readonly sun: THREE.DirectionalLight;

  /**
   * Modeli yükler. [mapUrl] verilirse ya da modelin yanında aynı adla
   * `.parts.json` varsa montaj ağacı oradan okunur ve parçalara ayırma
   * gruplara göre yapılır; yoksa her parça merkezden dışarı açılır.
   */
  async load(
    url: string,
    mapUrl?: string,
    onProgress?: (fraction: number) => void,
  ): Promise<string[]> {
    const draco = new DRACOLoader().setDecoderPath(new URL("./draco/", document.baseURI).href);
    const loader = new GLTFLoader().setDRACOLoader(draco).setMeshoptDecoder(MeshoptDecoder);
    const [gltf, map] = await Promise.all([
      loader.loadAsync(url, (e) => {
        // Sunucu boyut vermezse ilerleme bilinmez; çağıran tahmin eder.
        if (e.lengthComputable && e.total > 0) onProgress?.(e.loaded / e.total);
      }),
      loadMap(mapUrl ?? url.replace(/\.glb$/i, ".parts.json")),
    ]);
    this.finishIntro();
    if (this.model) {
      this.scene.remove(this.model);
      disposeModel(this.model, this.ghost);
    }
    this.finishScan();
    this.selected = null;
    this.isolated = null;
    this.weights = new Map();
    this.model = gltf.scene;
    this.scene.add(this.model);

    this.placeOnGround(this.model);
    this.parts = this.collectParts(this.model, map);
    this.addShadowCatcher(this.model);
    this.prepareBand(this.model);
    await this.frameModel(false);
    return this.parts.map((p) => p.id);
  }

  /**
   * Açılış animasyonu; bitince tamamlanır. Kullanıcı hareketi azaltmayı
   * seçtiyse hiç oynamaz.
   */
  introduce(): Promise<void> {
    this.finishIntro();
    if (!this.model || this.parts.length === 0) return Promise.resolve();
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return Promise.resolve();

    // Önce merkezdekiler (kadro), en son en dıştakiler (tekerlek parçaları).
    const order = [...this.parts].sort(
      (a, b) => a.away.distanceTo(a.home) - b.away.distanceTo(b.home),
    );
    const delays = new Map<Part, number>();
    order.forEach((part, i) =>
      delays.set(part, order.length === 1 ? 0 : (i / (order.length - 1)) * INTRO_STAGGER),
    );

    // Kamera son kadrajını load'da aldı; oradan geriye ve yana çekilip geri döner.
    const azimuth = this.controls.azimuthAngle;
    const polar = this.controls.polarAngle;
    const distance = this.controls.distance;
    void this.controls.rotateTo(azimuth - 1.1, polar - 0.3, false);
    void this.controls.dollyTo(distance * 1.9, false);
    this.controls.smoothTime = 0.9;
    void Promise.all([
      this.controls.rotateTo(azimuth, polar, true),
      this.controls.dollyTo(distance, true),
    ]).then(() => (this.controls.smoothTime = 0.35));

    return new Promise((done) => {
      this.intro = { start: this.clock.elapsedTime, delays, done };
      this.stepIntro();
    });
  }

  /**
   * 0 = toplu, 1 = tamamen ayrılmış. Kamera, parçaların varacağı yere göre
   * geri çekilir ya da yaklaşır; açılan parçalar kadrajdan taşmaz.
   */
  explode(amount: number): void {
    const target = THREE.MathUtils.clamp(amount, 0, 1);
    if (Math.abs(target - this.explodeTarget) < 1e-3) return;
    this.finishIntro();
    this.explodeTarget = target;
    if (this.isolated || !this.model) return;
    void this.controls.fitToBox(this.boxAt(target), true, {
      paddingTop: 0.1,
      paddingBottom: 0.1,
      paddingLeft: 0.1,
      paddingRight: 0.1,
    });
  }

  /** Parçalar [amount] kadar açıkken modelin kapladığı kutu. */
  private boxAt(amount: number): THREE.Box3 {
    const now = this.parts.map((p) => p.node.position.clone());
    for (const part of this.parts) part.node.position.lerpVectors(part.home, part.away, amount);
    const box = new THREE.Box3().setFromObject(this.model!);
    this.parts.forEach((part, i) => part.node.position.copy(now[i]));
    return box;
  }

  setXray(enabled: boolean): void {
    this.finishIntro();
    this.xray = enabled;
    this.refreshMaterials();
  }

  select(id: string | null): void {
    this.finishIntro();
    this.selected = this.find(id);
    this.refreshMaterials();
  }

  /**
   * Parçaları olasılıklarına göre parlatır; ağırlığı olmayanlar CAD
   * görünümüne geçer. Boş harita vurguyu kaldırır.
   */
  highlight(weights: Weights): void {
    this.finishIntro();
    this.weights = new Map([...weights].filter(([id, w]) => w > 0 && this.find(id)));
    this.refreshMaterials();
  }

  /**
   * Yalnız [id] görünür, kamera ona uçar. null bütün modeli geri getirir.
   */
  async isolate(id: string | null): Promise<void> {
    this.finishIntro();
    this.isolated = this.find(id);
    this.refreshMaterials();
    if (this.isolated) await this.focus(this.isolated.id);
    else await this.frameModel(true);
  }

  /**
   * Teşhis taraması: bir ışık bandı modelin boyunca geçer, geçtiği parçalar
   * olasılıklarıyla orantılı parlar. Sonunda parlaklık [weights]'e oturur.
   * Süre [SCAN_SECONDS]; Promise tarama bitince tamamlanır.
   */
  scan(weights: Weights): Promise<void> {
    if (!this.model) return Promise.resolve();
    this.finishIntro();
    this.finishScan();
    this.selected = null;
    this.weights = new Map();

    const box = new THREE.Box3().setFromObject(this.model);
    const size = box.getSize(new THREE.Vector3());
    const axis = size.x >= size.z ? "x" : "z";
    const margin = Math.max(size.x, size.z) * 0.08;
    const band = this.band!;
    band.rotation.y = axis === "x" ? Math.PI / 2 : 0;
    band.position.copy(box.getCenter(new THREE.Vector3()));

    const centers = new Map<Part, number>();
    for (const part of this.parts) {
      const c = new THREE.Box3().setFromObject(part.node).getCenter(new THREE.Vector3());
      centers.set(part, c[axis]);
    }
    const scanning = new Promise<void>((done) => {
      this.scanning = {
        start: this.clock.elapsedTime,
        weights,
        axis,
        from: box.min[axis] - margin,
        to: box.max[axis] + margin,
        centers,
        band,
        done,
      };
    });
    // Tarama sürerken X-ışını açık olsa da parçalar kendi malzemesinde kalır;
    // yoksa parlama görünmez.
    this.refreshMaterials();
    return scanning;
  }

  async focus(id: string): Promise<void> {
    const part = this.find(id);
    if (!part || !this.model) return;
    this.select(id);
    // Kamera uçuşu: önce parçanın bulunduğu tarafa döner, sonra parçaya
    // yaklaşır. Ortadaki parçalarda (kadro, sele) açı korunur.
    const box = new THREE.Box3().setFromObject(part.node);
    const modelBox = new THREE.Box3().setFromObject(this.model);
    const lateral = box.getCenter(new THREE.Vector3()).z - modelBox.getCenter(new THREE.Vector3()).z;
    const width = modelBox.getSize(new THREE.Vector3()).z;
    let azimuth = this.controls.azimuthAngle;
    if (lateral > width * 0.08) azimuth = -Math.PI / 6;
    else if (lateral < -width * 0.08) azimuth = Math.PI + Math.PI / 6;
    this.controls.smoothTime = 0.5;
    await this.controls.rotateTo(azimuth, Math.PI / 2.8, true);
    await this.controls.fitToBox(box, true, {
      paddingTop: 0.15,
      paddingBottom: 0.15,
      paddingLeft: 0.15,
      paddingRight: 0.15,
    });
    this.controls.smoothTime = 0.35;
  }

  /**
   * Seçilen parçaya hafifçe yaklaşır: hedefi parçanın merkezine kaydırır,
   * mesafeyi parçayı tam dolduracak mesafeye doğru yalnız bir miktar kısaltır.
   */
  async nudge(id: string): Promise<void> {
    const part = this.parts.find((p) => p.id === id);
    if (!part) return;
    const box = new THREE.Box3().setFromObject(part.node);
    const size = box.getSize(new THREE.Vector3());
    const center = box.getCenter(new THREE.Vector3());
    const fit = this.controls.getDistanceToFitBox(size.x, size.y, size.z);
    const distance = THREE.MathUtils.lerp(this.controls.distance, Math.max(fit * 1.6, 0.4), 0.35);
    await Promise.all([
      this.controls.moveTo(center.x, center.y, center.z, true),
      this.controls.dollyTo(Math.min(distance, this.controls.distance), true),
    ]);
  }

  async reset(): Promise<void> {
    this.finishIntro();
    this.finishScan();
    this.selected = null;
    this.isolated = null;
    this.weights = new Map();
    this.refreshMaterials();
    this.explode(0);
    await this.frameModel(true);
  }

  private find(id: string | null): Part | null {
    return id === null ? null : (this.parts.find((p) => p.id === id) ?? null);
  }

  // ------------------------------------------------------------------ iç işler

  private frame(): void {
    const delta = this.clock.getDelta();
    this.controls.update(delta);

    // Parçalara ayırma yumuşakça hedefe yaklaşır; açılış sürerken parçaları
    // o yönetir.
    const next = THREE.MathUtils.damp(this.explodeValue, this.explodeTarget, 6, delta);
    if (this.intro) {
      this.stepIntro();
    } else if (Math.abs(next - this.explodeValue) > 1e-4) {
      this.explodeValue = next;
      for (const part of this.parts) {
        part.node.position.lerpVectors(part.home, part.away, this.explodeValue);
      }
    }
    if (this.scanning) this.stepScan();
    this.renderer.render(this.scene, this.camera);
  }

  private stepIntro(): void {
    const intro = this.intro!;
    const elapsed = this.clock.elapsedTime - intro.start;
    const offset = new THREE.Vector3();
    let landed = 0;
    for (const part of this.parts) {
      const t = THREE.MathUtils.clamp((elapsed - intro.delays.get(part)!) / INTRO_FLIGHT, 0, 1);
      if (t >= 1) landed++;
      offset.subVectors(part.away, part.home).multiplyScalar((1 - easeOutExpo(t)) * INTRO_SPREAD);
      part.node.position.copy(part.home).add(offset);
      // Yolun yarısından sonra kendi malzemesine geçer ve sönerek parlar.
      const solid = t > 0.55;
      for (const { mesh, normal } of part.meshes) {
        mesh.material = solid ? normal : this.ghost;
        mesh.castShadow = solid;
      }
      part.glow.strength.value = solid ? 0.45 * (1 - (t - 0.55) / 0.45) : 0;
    }
    if (landed === this.parts.length) this.finishIntro();
  }

  /**
   * Süren açılışı hemen bitirir: parçalar yerinde, malzemeler normal.
   * Kullanıcı açılış sürerken bir şey yaparsa (dokunma, X-ışını, ayırma)
   * açılış onu ezmesin diye her komut önce bunu çağırır.
   */
  private finishIntro(): void {
    const intro = this.intro;
    if (!intro) return;
    this.intro = null;
    for (const part of this.parts) {
      part.node.position.lerpVectors(part.home, part.away, this.explodeValue);
    }
    this.refreshMaterials();
    intro.done();
  }

  private stepScan(): void {
    const scan = this.scanning!;
    const t = Math.min((this.clock.elapsedTime - scan.start) / SCAN_SECONDS, 1);
    // Bant hızlı başlar, sona doğru yavaşlar (NayaMotion.decelerate gibi).
    const eased = 1 - Math.pow(1 - t, 2.2);
    const at = THREE.MathUtils.lerp(scan.from, scan.to, eased);
    scan.band.position[scan.axis] = at;
    (scan.band.material as THREE.ShaderMaterial).uniforms.opacity.value = Math.sin(Math.PI * t);

    const width = (scan.to - scan.from) * 0.08;
    const settle = THREE.MathUtils.smoothstep(t, 0.7, 1);
    for (const part of this.parts) {
      const weight = scan.weights.get(part.id) ?? 0;
      const d = (at - scan.centers.get(part)!) / width;
      const pulse = Math.exp(-d * d) * (0.35 + 1.2 * weight);
      part.glow.strength.value = pulse * (1 - settle) + settle * restingGlow(weight);
    }
    if (t >= 1) this.finishScan();
  }

  /** Taramayı bitirir: bandı kaldırır, son parlaklığı kalıcı yapar. */
  /** Süren taramayı hemen bitirir; parlama taramanın ağırlıklarına oturur. */
  finishScan(): void {
    const scan = this.scanning;
    if (!scan) return;
    this.scanning = null;
    (scan.band.material as THREE.ShaderMaterial).uniforms.opacity.value = 0;
    this.highlight(scan.weights);
    scan.done();
  }

  private resize(): void {
    const canvas = this.renderer.domElement;
    const { clientWidth: w, clientHeight: h } = canvas;
    if (!w || !h) return;
    this.renderer.setSize(w, h, false);
    this.camera.aspect = w / h;
    this.camera.updateProjectionMatrix();
  }

  /** Modeli zemine oturtur ve yatayda ortalar. */
  private placeOnGround(model: THREE.Object3D): void {
    const box = new THREE.Box3().setFromObject(model);
    const center = box.getCenter(new THREE.Vector3());
    model.position.x -= center.x;
    model.position.z -= center.z;
    model.position.y -= box.min.y;
  }

  /**
   * Parçaları bulur. Kökün altında tek bir sarmalayıcı düğüm varsa (çoğu
   * dışa aktarımda olur) onun içine iner; ilk dallanan seviyedeki her düğüm
   * bir parçadır.
   */
  private collectParts(model: THREE.Object3D, map: PartsMap | null): Part[] {
    let level: THREE.Object3D = model;
    while (level.children.length === 1 && !(level.children[0] instanceof THREE.Mesh)) {
      level = level.children[0];
    }

    const modelBox = new THREE.Box3().setFromObject(model);
    const size = modelBox.getSize(new THREE.Vector3()).length();
    const center = level.worldToLocal(modelBox.getCenter(new THREE.Vector3()));

    const nodes = level.children.map((node, i) => ({ id: node.name || `part-${i}`, node }));
    const boxes = new Map<string, THREE.Box3>();
    const placed = nodes.map(({ id, node }) => {
      // Kutuyu modelin yerel koordinatlarına çevir. Üst düğüm döndürülmüş
      // olabilir; sekiz köşeyi ayrı ayrı çevirip yeniden kutu kur.
      const box = new THREE.Box3().setFromObject(node);
      const corners = [0, 1, 2, 3, 4, 5, 6, 7].map((i) =>
        level.worldToLocal(
          new THREE.Vector3(
            i & 1 ? box.max.x : box.min.x,
            i & 2 ? box.max.y : box.min.y,
            i & 4 ? box.max.z : box.min.z,
          ),
        ),
      );
      const local = new THREE.Box3().setFromPoints(corners);
      boxes.set(id, local);
      return { id, center: local.getCenter(new THREE.Vector3()) };
    });
    const offsets = explodeOffsets(
      placed,
      groupNodes(map, nodes.map((n) => n.id)),
      center,
      size,
      boxes,
    );

    return nodes.map(({ id, node }) => {
      const glow = new Glow(this.glowColor);
      const meshes: Part["meshes"] = [];
      node.traverse((child) => {
        if (!(child instanceof THREE.Mesh)) return;
        child.castShadow = true;
        child.receiveShadow = true;
        const normal = Array.isArray(child.material)
          ? child.material.map((m) => glow.apply(m))
          : glow.apply(child.material);
        child.material = normal;
        meshes.push({ mesh: child, normal });
      });
      const home = node.position.clone();
      const away = home.clone().add(offsets.get(id)!);
      return { id, node, home, away, glow, meshes };
    });
  }

  private prepareBand(model: THREE.Object3D): void {
    if (this.band) {
      this.scene.remove(this.band);
      this.band.geometry.dispose();
      (this.band.material as THREE.Material).dispose();
    }
    const size = new THREE.Box3().setFromObject(model).getSize(new THREE.Vector3());
    this.band = scanBand(size.y * 1.15, Math.min(size.x, size.z) * 1.6, this.glowColor);
    this.scene.add(this.band);
  }

  private addShadowCatcher(model: THREE.Object3D): void {
    // Yeni model yüklenince eski zemin kalmasın.
    if (this.ground) {
      this.scene.remove(this.ground);
      this.ground.geometry.dispose();
      (this.ground.material as THREE.Material).dispose();
    }
    const size = new THREE.Box3().setFromObject(model).getSize(new THREE.Vector3());
    const ground = new THREE.Mesh(
      new THREE.PlaneGeometry(1, 1),
      new THREE.ShadowMaterial({ opacity: 0.28 }),
    );
    ground.rotation.x = -Math.PI / 2;
    ground.scale.setScalar(Math.max(size.x, size.z) * 4);
    ground.receiveShadow = true;
    this.scene.add(ground);
    this.ground = ground;

    const span = Math.max(size.x, size.y, size.z);
    const cam = this.sun.shadow.camera;
    cam.left = cam.bottom = -span;
    cam.right = cam.top = span;
    cam.far = span * 10;
    this.sun.position.set(span, span * 2, span * 1.2);
    cam.updateProjectionMatrix();
  }

  private async frameModel(animate: boolean): Promise<void> {
    if (!this.model) return;
    const box = new THREE.Box3().setFromObject(this.model);
    await this.controls.fitToBox(box, animate, {
      paddingTop: 0.15,
      paddingBottom: 0.15,
      paddingLeft: 0.15,
      paddingRight: 0.15,
    });
    // Hafif yukarıdan, önden üç çeyrek açı.
    await this.controls.rotateTo(-Math.PI / 5, Math.PI / 2.6, animate);
  }

  /**
   * Seçim, vurgu, izole ya da X-ışını değişince görünümü yeniler. Öne
   * çıkan parçalar kendi malzemesiyle parlar; diğerleri CAD görünümüne
   * geçer, izole edilmişse hiç görünmez.
   */
  private refreshMaterials(): void {
    const ghostOthers =
      this.scanning === null && (this.xray || this.selected !== null || this.weights.size > 0);
    for (const part of this.parts) {
      part.node.visible = this.isolated === null || part === this.isolated;
      const weight = this.weights.get(part.id) ?? 0;
      const isSelected = part === this.selected;
      const stands = isSelected || weight > 0;
      for (const { mesh, normal } of part.meshes) {
        const ghosted = ghostOthers && !stands;
        mesh.material = ghosted ? this.ghost : normal;
        mesh.castShadow = !ghosted;
      }
      part.glow.strength.value = isSelected ? 0.28 : restingGlow(weight);
    }
  }

  /** Sürükleme değil, kısa bir dokunuşsa parça seçilir. */
  private listenForTaps(canvas: HTMLCanvasElement): void {
    let down: { x: number; y: number } | null = null;
    canvas.addEventListener("pointerdown", (e) => (down = { x: e.clientX, y: e.clientY }));
    canvas.addEventListener("pointerup", (e) => {
      if (!down || Math.hypot(e.clientX - down.x, e.clientY - down.y) > 6) return;
      const rect = canvas.getBoundingClientRect();
      const pointer = new THREE.Vector2(
        ((e.clientX - rect.left) / rect.width) * 2 - 1,
        -((e.clientY - rect.top) / rect.height) * 2 + 1,
      );
      this.raycaster.setFromCamera(pointer, this.camera);
      // Raycaster gizli nesneleri de yakalar; izole görünümde gizli parçalar
      // seçilmesin.
      const hit = this.model
        ? this.raycaster.intersectObject(this.model, true).find((h) => isShown(h.object))
        : undefined;
      const part = hit ? this.parts.find((p) => isInside(hit.object, p.node)) : undefined;
      this.select(part?.id ?? null);
      if (part) void this.nudge(part.id);
      this.options.onPartTap?.(part?.id ?? null);
    });
  }
}

/** Tarama bittikten sonra kalan parlaklık; olasılıkla orantılı. */
function restingGlow(weight: number): number {
  return weight > 0 ? 0.15 + 0.85 * weight : 0;
}

/** Montaj haritasını indirir; yoksa ya da bozuksa null. */
async function loadMap(url: string): Promise<PartsMap | null> {
  try {
    const response = await fetch(url);
    if (!response.ok) return null;
    const json = (await response.json()) as PartsMap;
    return Array.isArray(json?.parts) ? json : null;
  } catch {
    return null;
  }
}

/** Nesne ve bütün üst düğümleri görünür mü? */
function isShown(object: THREE.Object3D): boolean {
  for (let o: THREE.Object3D | null = object; o; o = o.parent) {
    if (!o.visible) return false;
  }
  return true;
}

/** Bir modelin geometri ve malzemelerini GPU'dan bırakır. */
function disposeModel(model: THREE.Object3D, keep: THREE.Material): void {
  model.traverse((o) => {
    if (!(o instanceof THREE.Mesh)) return;
    o.geometry.dispose();
    for (const m of Array.isArray(o.material) ? o.material : [o.material]) {
      if (m !== keep) m.dispose();
    }
  });
}

function isInside(object: THREE.Object3D, ancestor: THREE.Object3D): boolean {
  for (let o: THREE.Object3D | null = object; o; o = o.parent) {
    if (o === ancestor) return true;
  }
  return false;
}
