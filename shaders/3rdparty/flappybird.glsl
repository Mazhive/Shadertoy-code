// FlappyBird by Ben Raziel. Feb 2014

// Based on the "Super Mario Bros" shader by HLorenzi
// https://www.shadertoy.com/view/Msj3zD

// Helper functions for drawing sprites
#define RGB(r,g,b) vec4(float(r)/255.0,float(g)/255.0,float(b)/255.0,1.0)
#define SPRROW(x,a,b,c,d,e,f,g,h, i,j,k,l,m,n,o,p) (x <= 7 ? SPRROW_H(a,b,c,d,e,f,g,h) : SPRROW_H(i,j,k,l,m,n,o,p))
#define SPRROW_H(a,b,c,d,e,f,g,h) (a+4.0*(b+4.0*(c+4.0*(d+4.0*(e+4.0*(f+4.0*(g+4.0*(h))))))))
#define SECROW(x,a,b,c,d,e,f,g,h) (x <= 3 ? SECROW_H(a,b,c,d) : SECROW_H(e,f,g,h))
#define SECROW_H(a,b,c,d) (a+8.0*(b+8.0*(c+8.0*(d))))
#define SELECT(x,i) mod(floor(i/pow(4.0,float(x))),4.0)
#define SELECTSEC(x,i) mod(floor(i/pow(8.0,float(x))),8.0)

// drawing consts
const float PIPE_WIDTH = 26.0; // px
const float PIPE_BOTTOM = 39.0; // px
const float PIPE_HOLE_HEIGHT = 12.0; // px
const vec4 PIPE_OUTLINE_COLOR = RGB(84, 56, 71);

// gameplay consts
const float HORZ_PIPE_DISTANCE = 100.0; // px;
const float VERT_PIPE_DISTANCE = 55.0; // px;
const float PIPE_MIN = 20.0;
const float PIPE_MAX = 70.0;
const float PIPE_PER_CYCLE = 8.0;

// Tijdelijke globale variabele gebruikt binnen de tekenfuncties (wordt overschreven)
// Let op: Dit is geen goede GLSL praktijk, maar komt voor in oudere Shadertoys.
// De uiteindelijke output gaat via de parameter 'iFragColor' van mainImage.
vec4 fragColor;

void drawHorzRect(float yCoord, float minY, float maxY, vec4 color)
{
	if ((yCoord >= minY) && (yCoord < maxY)) {
		fragColor = color;
	}
}

void drawLowBush(int x, int y)
{
	if (y < 0 || y > 3 || x < 0 || x > 15) {
		return;
	}

	float col = 0.0; // 0 = transparent

	if (y ==  3) col = SPRROW(x,0.,0.,0.,0.,0.,0.,1.,1., 1.,1.,0.,0.,0.,0.,0.,0.);
	if (y ==  2) col = SPRROW(x,0.,0.,0.,0.,1.,1.,2.,2., 2.,2.,1.,1.,0.,0.,0.,0.);
	if (y ==  1) col = SPRROW(x,0.,0.,0.,1.,1.,2.,2.,2., 2.,2.,2.,1.,1.,0.,0.,0.);
	if (y ==  0) col = SPRROW(x,0.,0.,1.,2.,2.,2.,2.,2., 2.,2.,2.,2.,2.,1.,0.,0.);

	col = SELECT(mod(float(x),8.0),col);
	if (col == 1.0) {
		fragColor = RGB(87,201,111);
	}
	else if (col == 2.0) {
		fragColor = RGB(100,224,117);
	}
}

void drawHighBush(int x, int y)
{
	if (y < 0 || y > 6 || x < 0 || x > 15) {
		return;
	}

	float col = 0.0; // 0 = transparent

	if (y ==  6) col = SPRROW(x,0.,0.,0.,0.,0.,0.,1.,1., 1.,1.,0.,0.,0.,0.,0.,0.);
	if (y ==  5) col = SPRROW(x,0.,0.,0.,0.,1.,1.,2.,2., 2.,2.,1.,1.,0.,0.,0.,0.);
	if (y ==  4) col = SPRROW(x,0.,0.,1.,1.,2.,2.,2.,2., 2.,2.,2.,2.,1.,1.,0.,0.);
	if (y ==  3) col = SPRROW(x,0.,1.,2.,2.,2.,2.,2.,2., 2.,2.,2.,2.,2.,2.,1.,0.);
	if (y ==  2) col = SPRROW(x,0.,1.,2.,2.,2.,2.,2.,2., 2.,2.,2.,2.,2.,2.,1.,0.);
	if (y ==  1) col = SPRROW(x,1.,2.,2.,2.,2.,2.,2.,2., 2.,2.,2.,2.,2.,2.,2.,1.);
	if (y ==  0) col = SPRROW(x,1.,2.,2.,2.,2.,2.,2.,2., 2.,2.,2.,2.,2.,2.,2.,1.);

	col = SELECT(mod(float(x),8.0),col);
	if (col == 1.0) {
		fragColor = RGB(87,201,111);
	}
	else if (col == 2.0) {
		fragColor = RGB(100,224,117);
	}
}

