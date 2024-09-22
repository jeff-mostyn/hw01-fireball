#version 300 es

//This is a vertex shader. While it is called a "shader" due to outdated conventions, this file
//is used to apply matrix transformations to the arrays of vertex data passed to it.
//Since this code is run on your GPU, each vertex is transformed simultaneously.
//If it were run on your CPU, each vertex would have to be processed in a FOR loop, one at a time.
//This simultaneous transformation allows your program to run much faster, especially when rendering
//geometry with millions of vertices.

uniform mat4 u_Model;       // The matrix that defines the transformation of the
                            // object we're rendering. In this assignment,
                            // this will be the result of traversing your scene graph.

uniform mat4 u_ModelInvTr;  // The inverse transpose of the model matrix.
                            // This allows us to transform the object's normals properly
                            // if the object has been non-uniformly scaled.

uniform mat4 u_ViewProj;    // The matrix that defines the camera's transformation.
                            // We've written a static matrix for you to use for HW2,
                            // but in HW3 you'll have to generate one yourself

uniform float u_Time;            // Amount time has advanced since render start.


in vec4 vs_Pos;             // The array of vertex positions passed to the shader

in vec4 vs_Nor;             // The array of vertex normals passed to the shader

in vec4 vs_Col;             // The array of vertex colors passed to the shader.


out vec4 fs_Nor;            // The array of normals that has been transformed by u_ModelInvTr. This is implicitly passed to the fragment shader.
out vec4 fs_LightVec;       // The direction in which our virtual light lies, relative to each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Col;            // The color of each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Pos;

const vec4 lightPos = vec4(5, 5, 3, 1); //The position of our virtual light, which is used to compute the shading of
                                        //the geometry in the fragment shader.

// ---------- Constants --------------
const float LARGE_FLICKER_MAGNITUDE = 0.6;
const float SMALL_FLICKER_MAGNITUDE = 0.5;
const float PEAK_AMPLITUDE = 1.15;
const float PEAK_FREQUENCY = 5.0;

// -------- Function Defs ------------

float hash3to1 (vec3 point);
float PerlinNoise (vec3 point, float frequency, float amplitude);
float FBM (vec3 point);

// ------------ Function Implementation -----------
float map(float value, float min1, float max1, float min2, float max2) {
  return min2 + (value - min1) * (max2 - min2) / (max1 - min1);
}

float bias (float b, float t) {
    return pow(t, log(b) / log(0.5));
}

float fireballSilhouetteDisplacement (vec3 position) {
    float shrinkAmount = 0.0;

    float t_height = (position.y + 1.0) / 2.0;

    // bias
    shrinkAmount = 1.0 * bias(0.5, pow(t_height, 1.4));

    return shrinkAmount;
}

float largeFlickerDisplacement (vec3 position, float time) {
    float t_height = (position.y + 1.0) / 2.0;

    return 
        ( // the first sine is large steady waver, the others are "noise"/irregularly offset smaller flickers
            sin(((position.y - (time * 1.25)) * 1.6)) 
            + max(0.0, (sin(position.y - (time * 3.0)) - 0.75) * 1.5) 
            + max(0.0, (sin(position.y - (time * 4.0) + 1.5) - 0.75) * 1.2)
            + max(0.0, (sin(position.y - (time * 3.0) + 2.25) - 0.75) * 2.0)
            + max(0.0, (sin(position.y - (time * 4.0) + 2.8) - 0.75) * 1.2)
        )
        * LARGE_FLICKER_MAGNITUDE 
        * bias(0.3, t_height);
}

float hash3to1(vec3 point) {
    return fract(sin(
        dot(
            point,
            vec3(343.7, 151.1, 938.3)
        )
    ) * 200419.35);
}

float PerlinNoise (vec3 point, float frequency, float amplitude) {
    const float baseFrequencyMultiplier = 1.1;

    point *= frequency;
    point *= baseFrequencyMultiplier;

    vec3 flooredPoint = floor(point);
    vec3 pointFract = fract(point);

    // pass corners of a cube into the random hash function
    float front_bottom_left =   hash3to1(flooredPoint);
    float front_bottom_right =  hash3to1(flooredPoint + vec3(1.0, 0.0, 0.0));
    float back_bottom_left =    hash3to1(flooredPoint + vec3(0.0, 0.0, 1.0));
    float back_bottom_right =   hash3to1(flooredPoint + vec3(1.0, 0.0, 1.0));

    float front_top_left =      hash3to1(flooredPoint + vec3(0.0, 1.0, 0.0));
    float front_top_right =     hash3to1(flooredPoint + vec3(1.0, 1.0, 0.0));
    float back_top_left =       hash3to1(flooredPoint + vec3(0.0, 1.0, 1.0));
    float back_top_right =      hash3to1(flooredPoint + vec3(1.0, 1.0, 1.0));

    // vec3 u = pointFract * pointFract * (3.0 - (2.0 * pointFract));

    // based on fract value, interpolate between the eight corners
    float mix_bottom_left = mix(front_bottom_left, back_bottom_left, pointFract.z);
    float mix_bottom_right = mix(front_bottom_right, back_bottom_right, pointFract.z);
    float mix_top_left = mix(front_top_left, back_top_left, pointFract.z);
    float mix_top_right = mix(front_top_right, back_top_right, pointFract.z);

    float mix_bottom = mix(mix_bottom_left, mix_bottom_right, pointFract.x);
    float mix_top = mix(mix_top_left, mix_top_right, pointFract.x);

    float mix_volume = mix(mix_bottom, mix_top, pointFract.y);

    return mix_volume * amplitude;
}

