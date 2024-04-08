/*
 * $Id: Roll.d,v 1.3 2004/01/01 11:26:42 kenta Exp $
 *
 * Copyright 2003 Kenta Cho. All rights reserved.
 */
module abagames.p47.Roll;

private:
import std.math;
import abagames.util.Vector;
import abagames.util.Actor;
import abagames.util.ActorInitializer;
import abagames.p47.Ship;
import abagames.p47.Field;
import abagames.p47.P47Screen;
import abagames.p47.P47GameManager;

/**
 * Roll shot.
 */
public class Roll: Actor {
 public:
  bool released;
  static const int LENGTH = 4;
  Vector[LENGTH] pos;
  static const int NO_COLLISION_CNT = 45;
  int cnt;
 private:
  static const float BASE_LENGTH = 1.0, BASE_RESISTANCE = 0.8, BASE_SPRING = 0.2;
  static const float BASE_SIZE = 0.2, BASE_DIST = 3;
  static const float SPEED = 0.75;
  Vector[LENGTH] vel;
  Ship ship;
  Field field;
  P47GameManager manager;
  float dist;

  public override Actor newActor() {
    return new Roll;
  }

  public override void init(ActorInitializer ini) {
    RollInitializer ri = cast(RollInitializer) ini;
    ship = ri.ship;
    field = ri.field;
    manager = ri.manager;
    for (int i = 0; i < LENGTH; i++) {
      pos[i] = new Vector;
      vel[i] = new Vector;
    }
  }

  public void set() {
    for (int i = 0; i < LENGTH; i++) {
      pos[i].x = ship.pos.x;
      pos[i].y = ship.pos.y;
      vel[i].x = vel[i].y = 0;
    }
    cnt = 0;
    dist = 0;
    released = false;
    isExist = true;
  }

  public override void move() {
    if (released) {
      pos[0].y += SPEED;
      if (pos[0].y > field.size.y) {
	isExist = false;
	return;
      }
      manager.addParticle(pos[0], std.math.PI,
			  BASE_SIZE * LENGTH, SPEED / 8);
    } else {
      if (dist < BASE_DIST)
	dist += BASE_DIST / 90;
      pos[0].x = ship.pos.x + sin(cnt * 0.1) * dist;
      pos[0].y = ship.pos.y + cos(cnt * 0.1) * dist;
    }
    float dist, deg, v;
    for (int i = 1; i < LENGTH; i++) {
      pos[i].x += vel[i].x;
      pos[i].y += vel[i].y;
      vel[i].x *= BASE_RESISTANCE;
      vel[i].y *= BASE_RESISTANCE;
      dist = pos[i].dist(pos[i - 1]);
      if (dist <= BASE_LENGTH)
	continue;
      v = (dist - BASE_LENGTH) * BASE_SPRING;
      deg = std.math.atan2(pos[i - 1].x - pos[i].x, pos[i - 1].y - pos[i].y);
      vel[i].x += sin(deg) * v; vel[i].y += cos(deg) * v;
    }
    cnt++;
  }

  public override void draw() {
    if (released)
      P47Screen.setRetroParam(1, 0.2);
    else
      P47Screen.setRetroParam(0.5, 0.2);
    for (int i = 0; i < LENGTH; i++) {
      P47Screen.drawBoxRetro(pos[i].x, pos[i].y,
			     BASE_SIZE * (LENGTH - i),  BASE_SIZE * (LENGTH - i),
			     cnt * 0.1);
    }
  }
}

public class RollInitializer: ActorInitializer {
 public:
  Ship ship;
  Field field;
  P47GameManager manager;

  public this(Ship ship, Field field, P47GameManager manager) {
    this.ship = ship;
    this.field = field;
    this.manager = manager;
  }
}
