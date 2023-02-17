import * as THREE from 'three'
import { gl } from './core/WebGL'
import { Assets, loadAssets } from './utils/assetLoader'
import { controls } from './utils/OrbitControls'
import vertexShader from './shaders/vertex.glsl'
import fragmentShader from './shaders/fragment.glsl'
import 'glsl-noise/simplex/2d.glsl'
import { GUIController } from './utils/gui'
import { mouse2d } from './utils/Mouse2D'

const mouseDummy = new THREE.Vector2()

const store = {
  progress: 0.3,
}

export class TCanvas {
  private assets: Assets = {
    // https://sketchfab.com/3d-models/deer-sculpture-e97f99c0216a4cae9a8b11d044d2694a
    model: { path: '/resources/deer.glb' },
    matcap: { path: '/pngegg.png' },
    matcap2: { path: '/chrome.png' },
  }

  constructor(private parentNode: ParentNode) {
    loadAssets(this.assets).then(() => {
      this.init()
      this.initControls()
      this.createObjects()
      gl.requestAnimationFrame(this.anime)
    })
  }

  private init() {
    gl.setup(this.parentNode.querySelector('.three-container')!)
    gl.scene.background = new THREE.Color('#fff')
  }

  // lil-gui
  private initControls() {
    const gui = GUIController.instance
    gui.addNumericSlider(store, 'progress', 0, 1, 0.01)
  }

  private createObjects() {
    const material = new THREE.ShaderMaterial({
      uniforms: {
        uResolution: {
          value: new THREE.Vector4(gl.size.width, gl.size.height, 1, gl.size.aspect),
        },
        uTexture: {
          value: this.assets.matcap.data,
        },
        uTexture2: {
          value: this.assets.matcap2.data,
        },
        uMouse: {
          value: mouseDummy.set(mouse2d.position[0], mouse2d.position[1]),
        },
        uProgress: {
          value: store.progress,
        },
        uTime: {
          value: 0,
        },
      },
      vertexShader,
      fragmentShader,
    })

    // --------------------

    const plane = new THREE.PlaneGeometry(1, 1)
    const planeMesh = new THREE.Mesh(plane, material)
    planeMesh.name = 'floor'
    gl.scene.add(planeMesh)
  }

  // ----------------------------------
  // animation
  private anime = () => {
    const floor = gl.getMesh<THREE.ShaderMaterial>('floor')
    floor.material.uniforms.uTime.value = gl.time.elapsed
    floor.material.uniforms.uMouse.value = mouseDummy.set(mouse2d.position[0], mouse2d.position[1]).clone()
    floor.material.uniforms.uProgress.value = store.progress
    gl.render()
  }

  // ----------------------------------
  // dispose
  dispose() {
    gl.dispose()
  }
}
