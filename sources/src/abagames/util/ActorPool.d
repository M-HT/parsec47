/*
 * $Id: ActorPool.d,v 1.2 2004/01/01 11:26:43 kenta Exp $
 *
 * Copyright 2003 Kenta Cho. All rights reserved.
 */
module abagames.util.ActorPool;

private:
import abagames.util.Actor;
import abagames.util.ActorInitializer;

/**
 * Object pooling for actors.
 */
public class ActorPool {
 public:
  Actor[] actor;
 protected:
  int actorIdx;

  public this(int n, Actor act, ActorInitializer ini) {
    actor = new Actor[n];
    for (int i = 0; i < actor.length; i++) {
      actor[i] = act.newActor();
      actor[i].isExist = false;
      actor[i].init(ini);
    }
    actorIdx = n;
  }

  public Actor getInstance() {
    for (int i = 0; i < actor.length; i++) {
      actorIdx--;
      if (actorIdx < 0)
	actorIdx = cast(int)(actor.length - 1);
      if (!actor[actorIdx].isExist)
	return actor[actorIdx];
    }
    return null;
  }

  public Actor getInstanceForced() {
    actorIdx--;
    if (actorIdx < 0)
      actorIdx = cast(int)(actor.length - 1);
    return actor[actorIdx];
  }

  public void move() {
    for (int i = 0; i < actor.length; i++) {
      if (actor[i].isExist)
	actor[i].move();
    }
  }

  public void draw() {
    for (int i = 0; i < actor.length; i++) {
      if (actor[i].isExist)
	actor[i].draw();
    }
  }

  public void clear() {
    for (int i = 0; i < actor.length; i++) {
      actor[i].isExist = false;
    }
  }
}
