/*
 * $Id: Bullet.d,v 1.2 2004/01/01 11:26:43 kenta Exp $
 *
 * Copyright 2003 Kenta Cho. All rights reserved.
 */
module abagames.util.bulletml.Bullet;

private:
import std.math;
import bulletml;
import abagames.util.Vector;
import abagames.util.Rand;
import abagames.util.bulletml.BulletsManager;

/**
 * Bullet controled by BulletML.
 */
public class Bullet {
 public:
  static Bullet now;
  static Vector target;
  Vector pos, acc;
  float deg;
  float speed;
  float rank;
  int id;

 private:
  static Rand rand;
  static BulletsManager manager;
  BulletMLRunner* runner;
  
  public static this() {
    rand = new Rand;
  }

  public static void setBulletsManager(BulletsManager bm) {
    manager = bm;
    target = new Vector;
    target.x = target.y = 0;
  }

  public static double getRand() {
    return rand.nextFloat(1);
  }

  public static void addBullet(float deg, float speed) {
    manager.addBullet(deg, speed);
  }

  public static void addBullet(BulletMLState *state, float deg, float speed) {
    manager.addBullet(state, deg, speed);
  }

  public static int getTurn() {
    return manager.getTurn();
  }

  public this(int id) {
    pos = new Vector;
    acc = new Vector;
    this.id = id;
  }

  public void set(float x, float y, float deg, float speed, float rank) {
    pos.x = x; pos.y = y;
    acc.x = acc.y = 0;
    this.deg = deg;
    this.speed = speed;
    this.rank = rank;
    runner = null;
  }

  public void setRunner(BulletMLRunner* runner) {
    this.runner = runner;
  }

  public void set(BulletMLRunner* runner, 
		  float x, float y, float deg, float speed, float rank) {
    set(x, y, deg, speed, rank);
    setRunner(runner);
  }

  public void move() {
    now = this;
    if (!BulletMLRunner_isEnd(runner)) {
      BulletMLRunner_run(runner);
    }
  }

  public bool isEnd() {
    return BulletMLRunner_isEnd(runner);
  }

  public void kill() {
    manager.killMe(this);
  }

  public void remove() {
    if (runner) {
      BulletMLRunner_delete(runner);
      runner = null;
    }
  }
}

private:
const float VEL_SS_SDM_RATIO = 62.0 / 10;
const float VEL_SDM_SS_RATIO = 10.0 / 62;

public:

float rtod(float a) {
  return a * 180 / std.math.PI;
}

float dtor(float a) {
  return a * std.math.PI / 180;
}


extern (C) {
  double getBulletDirection_(BulletMLRunner* r) {
    return rtod(Bullet.now.deg);
  }
  double getAimDirection_(BulletMLRunner* r) {
    Vector b = Bullet.now.pos;
    Vector t = Bullet.target;
    return rtod(std.math.atan2(t.x - b.x, t.y - b.y));
  }
  double getBulletSpeed_(BulletMLRunner* r) {
    return Bullet.now.speed * VEL_SS_SDM_RATIO;
  }
  double getDefaultSpeed_(BulletMLRunner* r) {
    return 1;
  }
  double getRank_(BulletMLRunner* r) {
    return Bullet.now.rank;
  }
  void createSimpleBullet_(BulletMLRunner* r, double d, double s) {
    Bullet.addBullet(dtor(d), s * VEL_SDM_SS_RATIO);
  }
  void createBullet_(BulletMLRunner* r, BulletMLState* state, double d, double s) {
    Bullet.addBullet(state, dtor(d), s * VEL_SDM_SS_RATIO);
  }
  int getTurn_(BulletMLRunner* r) {
    return Bullet.getTurn();
  }
  void doVanish_(BulletMLRunner* r) {
    Bullet.now.kill();
  }
  void doChangeDirection_(BulletMLRunner* r, double d) {
    Bullet.now.deg = dtor(d);
  }
  void doChangeSpeed_(BulletMLRunner* r, double s) {
    Bullet.now.speed = s * VEL_SDM_SS_RATIO;
  }
  void doAccelX_(BulletMLRunner* r, double sx) {
    Bullet.now.acc.x = sx * VEL_SDM_SS_RATIO;
  }
  void doAccelY_(BulletMLRunner* r, double sy) {
    Bullet.now.acc.y = sy * VEL_SDM_SS_RATIO;
  }
  double getBulletSpeedX_(BulletMLRunner* r) {
    return Bullet.now.acc.x;
  }
  double getBulletSpeedY_(BulletMLRunner* r) {
    return Bullet.now.acc.y;
  }
  double getRand_(BulletMLRunner *r) {
    return Bullet.getRand();
  }
}
