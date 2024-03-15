#version 330 core

layout (location = 0) in vec3 a_pos;
layout (location = 1) in vec2 a_tex_coords;

uniform mat4 model_mat;
uniform mat4 view_mat;
uniform mat4 projection_mat;

out vec2 tex_coords;

void main() {
    gl_Position = projection_mat * view_mat * model_mat * vec4(a_pos, 1.0);
    tex_coords = a_tex_coords;
}