void drawCloud(int x, int y)
{
	if (y < 0 || y > 6 || x < 0 || x > 15) {
		return;
	}

	float col = 0.0; // 0 = transparent

	if (y ==  6) col = SPRROW(x,0.,0.,0.,0.,0.,0.,1.,1., 1.,1.,0.,0.,0.,0.,0.,0.);
	if (y ==  5) col = SPRROW(x,0.,0.,0.,0.,1.,1.,2.,2., 2.,2.,1.,1.,0.,0.,0.,0.);
	if (y ==  4) col = SPRROW(x,0.,0.,1.,1.,2.,2.,2.,2., 2.,2.,2.,2.,1.,1.,0.,0.);
	if (y ==  3) col = SPRROW(x,0.,1.,2.,2.,2.,2.,2.,2., 2.,2.,2.,2.,2.,2.,1.,0.);
	if (y ==  2) col = SPRROW(x,0.,1.,2.,2.,2.,2.,2.,2., 2.,2.,2.,2.,2.,2.,1.,0.);
	if (y ==  1) col = SPRROW(x,1.,2.,2.,2.,2.,2.,2.,2., 2.,2.,2.,2.,2.,2.,2.,1.);
	if (y ==  0) col = SPRROW(x,1.,2.,2.,2.,2.,2.,2.,2., 2.,2.,2.,2.,2.,2.,2.,1.);

	col = SELECT(mod(float(x),8.0),col);
	if (col == 1.0) {
		fragColor = RGB(218,246,216);
	}
	else if (col == 2.0) {
		fragColor = RGB(233,251,218);
	}
}

void drawBirdF0(int x, int y)
{
	if (y < 0 || y > 11 || x < 0 || x > 15) {
		return;
	}

	// pass 0 - draw black, white and yellow
	float col = 0.0; // 0 = transparent
	if (y == 11) col = SPRROW(x,0.,0.,0.,0.,0.,0.,1.,1., 1.,1.,1.,1.,0.,0.,0.,0.);
	if (y == 10) col = SPRROW(x,0.,0.,0.,0.,1.,1.,3.,3., 3.,1.,2.,2.,1.,0.,0.,0.);
	if (y ==  9) col = SPRROW(x,0.,0.,0.,1.,3.,3.,3.,3., 1.,2.,2.,2.,2.,1.,0.,0.);
	if (y ==  8) col = SPRROW(x,0.,0.,1.,3.,3.,3.,3.,3., 1.,2.,2.,2.,1.,2.,1.,0.);
	if (y ==  7) col = SPRROW(x,0.,1.,3.,3.,3.,3.,3.,3., 1.,2.,2.,2.,1.,2.,1.,0.);
	if (y ==  6) col = SPRROW(x,0.,1.,3.,3.,3.,3.,3.,3., 3.,1.,2.,2.,2.,2.,1.,0.);
	if (y ==  5) col = SPRROW(x,0.,1.,1.,1.,1.,1.,3.,3., 3.,3.,1.,1.,1.,1.,1.,1.);
	if (y ==  4) col = SPRROW(x,1.,2.,2.,2.,2.,2.,1.,3., 3.,1.,2.,2.,2.,2.,2.,1.);
	if (y ==  3) col = SPRROW(x,1.,2.,2.,2.,2.,1.,3.,3., 1.,2.,1.,1.,1.,1.,1.,1.);
	if (y ==  2) col = SPRROW(x,1.,2.,2.,2.,1.,3.,3.,3., 3.,1.,2.,2.,2.,2.,1.,0.);
	if (y ==  1) col = SPRROW(x,0.,1.,1.,1.,1.,3.,3.,3., 3.,3.,1.,1.,1.,1.,1.,0.);
	if (y ==  0) col = SPRROW(x,0.,0.,0.,0.,0.,1.,1.,1., 1.,1.,0.,0.,0.,0.,0.,0.);

	col = SELECT(mod(float(x),8.0),col);
	if (col == 1.0) {
		fragColor = RGB(82,56,70); // outline color (black)
	}
	else if (col == 2.0) {
		fragColor = RGB(250,250,250); // eye color (white)
	}
	else if (col == 3.0) {
		fragColor = RGB(247, 182, 67); // normal yellow color
	}

	// pass 1 - draw red, light yellow and dark yellow
	col = 0.0; // 0 = transparent
	if (y == 11) col = SPRROW(x,0.,0.,0.,0.,0.,0.,0.,0., 0.,0.,0.,0.,0.,0.,0.,0.);
	if (y == 10) col = SPRROW(x,0.,0.,0.,0.,0.,0.,3.,3., 3.,0.,0.,0.,0.,0.,0.,0.);
	if (y ==  9) col = SPRROW(x,0.,0.,0.,0.,3.,3.,0.,0., 0.,0.,0.,0.,0.,0.,0.,0.);
	if (y ==  8) col = SPRROW(x,0.,0.,0.,3.,0.,0.,0.,0., 0.,0.,0.,0.,0.,0.,0.,0.);
	if (y ==  7) col = SPRROW(x,0.,0.,0.,0.,0.,0.,0.,0., 0.,0.,0.,0.,0.,0.,0.,0.);
	if (y ==  6) col = SPRROW(x,0.,0.,0.,0.,0.,0.,0.,0., 0.,0.,0.,0.,0.,0.,0.,0.);
	if (y ==  5) col = SPRROW(x,0.,0.,0.,0.,0.,0.,0.,0., 0.,0.,0.,0.,0.,0.,0.,0.);
	if (y ==  4) col = SPRROW(x,0.,3.,0.,0.,0.,3.,0.,0., 0.,0.,1.,1.,1.,1.,1.,0.);
	if (y ==  3) col = SPRROW(x,0.,0.,0.,0.,0.,0.,2.,2., 0.,1.,0.,0.,0.,0.,0.,0.);
	if (y ==  2) col = SPRROW(x,0.,0.,0.,3.,0.,2.,2.,2., 2.,0.,1.,1.,1.,1.,0.,0.);
	if (y ==  1) col = SPRROW(x,0.,0.,0.,0.,0.,2.,2.,2., 2.,2.,0.,0.,0.,0.,0.,0.);
	if (y ==  0) col = SPRROW(x,0.,0.,0.,0.,0.,0.,0.,0., 0.,0.,0.,0.,0.,0.,0.,0.);

	col = SELECT(mod(float(x),8.0),col);
	if (col == 1.0) {
		fragColor = RGB(249, 58, 28); // mouth color (red)
	}
	else if (col == 2.0) {
		fragColor = RGB(222, 128, 55); // brown
	}
	else if (col == 3.0) {
		fragColor = RGB(249, 214, 145); // light yellow
	}
}

