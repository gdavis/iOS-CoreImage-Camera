varying mediump vec2 textureCoordinate;
precision mediump float;


uniform sampler2D videoFrame;
uniform vec4 inputColor;
uniform float threshold;

vec3 normalizeColor(vec3 color)
{
    return color / max(dot(color, vec3(1.0/3.0)), 0.3);
}

vec4 maskPixel(vec4 pixelColor, vec4 maskColor)
{
    float  d;
    vec4   calculatedColor;

    // Compute distance between current pixel color and reference color
    d = distance(normalizeColor(pixelColor.rgb), normalizeColor(maskColor.rgb));
    
    // If color difference is larger than threshold, return black.
    calculatedColor =  (d > threshold)  ?  vec4(0.0)  :  vec4(1.0);

	//Multiply color by texture
	return calculatedColor;
}

void main()
{
	float d;
	vec4 pixelColor, maskedColor;

	pixelColor = texture2D(videoFrame, textureCoordinate);
	maskedColor = maskPixel(pixelColor, inputColor);

	gl_FragColor = (maskedColor.a < 1.0) ? pixelColor : maskedColor;
}