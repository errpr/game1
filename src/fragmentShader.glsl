#version 330 core
out vec4 FragColor;

in vec3 vertexColor;
in vec2 texCoord;

uniform vec4 ourColor;
uniform sampler2D ourTexture;

void main()
{
    FragColor = texture(ourTexture, texCoord) + ourColor;
}
