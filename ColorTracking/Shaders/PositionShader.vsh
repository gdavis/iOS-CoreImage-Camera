attribute vec4 position;
attribute mediump vec4 inputTextureCoordinate;

varying mediump vec2 textureCoordinate;

void main()
{
	gl_Position = position;
	textureCoordinate = inputTextureCoordinate.xy;
}