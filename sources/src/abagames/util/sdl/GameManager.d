/*
 * $Id: GameManager.d,v 1.2 2004/01/01 11:26:43 kenta Exp $
 *
 * Copyright 2003 Kenta Cho. All rights reserved.
 */
module abagames.util.sdl.GameManager;

private:
import abagames.util.PrefManager;
import abagames.util.sdl.MainLoop;
import abagames.util.sdl.Screen;
import abagames.util.sdl.Input;

/**
 * Manage the lifecycle of the game.
 */
public class GameManager {
 public:
  int status;

 protected:
  MainLoop mainLoop;
  Screen abstScreen;
  Input input;
  PrefManager abstPrefManager;

 private:

  public void setMainLoop(MainLoop mainLoop) {
    this.mainLoop = mainLoop;
  }

  public void setUIs(Screen screen, Input input) {
    abstScreen = screen;
    this.input = input;
  }

  public void setPrefManager(PrefManager prefManager) {
    abstPrefManager = prefManager;
  }

  public abstract void init();
  public abstract void start();
  public abstract void close();
  public abstract void move();
  public abstract void draw();
}
