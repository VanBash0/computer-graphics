const int KEY_A = 65;
const int KEY_D = 68;
const int KEY_W = 87;
const int KEY_S = 83;
const int KEY_Q = 81;
const int KEY_E = 69;
const int KEY_R = 82;
const int KEY_F = 70;
const int KEY_SPACE = 32;

const float PI = 3.1415926535;
const float G = 9.80665;

const float BODY_ROTATION_SPEED = 1.;
const float TURRET_ROTATION_SPEED = .8;
const float MOVE_SPEED = 3.;
const float GUN_SPEED = .3;

const float MAX_GUN_ANGLE = PI / 6.5;
const float MIN_GUN_ANGLE = -PI / 30.;
const float START_VELOCITY = 15.;

const vec2 TANK_START_POS = vec2(118.0, 108.0);
const vec2 ENEMY_POS = vec2(109.0, 111.0);
const float FIRE_DISTANCE = 8.;

const vec3 TANK_BODY_SIZE = vec3(1.0, 0.5, 1.5);
const vec3 TANK_TURRET_SIZE = vec3(0.6, 1.5, 0.6);
const float GUN_LENGTH = 3.;
const vec3 GUN_OFFSET = vec3(0., 0., -1.);

float getDistance(in vec2 pos1, in vec2 pos2) {
    vec2 diff = pos1 - pos2;
    return sqrt(diff.x * diff.x + diff.y * diff.y);
}