void drawBirdF1(int x, int y)
{
	if (y < 0 || y > 11 || x < 0 || x > 15) {
		return;
	}

	// pass 0 - draw black, white and yellow
	float col = 0.0; // 0 = transparent
	if (y == 11) col = SPRROW(x,0.,0.,0.,0.,0.,0.,1.,1., 1.,1.,1.,1.,0.,0.,0.,0.);
	if (y == 10) col = SPRROW(x,0.,0.,0.,0.,1.,1.,3.,3., 3.,1.,2.,2.,1.,0.,0.,0.);
	if (y ==  9) col = SPRROW(x,0.,0.,0.,1.,3.,3.,3.,3., 1.,2.,2.,2.,2.,1.,0.,0.);
	if (y ==  8) col = SPRROW(x,0.,0.,1.,3.,3.,3.,3.,3., 1.,2.,2.,2.,1.,2.,1.,0.);
	if (y ==  7) col = SPRROW(x,0.,1.,3.,3.,3.,3.,3.,3., 1.,2.,2.,2.,1.,2.,1.,0.);
	if (y ==  6) col = SPRROW(x,0.,1.,1.,1.,1.,1.,3.,3., 3.,1.,2.,2.,2.,2.,1.,0.);
	if (y ==  5) col = SPRROW(x,1.,2.,2.,2.,2.,2.,1.,3., 3.,3.,1.,1.,1.,1.,1.,1.);
	if (y ==  4) col = SPRROW(x,1.,2.,2.,2.,2.,2.,1.,3., 3.,1.,2.,2.,2.,2.,2.,1.);
	if (y ==  3) col = SPRROW(x,0.,1.,1.,1.,1.,1.,3.,3., 1.,2.,1.,1.,1.,1.,1.,1.);
	if (y ==  2) col = SPRROW(x,0.,0.,1.,3.,3.,3.,3.,3., 3.,1.,2.,2.,2.,2.,1.,0.);
	if (y ==  1) col = SPRROW(x,0.,0.,0.,1.,1.,3.,3.,3., 3.,3.,1.,1.,1.,1.,1.,0.);
	if (y ==  0) col = SPRROW(x,0.,0.,0.,0.,0.,1.,1.,1., 1.,1.,0.,0.,0.,0.,0.,0.);

	col = SELECT(mod(float(x),8.0),col);
	if (col == 1.0) {
		fragColor = RGB(82,56,70); // outline color (black)
	}
	else if (col == 2.0) {
		fragColor = RGB(250,250,250); // eye color (white)
	}
	else if (col == 3.0) {
		fragColor = RGB(247, 182, 67); // normal yellow color
	}

	// pass 1 - draw red, light yellow and dark yellow
	col = 0.0; // 0 = transparent
	if (y == 11) col = SPRROW(x,0.,0.,0.,0.,0.,0.,0.,0., 0.,0.,0.,0.,0.,0.,0.,0.);
	if (y == 10) col = SPRROW(x,0.,0.,0.,0.,0.,0.,3.,3., 3.,0.,0.,0.,0.,0.,0.,0.);
	if (y ==  9) col = SPRROW(x,0.,0.,0.,0.,3.,3.,0.,0., 0.,0.,0.,0.,0.,0.,0.,0.);
	if (y ==  8) col = SPRROW(x,0.,0.,0.,3.,0.,0.,0.,0., 0.,0.,0.,0.,0.,0.,0.,0.);
	if (y ==  7) col = SPRROW(x,0.,0.,0.,0.,0.,0.,0.,0., 0.,0.,0.,0.,0.,0.,0.,0.);
	if (y ==  6) col = SPRROW(x,0.,0.,0.,0.,0.,0.,0.,0., 0.,0.,0.,0.,0.,0.,0.,0.);
	if (y ==  5) col = SPRROW(x,0.,0.,0.,0.,0.,0.,0.,0., 0.,0.,0.,0.,0.,0.,0.,0.);
	if (y ==  4) col = SPRROW(x,0.,3.,0.,0.,0.,3.,0.,0., 0.,0.,1.,1.,1.,1.,1.,0.);
	if (y ==  3) col = SPRROW(x,0.,0.,0.,0.,0.,0.,2.,2., 0.,1.,0.,0.,0.,0.,0.,0.);
	if (y ==  2) col = SPRROW(x,0.,0.,0.,2.,2.,2.,2.,2., 2.,0.,1.,1.,1.,1.,0.,0.);
	if (y ==  1) col = SPRROW(x,0.,0.,0.,0.,0.,2.,2.,2., 2.,2.,0.,0.,0.,0.,0.,0.);
	if (y ==  0) col = SPRROW(x,0.,0.,0.,0.,0.,0.,0.,0., 0.,0.,0.,0.,0.,0.,0.,0.);

	col = SELECT(mod(float(x),8.0),col);
	if (col == 1.0) {
		fragColor = RGB(249, 58, 28); // mouth color (red)
	}
	else if (col == 2.0) {
		fragColor = RGB(222, 128, 55); // brown
	}
	else if (col == 3.0) {
		fragColor = RGB(249, 214, 145); // light yellow
	}
}

