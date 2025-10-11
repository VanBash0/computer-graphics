const int MAX_MARCHING_STEPS = 255;
const float MIN_DIST = 0.0;
const float MAX_DIST = 100.0;
const float PRECISION = 0.001;
const float EPSILON = 0.0005;

const vec3 COLOR_BACKGROUND = vec3(.73, .86, .85);
const vec3 COLOR_GROUND = vec3(0.7, 0.9, 0.1);
const vec3 COLOR_PLAYER = vec3(.4, .494, .172);
const vec3 COLOR_MISSILE = vec3(.5, .5, .5);
const vec3 COLOR_ENEMY = vec3(.8, .306, .361);

const vec3 LIGHT_POSITION = vec3(110.0, 10.0, 125.0);
const vec3 CAMERA_POS = vec3(118.0, 5.0, 118.0);
const vec3 CAMERA_LOOKAT = vec3(114.0, 3.0, 111.0);

const vec3 TANK_BODY_SIZE = vec3(1.0, 0.5, 1.5);
const vec3 TANK_TURRET_SIZE = vec3(0.6, 1.5, 0.6);
const float GUN_RADIUS = .2;
const float GUN_LENGTH = 3.;
const vec3 GUN_OFFSET = vec3(0., 0., -1.);
const float MISSILE_RADIUS = .2;

const vec2 ENEMY_POS = vec2(109.0, 111.0);
const float ENEMY_BODY_ANGLE = 0.0;
const float ENEMY_GUN_PITCH = 0.0;

mat3 rotateY(float alpha) {
    float s = sin(alpha);
    float c = cos(alpha);
    return mat3(c, 0, s, 0, 1, 0, -s, 0, c);
}

mat3 rotateX(float alpha) {
    float s = sin(alpha);
    float c = cos(alpha);
    return mat3(1, 0, 0, 0, c, -s, 0, s, c);
}

struct Surface {
    float sd;
    vec3 col;
};

Surface sdPlane(in vec3 p, in vec3 col) {
    return Surface(p.y, col);
}

Surface sdBox(in vec3 p, in vec3 halfSize, in vec3 offset, float angle, in vec3 col) {
    vec3 localP = p - offset;
    localP = rotateY(angle) * localP;
    vec3 q = abs(localP) - halfSize;
    float sd = length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
    return Surface(sd, col);
}

Surface sdCylinder(in vec3 localP, float radius, float cylLength, in vec3 col) {
    vec2 d = vec2(length(localP.xy) - radius, abs(localP.z) - cylLength / 2.0); 
    float sd = min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
    return Surface(sd, col);
}

Surface sdGun(in vec3 p, float radius, float cylLength, vec2 tankPos, float turretAngle, float pitch, in vec3 col) {
    vec3 localP = p - vec3(tankPos.x, (TANK_TURRET_SIZE.y + TANK_BODY_SIZE.y) / 2.0, tankPos.y);
    localP = rotateY(turretAngle) * localP;
    localP = rotateX(-pitch) * localP;
    localP += GUN_OFFSET;
    return sdCylinder(localP, radius, cylLength, col);
}

Surface sdSphere(in vec3 p, in vec3 offset, float r, in vec3 col) {
    float sd =  length(p - offset) - r;
    return Surface(sd, col);
}

Surface minWithColor(Surface obj1, Surface obj2) {
  if (obj2.sd < obj1.sd) return obj2;
  return obj1;
}

Surface sdTank(in vec3 p, in vec2 tankPos, float bodyAngle, float turretAngle, float gunPitch, in vec3 col) {
    Surface body = sdBox(p, TANK_BODY_SIZE, vec3(tankPos.x, 0.0, tankPos.y), bodyAngle, col);
    Surface turret = sdBox(p, TANK_TURRET_SIZE, vec3(tankPos.x, 0.0, tankPos.y), turretAngle, col);
    Surface gun = sdGun(p, GUN_RADIUS, GUN_LENGTH, tankPos, turretAngle, gunPitch, col);
    
    return minWithColor(body, minWithColor(gun, turret));
}

