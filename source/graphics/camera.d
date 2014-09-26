module graphics.camera;
import math.matrix;
import graphics.GraphicsState;

public struct camera
{
	public mat4 projMatrix;
	public mat4 viewMatrix;

	public this(float fov, float aspect)
	{
		projMatrix = projectionMatrix(fov, aspect, -1.0f, -100.0f);
		viewMatrix = translationMatrix(0.0f, 0.0f, 0.0f);
	}
}