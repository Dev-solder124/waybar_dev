#version 320 es

precision highp float;
in vec2 v_texcoord;
uniform sampler2D tex;
layout(location = 0) out vec4 fragColor;

void main() {
    vec4 color = texture(tex, v_texcoord);
    color.r = min(color.r * 1.08, 1.0);
    color.g = color.g * 0.84;
    color.b = color.b * 0.58;
    fragColor = color;
}