float getAngleToPlayer(in vec2 plPos, in vec2 enPos) {
    vec2 dirToPlayer = plPos - enPos;
    return atan(dirToPlayer.x, dirToPlayer.y); // atan с двумя аргументами
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec4 outValue = vec4(0.0, 0.0, 0.0, 0.0);
    if (iFrame == 0 && int(fragCoord.x) == 0 && int(fragCoord.y) == 0)
        outValue = vec4(TANK_START_POS, 0.0, 0.0);
    
    if (iFrame != 0 && int(fragCoord.x) == 0) {
        bool isMissileActive = texelFetch(iChannel0, ivec2(0, 5), 0).x == 1.0;
        bool spacePressed = texelFetch(iChannel1, ivec2(KEY_SPACE, 0), 0).x > 0.;
        bool enemyCanShoot = texelFetch(iChannel0, ivec2(0, 6), 0).y == 1.0;
        bool isEnemyMissileActive = texelFetch(iChannel0, ivec2(0, 10), 0).x == 1.0;
            
        switch (int(fragCoord.y)) {
        
        // Вращение и перемещение корпуса
        case 0:
            float prevBodyAngle = texelFetch(iChannel0, ivec2(0), 0).z;
            float rightInputBody = texelFetch(iChannel1, ivec2(KEY_D, 0), 0).x;
            float leftInputBody = texelFetch(iChannel1, ivec2(KEY_A, 0), 0).x;
            outValue.z = prevBodyAngle + (iTimeDelta * BODY_ROTATION_SPEED) * (leftInputBody - rightInputBody);

            vec2 prevPos = texelFetch(iChannel0, ivec2(0), 0).xy;
            float forwardInput = texelFetch(iChannel1, ivec2(KEY_W, 0), 0).x;
            float backwardInput = texelFetch(iChannel1, ivec2(KEY_S, 0), 0).x;
            float totalInput = backwardInput - forwardInput;
            outValue.x = prevPos.x + MOVE_SPEED * sin(outValue.z) * totalInput * iTimeDelta;
            outValue.y = prevPos.y + MOVE_SPEED * cos(outValue.z) * totalInput * iTimeDelta;
            break;
        
        // Вращение башни и пушки
        case 1:
            float prevTurretAngle = texelFetch(iChannel0, ivec2(0, 1), 0).x;
            float rightInputTurret = texelFetch(iChannel1, ivec2(KEY_E, 0), 0).x;
            float leftInputTurret = texelFetch(iChannel1, ivec2(KEY_Q, 0), 0).x;
            outValue.x = prevTurretAngle + iTimeDelta * TURRET_ROTATION_SPEED * (leftInputTurret - rightInputTurret);
            
            float prevGunAngle = texelFetch(iChannel0, ivec2(0, 1), 0).y;
            float upInputTurret = texelFetch(iChannel1, ivec2(KEY_R, 0), 0).x;
            float downInputTurret = texelFetch(iChannel1, ivec2(KEY_F, 0), 0).x;
            float newGunAngle = prevGunAngle + iTimeDelta * GUN_SPEED * (upInputTurret - downInputTurret);
            if (newGunAngle > MAX_GUN_ANGLE) newGunAngle = MAX_GUN_ANGLE;
            if (newGunAngle < MIN_GUN_ANGLE) newGunAngle = MIN_GUN_ANGLE;
            outValue.y = newGunAngle;
            break;
        
        // Текущие xyz снаряда
        case 2:
            if (!isMissileActive) break;
            
            vec3 startCoord = texelFetch(iChannel0, ivec2(0, 3), 0).xyz;
            float startTime = texelFetch(iChannel0, ivec2(0, 3), 0).w;
            float startPitch = texelFetch(iChannel0, ivec2(0, 4), 0).x;
            float startYaw = texelFetch(iChannel0, ivec2(0, 4), 0).y;
            
            float time = iTime - startTime;
            float x = START_VELOCITY * cos(startPitch) * sin(startYaw) * time + startCoord.x;
            float z = START_VELOCITY * cos(startYaw) * cos(startPitch) * time + startCoord.z;
            float y = startCoord.y + sin(startPitch) * time - .5 * G * time * time;
            outValue = vec4(x, y, z, 0.0);
            break;
        
        // Стартовые xyz снаряда, время
        case 3:
            if (spacePressed && !isMissileActive) {
                vec2 tankPos = texelFetch(iChannel0, ivec2(0), 0).xy;
                float turretAngle = texelFetch(iChannel0, ivec2(0, 1), 0).x;
                float gunPitch = texelFetch(iChannel0, ivec2(0, 1), 0).y;
                
                vec3 gunEnd = vec3(
                    tankPos.x + sin(turretAngle) * cos(gunPitch) * GUN_LENGTH,
                    (TANK_BODY_SIZE.y + TANK_TURRET_SIZE.y)/2.0 + sin(gunPitch) * GUN_LENGTH,
                    tankPos.y + cos(turretAngle) * cos(gunPitch) * GUN_LENGTH
                );
                outValue = vec4(gunEnd, iTime);
            } else {
                outValue = texelFetch(iChannel0, ivec2(0, 3), 0);
            }
            break;
        
        // Стартовые yaw и pitch
        case 4:
            if (spacePressed && !isMissileActive) {
                float turretAngle = texelFetch(iChannel0, ivec2(0, 1), 0).x;
                float gunPitch = texelFetch(iChannel0, ivec2(0, 1), 0).y;
                outValue = vec4(gunPitch, turretAngle, 0.0, 0.0);
            } else {
                outValue = texelFetch(iChannel0, ivec2(0, 4), 0);
            }
            break;
            
        // Флаг
        case 5:
            bool newIsMissileActive = isMissileActive;
            
            // Создание нового снаряда
            if (spacePressed && !isMissileActive) {
                newIsMissileActive = true;
            }
            
            // Проверка столкновения с землей
            if (isMissileActive) {
                vec3 missilePos = texelFetch(iChannel0, ivec2(0, 2), 0).xyz;
                if (missilePos.y < 0.0) {
                    newIsMissileActive = false;
                }
            }
            
            outValue = vec4(newIsMissileActive ? 1.0 : 0.0, 0.0, 0.0, 0.0);
            break;
        
        // Вращение башни врага, флаг должен ли он стрелять
        case 6:
            float enemyRotateAngle = texelFetch(iChannel0, ivec2(0, 6), 0).x;
            vec2 playerPos = texelFetch(iChannel0, ivec2(0, 0), 0).xy;
            float dist = getDistance(playerPos, ENEMY_POS);
            if (dist > FIRE_DISTANCE) {
                outValue = vec4(enemyRotateAngle, 0.0, vec2(.0));
                break;
            }
            else {
                float newAngle = getAngleToPlayer(playerPos, ENEMY_POS);
                outValue = vec4(newAngle, 1.0, vec2(.0));
                break;
            }
            
        // Текущие xyz снаряда врага
        case 7:
            if (!isEnemyMissileActive) break;
            {
            vec3 startCoord = texelFetch(iChannel0, ivec2(0, 8), 0).xyz;
            float startTime = texelFetch(iChannel0, ivec2(0, 8), 0).w;
            float startYaw = texelFetch(iChannel0, ivec2(0, 9), 0).x;
            
            float time = iTime - startTime;
            float x = START_VELOCITY * sin(startYaw) * time + startCoord.x;
            float z = START_VELOCITY * cos(startYaw) * time + startCoord.z;
            float y = startCoord.y - .5 * G * time * time;
            outValue = vec4(x, y, z, 0.0);
            }
            break;
            
        // Стартовые xyz снаряда врага, время
        case 8:
            if (enemyCanShoot && !isEnemyMissileActive) {
                vec2 tankPos = ENEMY_POS;
                float turretAngle = texelFetch(iChannel0, ivec2(0, 6), 0).x;
                
                vec3 gunEnd = vec3(
                    tankPos.x + sin(turretAngle) * GUN_LENGTH,
                    (TANK_BODY_SIZE.y + TANK_TURRET_SIZE.y)/2.0,
                    tankPos.y + cos(turretAngle) * GUN_LENGTH
                );
                outValue = vec4(gunEnd, iTime);
            } else {
                outValue = texelFetch(iChannel0, ivec2(0, 8), 0);
            }
            break;
        
        // Стартовый yaw врага
        case 9:
            if (enemyCanShoot && !isEnemyMissileActive) {
                float turretAngle = texelFetch(iChannel0, ivec2(0, 6), 0).x;
                outValue = vec4(turretAngle, vec3(.0));
            } else {
                outValue = texelFetch(iChannel0, ivec2(0, 9), 0);
            }
            break;
            
        // Флаг для врага
        case 10:
            bool newIsEnemyMissileActive = isEnemyMissileActive;
            
            // Создание нового снаряда
            if (enemyCanShoot && !isEnemyMissileActive) {
                newIsEnemyMissileActive = true;
            }
            
            // Проверка столкновения с землей
            if (isEnemyMissileActive) {
                vec3 missilePos = texelFetch(iChannel0, ivec2(0, 7), 0).xyz;
                if (missilePos.y < 0.0) {
                    newIsEnemyMissileActive = false;
                }
            }
            
            outValue = vec4(newIsEnemyMissileActive ? 1.0 : 0.0, 0.0, 0.0, 0.0);
            break;
        }
    }
    
    fragColor = outValue;
}