void drawBirdF2(int x, int y)
{
	if (y < 0 || y > 11 || x < 0 || x > 15) {
		return;
	}

	// pass 0 - draw black, white and yellow
	float col = 0.0; // 0 = transparent
	if (y == 11) col = SPRROW(x,0.,0.,0.,0.,0.,0.,1.,1., 1.,1.,1.,1.,0.,0.,0.,0.);
	if (y == 10) col = SPRROW(x,0.,0.,0.,0.,1.,1.,3.,3., 3.,1.,2.,2.,1.,0.,0.,0.);
	if (y ==  9) col = SPRROW(x,0.,0.,0.,1.,3.,3.,3.,3., 1.,2.,2.,2.,2.,1.,0.,0.);
	if (y ==  8) col = SPRROW(x,0.,1.,1.,1.,3.,3.,3.,3., 1.,2.,2.,2.,1.,2.,1.,0.);
	if (y ==  7) col = SPRROW(x,1.,2.,2.,2.,1.,3.,3.,3., 1.,2.,2.,2.,1.,2.,1.,0.);
	if (y ==  6) col = SPRROW(x,1.,2.,2.,2.,2.,1.,3.,3., 3.,1.,2.,2.,2.,2.,1.,0.);
	if (y ==  5) col = SPRROW(x,1.,2.,2.,2.,2.,1.,3.,3., 3.,3.,1.,1.,1.,1.,1.,1.);
	if (y ==  4) col = SPRROW(x,0.,1.,2.,2.,2.,1.,3.,3., 3.,1.,2.,2.,2.,2.,2.,1.);
	if (y ==  3) col = SPRROW(x,0.,1.,1.,1.,1.,3.,3.,3., 1.,2.,1.,1.,1.,1.,1.,1.);
	if (y ==  2) col = SPRROW(x,0.,0.,1.,3.,3.,3.,3.,3., 3.,1.,2.,2.,2.,2.,1.,0.);
	if (y ==  1) col = SPRROW(x,0.,0.,0.,1.,1.,3.,3.,3., 3.,3.,1.,1.,1.,1.,1.,0.);
	if (y ==  0) col = SPRROW(x,0.,0.,0.,0.,0.,1.,1.,1., 1.,1.,0.,0.,0.,0.,0.,0.);

	col = SELECT(mod(float(x),8.0),col);
	if (col == 1.0) {
		fragColor = RGB(82,56,70); // outline color (black)
	}
	else if (col == 2.0) {
		fragColor = RGB(250,250,250); // eye color (white)
	}
	else if (col == 3.0) {
		fragColor = RGB(247, 182, 67); // normal yellow color
	}

	// pass 1 - draw red, light yellow and dark yellow
	col = 0.0; // 0 = transparent
	if (y == 11) col = SPRROW(x,0.,0.,0.,0.,0.,0.,0.,0., 0.,0.,0.,0.,0.,0.,0.,0.);
	if (y == 10) col = SPRROW(x,0.,0.,0.,0.,0.,0.,3.,3., 3.,0.,0.,0.,0.,0.,0.,0.);
	if (y ==  9) col = SPRROW(x,0.,0.,0.,0.,3.,3.,0.,0., 0.,0.,0.,0.,0.,0.,0.,0.);
	if (y ==  8) col = SPRROW(x,0.,0.,0.,0.,0.,0.,0.,0., 0.,0.,0.,0.,0.,0.,0.,0.);
	if (y ==  7) col = SPRROW(x,0.,0.,0.,0.,0.,0.,0.,0., 0.,0.,0.,0.,0.,0.,0.,0.);
	if (y ==  6) col = SPRROW(x,0.,0.,0.,0.,0.,0.,0.,0., 0.,0.,0.,0.,0.,0.,0.,0.);
	if (y ==  5) col = SPRROW(x,0.,3.,0.,0.,0.,0.,0.,0., 0.,0.,0.,0.,0.,0.,0.,0.);
	if (y ==  4) col = SPRROW(x,0.,0.,3.,3.,3.,0.,0.,0., 0.,0.,1.,1.,1.,1.,1.,0.);
	if (y ==  3) col = SPRROW(x,0.,0.,0.,0.,0.,2.,2.,2., 0.,1.,0.,0.,0.,0.,0.,0.);
	if (y ==  2) col = SPRROW(x,0.,0.,0.,2.,2.,2.,2.,2., 2.,0.,1.,1.,1.,1.,0.,0.);
	if (y ==  1) col = SPRROW(x,0.,0.,0.,0.,0.,2.,2.,2., 2.,2.,0.,0.,0.,0.,0.,0.);
	if (y ==  0) col = SPRROW(x,0.,0.,0.,0.,0.,0.,0.,0., 0.,0.,0.,0.,0.,0.,0.,0.);

	col = SELECT(mod(float(x),8.0),col);
	if (col == 1.0) {
		fragColor = RGB(249, 58, 28); // mouth color (red)
	}
	else if (col == 2.0) {
		fragColor = RGB(222, 128, 55); // brown
	}
	else if (col == 3.0) {
		fragColor = RGB(249, 214, 145); // light yellow
	}
}

