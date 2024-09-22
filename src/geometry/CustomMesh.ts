import {vec3, vec4} from 'gl-matrix';
import Drawable from '../rendering/gl/Drawable';
import {gl} from '../globals';
// import * as fs from 'fs'

class CustomMesh extends Drawable {
  indices: Uint32Array;
  positions: Float32Array;
  normals: Float32Array;
  center: vec4;
  data: string[];

  constructor(center: vec3, data: string[]) {
    super(); // Call the constructor of the super class. This is required.
    this.center = vec4.fromValues(center[0], center[1], center[2], 1);
 
    this.data = data;
  }

  create() {
    const vertpositions: number[] = [];
    const vertnormals: number[] = [];
    const indices: number[] = []

    this.data.forEach(dataLine =>  {
      const normalizedLine = dataLine.trim();
      
      if (normalizedLine && !normalizedLine.startsWith("#")) {
        const parts = normalizedLine.split(/\s+/g);
        const values = parts.slice(1).map(x => parseFloat(x));
        
        switch(parts[0]){
          case "v": {
            vertpositions.push(...values);
            vertpositions.push(1);
            break;
          }
          case "vn": {
            vertnormals.push(...values);
            vertnormals.push(0);
            break;
          }
          case "f": {
            indices.push(...values.map(x => x - 1));
            break;
          }
        }
      }

    });

    this.indices = new Uint32Array([...indices]);
    this.normals = new Float32Array([...vertnormals]);
    this.positions = new Float32Array([...vertpositions]);

    this.generateIdx();
    this.generatePos();
    this.generateNor();

    for (let i = 0; i < 4; i++) {
      for (let j = 0; j < 4; j++) {
        if (j != 3) this.positions[4 * i + j] += this.center[j];
      }
    }

    this.count = this.indices.length;
    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, this.bufIdx);
    gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, this.indices, gl.STATIC_DRAW);

    gl.bindBuffer(gl.ARRAY_BUFFER, this.bufNor);
    gl.bufferData(gl.ARRAY_BUFFER, this.normals, gl.STATIC_DRAW);

    gl.bindBuffer(gl.ARRAY_BUFFER, this.bufPos);
    gl.bufferData(gl.ARRAY_BUFFER, this.positions, gl.STATIC_DRAW);

    console.log(`Created custom mesh`);
  }
};

export default CustomMesh;
