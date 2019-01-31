#version 300 es
precision highp float;

uniform vec2 u_PlanePos; // Our location in the virtual world displayed by the plane

in vec3 fs_Pos;
in vec4 fs_Nor;
in vec4 fs_Col;
in float fs_Sea_Level;
in float fs_Sine;
out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.


float random1( vec3 p , vec3 seed) {
  return fract(sin(dot(p + seed, vec3(987.654, 123.456, 531.975))) * 85734.3545);
}

void main()
{
    float t = clamp(smoothstep(40.0, 50.0, length(fs_Pos)), 0.0, 1.0); // Distance fog
    
    vec4 out_Col_Forest = mix(vec4(0.0157, 0.051, 0.2549, 1.0), vec4(0.5333, 0.2078, 0.2078, 0.603), fs_Pos.y);

    if(fs_Pos.y > fs_Sea_Level)
    {
        out_Col = out_Col_Forest;
    }
    else{
        vec4 pool1 = vec4(0.0353, 0.1843, 0.2745, 1.0);
        vec4 pool2 = vec4(0.2824, 0.2824, 0.5529, 0.651);

        out_Col = mix(pool1, pool2, fs_Sine);
    }

   out_Col = mix(out_Col, vec4(164.0 / 255.0, 233.0 / 255.0, 1.0, 1.0), t);


}