vec2 getLevelPixel(vec2 fragCoord)
{
	// Get the current game pixel
	// (Each game pixel is two screen pixels)
	//  (or four, if the screen is larger)
	float x = fragCoord.x / 2.0;
	float y = fragCoord.y / 2.0;

	// iResolution is provided by the C++ wrapper
	if (iResolution.y >= 640.0) {
		x /= 2.0;
		y /= 2.0;
	}

	if (iResolution.y < 200.0) {
		x *= 2.0;
		y *= 2.0;
	}

	return vec2(x,y);
}

vec2 getLevelBounds()
{
	// same logic as getLevelPixel, but returns the boundaries of the screen
	// iResolution is provided by the C++ wrapper
	float x = iResolution.x / 2.0;
	float y = iResolution.y / 2.0;

	if (iResolution.y >= 640.0) {
		x /= 2.0;
		y /= 2.0;
	}

	if (iResolution.y < 200.0) {
		x *= 2.0;
		y *= 2.0;
	}

	return vec2(x,y);
}

void drawGround(vec2 co)
{
	drawHorzRect(co.y, 0.0, 31.0, RGB(221, 216, 148));
	drawHorzRect(co.y, 31.0, 32.0, RGB(208, 167, 84)); // shadow below the green sprites
}

void drawGreenStripes(vec2 co)
{
	// iTime is provided by the C++ wrapper
	int f = int(mod(iTime * 60.0, 6.0));

	drawHorzRect(co.y, 32.0, 33.0, RGB(86, 126, 41)); // shadow blow

	const float MIN_Y = 33.0;
	const float HEIGHT = 6.0;

	vec4 darkGreen  = RGB(117, 189, 58);
	vec4 lightGreen = RGB(158, 228, 97);

	// draw diagonal stripes, and animate them
	if ((co.y >= MIN_Y) && (co.y < MIN_Y+HEIGHT)) {
		float yPos = co.y - MIN_Y - float(f);
		float xPos = mod((co.x - yPos), HEIGHT);

		if (xPos >= HEIGHT / 2.0) {
			fragColor = darkGreen;
		}
		else {
			fragColor = lightGreen;
		}
	}

	drawHorzRect(co.y, 37.0, 38.0, RGB(228, 250, 145)); // shadow highlight above
	drawHorzRect(co.y, 38.0, 39.0, RGB(84, 56, 71)); // black separator
}

void drawTile(int type, vec2 tileCorner, vec2 co)
{
	if ((co.x < tileCorner.x) || (co.x > (tileCorner.x + 16.0)) ||
		(co.y < tileCorner.y) || (co.y > (tileCorner.y + 16.0)))
	{
		return;
	}

	int modX = int(mod(co.x - tileCorner.x, 16.0));
	int modY = int(mod(co.y - tileCorner.y, 16.0));

	if (type == 0){
		drawLowBush(modX, modY);
	}
	else if (type == 1) {
		drawHighBush(modX, modY);
	}
	else if (type == 2) {
		drawCloud(modX, modY);
	}
	else if (type == 3) {
		drawBirdF0(modX, modY);
	}
	else if (type == 4) {
		drawBirdF1(modX, modY);
	}
	else if (type == 5) {
		drawBirdF2(modX, modY);
	}
}

void drawVertLine(vec2 co, float xPos, float yStart, float yEnd, vec4 color)
{
	if ((co.x >= xPos) && (co.x < (xPos + 1.0)) && (co.y >= yStart) && (co.y < yEnd)) {
		fragColor = color;
	}
}

void drawHorzLine(vec2 co, float yPos, float xStart, float xEnd, vec4 color)
{
	if ((co.y >= yPos) && (co.y < (yPos + 1.0)) && (co.x >= xStart) && (co.x < xEnd)) {
		fragColor = color;
	}
}

