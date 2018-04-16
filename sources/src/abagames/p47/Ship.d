/*
 * $Id: Ship.d,v 1.4 2004/01/01 11:26:42 kenta Exp $
 *
 * Copyright 2003 Kenta Cho. All rights reserved.
 */
module abagames.p47.Ship;

private:
import std.math;
import opengl;
import abagames.util.Vector;
import abagames.util.Rand;
import abagames.util.sdl.Pad;
import abagames.util.sdl.Screen3D;
import abagames.util.bulletml.Bullet;
import abagames.p47.Field;
import abagames.p47.Bonus;
import abagames.p47.P47GameManager;
import abagames.p47.P47Screen;
import abagames.p47.SoundManager;

/**
 * My ship.
 */
public class Ship {
 public:
  static bool isSlow = false;
  static int displayListIdx;
  Vector pos;
  static const float SIZE = 0.3;
  bool restart;
  static const int RESTART_CNT = 300;
  static const int INVINCIBLE_CNT = 228;
  int cnt;
 private:
  static Rand rand;
  Pad pad;
  Field field;
  P47GameManager manager;
  Vector ppos;
  static const float BASE_SPEED = 0.6;
  static const float SLOW_BASE_SPEED = 0.3;
  float baseSpeed, slowSpeed;

  float speed;
  Vector vel;
  static const float BANK_BASE = 50;
  float bank;
  Vector firePos;
  float fireWideDeg;
  static const float FIRE_WIDE_BASE_DEG = 0.7;
  static const float FIRE_NARROW_BASE_DEG = 0.5;
  int fireCnt;
  static const float TURRET_INTERVAL_LENGTH = 0.2;
  int ttlCnt;
  static const float FIELD_SPACE = 1.5;
  float fieldLimitX, fieldLimitY;
  int rollLockCnt;
  bool rollCharged;

  public static void initRand() {
    rand = new Rand;
  }

  public void init(Pad pad, Field field, P47GameManager manager) {
    this.pad = pad;
    this.field = field;
    this.manager = manager;
    pos = new Vector;
    ppos = new Vector;
    vel = new Vector;
    firePos = new Vector;
    ttlCnt = 0;
    fieldLimitX = field.size.x - FIELD_SPACE;
    fieldLimitY = field.size.y - FIELD_SPACE;
  }

  public void start() {
    ppos.x = pos.x = 0;
    ppos.y = pos.y = -field.size.y / 2;
    vel.x = vel.y = 0;
    speed = BASE_SPEED;
    fireWideDeg = FIRE_WIDE_BASE_DEG;
    restart = true;
    cnt = -INVINCIBLE_CNT;
    fireCnt = 0;
    rollLockCnt = 0;
    bank = 0;
    rollCharged = false;
    Bonus.resetBonusScore();
  }

  public void setSpeedRate(float rate) {
    if (!isSlow)
      baseSpeed = BASE_SPEED * rate;
    else
      baseSpeed = BASE_SPEED * 0.7;
    slowSpeed = SLOW_BASE_SPEED * rate;
  }

  public void destroyed() {
    if (cnt <= 0)
      return;
    SoundManager.playSe(SoundManager.SHIP_DESTROYED);
    manager.shipDestroyed();
    manager.addFragments(30, pos.x, pos.y, pos.x, pos.y, 0, 0.08, std.math.PI);
    for (int i = 0; i < 45; i++)
      manager.addParticle(pos, rand.nextFloat(std.math.PI * 2), 0, 0.6);
    start();
    cnt = -RESTART_CNT;
  }

