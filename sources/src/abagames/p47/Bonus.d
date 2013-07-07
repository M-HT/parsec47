/*
 * $Id: Bonus.d,v 1.4 2004/01/01 11:26:41 kenta Exp $
 *
 * Copyright 2003 Kenta Cho. All rights reserved.
 */
module abagames.p47.Bonus;

private:
import std.math;
version (USE_GLES) {
  import opengles;
} else {
  import opengl;
}
import abagames.util.Vector;
import abagames.util.Rand;
import abagames.util.Actor;
import abagames.util.ActorInitializer;
import abagames.util.sdl.Screen3D;
import abagames.p47.Field;
import abagames.p47.Ship;
import abagames.p47.P47GameManager;
import abagames.p47.P47Screen;
import abagames.p47.SoundManager;

/**
 * Bonus items.
 */
public class Bonus: Actor {
 public:
  static float rate;
  static int bonusScore;
 private:
  static const float BASE_SPEED = 0.1;
  static float speed;
  static const float INHALE_WIDTH = 3;
  static const float ACQUIRE_WIDTH = 1;
  static const int RETRO_CNT = 20;
  static const float BOX_SIZE = 0.4;
  static Rand rand;
  float fieldLimitX, fieldLimitY;
  Field field;
  Ship ship;
  P47GameManager manager;
  Vector pos;
  Vector vel;
  int cnt;
  bool isDown;
  bool isInhaled;
  int inhaleCnt;

  public static void init() {
    rand = new Rand;
  }

  public static void resetBonusScore() {
    bonusScore = 10;
  }

  public static void setSpeedRate(float r) {
    rate = r;
    speed = BASE_SPEED * rate;
  }

  public override Actor newActor() {
    return new Bonus;
  }

  public override void init(ActorInitializer ini) {
    BonusInitializer bi = cast(BonusInitializer) ini;
    field = bi.field;
    ship = bi.ship;
    manager = bi.manager;
    pos = new Vector;
    vel = new Vector;
    fieldLimitX = field.size.x / 6 * 5;
    fieldLimitY = field.size.y / 10 * 9;
  }

  public void set(Vector p, Vector ofs) {
    pos.x = p.x;
    pos.y = p.y;
    if (ofs) {
      pos.x += ofs.x;
      pos.y += ofs.y;
    }
    vel.x = rand.nextSignedFloat(0.07);
    vel.y = rand.nextSignedFloat(0.07);
    cnt = 0;
    inhaleCnt = 0;
    isDown = true;
    isInhaled = false;
    isExist = true;
  }

  private void missBonus() {
    resetBonusScore();
  }

  private void getBonus() {
    SoundManager.playSe(SoundManager.GET_BONUS);
    manager.addScore(bonusScore);
    if (bonusScore < 1000)
      bonusScore += 10;
  }

  public override void move() {
    pos.x += vel.x;
    pos.y += vel.y;
    vel.x -= vel.x / 50;
    if (pos.x > fieldLimitX) {
      pos.x = fieldLimitX;
      if (vel.x > 0)
	vel.x = -vel.x;
    } else if (pos.x < -fieldLimitX) {
      pos.x = -fieldLimitX;
      if (vel.x < 0)
	vel.x = -vel.x;
    }
    if (isDown) {
      vel.y += (-speed - vel.y) / 50;
      if (pos.y < -fieldLimitY) {
	isDown = false;
	pos.y = -fieldLimitY;
	vel.y = speed;
      }
    } else {
      vel.y += (speed - vel.y) / 50;
      if (pos.y > fieldLimitY) {
	missBonus();
	isExist = false;
	return;
      }
    }
    cnt++;
    if (cnt < RETRO_CNT)
      return;
    float d = pos.dist(ship.pos);
    if (d < ACQUIRE_WIDTH * (1 + cast(float) inhaleCnt * 0.2) && ship.cnt >= -Ship.INVINCIBLE_CNT) {
      getBonus();
      isExist = false;
      return;
    }
    if (isInhaled) {
      inhaleCnt++;
      float ip = (INHALE_WIDTH - d) / 48;
      if (ip < 0.025)
	ip = 0.025;
      vel.x += (ship.pos.x - pos.x) * ip;
      vel.y += (ship.pos.y - pos.y) * ip;
      if (ship.cnt < -Ship.INVINCIBLE_CNT) {
	isInhaled = false;
	inhaleCnt = 0;
      }
    } else {
      if (d < INHALE_WIDTH && ship.cnt >= -Ship.INVINCIBLE_CNT)
	isInhaled = true;
    }
  }

  public override void draw() {
    float retro;
    if (cnt < RETRO_CNT)
      retro = 1 - cast(float) cnt / RETRO_CNT;
    else
      retro = 0;
    float d = cnt * 0.1;
    float ox = sin(d) * 0.3;
    float oy = cos(d) * 0.3;
    if (retro > 0) {
      P47Screen.setRetroParam(retro, 0.2);
      P47Screen.drawBoxRetro(pos.x - ox, pos.y - oy, BOX_SIZE / 2, BOX_SIZE / 2, 0);
      P47Screen.drawBoxRetro(pos.x + ox, pos.y + oy, BOX_SIZE / 2, BOX_SIZE / 2, 0);
      P47Screen.drawBoxRetro(pos.x - oy, pos.y + ox, BOX_SIZE / 2, BOX_SIZE / 2, 0);
      P47Screen.drawBoxRetro(pos.x + oy, pos.y - ox, BOX_SIZE / 2, BOX_SIZE / 2, 0);
    } else {
      if (isInhaled)
	Screen3D.setColor(0.8, 0.6, 0.4, 0.7);
      else if (isDown)
	Screen3D.setColor(0.4, 0.9, 0.6, 0.7);
      else
	Screen3D.setColor(0.8, 0.9, 0.5, 0.7);
      P47Screen.drawBoxLine(pos.x - ox - BOX_SIZE / 2, pos.y - oy - BOX_SIZE / 2,
			    BOX_SIZE, BOX_SIZE);
      P47Screen.drawBoxLine(pos.x + ox - BOX_SIZE / 2, pos.y + oy - BOX_SIZE / 2,
			    BOX_SIZE, BOX_SIZE);
      P47Screen.drawBoxLine(pos.x - oy - BOX_SIZE / 2, pos.y + ox - BOX_SIZE / 2,
			    BOX_SIZE, BOX_SIZE);
      P47Screen.drawBoxLine(pos.x + oy - BOX_SIZE / 2, pos.y - ox - BOX_SIZE / 2,
			    BOX_SIZE, BOX_SIZE);
    }
  }
}

public class BonusInitializer: ActorInitializer {
 public:
  Field field;
  Ship ship;
  P47GameManager manager;

  public this(Field field, Ship ship, P47GameManager manager) {
    this.field = field;
    this.ship = ship;
    this.manager = manager;
  }
}