void drawHorzGradientRect(vec2 co, vec2 bottomLeft, vec2 topRight, vec4 leftColor, vec4 rightColor)
{
	if ((co.x < bottomLeft.x) || (co.y < bottomLeft.y) ||
		(co.x > topRight.x) || (co.y > topRight.y))
	{
		return;
	}

	float distanceRatio = (co.x - bottomLeft.x) / (topRight.x - bottomLeft.x);

	fragColor = (1.0 - distanceRatio) * leftColor + distanceRatio * rightColor;
}

void drawBottomPipe(vec2 co, float xPos, float height)
{
	if ((co.x < xPos) || (co.x > (xPos + PIPE_WIDTH)) ||
		(co.y < PIPE_BOTTOM) || (co.y > (PIPE_BOTTOM + height)))
	{
		return;
	}

	// draw the bottom part of the pipe
	// outlines
	float bottomPartEnd = PIPE_BOTTOM - PIPE_HOLE_HEIGHT + height;
	drawVertLine(co, xPos+1.0, PIPE_BOTTOM, bottomPartEnd, PIPE_OUTLINE_COLOR);
	drawVertLine(co, xPos+PIPE_WIDTH-2.0, PIPE_WIDTH, bottomPartEnd, PIPE_OUTLINE_COLOR); // Corrected: Should be PIPE_BOTTOM?

	// gradient fills
	drawHorzGradientRect(co, vec2(xPos+2.0, PIPE_BOTTOM), vec2(xPos + 10.0, bottomPartEnd), RGB(133, 168, 75), RGB(228, 250, 145));
	drawHorzGradientRect(co, vec2(xPos+10.0, PIPE_BOTTOM), vec2(xPos + 20.0, bottomPartEnd), RGB(228, 250, 145), RGB(86, 126, 41));
	drawHorzGradientRect(co, vec2(xPos+20.0, PIPE_BOTTOM), vec2(xPos + 24.0, bottomPartEnd), RGB(86, 126, 41), RGB(86, 126, 41));

	// shadows
	drawHorzLine(co, bottomPartEnd - 1.0, xPos + 2.0, xPos+PIPE_WIDTH-2.0, RGB(86, 126, 41));

	// draw the pipe opening
	// outlines
	drawVertLine(co, xPos, bottomPartEnd, bottomPartEnd + PIPE_HOLE_HEIGHT, PIPE_OUTLINE_COLOR);
	drawVertLine(co, xPos+PIPE_WIDTH-1.0, bottomPartEnd, bottomPartEnd + PIPE_HOLE_HEIGHT, PIPE_OUTLINE_COLOR);
	drawHorzLine(co, bottomPartEnd, xPos, xPos+PIPE_WIDTH-1.0, PIPE_OUTLINE_COLOR);
	drawHorzLine(co, bottomPartEnd + PIPE_HOLE_HEIGHT-1.0, xPos, xPos+PIPE_WIDTH-1.0, PIPE_OUTLINE_COLOR);

	// gradient fills
	float gradientBottom = bottomPartEnd + 1.0;
	float gradientTop = bottomPartEnd + PIPE_HOLE_HEIGHT - 1.0;
	drawHorzGradientRect(co, vec2(xPos+1.0, gradientBottom), vec2(xPos + 5.0, gradientTop), RGB(221, 234, 131), RGB(228, 250, 145));
	drawHorzGradientRect(co, vec2(xPos+5.0, gradientBottom), vec2(xPos + 22.0, gradientTop), RGB(228, 250, 145), RGB(86, 126, 41));
	drawHorzGradientRect(co, vec2(xPos+22.0, gradientBottom), vec2(xPos + 25.0, gradientTop), RGB(86, 126, 41), RGB(86, 126, 41));

	// shadows
	drawHorzLine(co, gradientBottom, xPos+1.0, xPos+25.0, RGB(86, 126, 41));
	drawHorzLine(co, gradientTop-1.0, xPos+1.0, xPos+25.0, RGB(122, 158, 67));
}

