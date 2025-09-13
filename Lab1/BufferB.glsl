const int FIGURES_COUNT = 20;
const float E = 2.718281828;
const float PI = 3.1415926535;
const float FALL_SPEED = 0.49;
const float MAX_TIMER = 5.0;

float rand(in vec2 vec)
{
    return fract(sin(dot(vec, vec2(12.9898,78.233))) * 43758.5453);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    float id;
    if (int(fragCoord.x) < FIGURES_COUNT && int(fragCoord.y) == 0) {
        id = fragCoord.x;
    }
    else {
        if (int(fragCoord.x) == 0 && int(fragCoord.y) == 1) {
            fragColor = vec4(FIGURES_COUNT, 0.0, 0.0, 0.0);
        }
        else {
            fragColor = vec4(0.0);
        }
        return;
    }
    
    vec4 prev = texelFetch(iChannel0, ivec2(id, 0), 0);
    vec2 pos = prev.xy;
    float timer = prev.z;
    
    float outData = 0.0;
    if (iFrame == 0) {
        pos.x = rand(vec2(id, E * float(id)));
        pos.y = rand(vec2(PI * float(id), id)) * 1.5;
        timer = 0.0;
    }
    else {
        vec2 prevPos = pos;
        float prevTimer = timer;
        if (timer == 0.0) {
            if (pos.y >= -0.5) {
                pos.y -= iTimeDelta * FALL_SPEED;
            }
            else {
                timer = rand(vec2(id, iTime)) * MAX_TIMER;
            }
        }
        else {
            timer -= iTimeDelta;
            if (timer <= 0.0) {
                pos.y = 1.5;
                timer = 0.0;
            }
        }
    }
    
    fragColor = vec4(pos, timer, 0.0);
}