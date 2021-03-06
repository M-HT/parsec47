/*
 * $Id: Screen3D.d,v 1.3 2004/01/01 11:26:43 kenta Exp $
 *
 * Copyright 2003 Kenta Cho. All rights reserved.
 */
module abagames.util.sdl.Screen3D;

private:
import std.string;
import std.conv;
import SDL;
import opengl;
import abagames.util.Logger;
import abagames.util.sdl.Screen;
import abagames.util.sdl.SDLInitFailedException;

/**
 * SDL screen handler(3D, OpenGL).
 */
public class Screen3D: Screen {
 public:
  static float brightness = 1;
  static int width = 640;
  static int height = 480;
  static int startx = 0;
  static int starty = 0;
  static bool lowres = false;
  static bool windowMode = false;
  static float nearPlane = 0.1;
  static float farPlane = 1000;

 private:

  protected abstract void init();
  protected abstract void close();

  public override void initSDL() {
    if (lowres) {
      width /= 2;
      height /= 2;
    }
    // Initialize SDL.
    if (SDL_Init(SDL_INIT_VIDEO) < 0) {
      throw new SDLInitFailedException(
	"Unable to initialize SDL: " ~ to!string(SDL_GetError()));
    }
    // Create an OpenGL screen.
    Uint32 videoFlags;
    if (windowMode) {
      videoFlags = SDL_OPENGL | SDL_RESIZABLE;
    } else {
      videoFlags = SDL_OPENGL | SDL_FULLSCREEN;
    }
    int physical_width = width;
    int physical_height = height;
    version (PANDORA) {
      if (!windowMode) {
        physical_width = 800;
        physical_height = 480;
        startx = (800 - width) / 2;
        starty = (480 - height) / 2;
      }
    }
    if (SDL_SetVideoMode(physical_width, physical_height, 0, videoFlags) == null) {
      throw new SDLInitFailedException
	("Unable to create SDL screen: " ~ to!string(SDL_GetError()));
    }
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    resized(width, height);
    SDL_ShowCursor(SDL_DISABLE);
    init();
  }

  // Reset viewport when the screen is resized.

  private void screenResized() {
    glViewport(startx, starty, width, height);
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    //gluPerspective(45.0f, (GLfloat)width/(GLfloat)height, nearPlane, farPlane);
    glFrustum(-nearPlane,
	      nearPlane,
	      -nearPlane * cast(GLfloat)height / cast(GLfloat)width,
	      nearPlane * cast(GLfloat)height / cast(GLfloat)width,
	      0.1f, farPlane);
    glMatrixMode(GL_MODELVIEW);
  }

  public void resized(int width, int height) {
    this.width = width; this.height = height;
    screenResized();
  }

  public override void closeSDL() {
    close();
    SDL_ShowCursor(SDL_ENABLE);
  }

  public override void flip() {
    handleError();
    SDL_GL_SwapBuffers();
  }

  public override void clear() {
    glClear(GL_COLOR_BUFFER_BIT);
  }

  public void handleError() {
    GLenum error = glGetError();
    if (error == GL_NO_ERROR) return;
    closeSDL();
    throw new Exception("OpenGL error");
  }

  protected void setCaption(const char[] name) {
    SDL_WM_SetCaption(std.string.toStringz(name), null);
  }

  public static void setColor(float r, float g, float b, float a) {
    glColor4f(r * brightness, g * brightness, b * brightness, a);
  }
}