void drawTopPipe(vec2 co, float xPos, float height)
{
	vec2 bounds = getLevelBounds();

	if ((co.x < xPos) || (co.x > (xPos + PIPE_WIDTH)) ||
		(co.y < (bounds.y - height)) || (co.y > bounds.y))
	{
		return;
	}

	// draw the top part of the pipe (main tube)
	// outlines
	float topPartStart = bounds.y - height; // Y-coord where the main tube begins (bottom edge)
	drawVertLine(co, xPos+1.0, topPartStart, bounds.y, PIPE_OUTLINE_COLOR);
	drawVertLine(co, xPos+PIPE_WIDTH-2.0, topPartStart, bounds.y, PIPE_OUTLINE_COLOR);

	// gradient fills
	drawHorzGradientRect(co, vec2(xPos+2.0, topPartStart), vec2(xPos + 10.0, bounds.y), RGB(133, 168, 75), RGB(228, 250, 145));
	drawHorzGradientRect(co, vec2(xPos+10.0, topPartStart), vec2(xPos + 20.0, bounds.y), RGB(228, 250, 145), RGB(86, 126, 41));
	drawHorzGradientRect(co, vec2(xPos+20.0, topPartStart), vec2(xPos + 24.0, bounds.y), RGB(86, 126, 41), RGB(86, 126, 41));

	// shadows
	drawHorzLine(co, topPartStart + 1.0, xPos + 2.0, xPos+PIPE_WIDTH-2.0, RGB(86, 126, 41)); // Shadow at the bottom edge of the tube

	// draw the pipe opening (the wider part at the bottom)
	float openingBottom = topPartStart - PIPE_HOLE_HEIGHT; // Y-coord of the very bottom edge of the opening
	// outlines
	drawVertLine(co, xPos, openingBottom, topPartStart, PIPE_OUTLINE_COLOR);
	drawVertLine(co, xPos+PIPE_WIDTH-1.0, openingBottom, topPartStart, PIPE_OUTLINE_COLOR);
	drawHorzLine(co, topPartStart, xPos, xPos+PIPE_WIDTH, PIPE_OUTLINE_COLOR); // Top edge of opening
	drawHorzLine(co, openingBottom, xPos, xPos+PIPE_WIDTH-1.0, PIPE_OUTLINE_COLOR); // Bottom edge of opening

	// gradient fills
	float gradientBottom = openingBottom + 1.0;
	float gradientTop = topPartStart -1.0; // Corrected: should be topPartStart?
	drawHorzGradientRect(co, vec2(xPos+1.0, gradientBottom), vec2(xPos + 5.0, gradientTop), RGB(221, 234, 131), RGB(228, 250, 145));
	drawHorzGradientRect(co, vec2(xPos+5.0, gradientBottom), vec2(xPos + 22.0, gradientTop), RGB(228, 250, 145), RGB(86, 126, 41));
	drawHorzGradientRect(co, vec2(xPos+22.0, gradientBottom), vec2(xPos + 25.0, gradientTop), RGB(86, 126, 41), RGB(86, 126, 41));

	// shadows
	drawHorzLine(co, gradientBottom, xPos+1.0, xPos+25.0, RGB(122, 158, 67)); // Shadow just above bottom edge
	drawHorzLine(co, gradientTop, xPos+1.0, xPos+25.0, RGB(86, 126, 41)); // Shadow just below top edge
}


void drawBushGroup(vec2 bottomCorner, vec2 co)
{
	drawTile(0, bottomCorner, co);
	bottomCorner.x += 13.0;

	drawTile(1, bottomCorner, co);
	bottomCorner.x += 13.0;

	drawTile(0, bottomCorner, co);
}

void drawBushes(vec2 co)
{
	drawHorzRect(co.y, 39.0, 70.0, RGB(100, 224, 117));

	// iTime is provided by the C++ wrapper
	float scrollSpeed = 40.0; // Adjust speed as needed
	float scrollOffset = mod(iTime * scrollSpeed, 45.0 * 3.0); // Cycle length based on group width

	for (int i = -3; i < 20; i++) { // Start drawing earlier to cover screen edge
		float xOffset = float(i) * 45.0 - scrollOffset;
		drawBushGroup(vec2(xOffset, 70.0), co); // Main level bushes
		// Add parallax effect for other layers if desired
	}
}

void drawClouds(vec2 co)
{
	// iTime is provided by the C++ wrapper
	float scrollSpeed = 20.0; // Slower speed for clouds
	float scrollOffset = mod(iTime * scrollSpeed, 40.0 * 3.0); // Adjust cycle length if needed

	for (int i = -3; i < 20; i++) { // Start drawing earlier
		float xOffset = float(i) * 40.0 - scrollOffset;
		drawTile(2, vec2(xOffset, 95.0), co);
		drawTile(2, vec2(xOffset+14.0, 91.0), co);
		drawTile(2, vec2(xOffset+28.0, 93.0), co);
	}

	drawHorzRect(co.y, 70.0, 95.0, RGB(233,251,218)); // Area below clouds
}


void drawPipePair(vec2 co, float xPos, float bottomPipeHeight)
{
	vec2 bounds = getLevelBounds();
	float topPipeHeight = bounds.y - (VERT_PIPE_DISTANCE + PIPE_BOTTOM + bottomPipeHeight);

	drawBottomPipe(co, xPos, bottomPipeHeight);
	drawTopPipe(co, xPos, topPipeHeight);
}

void drawPipes(vec2 co)
{
	// calculate the starting position of the pipes according to the current frame
	// iTime is provided by the C++ wrapper
	float scrollSpeed = 60.0; // Match the original speed if needed
	float animationCycleLength = HORZ_PIPE_DISTANCE * PIPE_PER_CYCLE; // the number of pixels after which the animation should repeat itself
	float xScrollOffset = mod(iTime * scrollSpeed, animationCycleLength);
	float startXPos = -xScrollOffset; // Start drawing from the left, scrolled by time

	float center = (PIPE_MAX + PIPE_MIN) / 2.0;
	float halfTop = (center + PIPE_MAX) / 2.0;
	float halfBottom = (center + PIPE_MIN) / 2.0;

	vec2 bounds = getLevelBounds();
	int numPipesToDraw = int(ceil(bounds.x / HORZ_PIPE_DISTANCE)) + 2; // Draw enough pipes to cover screen + buffer

	float currentXPos = startXPos;
	// Determine the index of the first pipe based on the scroll offset
	int firstPipeIndex = int(floor(xScrollOffset / HORZ_PIPE_DISTANCE));

	for (int i = 0; i < numPipesToDraw; i++)
	{
	    int pipeIndex = firstPipeIndex + i; // Absolute index in the repeating pattern
		float yPos = center;
		int cycle = int(mod(float(pipeIndex), PIPE_PER_CYCLE)); // Use absolute index for height cycle

		if ((cycle == 1) || (cycle == 3)){
			yPos = halfTop;
		}
		else if (cycle == 2) {
			yPos = PIPE_MAX;
		}
		else if ((cycle == 5) || (cycle == 7)) {
			yPos = halfBottom;
		}
		else if (cycle == 6){
			yPos = PIPE_MIN;
		}

		// Calculate the actual drawing position for this pipe index
		currentXPos = float(pipeIndex) * HORZ_PIPE_DISTANCE - xScrollOffset;
		drawPipePair(co, currentXPos, yPos);
	}
}


