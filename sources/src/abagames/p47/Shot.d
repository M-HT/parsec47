/*
 * $Id: Shot.d,v 1.2 2004/01/01 11:26:42 kenta Exp $
 *
 * Copyright 2003 Kenta Cho. All rights reserved.
 */
module abagames.p47.Shot;

private:
import std.math;
import abagames.util.Actor;
import abagames.util.ActorInitializer;
import abagames.util.Vector;
import abagames.util.sdl.Screen3D;
import abagames.p47.Field;
import abagames.p47.P47Screen;

/**
 * Player's shots.
 */
public class Shot: Actor {
 public:
  Vector pos;
  const float SPEED = 1;
 private:
  static const float FIELD_SPACE = 1;
  Field field;
  Vector vel;
  float deg;
  int cnt;
  const int RETRO_CNT = 4;

  public override Actor newActor() {
    return new Shot;
  }

  public override void init(ActorInitializer ini) {
    ShotInitializer si = cast(ShotInitializer) ini;
    field = si.field;
    pos = new Vector;
    vel = new Vector;
  }

  public void set(Vector p, float d) {
    pos.x = p.x; pos.y = p.y;
    deg = d;
    vel.x = sin(deg) * SPEED;
    vel.y = cos(deg) * SPEED;
    cnt = 0;
    isExist = true;
  }

  public override void move() {
    pos.x += vel.x;
    pos.y += vel.y;
    if (field.checkHit(pos, FIELD_SPACE))
      isExist = false;
    cnt++;
  }

  public override void draw() {
    float r;
    if (cnt > RETRO_CNT)
      r = 1;
    else
      r = cnt / RETRO_CNT;
    P47Screen.setRetroParam(r, 0.2);
    P47Screen.drawBoxRetro(pos.x, pos.y, 0.2, 1, deg);
  }
}

public class ShotInitializer: ActorInitializer {
 public:
  Field field;

  public this(Field field) {
    this.field = field;
  }
}
