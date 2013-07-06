/*
 * $Id: MainLoop.d,v 1.3 2004/01/01 11:26:43 kenta Exp $
 *
 * Copyright 2003 Kenta Cho. All rights reserved.
 */
module abagames.util.sdl.MainLoop;

private:
import std.string;
import SDL;
import abagames.util.Logger;
import abagames.util.Rand;
import abagames.util.PrefManager;
import abagames.util.sdl.GameManager;
import abagames.util.sdl.Screen;
import abagames.util.sdl.Input;
import abagames.util.sdl.Sound;
import abagames.util.sdl.SDLInitFailedException;

/**
 * SDL main loop.
 */
public class MainLoop {
 public:
  const int INTERVAL_BASE = 16;
  int interval = INTERVAL_BASE;
  int accframe = 0;
  int maxSkipFrame = 5;
  SDL_Event event;

 private:
  Screen screen;
  Input input;
  GameManager gameManager;
  PrefManager prefManager;

  public this(Screen screen, Input input,
	      GameManager gameManager, PrefManager prefManager) {
    this.screen = screen;
    this.input = input;
    gameManager.setMainLoop(this);
    gameManager.setUIs(screen, input);
    gameManager.setPrefManager(prefManager);
    this.gameManager = gameManager;
    this.prefManager = prefManager;
  }

  // Initialize and load preference.
  private void initFirst() {
    prefManager.load();
    try {
      Sound.init();
    } catch (SDLInitFailedException e) {
      Logger.error(e);
    }
    gameManager.init();
  }

  // Quit and save preference.
  private void quitLast() {
    gameManager.close();
    Sound.close();
    prefManager.save();
    screen.closeSDL();
    SDL_Quit();
  }

  private bool done;

  public void breakLoop() {
    done = true;
  }

  public void loop() {
    done = false;
    long prvTickCount = 0;
    int i;
    long nowTick;
    int frame;

    screen.initSDL();
    initFirst();
    gameManager.start();

    while (!done) {
      SDL_PollEvent(&event);
      input.handleEvent(&event);
      if (event.type == SDL_QUIT)
	breakLoop();
      nowTick = SDL_GetTicks();
      frame = cast(int) (nowTick-prvTickCount) / interval;
      if (frame <= 0) {
	frame = 1;
	SDL_Delay(cast(uint)(prvTickCount+interval-nowTick));
	if (accframe) {
	  prvTickCount = SDL_GetTicks();
	} else {
	  prvTickCount += interval;
	}
      } else if (frame > maxSkipFrame) {
	frame = maxSkipFrame;
	prvTickCount = nowTick;
      } else {
	prvTickCount += frame * interval;
      }
      for (i = 0; i < frame; i++) {
	gameManager.move();
      }
      screen.clear();
      gameManager.draw();
      screen.flip();
    }
    quitLast();
  }
}
