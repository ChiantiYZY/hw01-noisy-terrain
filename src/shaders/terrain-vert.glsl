#version 300 es


uniform mat4 u_Model;
uniform mat4 u_ModelInvTr;
uniform mat4 u_ViewProj;
uniform vec2 u_PlanePos; // Our location in the virtual world displayed by the plane
uniform vec4 u_Terrain_Size;

in vec4 vs_Pos;
in vec4 vs_Nor;
in vec4 vs_Col;

out vec3 fs_Pos;
out vec4 fs_Nor;
out vec4 fs_Col;

out float fs_Sine;
out float fs_Height;
out float fs_Height_Forest;
out float fs_Sea_Level;

out vec2 fs_Worley;

vec3 random3( vec3 p ) {
    return fract(sin(vec3(dot(p,vec3(127.1, 311.7, 191.999)),
                          dot(p,vec3(269.5, 183.3, 765.54)),
                          dot(p, vec3(420.69, 631.2,109.21))))
                 *43758.5453);
}

float WorleyNoise3D(vec3 p)
{
    // Tile the space
    vec3 pointInt = floor(p);
    vec3 pointFract = fract(p);

    float minDist = 1.0; // Minimum distance initialized to max.

    // Search all neighboring cells and this cell for their point
    for(int z = -1; z <= 1; z++)
    {
        for(int y = -1; y <= 1; y++)
        {
            for(int x = -1; x <= 1; x++)
            {
                vec3 neighbor = vec3(float(x), float(y), float(z));

                // Random point inside current neighboring cell
                vec3 point = random3(pointInt + neighbor);

                // Animate the point
                //point = 0.5 + 0.5 * sin(u_Time * 0.01 + 6.2831 * point); // 0 to 1 range

                // Compute the distance b/t the point and the fragment
                // Store the min dist thus far
                vec3 diff = neighbor + point - pointFract;
                float dist = length(diff);
                minDist = min(minDist, dist);
            }
        }
    }
    return minDist;
}

float worleyFBM(vec3 uv) {
    float sum = 0.f;
    float freq = 4.f;
    float amp = 0.5;
    for(int i = 0; i < 8; i++) {
        sum += WorleyNoise3D(uv * freq) * amp;
        freq *= 2.f;
        amp *= 0.5;
    }
    return sum;
}

//perlin noise
vec2 fade(vec2 t) {return t*t*t*(t*(t*6.0-15.0)+10.0);}

vec4 permute(vec4 x){return mod(((x*34.0)+1.0)*x, 289.0);}

float perlin_noise(vec2 P){
  vec4 Pi = floor(P.xyxy) + vec4(0.0, 0.0, 1.0, 1.0);
  vec4 Pf = fract(P.xyxy) - vec4(0.0, 0.0, 1.0, 1.0);
  Pi = mod(Pi, 289.0); // To avoid truncation effects in permutation
  vec4 ix = Pi.xzxz;
  vec4 iy = Pi.yyww;
  vec4 fx = Pf.xzxz;
  vec4 fy = Pf.yyww;
  vec4 i = permute(permute(ix) + iy);
  vec4 gx = 2.0 * fract(i * 0.0243902439) - 1.0; // 1/41 = 0.024...
  vec4 gy = abs(gx) - 0.5;
  vec4 tx = floor(gx + 0.5);
  gx = gx - tx;
  vec2 g00 = vec2(gx.x,gy.x);
  vec2 g10 = vec2(gx.y,gy.y);
  vec2 g01 = vec2(gx.z,gy.z);
  vec2 g11 = vec2(gx.w,gy.w);
  vec4 norm = 1.79284291400159 - 0.85373472095314 * 
    vec4(dot(g00, g00), dot(g01, g01), dot(g10, g10), dot(g11, g11));
  g00 *= norm.x;
  g01 *= norm.y;
  g10 *= norm.z;
  g11 *= norm.w;
  float n00 = dot(g00, vec2(fx.x, fy.x));
  float n10 = dot(g10, vec2(fx.y, fy.y));
  float n01 = dot(g01, vec2(fx.z, fy.z));
  float n11 = dot(g11, vec2(fx.w, fy.w));
  vec2 fade_xy = fade(Pf.xy);
  vec2 n_x = mix(vec2(n00, n01), vec2(n10, n11), fade_xy.x);
  float n_xy = mix(n_x.x, n_x.y, fade_xy.y);
  return 2.3 * n_xy;
}

float random1( vec2 p , vec2 seed) {
  return fract(sin(dot(p + seed, vec2(127.1, 311.7))) * 43758.5453);
}

float random1( vec3 p , vec3 seed) {
  return fract(sin(dot(p + seed, vec3(987.654, 123.456, 531.975))) * 85734.3545);
}

vec2 random2( vec2 p , vec2 seed) {
  return fract(sin(vec2(dot(p + seed, vec2(311.7, 127.1)), dot(p + seed, vec2(269.5, 183.3)))) * 85734.3545);
}



void main()
{
  fs_Pos = vs_Pos.xyz;

//couple inputs 
    float terrain_size = u_Terrain_Size.x;
    float distribution = u_Terrain_Size.y;
    float terrain_slope = u_Terrain_Size.z;
    fs_Sea_Level = u_Terrain_Size.w;

  //mountain height 
  float height = perlin_noise((vec2(vs_Pos.x, vs_Pos.z) + u_PlanePos) / distribution)
           + 0.5 * perlin_noise((vec2(vs_Pos.x, vs_Pos.z) + u_PlanePos) / distribution)
           + 0.25 * perlin_noise((vec2(vs_Pos.x, vs_Pos.z) + u_PlanePos) / distribution);

  float height_forest = perlin_noise((vec2(vs_Pos.x, vs_Pos.z) + u_PlanePos) / terrain_slope);
          //  + 0.5 * perlin_noise((vec2(vs_Pos.x, vs_Pos.z) + u_PlanePos) / 2.f)
          //  + 0.25 * perlin_noise((vec2(vs_Pos.x, vs_Pos.z) + u_PlanePos) / 2.f);

  float worley_Offset = worleyFBM(vs_Pos.xyz + vec3(u_PlanePos, 1.f));

  fs_Height = height * 6.f;
  fs_Sine = height;
  fs_Height_Forest = height_forest * terrain_size * 0.2;

  float tree_Height = mix(fs_Height, fs_Height_Forest, worley_Offset);

  float terrain_y = smoothstep(tree_Height, fs_Height_Forest, fs_Pos.y);

  float river_y = smoothstep(fs_Height_Forest, tree_Height, fs_Pos.y);

  fs_Pos.y = river_y;

  vec4 modelposition = vec4(fs_Pos, 1.f);

  modelposition = u_Model * modelposition;

  

  gl_Position = u_ViewProj * modelposition;



}