  public void move() {
    cnt++;
    if (cnt < -INVINCIBLE_CNT) {
      return;
    }
    if (cnt == 0)
      restart = false;
    int btn = pad.getButtonState();
    if (btn & Pad.PAD_BUTTON2) {
      speed += (slowSpeed - speed) * 0.2;
      fireWideDeg += (FIRE_NARROW_BASE_DEG - fireWideDeg) * 0.1;
      rollLockCnt++;
      if (manager.mode == P47GameManager.ROLL) {
	if (rollLockCnt % 15 == 0) {
	  manager.addRoll();
	  SoundManager.playSe(SoundManager.ROLL_CHARGE);
	  rollCharged = true;
	}
      } else {
	if (rollLockCnt % 10 == 0) {
	  manager.addLock();
	}
      }
    } else {
      speed += (baseSpeed - speed) * 0.2;
      fireWideDeg += (FIRE_WIDE_BASE_DEG - fireWideDeg) * 0.1;
      if (manager.mode == P47GameManager.ROLL) {
	if (rollCharged) {
	  rollLockCnt = 0;
	  manager.releaseRoll();
	  SoundManager.playSe(SoundManager.ROLL_RELEASE);
	  rollCharged = false;
	}
      } else {
	rollLockCnt = 0;
	manager.releaseLock();
      }
    }
    int ps = pad.getPadState();
    vel.x = vel.y = 0;
    if (ps & Pad.PAD_UP)
      vel.y = speed;
    else if (ps & Pad.PAD_DOWN)
      vel.y = -speed;
    if (ps & Pad.PAD_RIGHT)
      vel.x = speed;
    else if (ps & Pad.PAD_LEFT)
      vel.x = -speed;
    if (vel.x != 0 && vel.y != 0) {
      vel.x *= 0.707;
      vel.y *= 0.707;
    }
    ppos.x = pos.x;
    ppos.y = pos.y;
    pos.x += vel.x;
    pos.y += vel.y;
    bank += (vel.x * BANK_BASE - bank) * 0.1;
    if (pos.x < -fieldLimitX)
      pos.x = -fieldLimitX;
    else if (pos.x > fieldLimitX)
      pos.x = fieldLimitX;
    if (pos.y < -fieldLimitY)
      pos.y = -fieldLimitY;
    else if (pos.y > fieldLimitY)
      pos.y = fieldLimitY;
    if (btn & Pad.PAD_BUTTON1) {
      float td;
      switch (fireCnt % 4) {
      case 0:
	firePos.x = pos.x + TURRET_INTERVAL_LENGTH;
	firePos.y = pos.y;
	td = 0;
	break;
      case 1:
	firePos.x = pos.x + TURRET_INTERVAL_LENGTH;
	firePos.y = pos.y;
	td = fireWideDeg * (fireCnt / 4 % 5) * 0.2;
	break;
      case 2:
	firePos.x = pos.x - TURRET_INTERVAL_LENGTH;
	firePos.y = pos.y;
	td = 0;
	break;
      case 3:
	firePos.x = pos.x - TURRET_INTERVAL_LENGTH;
	firePos.y = pos.y;
	td = - fireWideDeg * (fireCnt / 4 % 5) * 0.2;
	break;
      default:
	break;
      }
      manager.addShot(firePos, td);
      SoundManager.playSe(SoundManager.SHOT);
      fireCnt++;
    }
    Bullet.target.x = pos.x;
    Bullet.target.y = pos.y;
    ttlCnt++;
  }

  public void draw() {
    if (cnt < -INVINCIBLE_CNT || (cnt < 0 && (-cnt % 32) < 16))
      return;
    glPushMatrix();
    glTranslatef(pos.x, pos.y, 0);
    glCallList(displayListIdx + 1);
    glRotatef(bank, 0, 1, 0);
    glTranslatef(-0.5, 0, 0);
    glCallList(displayListIdx);
    glTranslatef(0.2, 0.3, 0.2);
    glCallList(displayListIdx);
    glTranslatef(0, 0, -0.4);
    glCallList(displayListIdx);
    glPopMatrix();
    glPushMatrix();
    glTranslatef(pos.x, pos.y, 0);
    glRotatef(bank, 0, 1, 0);
    glTranslatef(0.5, 0, 0);
    glCallList(displayListIdx);
    glTranslatef(-0.2, 0.3, 0.2);
    glCallList(displayListIdx);
    glTranslatef(0, 0, -0.4);
    glCallList(displayListIdx);
    glPopMatrix();
    for (int i = 0; i < 6; i++) {
      glPushMatrix();
      glTranslatef(pos.x - 0.7, pos.y - 0.3, 0);
      glRotatef(bank, 0, 1, 0);
      glRotatef(180.0f / 2 - fireWideDeg * 100, 0, 0, 1);
      glRotatef(i * 180.0f / 3 - ttlCnt * 4, 1, 0, 0);
      glTranslatef(0, 0, 0.7);
      glCallList(displayListIdx + 2);
      glPopMatrix();
      glPushMatrix();
      glTranslatef(pos.x + 0.7, pos.y - 0.3, 0);
      glRotatef(bank, 0, 1, 0);
      glRotatef(-180.0f / 2 + fireWideDeg * 100, 0, 0, 1);
      glRotatef(i * 180.0f / 3 - ttlCnt * 4, 1, 0, 0);
      glTranslatef(0, 0, 0.7);
      glCallList(displayListIdx + 2);
      glPopMatrix();
    }
  }

  public static void createDisplayLists() {
    displayListIdx = glGenLists(3);
    glNewList(displayListIdx, GL_COMPILE);
    Screen3D.setColor(0.5, 1, 0.5, 0.2);
    P47Screen.drawBoxSolid(-0.1, -0.5, 0.2, 1);
    Screen3D.setColor(0.5, 1, 0.5, 0.4);
    P47Screen.drawBoxLine(-0.1, -0.5, 0.2, 1);
    glEndList();
    glNewList(displayListIdx + 1, GL_COMPILE);
    Screen3D.setColor(1, 0.2, 0.2, 1);
    P47Screen.drawBoxSolid(-0.2, -0.2, 0.4, 0.4);
    Screen3D.setColor(1, 0.5, 0.5, 1);
    P47Screen.drawBoxLine(-0.2, -0.2, 0.4, 0.4);
    glEndList();
    glNewList(displayListIdx + 2, GL_COMPILE);
    Screen3D.setColor(0.7, 1, 0.5, 0.3);
    P47Screen.drawBoxSolid(-0.15, -0.3, 0.3, 0.6);
    Screen3D.setColor(0.7, 1, 0.5, 0.6);
    P47Screen.drawBoxLine(-0.15, -0.3, 0.3, 0.6);
    glEndList();
  }

  public static void deleteDisplayLists() {
    glDeleteLists(displayListIdx, 3);
  }
}
