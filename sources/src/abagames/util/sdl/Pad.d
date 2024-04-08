/*
 * $Id: Pad.d,v 1.3 2004/01/01 11:26:43 kenta Exp $
 *
 * Copyright 2003 Kenta Cho. All rights reserved.
 */
module abagames.util.sdl.Pad;

private:
import std.string;
import std.conv;
import bindbc.sdl;
import abagames.util.sdl.Input;
import abagames.util.sdl.SDLInitFailedException;

version(PANDORA) version = PANDORA_OR_PYRA;
version(PYRA) version = PANDORA_OR_PYRA;
/**
 * Joystick and keyboard input.
 */
public class Pad: Input {
 public:
  static const int PAD_UP = 1;
  static const int PAD_DOWN = 2;
  static const int PAD_LEFT = 4;
  static const int PAD_RIGHT = 8;
  static const int PAD_BUTTON1 = 16;
  static const int PAD_BUTTON2 = 32;
  ubyte *keys;
  bool buttonReversed = false;

 private:
  SDL_Joystick *stick = null;
  const int JOYSTICK_AXIS = 16384;

  public void openJoystick() {
    if (SDL_InitSubSystem(SDL_INIT_JOYSTICK) < 0) {
      throw new SDLInitFailedException(
	"Unable to init SDL joystick: " ~ to!string(SDL_GetError()));
    }
    version (PANDORA) {
      foreach (i; 0..SDL_NumJoysticks()) {
        if (to!string(SDL_JoystickNameForIndex(i)) == "nub0") {
          stick = SDL_JoystickOpen(i);
        }
      }
    } else {
      stick = SDL_JoystickOpen(0);
    }
  }

  public override void handleEvents() {
    keys = SDL_GetKeyboardState(null);
  }

  // Joystick and keyboard handler.

  public int getPadState() {
    int x = 0, y = 0;
    int pad = 0;
    if (stick) {
      x = SDL_JoystickGetAxis(stick, 0);
      y = SDL_JoystickGetAxis(stick, 1);
    }
    if (keys[SDL_SCANCODE_RIGHT] == SDL_PRESSED || keys[SDL_SCANCODE_KP_6] == SDL_PRESSED || x > JOYSTICK_AXIS) {
      pad |= PAD_RIGHT;
    }
    if (keys[SDL_SCANCODE_LEFT] == SDL_PRESSED || keys[SDL_SCANCODE_KP_4] == SDL_PRESSED || x < -JOYSTICK_AXIS) {
      pad |= PAD_LEFT;
    }
    if (keys[SDL_SCANCODE_DOWN] == SDL_PRESSED || keys[SDL_SCANCODE_KP_2] == SDL_PRESSED || y > JOYSTICK_AXIS) {
      pad |= PAD_DOWN;
    }
    if (keys[SDL_SCANCODE_UP] == SDL_PRESSED ||  keys[SDL_SCANCODE_KP_8] == SDL_PRESSED || y < -JOYSTICK_AXIS) {
      pad |= PAD_UP;
    }
    return pad;
  }

  public int getButtonState() {
    bool btnx = false, btnz = false;
    int btn = 0;
    int btn1 = 0, btn2 = 0, btn3 = 0, btn4 = 0, btn5 = 0, btn6 = 0, btn7 = 0, btn8 = 0;
    version(PYRA) {
    } else {
        if (stick) {
          btn1 = SDL_JoystickGetButton(stick, 0);
          btn2 = SDL_JoystickGetButton(stick, 1);
          btn3 = SDL_JoystickGetButton(stick, 2);
          btn4 = SDL_JoystickGetButton(stick, 3);
          btn5 = SDL_JoystickGetButton(stick, 4);
          btn6 = SDL_JoystickGetButton(stick, 5);
          btn7 = SDL_JoystickGetButton(stick, 6);
          btn8 = SDL_JoystickGetButton(stick, 7);
        }
    }
    version (PANDORA_OR_PYRA) {
      if (keys[SDL_SCANCODE_HOME] == SDL_PRESSED || keys[SDL_SCANCODE_PAGEUP] == SDL_PRESSED) btnz = true;
      if (keys[SDL_SCANCODE_PAGEDOWN] == SDL_PRESSED || keys[SDL_SCANCODE_END] == SDL_PRESSED) btnx = true;
    } else {
      if (keys[SDL_SCANCODE_Z] == SDL_PRESSED || keys[SDL_SCANCODE_LCTRL] == SDL_PRESSED ||
	  btn1 || btn4 || btn5 || btn8) btnz = true;
      if (keys[SDL_SCANCODE_X] == SDL_PRESSED ||
	  keys[SDL_SCANCODE_LALT] == SDL_PRESSED || keys[SDL_SCANCODE_LSHIFT] == SDL_PRESSED ||
	  btn2 || btn3 || btn6 || btn7) btnx = true;
    }
    if (btnz) {
      if (!buttonReversed)
	btn |= PAD_BUTTON1;
      else
	btn |= PAD_BUTTON2;
    }
    if (btnx) {
      if (!buttonReversed)
	btn |= PAD_BUTTON2;
      else
	btn |= PAD_BUTTON1;
    }
    return btn;
  }
}
