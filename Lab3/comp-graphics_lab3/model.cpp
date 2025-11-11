#include <iostream>
#include <string>
#include <fstream>
#include <sstream>
#include <vector>
#include "model.h"

Model::Model(const char* filename) : verts_(), faces_() {
    std::ifstream in;
    in.open(filename, std::ifstream::in);
    if (in.fail()) return;
    std::string line;
    while (std::getline(in, line)) {
        std::istringstream iss(line.c_str());
        char trash;
        if (!line.compare(0, 2, "v ")) {
            iss >> trash;
            Vec3f v;
            for (int i = 0; i < 3; i++) iss >> v.raw[i];
            verts_.push_back(v);
        }
        else if (!line.compare(0, 2, "f ")) {
            iss >> trash;
            std::vector<int> face;
            int fidx;
            int vertex_index, texture_index, normal_index;
            char separator;

            while (iss >> vertex_index) {
                face.push_back(vertex_index - 1);
                if (iss.peek() == '/') {
                    iss >> separator;
                    if (iss.peek() != '/') {
                        iss >> texture_index;
                    }
                    if (iss.peek() == '/') {
                        iss >> separator;
                        iss >> normal_index;
                    }
                    iss >> std::ws;
                }
            }

            faces_.push_back(std::move(face));
        }
    }
    std::cerr << "Vertex number: " << verts_.size() << ". Faces number: " << faces_.size() << std::endl;
}

Model::~Model() {
}

int Model::getNumVerts() {
    return (int)verts_.size();
}

int Model::getNumFaces() {
    return (int)faces_.size();
}

std::vector<int> Model::getFaceByIndex(int idx) {
    return faces_[idx];
}

Vec3f Model::getVertByIndex(int i) {
    return verts_[i];
}
