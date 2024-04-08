/*
 * $Id: LuminousScreen.d,v 1.4 2004/01/01 11:26:42 kenta Exp $
 *
 * Copyright 2003 Kenta Cho. All rights reserved.
 */
module abagames.p47.LuminousScreen;

private:
import std.math;
import std.string;
import core.stdc.string;
import opengl;
import abagames.util.Rand;

/**
 * Luminous effect texture.
 */
public class LuminousScreen {
 private:
  GLuint luminousTexture;
  const int LUMINOUS_TEXTURE_WIDTH_MAX = 64;
  const int LUMINOUS_TEXTURE_HEIGHT_MAX = 64;
  GLuint[LUMINOUS_TEXTURE_WIDTH_MAX * LUMINOUS_TEXTURE_HEIGHT_MAX * 4 * uint.sizeof] td;
  int luminousTextureWidth = 64, luminousTextureHeight = 64;
  int screenStartx, screenStarty, screenWidth, screenHeight;
  float luminous;

  private void makeLuminousTexture() {
    uint *data = td.ptr;
    int i;
    memset(data, 0, luminousTextureWidth * luminousTextureHeight * 4 * uint.sizeof);
    glGenTextures(1, &luminousTexture);
    glBindTexture(GL_TEXTURE_2D, luminousTexture);
    glTexImage2D(GL_TEXTURE_2D, 0, 4, luminousTextureWidth, luminousTextureHeight, 0,
		 GL_RGBA, GL_UNSIGNED_BYTE, data);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
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
  }

  public void startRenderToTexture() {
    glViewport(0, 0, luminousTextureWidth, luminousTextureHeight);
  }

  public void endRenderToTexture() {
    glBindTexture(GL_TEXTURE_2D, luminousTexture);
    glCopyTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA,
		     0, 0, luminousTextureWidth, luminousTextureHeight, 0);
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

  private int[2][5] lmOfs = [[0, 0], [1, 0], [-1, 0], [0, 1], [0, -1]];
  private const float lmOfsBs = 5;

  public void draw() {
    glEnable(GL_TEXTURE_2D);
    glBindTexture(GL_TEXTURE_2D, luminousTexture);
    viewOrtho();
    glColor4f(1, 0.8, 0.9, luminous);
    glBegin(GL_QUADS);
    for (int i = 0; i < 5; i++) {
      glTexCoord2f(0, 1);
      glVertex2f(0 + lmOfs[i][0] * lmOfsBs, 0 + lmOfs[i][1] * lmOfsBs);
      glTexCoord2f(0, 0);
      glVertex2f(0 + lmOfs[i][0] * lmOfsBs, screenHeight + lmOfs[i][1] * lmOfsBs);
      glTexCoord2f(1, 0);
      glVertex2f(screenWidth + lmOfs[i][0] * lmOfsBs, screenHeight + lmOfs[i][0] * lmOfsBs);
      glTexCoord2f(1, 1);
      glVertex2f(screenWidth + lmOfs[i][0] * lmOfsBs, 0 + lmOfs[i][0] * lmOfsBs);
    }
    glEnd();
    viewPerspective();
    glDisable(GL_TEXTURE_2D);
  }
}
