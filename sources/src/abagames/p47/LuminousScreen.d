/*
 * $Id: LuminousScreen.d,v 1.4 2004/01/01 11:26:42 kenta Exp $
 *
 * Copyright 2003 Kenta Cho. All rights reserved.
 */
module abagames.p47.LuminousScreen;

private:
import std.math;
import std.string;
import std.c.string;
version (USE_GLES) {
  import opengles;
  import opengles_fbo;
  alias glOrthof glOrtho;
} else {
  import opengl;
}
import abagames.util.Rand;

/**
 * Luminous effect texture.
 */
public class LuminousScreen {
 private:
  GLuint luminousTexture;
  const int LUMINOUS_TEXTURE_WIDTH_MAX = 64;
  const int LUMINOUS_TEXTURE_HEIGHT_MAX = 64;
  GLuint td[LUMINOUS_TEXTURE_WIDTH_MAX * LUMINOUS_TEXTURE_HEIGHT_MAX * 4 * uint.sizeof];
  int luminousTextureWidth = 64, luminousTextureHeight = 64;
  int screenStartx, screenStarty, screenWidth, screenHeight;
  float luminous;
  version (USE_GLES) {
    GLuint luminousFramebuffer;
  }

  private void makeLuminousTexture() {
    uint *data = td.ptr;
    int i;
    memset(data, 0, luminousTextureWidth * luminousTextureHeight * 4 * uint.sizeof);
    glGenTextures(1, &luminousTexture);
    glBindTexture(GL_TEXTURE_2D, luminousTexture);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, luminousTextureWidth, luminousTextureHeight, 0,
		 GL_RGBA, GL_UNSIGNED_BYTE, data);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    version (USE_GLES) {
      glGenFramebuffersOES(1, &luminousFramebuffer);
      glBindFramebufferOES(GL_FRAMEBUFFER_OES, luminousFramebuffer);
      glFramebufferTexture2DOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_TEXTURE_2D, luminousTexture, 0);
      glClear(GL_COLOR_BUFFER_BIT);
      glBindFramebufferOES(GL_FRAMEBUFFER_OES, 0);
    }
  }

  public void init(float luminous, int startx, int starty, int width, int height) {
    makeLuminousTexture();
    this.luminous = luminous;
    screenStartx = startx;
    screenStarty = starty;
    resized(width, height);
  }

  public void resized(int width, int height) {
    screenWidth = width;
    screenHeight = height;
  }

  public void close() {
    glDeleteTextures(1, &luminousTexture);
    version (USE_GLES) {
      glDeleteFramebuffersOES(1, &luminousFramebuffer);
    }
  }

  public void startRenderToTexture() {
    version (USE_GLES) {
      glBindFramebufferOES(GL_FRAMEBUFFER_OES, luminousFramebuffer);
      glClear(GL_COLOR_BUFFER_BIT);
    }
    glViewport(0, 0, luminousTextureWidth, luminousTextureHeight);
  }

  public void endRenderToTexture() {
    version (USE_GLES) {
      glBindFramebufferOES(GL_FRAMEBUFFER_OES, 0);
    } else {
      glBindTexture(GL_TEXTURE_2D, luminousTexture);
      glCopyTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA,
		       0, 0, luminousTextureWidth, luminousTextureHeight, 0);
    }
    glViewport(screenStartx, screenStarty, screenWidth, screenHeight);
  }

  private void viewOrtho() {
    glMatrixMode(GL_PROJECTION);
    glPushMatrix();
    glLoadIdentity();
    glOrtho(0, screenWidth, screenHeight, 0, -1, 1);
    glMatrixMode(GL_MODELVIEW);
    glPushMatrix();
    glLoadIdentity();
  }

  private void viewPerspective() {
    glMatrixMode(GL_PROJECTION);
    glPopMatrix();
    glMatrixMode(GL_MODELVIEW);
    glPopMatrix();
  }

  private int lmOfs[5][2] = [[0, 0], [1, 0], [-1, 0], [0, 1], [0, -1]];
  private const float lmOfsBs = 5;

  public void draw() {
    glEnable(GL_TEXTURE_2D);
    glBindTexture(GL_TEXTURE_2D, luminousTexture);
    viewOrtho();
    glColor4f(1, 0.8, 0.9, luminous);
    {
      static const GLfloat[2*4] luminousTexCoords = [
        0, 1,
        0, 0,
        1, 0,
        1, 1
      ];
      GLfloat[2*4] luminousVertices;

      glEnableClientState(GL_VERTEX_ARRAY);
      glEnableClientState(GL_TEXTURE_COORD_ARRAY);

      glVertexPointer(2, GL_FLOAT, 0, cast(void *)(luminousVertices.ptr));
      glTexCoordPointer(2, GL_FLOAT, 0, cast(void *)(luminousTexCoords.ptr));

      foreach (i; 0..5) {
        luminousVertices[0] = 0 + lmOfs[i][0] * lmOfsBs;
        luminousVertices[1] = 0 + lmOfs[i][1] * lmOfsBs;

        luminousVertices[2] = 0 + lmOfs[i][0] * lmOfsBs;
        luminousVertices[3] = screenHeight + lmOfs[i][1] * lmOfsBs;

        luminousVertices[4] = screenWidth + lmOfs[i][0] * lmOfsBs;
        luminousVertices[5] = screenHeight + lmOfs[i][0] * lmOfsBs;

        luminousVertices[6] = screenWidth + lmOfs[i][0] * lmOfsBs;
        luminousVertices[7] = 0 + lmOfs[i][0] * lmOfsBs;

        glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
      }

      glDisableClientState(GL_TEXTURE_COORD_ARRAY);
      glDisableClientState(GL_VERTEX_ARRAY);
    }
    viewPerspective();
    glDisable(GL_TEXTURE_2D);
  }
}