float FBM (vec3 point) {
    return PerlinNoise(point, 1.0, 1.0) 
        + PerlinNoise(point, 2.0, 0.5)
        + PerlinNoise(point, 4.0, 0.25)
        + PerlinNoise(point, 8.0, 0.125)
        + PerlinNoise(point, 16.0, 0.0625);
}

void main()
{
    vec3 vertexPosition = vs_Pos.xyz;
    vec3 shrinkDirection = vec3(-vs_Pos.x, 0, -vs_Pos.z);

    // create the fireball silhouette
    vertexPosition += shrinkDirection * fireballSilhouetteDisplacement(vertexPosition);
    
    // offset large displacement
    vertexPosition += vec3(largeFlickerDisplacement(vertexPosition, u_Time), 0.0, 0.0);

    // apply perlin noise to create moving peaks
    if (vertexPosition.y > -0.35) {
        // vertical displacement moving from right
        vec3 leftwardMotionDisplacement = mix(
            vec3(
                0.0, 
                PerlinNoise(vertexPosition + vec3(u_Time, 0.0, 0.0), PEAK_FREQUENCY, PEAK_AMPLITUDE), 
                0.0
            ),
            vec3(0.0, 0.0, 0.0),
            map(vertexPosition.x, -0.5, 1.0, 0.0, 1.0)
        );

        // vertical displacement moving from left
        vec3 rightwardMotionDisplacement = mix(
            vec3(0.0, 0.0, 0.0),
            vec3(
                0.0, 
                PerlinNoise(vertexPosition + vec3(-u_Time, 0.0, 0.0), PEAK_FREQUENCY, PEAK_AMPLITUDE), 
                0.0
            ),
            map(vertexPosition.x, -1.0, 0.5, 0.0, 1.0)
        );

        // vertical displacement moving from front
        vec3 backwardMotionDisplacement = mix(
            vec3(
                0.0,
                PerlinNoise(vertexPosition + vec3(0.0, 0.0, u_Time), PEAK_FREQUENCY, PEAK_AMPLITUDE), 
                0.0
            ),
            vec3(0.0, 0.0, 0.0),
            map(vertexPosition.z, -0.5, 1.0, 0.0, 1.0)
        );

        // vertical displacement moving from back
        vec3 forwardMotionDisplacement = mix(
            vec3(0.0, 0.0, 0.0),
            vec3(
                0.0, 
                PerlinNoise(vertexPosition + vec3(0.0, 0.0, -u_Time), 4.0, PEAK_AMPLITUDE), 
                0.0
            ),
            map(vertexPosition.z, -1.0, 0.5, 0.0, 1.0)
        );

        vec3 netVerticalDisplacement = (mix(
            rightwardMotionDisplacement, 
            leftwardMotionDisplacement, 
            map(vertexPosition.x, -1.0, 1.0, 0.0, 1.0)
        ) + mix(
            forwardMotionDisplacement, 
            backwardMotionDisplacement, 
            map(vertexPosition.z, -1.0, 1.0, 0.0, 1.0)
        )) / 2.0;

        vertexPosition += netVerticalDisplacement;
    }

    // offset based on FBM noise
    vertexPosition += (
        -shrinkDirection 
        * FBM(vertexPosition + vec3(0.0, -u_Time * 2.5, 0.0)) 
        * SMALL_FLICKER_MAGNITUDE 
        * mix(1.0, 0.0, (vertexPosition.y + 1.0) * .5));


    // fs_Col = vs_Col;                            // Pass the vertex colors to the fragment shader for interpolation
    fs_Pos = vec4(vertexPosition, vs_Pos.w);                            // Pass the vertex position to fragment shader


    mat3 invTranspose = mat3(u_ModelInvTr);
    fs_Nor = vec4(invTranspose * vec3(vs_Nor), 0);          // Pass the vertex normals to the fragment shader for interpolation.
                                                            // Transform the geometry's normals by the inverse transpose of the
                                                            // model matrix. This is necessary to ensure the normals remain
                                                            // perpendicular to the surface after the surface is transformed by
                                                            // the model matrix.

    // vec4 modelposition = u_Model * vec4(vertexPosition.xyz, 0);   // Temporarily store the transformed vertex positions for use below
    vec4 modelposition = u_Model * vec4(vertexPosition, vs_Pos.w);   // Temporarily store the transformed vertex positions for use below

    fs_LightVec = lightPos - modelposition;  // Compute the direction in which the light source lies

    gl_Position = u_ViewProj * modelposition;// gl_Position is a built-in variable of OpenGL which is
                                             // used to render the final positions of the geometry's vertices
}