Surface sdPlayerTank(in vec3 p) {
    float bodyAngle = texelFetch(iChannel0, ivec2(0), 0).z;
    float turretAngle = texelFetch(iChannel0, ivec2(0, 1), 0).x;
    float gunPitch = texelFetch(iChannel0, ivec2(0, 1), 0).y;
    vec2 tankPos = texelFetch(iChannel0, ivec2(0), 0).xy;
    
    return sdTank(p, tankPos, bodyAngle, turretAngle, gunPitch, COLOR_PLAYER);
}

Surface sdEnemyTank(in vec3 p) {
    float turretAngle = texelFetch(iChannel0, ivec2(0, 6), 0).x;
    return sdTank(p, ENEMY_POS, ENEMY_BODY_ANGLE, turretAngle, ENEMY_GUN_PITCH, COLOR_ENEMY);
}

Surface sdMissile(in vec3 p, bool isActive, in vec3 pos) {
    if (!isActive) return Surface(1000.0, COLOR_MISSILE);
    return sdSphere(p, pos, MISSILE_RADIUS, COLOR_MISSILE);
}

Surface sdPlayerMissile(in vec3 p) {
    bool isActive = texelFetch(iChannel0, ivec2(0, 5), 0).x == 1.0;
    vec3 pos = texelFetch(iChannel0, ivec2(0, 2), 0).xyz;
    return sdMissile(p, isActive, pos);
}

Surface sdEnemyMissile(in vec3 p) {
    bool isActive = texelFetch(iChannel0, ivec2(0, 10), 0).x == 1.0;
    vec3 pos = texelFetch(iChannel0, ivec2(0, 7), 0).xyz;
    return sdMissile(p, isActive, pos);
}

Surface sdScene(in vec3 p) {
    Surface playerTank = sdPlayerTank(p);
    Surface ground = sdPlane(p, COLOR_GROUND);
    Surface missile = sdPlayerMissile(p);
    Surface enemyTank = sdEnemyTank(p);
    Surface enemyMissile = sdEnemyMissile(p);
    
    Surface result = minWithColor(missile, playerTank);
    result = minWithColor(result, ground);
    result = minWithColor(result, enemyTank);
    result = minWithColor(result, enemyMissile);
    return result;
}

Surface rayMarch(in vec3 rayOrigin, in vec3 rayDirection) {
    float depth = MIN_DIST;
    Surface closestObject;
    for (int i = 0; i < MAX_MARCHING_STEPS; ++i) {
        vec3 p = rayOrigin + depth * rayDirection;
        closestObject = sdScene(p);
        depth += closestObject.sd;
        if (closestObject.sd < PRECISION || depth > MAX_DIST) break;
    }
    closestObject.sd = depth;
    return closestObject;
}

vec3 calcNormal(in vec3 p) {
    vec2 e = vec2(1, -1) * EPSILON;
    return normalize(
        e.xyy * sdScene(p + e.xyy).sd +
        e.yyx * sdScene(p + e.yyx).sd +
        e.yxy * sdScene(p + e.yxy).sd +
        e.xxx * sdScene(p + e.xxx).sd);
}

mat3 camera() {
    vec3 f = normalize(CAMERA_LOOKAT - CAMERA_POS);
    vec3 r = normalize(cross(f, vec3(0,1,0)));
    vec3 u = cross(r, f);
    return mat3(r, u, -f);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    vec3 rayDirection = camera() * normalize(vec3(uv, -1));
    Surface closestObject = rayMarch(CAMERA_POS, rayDirection);
    
    vec3 col;
    if (closestObject.sd > MAX_DIST) {
        col = COLOR_BACKGROUND;
    }
    else {
        vec3 p = CAMERA_POS + rayDirection * closestObject.sd;
        vec3 normal = calcNormal(p);
        vec3 lightDirection = normalize(LIGHT_POSITION - p);
        float dif = clamp(dot(normal, lightDirection), 0.0, 1.0) * 0.5 + 0.5;
        col = dif * closestObject.col;
    }
    
    fragColor = vec4(col, 1.0);
}
