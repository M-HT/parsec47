/*
 * $Id: Actor.d,v 1.2 2004/01/01 11:26:43 kenta Exp $
 *
 * Copyright 2003 Kenta Cho. All rights reserved.
 */
module abagames.util.Actor;

private:
import abagames.util.ActorInitializer;

/**
 * Actor in the game that has the interface to move and draw.
 */
public class Actor {
 public:
  bool isExist;
  
  public abstract Actor newActor();
  public abstract void init(ActorInitializer ini);
  public abstract void move();
  public abstract void draw();
}
