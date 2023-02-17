#include ../glsl/snoise2d.glsl

uniform vec4 uResolution;
uniform sampler2D uTexture;
uniform sampler2D uTexture2;
uniform float uTime;
uniform float uProgress;
uniform vec2 uMouse;

varying vec2 vUv;
varying vec3 vNormal;
varying vec3 vSurfaceToLight;

float PI = 3.14159265358979;

vec2 matcap(vec3 eye, vec3 normal) {
  vec3 reflected = reflect(eye, normal);
  float m = 2.8284271247461903 * sqrt( reflected.z+1.0 );
  return reflected.xy / m + 0.5;
}

mat4 rotationMatrix(vec3 axis, float angle) {
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;
    
    return mat4(oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,  0.0,
                oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,  0.0,
                oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c,           0.0,
                0.0,                                0.0,                                0.0,                                1.0);
}

vec3 rotate(vec3 v, vec3 axis, float angle) {
	mat4 m = rotationMatrix(axis, angle);
	return (m * vec4(v, 1.0)).xyz;
}

float smin( float a, float b, float k )
{
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

float sdSphere(vec3 p, float r) {
  return length(p)-r;
}

float sdBox( vec3 p, vec3 b ) {
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float rand(vec2 co){
    return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

float sdf(vec3 p) {
  vec3 p1 = rotate(p, vec3(1.0, 0.5, 0.0), uTime);
  float box = smin(sdBox(p1, vec3(0.2)), sdSphere(p, 0.2), 0.3);

  float realSphere = sdSphere(p1, 0.3);
  float final = mix(box, realSphere, uProgress);


  for(float i = 0.0; i < 5.0; i++) {
    float randOffset = rand(vec2(i, 0.0));
    float progress = 1.0 - fract(uTime/3.0 + randOffset * 3.0);
    vec3 pos = vec3(sin(randOffset * 2.0 * PI)*2.0, cos(randOffset * 2.0 * PI), 0.0);
    float gotoCenter = sdSphere(p- pos * progress, 0.1);
    final = smin(final, gotoCenter, 0.3);
  }



  // float mouseSphere = sdSphere(p - vec3(uMouse*uResolution.w, 0.0), 0.4);
  // return smin(final, mouseSphere, 0.2);
  return final;
}

vec3 calcNormal( vec3 p ) // for function f(p)
{
    float eps = 0.0001; // or some other value
    vec2 h = vec2(eps,0);
    return normalize( vec3(sdf(p+h.xyy) - sdf(p-h.xyy),
                           sdf(p+h.yxy) - sdf(p-h.yxy),
                           sdf(p+h.yyx) - sdf(p-h.yyx) ) );
}



void main() {
  float dist = length(vUv - vec2(0.5));
  vec3 bg = mix(vec3(0.3), vec3(0.0), dist);

  vec2 newUv = (vUv - vec2(0.5))*uResolution.wz + vec2(0.5);

  vec3 cameraPos = vec3(0.0, 0.0, 2.0);
  vec3 ray = normalize(vec3(newUv - vec2(0.5), -1));

  vec3 rayPos = cameraPos;
  float t = 0.0;
  float tMax = 5.0;

  for(int i=0;i<100;++i) {
    // moving foward
    vec3 pos = cameraPos + t * ray;
    float h = sdf(pos);
    if ( h<0.0001 || t>tMax) break;
    t += h;
  }

  vec3 color = bg;

  if (t<tMax) {
    vec3 pos = cameraPos + t * ray;
    color = vec3(1.0);
    vec3 normal = calcNormal(pos);
    color = normal;

    float diff = dot(vec3(1.0, 1.0, 1.0), normal);

    vec2 matcapUV = matcap(ray, normal);
    color = vec3(diff);
    color = vec3(matcapUV, 0.0);
    color = texture2D(uTexture2, matcapUV).rgb;

    float fresnel = pow(1.0 +dot(ray, normal), 3.0);
    // color = vec3(fresnel);

    color = mix(color, bg, fresnel);
  }
  gl_FragColor = vec4(color, 1.0);
  // gl_FragColor = vec4(vec3(dist), 1.0);
}
