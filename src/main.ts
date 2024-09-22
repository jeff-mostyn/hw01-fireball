import {vec3, vec4} from 'gl-matrix';
// const Stats = require('stats-js');
import * as DAT from 'dat.gui';
import Icosphere from './geometry/Icosphere';
import Square from './geometry/Square';
import Cube from './geometry/Cube';
import OpenGLRenderer from './rendering/gl/OpenGLRenderer';
import Camera from './Camera';
import {setGL} from './globals';
import ShaderProgram, {Shader} from './rendering/gl/ShaderProgram';
import CustomMesh from './geometry/CustomMesh';

// Define an object with application parameters and button callbacks
// This will be referred to by dat.GUI's functions that add GUI elements.
const controls = {
  tesselations: 5,
  'Load Scene': loadScene, // A function pointer, essentially
  'Reset Fireball': reset, // A function pointer, essentially
  // color: [255.0, 78.0, 0.0, 255.0],
  CoreColor: [255.0, 218.0, 41.0, 255.0],
  CoolColor1: [216.0, 68.0, 4.0, 255.0],
  CoolColor2: [235.0, 64.0, 4.0, 255.0],
};

let icosphere: Icosphere;
let square: Square;
let cube: Cube;
let customMesh: CustomMesh | undefined;
let prevTesselations: number = 5;

// save default colors
const defaultCoreColor: number[] = [controls.CoreColor[0], controls.CoreColor[1], controls.CoreColor[2], controls.CoreColor[3]];
const defaultCoolColor1: number[] = [controls.CoolColor1[0], controls.CoolColor1[1], controls.CoolColor1[2], controls.CoolColor1[3]];
const defaultCoolColor2: number[] = [controls.CoolColor2[0], controls.CoolColor2[1], controls.CoolColor2[2], controls.CoolColor2[3]];

function loadScene() {
  icosphere = new Icosphere(vec3.fromValues(0, 0, 0), 1, controls.tesselations);
  icosphere.create();
  square = new Square(vec3.fromValues(0, 0, 0));
  square.create();
  cube = new Cube(vec3.fromValues(0, 0, 0));
  cube.create();
}

function reset() {
  controls.CoreColor = defaultCoreColor;
  controls.CoolColor1 = defaultCoolColor1;
  controls.CoolColor2 = defaultCoolColor2;
}

const fileInput = document.getElementById('fileinput') as HTMLInputElement;

fileInput.addEventListener('change', () => {
   const file = fileInput.files[0];
   if (file) {
      const fileReader = new FileReader();
      fileReader.onload = () => {
        const fileContent = fileReader.result as string;
        const rows = fileContent.split('\n');

        customMesh = new CustomMesh(vec3.fromValues(0,0,0), rows);
        customMesh.create();
      };
      fileReader.readAsText(file);
   }
});

function main() {
  // Initial display for framerate
  // const stats = Stats();
  // stats.setMode(0);
  // stats.domElement.style.position = 'absolute';
  // stats.domElement.style.left = '0px';
  // stats.domElement.style.top = '0px';
  // document.body.appendChild(stats.domElement);

  // Add controls to the gui
  const gui = new DAT.GUI();
  gui.add(controls, 'tesselations', 0, 8).step(1);
  gui.add(controls, 'Load Scene');
  gui.add(controls, 'Reset Fireball');

  // gui.addColor(controls, 'color');
  gui.addColor(controls, 'CoreColor');
  gui.addColor(controls, 'CoolColor1');
  gui.addColor(controls, 'CoolColor2');

  // get canvas and webgl context
  const canvas = <HTMLCanvasElement> document.getElementById('canvas');
  const gl = <WebGL2RenderingContext> canvas.getContext('webgl2');
  if (!gl) {
    alert('WebGL 2 not supported!');
  }
  // `setGL` is a function imported above which sets the value of `gl` in the `globals.ts` module.
  // Later, we can import `gl` from `globals.ts` to access it
  setGL(gl);

  // Initial call to load scene
  loadScene();

  const camera = new Camera(vec3.fromValues(0, 0, 5), vec3.fromValues(0, 0, 0));

  const renderer = new OpenGLRenderer(canvas);
  renderer.setClearColor(0.2, 0.2, 0.2, 1);
  gl.enable(gl.DEPTH_TEST);

  const lambert_hw00 = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/lambert-vert.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/lambert-frag.glsl')),
  ]);

  const lambert_hw01 = new ShaderProgram([
    new Shader(gl.VERTEX_SHADER, require('./shaders/lambert-vert-fireball.glsl')),
    new Shader(gl.FRAGMENT_SHADER, require('./shaders/lambert-frag-fireball.glsl')),
  ]);

  // This function will be called every frame
  function tick(thisFrame: number) {

    // convert time to seconds
    thisFrame *= 0.001;

    // update stuff
    camera.update();
    // stats.begin();
    gl.viewport(0, 0, window.innerWidth, window.innerHeight);
    renderer.clear();

    lambert_hw01.setTime(thisFrame);

    // set base color
    lambert_hw01.setCustomColor(
      [controls.CoreColor[0], controls.CoreColor[1], controls.CoreColor[2], controls.CoreColor[3]],
      [controls.CoolColor1[0], controls.CoolColor1[1], controls.CoolColor1[2], controls.CoolColor1[3]],
      [controls.CoolColor2[0], controls.CoolColor2[1], controls.CoolColor2[2], controls.CoolColor2[3]],
    )

    if(controls.tesselations != prevTesselations)
    {
      prevTesselations = controls.tesselations;
      icosphere = new Icosphere(vec3.fromValues(0, 0, 0), 1, prevTesselations);
      icosphere.create();
    }
    
    if (customMesh != undefined) {
      renderer.render(camera, lambert_hw01, [
        customMesh
      ])
    }
    else {
      renderer.render(camera, lambert_hw01, [
        icosphere,
      ]);
    }

    // Tell the browser to call `tick` again whenever it renders a new frame
    requestAnimationFrame(tick);
  }

  window.addEventListener('resize', function() {
    renderer.setSize(window.innerWidth, window.innerHeight);
    camera.setAspectRatio(window.innerWidth / window.innerHeight);
    camera.updateProjectionMatrix();
  }, false);

  renderer.setSize(window.innerWidth, window.innerHeight);
  camera.setAspectRatio(window.innerWidth / window.innerHeight);
  camera.updateProjectionMatrix();

  // Start the render loop
  tick(0);
}

main();
