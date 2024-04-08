/*
 * $Id: Screen3D.d,v 1.3 2004/01/01 11:26:43 kenta Exp $
 *
 * Copyright 2003 Kenta Cho. All rights reserved.
 */
module abagames.util.sdl.Screen3D;

private:
import std.string;
import std.conv;
import bindbc.sdl;
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
  static int screenWidth = 640;
  static int screenHeight = 480;
  static int screenStartX = 0;
  static int screenStartY = 0;
  static string name = "";
  static SDL_Window* window;
  static SDL_GLContext context;
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
    uint videoFlags;
    if (windowMode) {
      videoFlags = SDL_WINDOW_OPENGL | SDL_WINDOW_RESIZABLE;
    } else {
      videoFlags = SDL_WINDOW_OPENGL | SDL_WINDOW_FULLSCREEN_DESKTOP;
    }
    window = SDL_CreateWindow(toStringz(name), SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, width, height, videoFlags);
    if (window == null) {
      throw new SDLInitFailedException(
        "Unable to create SDL window: " ~ to!string(SDL_GetError()));
    }
    context = SDL_GL_CreateContext(window);
    if (context == null) {
      SDL_DestroyWindow(window);
      window = null;
      throw new SDLInitFailedException(
        "Unable to initialize OpenGL context: " ~ to!string(SDL_GetError()));
    }
    SDL_GetWindowSize(window, &screenWidth, &screenHeight);
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    resized(screenWidth, screenHeight);
    SDL_ShowCursor(SDL_DISABLE);
    init();
  }

  // Reset viewport when the screen is resized.

  private void screenResized() {
    static if (SDL_VERSION_ATLEAST(2, 0, 1)) {
      SDL_version linked;
      SDL_GetVersion(&linked);
      if (SDL_version(linked.major, linked.minor, linked.patch) >= SDL_version(2, 0, 1)) {
        int glwidth, glheight;
        SDL_GL_GetDrawableSize(window, &glwidth, &glheight);
        if ((cast(float)(glwidth)) / width <= (cast(float)(glheight)) / height) {
          screenStartX = 0;
          screenWidth = glwidth;
          screenHeight = (glwidth * height) / width;
          screenStartY = (glheight - screenHeight) / 2;
        } else {
          screenStartY = 0;
          screenHeight = glheight;
          screenWidth = (glheight * width) / height;
          screenStartX = (glwidth - screenWidth) / 2;
        }
      }
    }
    glViewport(screenStartX, screenStartY, screenWidth, screenHeight);
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

  public override void resized(int width, int height) {
    this.screenWidth = width; this.screenHeight = height;
    screenResized();
  }

  public override void closeSDL() {
    close();
    SDL_ShowCursor(SDL_ENABLE);
    SDL_GL_DeleteContext(context);
    SDL_DestroyWindow(window);
  }

  public override void flip() {
    handleError();
    SDL_GL_SwapWindow(window);
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
    this.name = name.idup;
    if (window != null) {
      SDL_SetWindowTitle(window, toStringz(name));
    }
  }

  public static void setColor(float r, float g, float b, float a) {
    glColor4f(r * brightness, g * brightness, b * brightness, a);
  }
}
