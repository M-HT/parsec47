/*
 * $Id: P47Boot.d,v 1.6 2004/01/01 11:26:42 kenta Exp $
 *
 * Copyright 2003 Kenta Cho. All rights reserved.
 */
module abagames.p47.P47Boot;

private:
import std.string;
import std.c.stdlib;
import abagames.util.Logger;
import abagames.util.sdl.Pad;
import abagames.util.sdl.MainLoop;
import abagames.util.sdl.Screen3D;
import abagames.util.sdl.Sound;
import abagames.p47.P47Screen;
import abagames.p47.P47GameManager;
import abagames.p47.P47PrefManager;
import abagames.p47.Ship;

/**
 * Boot the game.
 */
private:
P47Screen screen;
Pad pad;
P47GameManager gameManager;
P47PrefManager prefManager;
MainLoop mainLoop;

private void usage(char[] args0) {
  Logger.error
    ("Usage: " ~ args0 ~ " [-brightness [0-100]] [-luminous [0-100]] [-nosound] [-window] [-reverse] [-lowres] [-slowship] [-nowait]");
}

private void parseArgs(char[][] args) {
  for (int i = 1; i < args.length; i++) {
    switch (args[i]) {
    case "-brightness":
      if (i >= args.length - 1) {
	usage(args[0]);
	throw new Exception("Invalid options");
      }
      i++;
      float b = (float) atoi(args[i]) / 100;
      if (b < 0 || b > 1) {
	usage(args[0]);
	throw new Exception("Invalid options");
      }
      Screen3D.brightness = b;
      break;
    case "-luminous":
      if (i >= args.length - 1) {
	usage(args[0]);
	throw new Exception("Invalid options");
      }
      i++;
      float l = (float) atoi(args[i]) / 100;
      if (l < 0 || l > 1) {
	usage(args[0]);
	throw new Exception("Invalid options");
      }
      P47Screen.luminous = l;
      break;
    case "-nosound":
      Sound.noSound = true;
      break;
    case "-window":
      Screen3D.windowMode = true;
      break;
    case "-reverse":
      pad.buttonReversed = true;
      break;
    case "-lowres":
      Screen3D.lowres = true;
      break;
    case "-slowship":
      Ship.isSlow = true;
      break;
    case "-nowait":
      gameManager.nowait = true;
      break;
    case "-accframe":
      mainLoop.accframe = 1;
      break;
    default:
      usage(args[0]);
      throw new Exception("Invalid options");
    }
  }
}

public int boot(char[][] args) {
  screen = new P47Screen;
  pad = new Pad;
  try {
    pad.openJoystick();
  } catch (Exception e) {}
  gameManager = new P47GameManager;
  prefManager = new P47PrefManager;
  mainLoop = new MainLoop(screen, pad, gameManager, prefManager);
  try {
    parseArgs(args);
  } catch (Exception e) {
    return EXIT_FAILURE;
  }
  mainLoop.loop();
  return EXIT_SUCCESS;
}

version (Win32_release) {

// Boot as the Windows executable.
import std.c.windows.windows;
import std.string;

extern (C) void gc_init();
extern (C) void gc_term();
extern (C) void _minit();
extern (C) void _moduleCtor();

extern (Windows)
public int WinMain(HINSTANCE hInstance,
	    HINSTANCE hPrevInstance,
	    LPSTR lpCmdLine,
	    int nCmdShow) {
  int result;
  
  gc_init();
  _minit();
  try {
    _moduleCtor();
    char exe[4096];
    GetModuleFileNameA(null, exe, 4096);
    char[][1] prog;
    prog[0] = std.string.toString(exe);
    result = boot(prog ~ std.string.split(std.string.toString(lpCmdLine)));
  } catch (Object o) {
    //Logger.error("Exception: " ~ o.toString());
    Logger.info("Exception: " ~ o.toString());
    result = EXIT_FAILURE;
  }
  gc_term();
  return result;
}

} else {

// Boot as the general executable.
public int main(char[][] args) {
  return boot(args);
}

}
