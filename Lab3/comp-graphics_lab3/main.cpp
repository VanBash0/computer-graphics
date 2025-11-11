#include "tgaimage.h"
#include "model.h"

const TGAColor white = TGAColor(255, 255, 255, 255);
const TGAColor red = TGAColor(255, 0, 0, 255);
const TGAColor green = TGAColor(0, 255, 0, 255);

Model* model = NULL;
const int width = 800;
const int height = 800;
const Vec3f lightDirection = Vec3f(0, 0, -1);

void drawTriangle(Vec2i t0, Vec2i t1, Vec2i t2, TGAImage& image, TGAColor color) {
    if (t0.y > t1.y) std::swap(t0, t1);
    if (t0.y > t2.y) std::swap(t0, t2);
    if (t1.y > t2.y) std::swap(t1, t2);

    const int total_height = t2.y - t0.y;
    const int segment1_height = t1.y - t0.y;
    const int segment2_height = t2.y - t1.y;

    for (int y = t0.y; y <= t2.y; y++) {
        float alpha = static_cast<float>(y - t0.y) / total_height;
        Vec2i A = t0 + (t2 - t0) * alpha;
        float beta;
        Vec2i B;
        if (y < t1.y) {
            if (segment1_height == 0) continue;
            beta = static_cast<float>(y - t0.y) / segment1_height;
            B = t0 + (t1 - t0) * beta;
        }
        else {
            if (segment2_height == 0) continue;
            beta = static_cast<float>(y - t1.y) / segment2_height;
            B = t1 + (t2 - t1) * beta;
        }
        if (A.x > B.x) std::swap(A, B);

        for (int x = A.x; x <= B.x; x++) {
            image.set(x, y, color);
        }
    }
}

int main(int argc, char** argv) {
    TGAImage image(height, width, TGAImage::RGB);
    model = new Model("african_head.obj");

    for (int i = 0; i < model->getNumFaces(); i++) {
        std::vector<int> face = model->getFaceByIndex(i);
        Vec2i screenCoords[3];
        Vec3f worldCoords[3];
        for (int j = 0; j < 3; j++) {
            Vec3f vert = model->getVertByIndex(face[j]);
            screenCoords[j] = Vec2i((vert.x + 1.) * width / 2., (vert.y + 1.) * height / 2.);
            worldCoords[j] = vert;
        }
        Vec3f normal = ((worldCoords[2] - worldCoords[0])^(worldCoords[1] - worldCoords[0])).normalize();
        float intensity = normal * lightDirection;
        if (intensity > 0) {
            drawTriangle(screenCoords[0], screenCoords[1], screenCoords[2], image, TGAColor(intensity * 255, intensity * 255, intensity * 255, 255));
        }
    }

    image.flip_vertically();
    image.write_tga_file("output.tga");
    delete model;
}