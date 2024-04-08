/*
 * $Id: Screen.d,v 1.1.1.1 2003/11/28 17:26:30 kenta Exp $
 *
 * Copyright 2003 Kenta Cho. All rights reserved.
 */
module abagames.util.sdl.Screen;

/**
 * SDL screen handler interface.
 */
//public interface Screen {
public abstract class Screen {
  public void initSDL();
  public void resized(int width, int height);
  public void closeSDL();
  public void flip();
  public void clear();
}
