#ifndef __MODEL_H__
#define __MODEL_H__

#include <vector>
#include "geometry.h"

class Model {
private:
    std::vector<Vec3f> verts_;
    std::vector<Vec2f> textureVerts_;
    std::vector<std::vector<int>> faces_;
    std::vector<std::vector<int>> textures_;
public:
    Model(const char* filename);
    ~Model();
    int getNumVerts();
    int getNumFaces();
    Vec3f getVertByIndex(int i);
    Vec2f getTextureVertByIndex(int i);
    std::vector<int> getTextureByIndex(int idx);
    std::vector<int> getFaceByIndex(int idx);
};

#endif //__MODEL_H__