/*
 * $Id: Input.d,v 1.2 2004/01/01 11:26:43 kenta Exp $
 *
 * Copyright 2003 Kenta Cho. All rights reserved.
 */
module abagames.util.sdl.Input;

private:
import SDL;

/**
 * Input device interface.
 */
//public interface Input {
public abstract class Input {
  public void handleEvent(SDL_Event *event);
}
