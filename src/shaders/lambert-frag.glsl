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

// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;
in vec4 fs_Pos;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.

// ---------- Constants --------------
const float cellCountMultiplier = 5.0;
const float maxLocusDist = 1.73;

// -------- Function Defs ------------
float hash3to1 (vec3 point);
vec3 hash3to3 (vec3 point);
float WorleyNoise (vec3 point);
vec3 GetWorleyLocus (vec3 point);

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

float WorleyNoise (vec3 point) {
    // adjust point "location" by cell count multiplier
    point *= cellCountMultiplier;

    // get the low-value corner for purposes of cell calculation/knowing which cell we're in
    vec3 currentLocus = floor(point);

    // get the fractional part of the point vector so we know where within the cell we are
    vec3 pointFract = fract(point);

    float minDist = 5.0;
    for (float x = -1.0; x <= 1.0; x += 1.0) {
        for (float y = -1.0; y <= 1.0; y += 1.0) {
            for (float z = -1.0; z <= 1.0; z += 1.0) {
                vec3 neighborCellOffset = vec3(x, y, z); // vector offset to locus of neighboring cell being analyzed

                // add offset to locus of neighboring cell, to the locus of the current point's cell so we can use that point
                vec3 neighborCellLocus = GetWorleyLocus(currentLocus + neighborCellOffset);

                // Distance between current point and neighbor cell’s locus
                vec3 diff = neighborCellOffset + neighborCellLocus - pointFract;
                float dist = length(diff);

                // check to see if the distance to neighbor's locus is closer than the current closest locus
                float newMinDist = min(minDist, dist);
                if (newMinDist < minDist) {
                    // hold closest distance
                    minDist = newMinDist;
                }
            }
        }
    }

    // return a fractional color modifier based on how far current point is from closest locus
    // closer to locus (lower dist) will return closer to white, while further will return darker color
    return 1.0 - (minDist / maxLocusDist);
}

vec3 GetWorleyLocus (vec3 point) {
    return hash3to3(point);
}

// -------------- Main ---------------
void main()
{
    // Material base color (before shading)
        vec4 diffuseColor = u_Color;

        // Calculate the diffuse term for Lambert shading
        float diffuseTerm = dot(normalize(fs_Nor), normalize(fs_LightVec));
        // Avoid negative lighting values
        // diffuseTerm = clamp(diffuseTerm, 0, 1);

        float ambientTerm = 0.2;

        float lightIntensity = diffuseTerm + ambientTerm;   //Add a small float value to the color multiplier
                                                            //to simulate ambient lighting. This ensures that faces that are not
                                                            //lit by our point light are not completely black.




        // Compute final shaded color
        out_Col = vec4(
            (diffuseColor.rgb * lightIntensity * WorleyNoise(fs_Pos.xyz)) / 255.0,
            diffuseColor.a
        );
}
