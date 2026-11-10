import * as THREE from "three";

/**
 * Parçaya kenar parlaması (rim glow) ekler. Malzemenin kopyasına küçük bir
 * shader eki konur; güç 0 iken görünüm değişmez. Tam ekran son işleme
 * (bloom, outline pass) yerine bu yolu seçtik: telefonda da her karede tek
 * çizim, fazladan geçiş yok.
 */
export class Glow {
  /** 0 = parlama yok. Tarama ve vurgu bunu değiştirir. */
  readonly strength = { value: 0 };
  readonly color: { value: THREE.Color };

  constructor(color: THREE.Color) {
    this.color = { value: color };
  }

  /** [material]'in bu parçaya özel, parlayabilen kopyası. */
  apply(material: THREE.Material): THREE.Material {
    const copy = material.clone();
    copy.onBeforeCompile = (shader) => {
      shader.uniforms.glowStrength = this.strength;
      shader.uniforms.glowColor = this.color;
      shader.fragmentShader = shader.fragmentShader
        .replace(
          "#include <common>",
          "#include <common>\nuniform float glowStrength;\nuniform vec3 glowColor;",
        )
        .replace(
          "#include <emissivemap_fragment>",
          [
            "#include <emissivemap_fragment>",
            // Kenara yaklaştıkça artan ışık: parça hacmini kaybetmeden öne çıkar.
            "float nayaRim = 1.0 - abs(dot(normal, normalize(vViewPosition)));",
            "totalEmissiveRadiance += glowColor * glowStrength * (0.3 + 2.4 * pow(nayaRim, 2.0));",
          ].join("\n"),
        );
    };
    // Bütün parlayan kopyalar aynı shader'ı kullansın; her biri için ayrı
    // derleme olmasın.
    copy.customProgramCacheKey = () => "naya-glow";
    return copy;
  }
}

/** Taramada modelin boyunca geçen ışık bandı. */
export function scanBand(height: number, depth: number, color: THREE.Color): THREE.Mesh {
  const material = new THREE.ShaderMaterial({
    uniforms: { bandColor: { value: color }, opacity: { value: 0 } },
    vertexShader: /* glsl */ `
      varying vec2 vUv;
      void main() {
        vUv = uv;
        gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
      }`,
    fragmentShader: /* glsl */ `
      uniform vec3 bandColor;
      uniform float opacity;
      varying vec2 vUv;
      void main() {
        // Dört kenara doğru sönen ışık perdesi; ortası hafifçe daha parlak.
        float y = smoothstep(0.0, 0.25, vUv.y) * smoothstep(1.0, 0.75, vUv.y);
        float x = smoothstep(0.0, 0.35, vUv.x) * smoothstep(1.0, 0.65, vUv.x);
        float core = 0.5 + 0.5 * x;
        gl_FragColor = vec4(bandColor, opacity * y * x * core * 0.22);
      }`,
    transparent: true,
    depthWrite: false,
    side: THREE.DoubleSide,
    blending: THREE.AdditiveBlending,
  });
  const band = new THREE.Mesh(new THREE.PlaneGeometry(depth, height), material);
  band.rotation.y = Math.PI / 2;
  band.renderOrder = 10;
  return band;
}
