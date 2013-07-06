/*
 * $Id: LuminousActorPool.d,v 1.2 2004/01/01 11:26:42 kenta Exp $
 *
 * Copyright 2003 Kenta Cho. All rights reserved.
 */
module abagames.p47.LuminousActorPool;

private:
import abagames.util.Actor;
import abagames.util.ActorPool;
import abagames.util.ActorInitializer;
import abagames.p47.LuminousActor;

/**
 * Actor pool for the LuminousActor.
 */
public class LuminousActorPool: ActorPool {
  public this(int n, Actor act, ActorInitializer ini) {
    super(n, act, ini);
  }

  public void drawLuminous() {
    for (int i = 0; i < actor.length; i++) {
      if (actor[i].isExist)
	(cast(LuminousActor) actor[i]).drawLuminous();
    }
  }
}
