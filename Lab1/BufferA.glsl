const int KEY_LEFT = 37;
const int KEY_RIGHT = 39;

const float SPEED = 0.4;

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    float outData = 0.0;
    
    if (int(fragCoord.x) == 0) {
        float prevValue =  texelFetch(iChannel0, ivec2(0), 0).x;
        float rightInput = texelFetch(iChannel1, ivec2(KEY_RIGHT, 0), 0).x;
        float leftInput = texelFetch(iChannel1, ivec2(KEY_LEFT, 0), 0).x;
        outData = prevValue + (iTimeDelta * SPEED) * (rightInput - leftInput);
    }
    
    fragColor = vec4(outData, 0.0, 0.0, 1.0);
}