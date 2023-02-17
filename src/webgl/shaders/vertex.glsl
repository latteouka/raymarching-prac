uniform vec3 uLightPos;

varying vec2 vUv;
varying vec3 vNormal;
varying vec3 vSurfaceToLight;

void main() {
  vUv = uv;
  // inverse transpose of modelViewMatrix *
  // geometry normal
  // geometry normal into world
  vNormal = normalize(normalMatrix * normal);

  gl_Position = projectionMatrix * modelViewMatrix * vec4( position, 1.0 );

  // surface position
  vec3 worldSurfacePos = vec3(modelViewMatrix * vec4(position, 1.0));
  vec3 worldLightPos = vec3(viewMatrix * vec4(uLightPos, 1.0));

  vSurfaceToLight = normalize(worldLightPos - worldSurfacePos);
}
