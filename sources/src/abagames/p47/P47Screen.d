/*
 * $Id: P47Screen.d,v 1.5 2004/01/01 11:26:42 kenta Exp $
 *
 * Copyright 2003 Kenta Cho. All rights reserved.
 */
module abagames.p47.P47Screen;

private:
import std.math;
import opengl;
import abagames.util.Rand;
import abagames.util.sdl.Screen3D;
import abagames.p47.LuminousScreen;

/**
 * Initialize an OpenGL and set the caption.
 */
public class P47Screen: Screen3D {
 public:
  static const char[] CAPTION = "PARSEC47";
  static float luminous = 0;
 private:
  static Rand rand;
  LuminousScreen luminousScreen;

  protected override void init() {
    setCaption(CAPTION);
    glLineWidth(1);
    glEnable(GL_LINE_SMOOTH);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE);
    glEnable(GL_BLEND);
    glDisable(GL_LIGHTING);
    glDisable(GL_CULL_FACE);
    glDisable(GL_DEPTH_TEST);
    glDisable(GL_TEXTURE_2D);
    glDisable(GL_COLOR_MATERIAL);    
    rand = new Rand;
    if (luminous > 0) {
      luminousScreen = new LuminousScreen;
      luminousScreen.init(luminous, width, height);
    } else {
      luminousScreen = null;
    }
  }

  protected override void close() {
    if (luminousScreen)
      luminousScreen.close();
  }

  public void startRenderToTexture() {
    if (luminousScreen)
      luminousScreen.startRenderToTexture();
  }

  public void endRenderToTexture() {
    if (luminousScreen)
      luminousScreen.endRenderToTexture();
  }

  public void drawLuminous() {
    if (luminousScreen)
      luminousScreen.draw();
  }

  public void resized(int width, int height) {
    if (luminousScreen)
      luminousScreen.resized(width, height);
    super.resized(width, height);
  }

  public void viewOrthoFixed() {
    glMatrixMode(GL_PROJECTION);
    glPushMatrix();
    glLoadIdentity();
    glOrtho(0, 640, 480, 0, -1, 1);
    glMatrixMode(GL_MODELVIEW);
    glPushMatrix();
    glLoadIdentity();
  }

  public void viewPerspective() {
    glMatrixMode(GL_PROJECTION);
    glPopMatrix();
    glMatrixMode(GL_MODELVIEW);
    glPopMatrix();
  }

  // Draw the retro style lines.
  private static float retro, retroSize;
  public static float retroR, retroG, retroB, retroA;
  private static float retroZ = 0;

  public static void setRetroParam(float r, float sz) {
    retro = r; retroSize = sz;
  }

  public static void setRetroColor(float r, float g, float b, float a) {
    retroR = r; retroG = g; retroB = b; retroA = a;
  }

  public static void setRetroZ(float z) {
    retroZ = z;
  }

  public static void drawLineRetro(float x1, float y1, float x2, float y2) {
    float cf = (1 - retro) * 0.5;
    float r = retroR + (1 - retroR) * cf;
    float g = retroG + (1 - retroG) * cf;
    float b = retroB + (1 - retroB) * cf;
    float a = retroA * (cf + 0.5);
    if (rand.nextInt(7) == 0) {
      r *= 1.5; if (r > 1) r = 1;
      g *= 1.5; if (g > 1) g = 1;
      b *= 1.5; if (b > 1) b = 1;
      a *= 1.5; if (a > 1) a = 1;
    }
    setColor(r, g, b, a);
    if (retro < 0.2f) {
      glBegin(GL_LINES);
      glVertex3f(x1, y1, retroZ);
      glVertex3f(x2, y2, retroZ);
      glEnd();
    } else {
      float ds = retroSize * retro;
      float ds2 = ds / 2;
      float lx = std.math.fabs(x2 - x1);
      float ly = std.math.fabs(y2 - y1);
      glBegin(GL_QUADS);
      if (lx < ly) {
	int n = ly / ds;
	if (n > 0) {
	  float xo = (x2 - x1) / n, xos  = 0;
	  float yo;
	  if (y2 < y1)
	    yo = -ds;
	  else
	    yo = ds;
	  float x = x1, y = y1;
	  for (int i = 0; i <= n; i++, xos += xo, y += yo) {
	    if (xos >= ds) {
	      x += ds;
	      xos -= ds;
	    } else if (xos <= -ds) {
	      x -= ds;
	      xos += ds;
	    }
	    glVertex3f(x - ds2, y - ds2, retroZ);
	    glVertex3f(x + ds2, y - ds2, retroZ);
	    glVertex3f(x + ds2, y + ds2, retroZ);
	    glVertex3f(x - ds2, y + ds2, retroZ);
	  }
	}
      } else {
	int n = lx / ds;
	if (n > 0) {
	  float yo = (y2 - y1) / n, yos = 0;
	  float xo;
	  if (x2 < x1)
	    xo = -ds;
	  else
	    xo = ds;
	  float x = x1, y = y1;
	  for (int i = 0; i <= n; i++, x += xo, yos += yo) {
	    if (yos >= ds) {
	      y += ds;
	      yos -= ds;
	    } else if (yos <= -ds) {
	      y -= ds;
	      yos += ds;
	    }
	    glVertex3f(x - ds2, y - ds2, retroZ);
	    glVertex3f(x + ds2, y - ds2, retroZ);
	    glVertex3f(x + ds2, y + ds2, retroZ);
	    glVertex3f(x - ds2, y + ds2, retroZ);
	  }
	}
      }
      glEnd();
    }
  }

  public static void drawBoxRetro(float x, float y, float width, float height, float deg) {
    float w1, h1, w2, h2;
    w1 = width * cos(deg) - height * sin(deg);
    h1 = width * sin(deg) + height * cos(deg);
    w2 = -width * cos(deg) - height * sin(deg);
    h2 = -width * sin(deg) + height * cos(deg);
    drawLineRetro(x + w2, y - h2, x + w1, y - h1);
    drawLineRetro(x + w1, y - h1, x - w2, y + h2);
    drawLineRetro(x - w2, y + h2, x - w1, y + h1);
    drawLineRetro(x - w1, y + h1, x + w2, y - h2);
  }

  public static void drawBoxSolid(float x, float y, float width, float height) {
    glBegin(GL_TRIANGLE_FAN);
    glVertex3f(x, y, 0);
    glVertex3f(x + width, y, 0);
    glVertex3f(x + width, y + height, 0);
    glVertex3f(x, y + height, 0);
    glEnd();
  }

  public static void drawBoxLine(float x, float y, float width, float height) {
    glBegin(GL_LINE_LOOP);
    glVertex3f(x, y, 0);
    glVertex3f(x + width, y, 0);
    glVertex3f(x + width, y + height, 0);
    glVertex3f(x, y + height, 0);
    glEnd();
  }
}