void drawBird(vec2 co)
{
	// iTime is provided by the C++ wrapper
	float animationCycleLength = HORZ_PIPE_DISTANCE * PIPE_PER_CYCLE; // the number of frames after which the animation should repeat itself
	int cycleFrame = int(mod(iTime * 60.0, animationCycleLength)); // Using 60fps assumption like original
	float fCycleFrame = float(cycleFrame);

	const float BIRD_X_POS = 105.0; // Fixed horizontal position for the bird
	const float START_POS = 110.0; // Initial Y position at the start of a jump cycle
	const float JUMP_SPEED = 2.88; // Initial upward speed for jump cycle
	const float UPDOWN_DELTA = 0.16; // Y change per pixel scrolled horizontally between pipes
	const float ACCELERATION = -0.0975; // Gravity effect during jump cycle
	float jumpCycleTime = mod(iTime * 60.0, 30.0); // Time within the 30-frame jump cycle
	int horzDist = int(HORZ_PIPE_DISTANCE);

	// calculate the "jumping" effect on the Y axis.
	// Using equations of motion, const acceleration: y = y0 + v0*t + 1/2at^2
	float yPosJump = START_POS + JUMP_SPEED * jumpCycleTime + 0.5 * ACCELERATION * pow(jumpCycleTime, 2.0);

	// Calculate the overall up/down trend based on pipe cycles passed
	float scrollOffset = mod(iTime * 60.0, animationCycleLength);
	int currentPipeCycle = int(floor(scrollOffset / HORZ_PIPE_DISTANCE)); // Which pipe cycle we are in
    float pixelsIntoCurrentCycle = mod(scrollOffset, HORZ_PIPE_DISTANCE); // How far into the current cycle

	int netUpDownCycles = 0; // Net effect of up/down cycles passed
	for (int i = 0; i < currentPipeCycle; i++) {
	    int cycleType = int(mod(float(i), PIPE_PER_CYCLE));
		if ((cycleType == 1) || (cycleType == 3) || (cycleType == 6) || (cycleType == 7)) { // Upward trend cycles
            netUpDownCycles++;
        } else if ((cycleType == 2) || (cycleType == 5)) { // Downward trend cycles
            netUpDownCycles--;
        }
        // Cycles 0 and 4 are neutral (center height)
	}

    // Add the Y offset from completed pipe cycles
    float yPosTrend = float(netUpDownCycles) * HORZ_PIPE_DISTANCE * UPDOWN_DELTA;

    // Add the Y offset from the current partial pipe cycle
    int currentCycleType = int(mod(float(currentPipeCycle), PIPE_PER_CYCLE));
    if ((currentCycleType == 1) || (currentCycleType == 3) || (currentCycleType == 6) || (currentCycleType == 7)) { // Upward trend
        yPosTrend += pixelsIntoCurrentCycle * UPDOWN_DELTA;
    } else if ((currentCycleType == 2) || (currentCycleType == 5)) { // Downward trend
        yPosTrend -= pixelsIntoCurrentCycle * UPDOWN_DELTA;
    }

    // Combine the jump cycle and the overall trend
	float finalYPos = yPosJump + yPosTrend - START_POS; // Subtract START_POS because trend is relative to center

	// Bird animation frame
	int animFrame = int(mod(iTime * 7.0, 3.0));
	if (animFrame == 0) drawTile(3, vec2(BIRD_X_POS, int(finalYPos)), co);
	if (animFrame == 1) drawTile(4, vec2(BIRD_X_POS, int(finalYPos)), co);
	if (animFrame == 2) drawTile(5, vec2(BIRD_X_POS, int(finalYPos)), co);
}

// Main function expected by the C++ wrapper
void mainImage( out vec4 outColor, in vec2 fragCoord )
{
	// Get pixel coordinates scaled for the game's internal resolution
	vec2 levelPixel = getLevelPixel(fragCoord);

	// Start with the sky color
	fragColor = RGB(113, 197, 207); // Use the temporary global

	// Draw scene elements back to front
	drawGround(levelPixel);
	drawGreenStripes(levelPixel);
	drawClouds(levelPixel);
	drawBushes(levelPixel);
	drawPipes(levelPixel);
	drawBird(levelPixel);

    // Assign the final color from the temporary global to the actual output
    outColor = fragColor;
}

// GEEN #version, out FragColor, uniforms, of main() hier - wordt door C++ toegevoegd.
