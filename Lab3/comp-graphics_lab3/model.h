#ifndef __MODEL_H__
#define __MODEL_H__

#include <vector>
#include "geometry.h"

class Model {
private:
    std::vector<Vec3f> verts_;
    std::vector<std::vector<int>> faces_;
public:
    Model(const char* filename);
    ~Model();
    int getNumVerts();
    int getNumFaces();
    Vec3f getVertByIndex(int i);
    std::vector<int> getFaceByIndex(int idx);
};

#endif //__MODEL_H__