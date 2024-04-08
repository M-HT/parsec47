/*
 * $Id: BulletActorPool.d,v 1.3 2004/01/01 11:26:41 kenta Exp $
 *
 * Copyright 2003 Kenta Cho. All rights reserved.
 */
module abagames.p47.BulletActorPool;

private:
import std.math;
import bulletml;
import abagames.util.ActorInitializer;
import abagames.util.ActorPool;
import abagames.util.Vector;
import abagames.util.bulletml.Bullet;
import abagames.util.bulletml.BulletsManager;
import abagames.p47.BulletActor;
import abagames.p47.P47Bullet;

/**
 * Bullet actor pool that works as the BulletsManager.
 */
public class BulletActorPool: ActorPool, BulletsManager {
 private:
  int cnt;

  public this(int n, ActorInitializer ini) {
    scope BulletActor bulletActorClass = new BulletActor;
    super(n, bulletActorClass, ini);
    Bullet.setBulletsManager(this);
    BulletActor.init();
    cnt = 0;
  }

  public void addBullet(float deg, float speed) {
    BulletActor ba = cast(BulletActor) getInstance();
    if (!ba)
      return;
    P47Bullet rb = cast(P47Bullet) Bullet.now;
    if (rb.isMorph) {
      BulletMLRunner *runner = BulletMLRunner_new_parser(rb.morphParser[rb.morphIdx]);
      BulletActorPool.registFunctions(runner);
      ba.set(runner, Bullet.now.pos.x, Bullet.now.pos.y, deg, speed,
	     Bullet.now.rank,
	     rb.speedRank, rb.shape, rb.color, rb.bulletSize, rb.xReverse,
	     rb.morphParser, rb.morphNum, rb.morphIdx + 1, rb.morphCnt - 1);
    } else {
      ba.set(Bullet.now.pos.x, Bullet.now.pos.y, deg, speed,
	     Bullet.now.rank,
	     rb.speedRank, rb.shape, rb.color, rb.bulletSize, rb.xReverse);
    }
  }

  public void addBullet(BulletMLState *state, float deg, float speed) {
    BulletActor ba = cast(BulletActor) getInstance();
    if (!ba)
      return;
    BulletMLRunner* runner = BulletMLRunner_new_state(state);
    registFunctions(runner);
    P47Bullet rb = cast(P47Bullet) Bullet.now;
    if (rb.isMorph)
      ba.set(runner, Bullet.now.pos.x, Bullet.now.pos.y, deg, speed,
	     Bullet.now.rank,
	     rb.speedRank, rb.shape, rb.color, rb.bulletSize, rb.xReverse,
	     rb.morphParser, rb.morphNum, rb.morphIdx, rb.morphCnt);
    else
      ba.set(runner, Bullet.now.pos.x, Bullet.now.pos.y, deg, speed,
	     Bullet.now.rank,
	     rb.speedRank, rb.shape, rb.color, rb.bulletSize, rb.xReverse);
  }

  public BulletActor addBullet(BulletMLRunner *runner,
			       float x, float y, float deg, float speed,
			       float rank,
			       float speedRank, int shape, int color, float size, float xReverse) {
    BulletActor ba = cast(BulletActor) getInstance();
    if (!ba)
      return null;
    ba.set(runner, x, y, deg, speed, rank, speedRank, shape, color, size, xReverse);
    ba.setInvisible();
    return ba;
  }

  public BulletActor addBullet(BulletMLParser *parser,
			       BulletMLRunner *runner,
			       float x, float y, float deg, float speed,
			       float rank,
			       float speedRank, int shape, int color, float size, float xReverse) {
    BulletActor ba =
      addBullet(runner, x, y, deg, speed, rank, speedRank, shape, color, size, xReverse);
    if (!ba)
      return null;
    ba.setTop(parser);
    return ba;
  }

  public BulletActor addBullet(BulletMLParser *parser,
			       BulletMLRunner *runner,
			       float x, float y, float deg, float speed,
			       float rank,
			       float speedRank, int shape, int color, float size, float xReverse,
			       BulletMLParser*[] morph, int morphNum, int morphCnt) {
    BulletActor ba = cast(BulletActor) getInstance();
    if (!ba)
      return null;
    ba.set(runner, x, y, deg, speed, rank,
	   speedRank, shape, color, size, xReverse,
	   morph, morphNum, 0, morphCnt);
    ba.setTop(parser);
    return ba;
  }

  public override void move() {
    super.move();
    cnt++;
  }

  public int getTurn() {
    return cnt;
  }

  public void killMe(Bullet bullet) {
    assert((cast(BulletActor) actor[bullet.id]).bullet.id == bullet.id);
    (cast(BulletActor) actor[bullet.id]).remove();
  }

  public override void clear() {
    for (int i = 0; i < actor.length; i++) {
      if (actor[i].isExist)
	(cast(BulletActor) actor[i]).remove();
    }
  }

  public static void registFunctions(BulletMLRunner* runner) {
    BulletMLRunner_set_getBulletDirection(runner, &getBulletDirection_);
    BulletMLRunner_set_getAimDirection(runner, &getAimDirectionWithXRev_);
    BulletMLRunner_set_getBulletSpeed(runner, &getBulletSpeed_);
    BulletMLRunner_set_getDefaultSpeed(runner, &getDefaultSpeed_);
    BulletMLRunner_set_getRank(runner, &getRank_);
    BulletMLRunner_set_createSimpleBullet(runner, &createSimpleBullet_);
    BulletMLRunner_set_createBullet(runner, &createBullet_);
    BulletMLRunner_set_getTurn(runner, &getTurn_);
    BulletMLRunner_set_doVanish(runner, &doVanish_);

    BulletMLRunner_set_doChangeDirection(runner, &doChangeDirection_);
    BulletMLRunner_set_doChangeSpeed(runner, &doChangeSpeed_);
    BulletMLRunner_set_doAccelX(runner, &doAccelX_);
    BulletMLRunner_set_doAccelY(runner, &doAccelY_);
    BulletMLRunner_set_getBulletSpeedX(runner, &getBulletSpeedX_);
    BulletMLRunner_set_getBulletSpeedY(runner, &getBulletSpeedY_);
    BulletMLRunner_set_getRand(runner, &getRand_);
  }
}

extern (C) {
  double getAimDirectionWithXRev_(BulletMLRunner* r) {
    Vector b = Bullet.now.pos;
    Vector t = Bullet.target;
    float xrev = (cast(P47Bullet) Bullet.now).xReverse;
    return rtod(std.math.atan2(t.x - b.x, t.y - b.y) * xrev);
  }
}
