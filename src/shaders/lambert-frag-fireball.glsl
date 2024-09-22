#version 300 es

// This is a fragment shader. If you've opened this file first, please
// open and read lambert.vert.glsl before reading on.
// Unlike the vertex shader, the fragment shader actually does compute
// the shading of geometry. For every pixel in your program's output
// screen, the fragment shader is run for every bit of geometry that
// particular pixel overlaps. By implicitly interpolating the position
// data passed into the fragment shader by the vertex shader, the fragment shader
// can compute what color to apply to its pixel based on things like vertex
// position, light position, and vertex color.
precision highp float;

uniform vec4 u_Color; // The color with which to render this instance of geometry.
uniform vec4 u_CoreColor; // The color with which to render this instance of geometry.
uniform vec4 u_CoolColor1; // The color with which to render this instance of geometry.
uniform vec4 u_CoolColor2; // The color with which to render this instance of geometry.

// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Nor;
in vec4 fs_LightVec;
// in vec4 fs_Col;
in vec4 fs_Pos;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.

// ---------- Constants --------------
const float cellCountMultiplier = 5.0;
const float maxLocusDist = 1.73;

// -------- Function Defs ------------
float map(float value, float min1, float max1, float min2, float max2);
float hash3to1 (vec3 point);
vec3 hash3to3 (vec3 point);
float bias (float b, float t);
float gain (float g, float t);

// ------------ Function Implementation -----------
float map(float value, float min1, float max1, float min2, float max2) {
  return min2 + (value - min1) * (max2 - min2) / (max1 - min1);
}

float hash3to1(vec3 point) {
    return fract(sin(
        dot(
            point,
            vec3(343.7, 151.1, 938.3)
        )
    ) * 200419.35);
}

vec3 hash3to3(vec3 point3D) {
    return fract(sin(
        vec3(
            dot(
                point3D,
                vec3(343.7, 151.1, 938.3)
            ),
            dot(
                point3D,
                vec3(678.9, 432.1, 352.9)
            ),
            dot(
                point3D,
                vec3(427.4, 537.2, 738.9)
            )
        )
    ) * 200419.35);
}

float bias (float b, float t) {
    return pow(t, log(b) / log(0.5));
}
float gain (float g, float t) {
    if (t < 0.5) {
        return bias(1.0 - g, 2.0 * t) / 2.0;
    }
    else {
        return 1.0 - (bias(1.0 - g, (2.0 - 2.0 * t)) / 2.0);
    }
}

// -------------- Main ---------------
void main()
{
    // Material base color (before shading)
    // Calculate the diffuse term for Lambert shading
    float diffuseTerm = dot(normalize(fs_Nor), normalize(fs_LightVec));
    // Avoid negative lighting values
    // diffuseTerm = clamp(diffuseTerm, 0, 1);

    float ambientTerm = 0.2;

    float lightIntensity = diffuseTerm + ambientTerm;   //Add a small float value to the color multiplier
                                                        //to simulate ambient lighting. This ensures that faces that are not
                                                        //lit by our point light are not completely black.

    vec3 blendedInnerColor = mix(
        u_CoreColor.rgb,
        u_CoolColor2.rgb,
        map(
            fs_Pos.y,
            -1.0, 1.0, 0.0, 1.0
        )
    );

    vec3 lerpColor = mix(
        blendedInnerColor, 
        u_CoolColor1.rgb, 
        map(
            length(vec3(fs_Pos.x, fs_Pos.y, fs_Pos.z)),
            0.95, 1.15, 0.0, 1.0 
        )
    );

    // Compute final shaded color
    out_Col = vec4(
        (lerpColor.rgb) / 255.0,
        1.0
    );
}
