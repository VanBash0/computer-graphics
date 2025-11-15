#include "tgaimage.h"
#include "model.h"
#include "geometry.h"
#include "openfile.h"

Model* model = NULL;
const int width = 800;
const int height = 800;
const int depth = 255;
const Vec3f lightDirection = Vec3f(0, 0, 1);
const Vec3f cameraPos = Vec3f(0, 0, 3);

void drawTriangle(Vec3f t0, Vec3f t1, Vec3f t2, Vec2f uv0, Vec2f uv1, Vec2f uv2, Vec3f n0, Vec3f n1, Vec3f n2, TGAImage& image, TGAImage& texture_image, int* zbuffer) {
    if (t0.y > t1.y) {
        std::swap(t0, t1);
        std::swap(uv0, uv1);
        std::swap(n0, n1);
    };
    if (t0.y > t2.y) {
        std::swap(t0, t2);
        std::swap(uv0, uv2);
        std::swap(n0, n2);
    };
    if (t1.y > t2.y) {
        std::swap(t1, t2);
        std::swap(uv1, uv2);
        std::swap(n1, n2);
    };
    const int total_height = t2.y - t0.y;
    if (total_height == 0) return;

    const int segment1_height = t1.y - t0.y;
    const int segment2_height = t2.y - t1.y;

    for (int y = t0.y; y <= t2.y; y++) {
        float alpha = static_cast<float>(y - t0.y) / total_height;
        Vec3f A = t0 + (t2 - t0) * alpha;
        Vec2f uvA = uv0 + (uv2 - uv0) * alpha;
        Vec3f nA = n0 + (n2 - n0) * alpha;

        Vec3f B;
        Vec2f uvB;
        Vec3f nB;

        if (y < t1.y && segment1_height > 0) {
            float beta = static_cast<float>(y - t0.y) / segment1_height;
            B = t0 + (t1 - t0) * beta;
            uvB = uv0 + (uv1 - uv0) * beta;
            nB = n0 + (n1 - n0) * beta;
        }
        else if (segment2_height > 0) {
            float beta = static_cast<float>(y - t1.y) / segment2_height;
            B = t1 + (t2 - t1) * beta;
            uvB = uv1 + (uv2 - uv1) * beta;
            nB = n1 + (n2 - n1) * beta;
        }
        else {
            continue;
        }

        if (A.x > B.x) {
            std::swap(A, B);
            std::swap(uvA, uvB);
            std::swap(nA, nB);
        }

        for (int x = A.x; x <= B.x; x++) {
            if (A.x == B.x) continue;
            float t = static_cast<float>(x - A.x) / (B.x - A.x);
            float z = A.z + (B.z - A.z) * t;

            Vec2f uv = uvA + (uvB - uvA) * t;
            uv.x *= texture_image.get_width();
            uv.y *= texture_image.get_height();
            TGAColor color = texture_image.get(static_cast<int>(uv.x), static_cast<int>(uv.y));

            Vec3f normal = nA + (nB - nA) * t;
            normal.normalize();
            float intensity = normal * lightDirection;
            if (intensity < 0) intensity = 0;
            color.r *= intensity;
            color.g *= intensity;
            color.b *= intensity;

            int idx = x + y * width;
            if (idx >= 0 && idx < width * height) {
                if (zbuffer[idx] < z && intensity > 0) {
                    zbuffer[idx] = z;
                    image.set(x, y, color);
                }
            }
        }
    }
}

Matrix vectorToMatrix(Vec3f v) {
    Matrix result(4, 1);
    result[0][0] = v.x;
    result[1][0] = v.y;
    result[2][0] = v.z;
    result[3][0] = 1.f;
    return result;
}

Vec3f matrixToVector(Matrix m) {
    Vec3f result;
    float w = m[3][0];
    result.x = m[0][0] / w;
    result.y = m[1][0] / w;
    result.z = m[2][0] / w;
    return result;
}

Matrix getCameraViewport(int x, int y, int width, int height, int depth) {
    Matrix result = Matrix::identity(4);
    result[0][0] = width / 2.f;
    result[1][1] = height / 2.f;
    result[2][2] = depth / 2.f;

    result[0][3] = width / 2.f + x;
    result[1][3] = height / 2.f + y;
    result[2][3] = depth / 2.f;
    return result;
}

int main(int argc, char** argv) {
    TGAImage image(width, height, TGAImage::RGB);
    TGAImage texture;
    texture.read_tga_file("resources/african_head_diffuse.tga");
    texture.flip_vertically();

    model = new Model("resources/african_head.obj");
    int* zbuffer = new int[width * height];
    for (int i = 0; i < width * height; i++) {
        zbuffer[i] = -1e30f;
    }

    Matrix cameraViewport = getCameraViewport(0, 0, width, height, depth);
    Matrix projectionMatrix = Matrix::identity(4);
    projectionMatrix[3][2] = -1.f / cameraPos.z;

    for (int i = 0; i < model->getNumFaces(); i++) {
        std::vector<int> face = model->getFaceByIndex(i);
        std::vector<int> textureIndices = model->getTextureByIndex(i);
        std::vector<int> normalIndices = model->getNormalByIndex(i);
        Vec3i screenCoords[3];
        Vec3f worldCoords[3];
        Vec2f uvCoords[3];
        Vec3f normalCoords[3];
        for (int j = 0; j < 3; j++) {
            Vec3f vert = model->getVertexByIndex(face[j]);
            //screenCoords[j] = Vec3i((vert.x + 1.) * width / 2.,
            //                        (vert.y + 1.) * height / 2.,
            //                        (vert.z + 1.) * depth / 2.);
            screenCoords[j] = matrixToVector(cameraViewport * projectionMatrix * vectorToMatrix(vert));
            worldCoords[j] = vert;
            uvCoords[j] = model->getTextureVertexByIndex(textureIndices[j]);
            normalCoords[j] = model->getNormalVertexByIndex(normalIndices[j]);
        }
        //Vec3f normal = ((worldCoords[2] - worldCoords[0])^(worldCoords[1] - worldCoords[0])).normalize();
        //float intensity = normal * lightDirection;
        //if (intensity > 0) {
            drawTriangle(screenCoords[0], screenCoords[1], screenCoords[2], uvCoords[0], uvCoords[1], uvCoords[2], normalCoords[0], normalCoords[1], normalCoords[2], image, texture, zbuffer);
        //}
    }

    image.flip_vertically();
    image.write_tga_file("output.tga");
    openFile("output.tga");

    delete[] zbuffer;
    delete model;
}