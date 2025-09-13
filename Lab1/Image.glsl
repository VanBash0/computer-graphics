const float CAR_Y = 0.08;
const vec2 CAR_BODY_SIZE = vec2(0.03, 0.06);
const vec2 FRONT_WHEEL_SIZE = vec2(0.04, 0.015);
const vec2 WHEEL_SIZE = vec2(0.04, 0.01);
const vec3 ROAD_COLOR = vec3(0.5, 0.5, 0.5);
const vec3 CAR_COLOR = vec3(0.195, 0.78, 0.7);
const vec3 OBSTACLE_COLOR = vec3(1.0, 0.7, 0.78);
const float OBSTACLE_SIZE = 0.04;

float sdRect(in vec2 p, in vec2 size) {  
  vec2 d = abs(p) - size;
  return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

float sdCircle(in vec2 p, float r) {
    return length(p) - r;
}

vec2 getCarCoord() {
    return vec2(
        texelFetch(iChannel0, ivec2(0, 0), 0).x,
        CAR_Y
    );
}

float sdCar(vec2 p) {
    float carBody = sdRect(p, CAR_BODY_SIZE);
    float wheel1 = sdRect(p + vec2(0.0, CAR_BODY_SIZE.y * 0.75), WHEEL_SIZE);
    float wheel2 = sdRect(p + vec2(0.0, CAR_BODY_SIZE.y * 0.35), WHEEL_SIZE);
    float wheel3 = sdRect(p - vec2(0.0, CAR_BODY_SIZE.y * 0.5), FRONT_WHEEL_SIZE);
    
    return min(carBody, min(wheel1, min(wheel2, wheel3)));
}

float sdObstacle(int id, vec2 p, vec2 pos) {
    switch (id % 2) {
        case 0:
            return sdRect(p - pos, vec2(OBSTACLE_SIZE));
        case 1:
            return sdCircle(p - pos, OBSTACLE_SIZE);
    }
}

vec2 correctAspectRatio(vec2 coord, vec2 res) {
    return coord * vec2(res.x / res.y, 1.0);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = correctAspectRatio(fragCoord / iResolution.xy, iResolution.xy);
    
    vec2 carPos = correctAspectRatio(getCarCoord(), iResolution.xy);
    float distCar = sdCar(uv - carPos);
    vec3 col = mix(CAR_COLOR, ROAD_COLOR, step(0.0, distCar));
    
    float obstDist = 1000.0;
    int figuresCount = int(texelFetch(iChannel1, ivec2(0, 1), 0));
    for (int id = 0; id < figuresCount; ++id) {
        vec4 figureData = texelFetch(iChannel1, ivec2(id, 0), 0);
        vec2 figurePos = figureData.xy;
        
        figurePos = correctAspectRatio(figurePos, iResolution.xy);
        
        float distFigure = sdObstacle(id, uv, figurePos);
        obstDist = min(obstDist, distFigure);
    }
    
    col = mix(OBSTACLE_COLOR, col, step(0.0, obstDist));
    fragColor = vec4(col, 1.0);
}