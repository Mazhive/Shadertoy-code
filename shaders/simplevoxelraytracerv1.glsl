float screenDist = 1.0;
float rayLength = 0.001;
float screenSize = 1.5;

int ITER = 1000;

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (fragCoord/iResolution.xy) * 2.0 - vec2(1.0);
    uv.x /= iResolution.y / iResolution.x;
    vec3 camera_pos = (vec3(sin(iTime), cos(iTime), -3.0) * 0.1) + vec3(0.5, 0.5, 0.0);
    vec3 ray_pos = camera_pos;
    
    vec3 ray_step = normalize(vec3(uv * screenSize, screenDist)) * rayLength;

    vec4 color = vec4(0.0);
    
    for (int i = 0; i < ITER; i++) {
        ray_pos += ray_step;
        vec4 voxel = texture(iChannel0, ray_pos);
        
        // (optional) Making dense voxels more clumped 
        voxel += texture(iChannel0, ray_pos / 2.0);
        voxel += texture(iChannel0, ray_pos / 4.0);
        voxel += texture(iChannel0, ray_pos / 8.0);
        voxel *= 0.25;
        
        // (optional) Making density more different
        voxel.a = smoothstep(0.0, 1.0, pow(voxel.a, 10.0));
        
        // Compute absolute density
        voxel.a = mix(voxel.a, 1.0, color.a) - color.a; 
        
        // Applying color
        color.rgb += voxel.rgb * voxel.a;
        color.a += voxel.a;
    }
    
    fragColor = color;
    
}
