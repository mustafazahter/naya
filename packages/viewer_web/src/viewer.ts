import CameraControls from "camera-controls";
import * as THREE from "three";
import { DRACOLoader } from "three/examples/jsm/loaders/DRACOLoader.js";
import { GLTFLoader } from "three/examples/jsm/loaders/GLTFLoader.js";
import { MeshoptDecoder } from "three/examples/jsm/libs/meshopt_decoder.module.js";
import { RoomEnvironment } from "three/examples/jsm/environments/RoomEnvironment.js";

CameraControls.install({ THREE });

/** Modeldeki tek bir parça: seçilebilen, parçalara ayırmada hareket eden düğüm. */
interface Part {
  id: string;
  node: THREE.Object3D;
  home: THREE.Vector3;
  /** Parçalara ayırırken gideceği yer, modelin yerel koordinatlarında. */
  away: THREE.Vector3;
  meshes: { mesh: THREE.Mesh; original: THREE.Material | THREE.Material[] }[];
}

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
    opacity: 0.16,
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
  private readonly accent = new THREE.Color("#8db8f2");
  private readonly ghost = ghostMaterial();
  private readonly highlighted = new Map<THREE.Material, THREE.Material>();

  private model: THREE.Object3D | null = null;
  private parts: Part[] = [];
  private selected: Part | null = null;
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

  async load(url: string): Promise<string[]> {
    const draco = new DRACOLoader().setDecoderPath(new URL("./draco/", document.baseURI).href);
    const loader = new GLTFLoader().setDRACOLoader(draco).setMeshoptDecoder(MeshoptDecoder);
    const gltf = await loader.loadAsync(url);
    if (this.model) this.scene.remove(this.model);
    this.model = gltf.scene;
    this.scene.add(this.model);

    this.placeOnGround(this.model);
    this.parts = this.collectParts(this.model);
    this.addShadowCatcher(this.model);
    await this.frameModel(false);
    return this.parts.map((p) => p.id);
  }

  /** 0 = toplu, 1 = tamamen ayrılmış. */
  explode(amount: number): void {
    this.explodeTarget = THREE.MathUtils.clamp(amount, 0, 1);
  }

  setXray(enabled: boolean): void {
    this.xray = enabled;
    this.refreshMaterials();
  }

  select(id: string | null): void {
    this.selected = this.parts.find((p) => p.id === id) ?? null;
    this.refreshMaterials();
  }

  async focus(id: string): Promise<void> {
    const part = this.parts.find((p) => p.id === id);
    if (!part) return;
    this.select(id);
    const box = new THREE.Box3().setFromObject(part.node);
    await this.controls.fitToBox(box, true, {
      paddingTop: 0.4,
      paddingBottom: 0.4,
      paddingLeft: 0.4,
      paddingRight: 0.4,
    });
  }

  async reset(): Promise<void> {
    this.select(null);
    this.explode(0);
    await this.frameModel(true);
  }

  // ------------------------------------------------------------------ iç işler

  private frame(): void {
    const delta = this.clock.getDelta();
    this.controls.update(delta);

    // Parçalara ayırma yumuşakça hedefe yaklaşır.
    const next = THREE.MathUtils.damp(this.explodeValue, this.explodeTarget, 6, delta);
    if (Math.abs(next - this.explodeValue) > 1e-4) {
      this.explodeValue = next;
      for (const part of this.parts) {
        part.node.position.lerpVectors(part.home, part.away, this.explodeValue);
      }
    }
    this.renderer.render(this.scene, this.camera);
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
  private collectParts(model: THREE.Object3D): Part[] {
    let level: THREE.Object3D = model;
    while (level.children.length === 1 && !(level.children[0] instanceof THREE.Mesh)) {
      level = level.children[0];
    }

    const modelBox = new THREE.Box3().setFromObject(model);
    const size = modelBox.getSize(new THREE.Vector3()).length();
    const center = level.worldToLocal(modelBox.getCenter(new THREE.Vector3()));

    return level.children.map((node, i) => {
      const meshes: Part["meshes"] = [];
      node.traverse((child) => {
        if (!(child instanceof THREE.Mesh)) return;
        child.castShadow = true;
        child.receiveShadow = true;
        meshes.push({ mesh: child, original: child.material });
      });

      const partCenter = level.worldToLocal(
        new THREE.Box3().setFromObject(node).getCenter(new THREE.Vector3()),
      );
      const direction = partCenter.clone().sub(center);
      if (direction.lengthSq() < 1e-8) direction.set(0, 1, 0);
      // Merkezden uzak parça biraz daha uzağa gider; hepsi kadrajda kalır.
      const distance = direction.length() * 0.55 + size * 0.04;
      const home = node.position.clone();
      const away = home.clone().add(direction.normalize().multiplyScalar(distance));
      return { id: node.name || `part-${i}`, node, home, away, meshes };
    });
  }

  private addShadowCatcher(model: THREE.Object3D): void {
    const size = new THREE.Box3().setFromObject(model).getSize(new THREE.Vector3());
    const ground = new THREE.Mesh(
      new THREE.PlaneGeometry(1, 1),
      new THREE.ShadowMaterial({ opacity: 0.28 }),
    );
    ground.rotation.x = -Math.PI / 2;
    ground.scale.setScalar(Math.max(size.x, size.z) * 4);
    ground.receiveShadow = true;
    this.scene.add(ground);

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
   * Seçim ya da X-ışını değişince malzemeleri yeniler. Seçili parça kendi
   * malzemesiyle ve hafif bir vurguyla kalır; diğerleri CAD görünümüne geçer.
   */
  private refreshMaterials(): void {
    const ghostOthers = this.xray || this.selected !== null;
    for (const part of this.parts) {
      const isSelected = part === this.selected;
      for (const { mesh, original } of part.meshes) {
        if (ghostOthers && !isSelected) {
          mesh.material = this.ghost;
          mesh.castShadow = false;
        } else {
          mesh.material = isSelected ? this.highlight(original) : original;
          mesh.castShadow = true;
        }
      }
    }
  }

  /** Malzemenin vurgulu kopyası; her malzeme için bir kez üretilir. */
  private highlight(material: THREE.Material | THREE.Material[]): THREE.Material | THREE.Material[] {
    if (Array.isArray(material)) return material.map((m) => this.highlight(m) as THREE.Material);
    let copy = this.highlighted.get(material);
    if (!copy) {
      copy = material.clone();
      if (copy instanceof THREE.MeshStandardMaterial) {
        copy.emissive = this.accent.clone();
        copy.emissiveIntensity = 0.18;
      }
      this.highlighted.set(material, copy);
    }
    return copy;
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
      const hit = this.model ? this.raycaster.intersectObject(this.model, true)[0] : undefined;
      const part = hit ? this.parts.find((p) => isInside(hit.object, p.node)) : undefined;
      this.select(part?.id ?? null);
      this.options.onPartTap?.(part?.id ?? null);
    });
  }
}

function isInside(object: THREE.Object3D, ancestor: THREE.Object3D): boolean {
  for (let o: THREE.Object3D | null = object; o; o = o.parent) {
    if (o === ancestor) return true;
  }
  return false;
}
