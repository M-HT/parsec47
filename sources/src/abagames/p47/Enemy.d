/*
 * $Id: Enemy.d,v 1.6 2004/01/01 11:26:41 kenta Exp $
 *
 * Copyright 2003 Kenta Cho. All rights reserved.
 */
module abagames.p47.Enemy;

private:
import std.math;
import opengl;
import bulletml;
import abagames.util.Vector;
import abagames.util.Rand;
import abagames.util.Actor;
import abagames.util.ActorInitializer;
import abagames.util.ActorPool;
import abagames.util.sdl.Screen3D;
import abagames.p47.Field;
import abagames.p47.Bonus;
import abagames.p47.Shot;
import abagames.p47.Roll;
import abagames.p47.Lock;
import abagames.p47.P47GameManager;
import abagames.p47.P47Screen;
import abagames.p47.BulletActor;
import abagames.p47.BulletActorPool;
import abagames.p47.EnemyType;
import abagames.p47.SoundManager;

/**
 * Enemies.
 */
public class Enemy: Actor {
  // Side wing with batteries.
  private struct Battery {
    BulletActor topBullet[BatteryType.WING_BATTERY_MAX];
    int shield;
    bool damaged;
  }

 public:
  static const float FIELD_SPACE = 0.5;
  Vector pos;
  EnemyType type;
  Battery battery[EnemyType.BATTERY_MAX];
  int shield;
 private:
  static const int MOVE_POINT_MAX = 8;
  static Rand rand;
  Field field;
  BulletActorPool bullets;
  ActorPool shots;
  ActorPool rolls;
  ActorPool locks;
  P47GameManager manager;
  int cnt;
  BulletActor topBullet;
  BulletActor moveBullet;
  Vector movePoint[MOVE_POINT_MAX];
  int movePointNum, movePointIdx;
  float speed, deg;
  bool onRoute;
  float baseDeg;
  int fireCnt, barragePatternIdx;
  float fieldLimitX, fieldLimitY;
  static const int APPEARANCE_CNT = 90;
  static const float APPEARANCE_Z = -15;
  static const int DESTROYED_CNT = 90;
  static const float DESTROYED_Z = -10;
  static const int TIMEOUT_CNT = 90;
  static const int BOSS_TIMEOUT = 30 * 60;
  int appCnt, dstCnt, timeoutCnt;
  float z;
  bool isBoss;
  Vector vel;
  int velCnt;
  bool damaged;
  int bossTimer;

  public static void initRand() {
    rand = new Rand;
  }

  public override Actor newActor() {
    return new Enemy;
  }

  public override void init(ActorInitializer ini) {
    EnemyInitializer ei = cast(EnemyInitializer) ini;
    field = ei.field;
    bullets = ei.bullets;
    shots = ei.shots;
    rolls = ei.rolls;
    locks = ei.locks;
    manager = ei.manager;
    pos = new Vector;
    for (int i = 0; i < movePoint.length; i++) {
      movePoint[i] = new Vector;
    }
    vel = new Vector;
    velCnt = 0;
    fieldLimitX = field.size.x / 4 * 3;
    fieldLimitY = field.size.y / 4 * 3;
  }

  public void set(Vector p, float d, EnemyType type, BulletMLParser *moveParser) {
    pos.x = p.x;
    pos.y = p.y;
    this.type = type;
    BulletMLRunner *moveRunner = BulletMLRunner_new_parser(moveParser);
    BulletActorPool.registFunctions(moveRunner);
    moveBullet = bullets.addBullet(moveRunner,
				   pos.x, pos.y, d, 0, 0.5,
				   1, 0, 0, 1, 1);
    if (!moveBullet)
      return;
    cnt = 0;
    shield = type.shield;
    for (int i = 0; i < type.batteryNum; i++) {
      battery[i].shield = type.batteryType[i].shield;
    }
    fireCnt = 0; barragePatternIdx = 0;
    baseDeg = d;
    appCnt = dstCnt = timeoutCnt = 0;
    z = 0;
    isBoss = false;
    isExist = true;
  }

  public void setBoss(Vector p, float d, EnemyType type) {
    pos.x = p.x;
    pos.y = p.y;
    this.type = type;
    moveBullet = null;

    // Set the moving patterns.
    float wx = rand.nextFloat(field.size.x / 4) + field.size.x / 4;
    float wy = rand.nextFloat(field.size.y / 9) + field.size.y / 7;
    float cy = field.size.y / 7 * 4;
    movePointNum = rand.nextInt(3) + 2;
    for (int i = 0; i < movePointNum / 2; i++) {
      movePoint[i * 2].x = rand.nextFloat(wx / 2) + wx / 2;
      movePoint[i * 2 + 1].x = -movePoint[i * 2].x;
      movePoint[i * 2].y = movePoint[i * 2 + 1].y = rand.nextSignedFloat(wy) + cy;
    }
    if (movePointNum == 3) {
      movePoint[2].x = 0;
      movePoint[2].y = rand.nextSignedFloat(wy) + cy;
    }
    for (int i = 0; i < 8; i++) {
      int idx1 = rand.nextInt(movePointNum);
      int idx2 = rand.nextInt(movePointNum);
      if (idx1 == idx2) {
	idx2++;
	if (idx2 >= movePointNum) idx2 = 0;
      }
      Vector mp = movePoint[idx1];
      movePoint[idx1] = movePoint[idx2];
      movePoint[idx2] = mp;
    }
    speed = 0.03 + rand.nextFloat(0.02);
    movePointIdx = 0;
    deg = std.math.PI;
    onRoute = false;

    cnt = 0;
    shield = type.shield;
    for (int i = 0; i < type.batteryNum; i++) {
      battery[i].shield = type.batteryType[i].shield;
    }
    for (int i = type.batteryNum; i < EnemyType.BATTERY_MAX; i++) {
      battery[i].shield = 0;
    }
    fireCnt = 0; barragePatternIdx = 0;
    baseDeg = d;
    appCnt = APPEARANCE_CNT;
    z = APPEARANCE_Z;
    dstCnt = timeoutCnt = 0;
    isBoss = true;
    bossTimer = 0;
    isExist = true;
  }

  private BulletActor setBullet(Barrage br, Vector ofs, float xr) {
    if (br.rank <= 0)
      return null;
    BulletMLRunner *runner = BulletMLRunner_new_parser(br.parser);
    BulletActorPool.registFunctions(runner);
    BulletActor ba;
    float bx = pos.x, by = pos.y;
    if (ofs) {
      bx += ofs.x;
      by += ofs.y;
    }
    if (br.morphCnt > 0)
      ba = bullets.addBullet
	(br.parser, runner,
	 bx, by, baseDeg, 0, br.rank,
	 br.speedRank,
	 br.shape, br.color, br.bulletSize,
	 br.xReverse * xr,
	 br.morphParser, br.morphNum, br.morphCnt);
    else
      ba = bullets.addBullet
	(br.parser, runner,
	 bx, by, baseDeg, 0, br.rank,
	 br.speedRank,
	 br.shape, br.color, br.bulletSize,
	 br.xReverse * xr);
    return ba;
  }

  private BulletActor setBullet(Barrage br, Vector ofs) {
    return setBullet(br, ofs, 1);
  }

  private void setTopBullets() {
    topBullet = setBullet(type.barrage[barragePatternIdx], null);
    for (int i = 0; i < type.batteryNum; i++) {
      Battery* b = &(battery[i]);
      if (b.shield <= 0)
	continue;
      BatteryType bt = type.batteryType[i];
      float xr = 1;
      for (int j = 0; j < bt.batteryNum; j++) {
	b.topBullet[j] = setBullet(bt.barrage[barragePatternIdx], bt.batteryPos[j], xr);
	if (bt.xReverseAlternate)
	  xr *= -1;
      }
    }
  }

  private void addBonuses(Vector p, int sl) {
    int bn = cast(int)(cast(float) sl * 3 / ((cast(float) cnt / 30) + 1) * Bonus.rate + 0.9);
    manager.addBonus(pos, p, bn);
  }

  private void addBonuses() {
    addBonuses(null, type.shield);
  }

  private void addWingFragments(BatteryType bt, int n, float z, float speed, float deg) {
    int ni = 1;
    for (int i = 0; i < BatteryType.WING_SHAPE_POINT_NUM; i++, ni++) {
      if (ni >= BatteryType.WING_SHAPE_POINT_NUM)
	ni = 0;
      manager.addFragments
	(n,
	 pos.x + bt.wingShapePos[i].x, pos.y + bt.wingShapePos[i].y,
	 pos.x + bt.wingShapePos[ni].x, pos.y + bt.wingShapePos[ni].y,
	 z, speed, deg);
    }
  }

  private void addFragments(int n, float z, float speed, float deg) {
    int ni = 1;
    for (int i = 0; i < EnemyType.BODY_SHAPE_POINT_NUM; i++, ni++) {
      if (ni >= EnemyType.BODY_SHAPE_POINT_NUM)
	ni = 0;
      manager.addFragments
	(n,
	 pos.x + type.bodyShapePos[i].x, pos.y + type.bodyShapePos[i].y,
	 pos.x + type.bodyShapePos[ni].x, pos.y + type.bodyShapePos[ni].y,
	 z, speed, deg);
    }
    for (int i = 0; i < type.batteryNum; i++) {
      if (battery[i].shield > 0)
	addWingFragments(type.batteryType[i], n, z, speed, deg);
    }
  }

  private static int SHOT_DAMAGE = 1;
  private static int ROLL_DAMAGE = 1;
  private static int LOCK_DAMAGE = 7;
  private static const int ENEMY_TYPE_SCORE[] = [100, 500, 1000, 5000, 10000];
  private static const int ENEMY_WING_SCORE = 1000;

  private void addDamage(int dmg) {
    shield -= dmg;
    if (shield <= 0) {
      // Destroyed.
      addBonuses();
      manager.addScore(ENEMY_TYPE_SCORE[type.type]);
      if (isBoss) {
	addFragments(15, 0, 0.1, rand.nextSignedFloat(1));
	SoundManager.playSe(SoundManager.BOSS_DESTROYED);
	manager.setScreenShake(20, 0.05);
	manager.clearBullets();
	removeTopBullets();
	dstCnt = DESTROYED_CNT;
      } else {
	float d;
	if (type.type == EnemyType.SMALL) {
	  d = moveBullet.bullet.deg;
	  SoundManager.playSe(SoundManager.ENEMY_DESTROYED);
	} else {
	  d = rand.nextSignedFloat(1);
	  SoundManager.playSe(SoundManager.LARGE_ENEMY_DESTROYED);
	}
	addFragments(type.type * 4 + 2, 0, 0.04, d);
	remove();
      }
    }
    damaged = true;
  }

  private void removeBattery(Battery *b, BatteryType bt) {
    for (int i = 0; i < bt.batteryNum; i++) {
      if (b.topBullet[i]) {
	b.topBullet[i].remove();
	b.topBullet[i] = null;
      }
    }
    b.damaged = true;
  }

  private void addDamageBattery(int idx, int dmg) {
    battery[idx].shield -= dmg;
    if (battery[idx].shield <= 0) {
      // Wing is destroyed.
      Vector p = type.batteryType[idx].collisionPos;
      addBonuses(p, type.batteryType[idx].shield);
      manager.addScore(ENEMY_WING_SCORE);
      addWingFragments(type.batteryType[idx], 10, 0, 0.1, rand.nextSignedFloat(1));
      SoundManager.playSe(SoundManager.LARGE_ENEMY_DESTROYED);
      manager.setScreenShake(10, 0.03);
      removeBattery(&battery[idx], type.batteryType[idx]);
      vel.x = -p.x / 10;
      vel.y = -p.y / 10;
      velCnt = 60;
      removeTopBullets();
      fireCnt = velCnt + 10;
    }
  }

  enum {
    NOHIT = -2, HIT = -1,
  }

  // Check shots and rolls hit the enemy.
  private int checkHit(Vector p, float xofs, float yofs) {
    if (fabs(p.x - pos.x) < type.collisionSize.x + xofs &&
	fabs(p.y - pos.y) < type.collisionSize.y + yofs)
      return HIT;
    if (type.wingCollision) {
      for (int i = 0; i < type.batteryNum; i++) {
	if (battery[i].shield <= 0)
	  continue;
	BatteryType bt = type.batteryType[i];
	if (fabs(p.x - pos.x - bt.collisionPos.x) < bt.collisionSize.x + xofs &&
	    fabs(p.y - pos.y - bt.collisionPos.y) < bt.collisionSize.y + yofs)
	  return i;
      }
    }
    return NOHIT;
  }

  // Check ship locks the enemy.
  private int checkLocked(Vector p, float xofs, Lock lock) {
    if (fabs(p.x - pos.x) < type.collisionSize.x + xofs && pos.y < lock.lockMinY && pos.y > p.y) {
      lock.lockMinY = pos.y;
      return HIT;
    }
    if (type.wingCollision) {
      int lp = NOHIT;
      for (int i = 0; i < type.batteryNum; i++) {
	if (battery[i].shield <= 0)
	  continue;
	BatteryType bt = type.batteryType[i];
	float by = pos.y + bt.collisionPos.y;
	if (fabs(p.x - pos.x - bt.collisionPos.x) < bt.collisionSize.x + xofs &&
	    by < lock.lockMinY && by > p.y) {
	  lock.lockMinY = by;
	  lp = i;
	}
      }
      if (lp != NOHIT)
	return lp;
    }
    return NOHIT;
  }

  private void checkDamage() {
    int ch;
    // Chech shots.
    for (int i = 0; i < shots.actor.length; i++) {
      if (!shots.actor[i].isExist)
	continue;
      Vector sp = (cast(Shot) shots.actor[i]).pos;
      ch = checkHit(sp, 0.7, 0);
      if (ch >= HIT) {
	manager.addParticle(sp, rand.nextSignedFloat(0.3), 0, Shot.SPEED / 4);
	manager.addParticle(sp, rand.nextSignedFloat(0.3), 0, Shot.SPEED / 4);
	manager.addParticle(sp, std.math.PI + rand.nextSignedFloat(0.3), 0, Shot.SPEED / 7);
	shots.actor[i].isExist = false;
	if (ch == HIT)
	  addDamage(SHOT_DAMAGE);
	else
	  addDamageBattery(ch, SHOT_DAMAGE);
      }
    }
    if (manager.mode == P47GameManager.ROLL) {
      // Chech rolls.
      for (int i = 0; i < rolls.actor.length; i++) {
	if (!rolls.actor[i].isExist)
	  continue;
	Roll rl = cast(Roll) rolls.actor[i];
	ch = checkHit(rl.pos[0], 1.0, 1.0);
	if (ch >= HIT) {
	  for (int j = 0; j < 4; j++)
	    manager.addParticle(rl.pos[0], rand.nextFloat(std.math.PI * 2), 0, Shot.SPEED / 10);
	  float rd = ROLL_DAMAGE;
	  if (rl.released) {
	    rd += rd;
	  } else {
	    if (rl.cnt < Roll.NO_COLLISION_CNT)
	      continue;
	  }
	  if (ch == HIT)
	    addDamage(cast(int)rd);
	  else
	    addDamageBattery(ch, cast(int)rd);
	}
      }
    } else if (type.type != EnemyType.SMALL) {
      // Chech locks.
      for (int i = 0; i < locks.actor.length; i++) {
	if (!locks.actor[i].isExist)
	  continue;
	Lock lk = cast(Lock) locks.actor[i];
	if (lk.state == Lock.SEARCH || lk.state == Lock.SEARCHED) {
	  ch = checkLocked(lk.pos[0], 2.5, lk);
	  if (ch >= HIT) {
	    lk.state = Lock.SEARCHED;
	    lk.lockedEnemy = this;
	    lk.lockedPart = ch;
	  }
	  return;
	} else if (lk.state == Lock.FIRED && lk.lockedEnemy == this) {
	  ch = checkHit(lk.pos[0], 1.5, 1.5);
	  if (ch >= HIT && ch == lk.lockedPart) {
	    for (int j = 0; j < 4; j++)
	      manager.addParticle(lk.pos[0], rand.nextFloat(std.math.PI * 2), 0, Shot.SPEED / 10);
	    if (ch == HIT)
	      addDamage(LOCK_DAMAGE);
	    else
	      addDamageBattery(ch, LOCK_DAMAGE);
	    lk.hit();
	  }
	}
      }
    }
  }

  private void removeTopBullets() {
    if (topBullet) {
      topBullet.remove();
      topBullet = null;
    }
    for (int i = 0; i < type.batteryNum; i++) {
      BatteryType bt = type.batteryType[i];
      Battery* b = &(battery[i]);
      for (int j = 0; j < bt.batteryNum; j++) {
	if (b.topBullet[j]) {
	  b.topBullet[j].remove();
	  b.topBullet[j] = null;
	}
      }
    }
  }

  private void remove() {
    removeTopBullets();
    if (moveBullet)
      moveBullet.remove();
    isExist = false;
  }

  private static float BOSS_MOVE_DEG = 0.02;

  private void gotoNextPoint() {
    onRoute = false;
    movePointIdx++;
    if (movePointIdx >= movePointNum)
      movePointIdx = 0;
  }

  private void moveBoss() {
    Vector aim = movePoint[movePointIdx];
    float d = std.math.atan2(aim.x - pos.x, aim.y - pos.y);
    float od = d - deg;
    if (od > std.math.PI)
      od -= std.math.PI * 2;
    else if (od < -std.math.PI)
      od += std.math.PI * 2;
    float aod = std.math.fabs(od);
    if (aod < BOSS_MOVE_DEG) {
      deg = d;
    } else if (od > 0) {
      deg += BOSS_MOVE_DEG;
      if (deg >= std.math.PI * 2)
	deg -= std.math.PI * 2;
    } else {
      deg -= BOSS_MOVE_DEG;
      if (deg < 0)
	deg += std.math.PI * 2;
    }
    pos.x += std.math.sin(deg) * speed;
    pos.y += std.math.cos(deg) * speed;
    if (velCnt > 0) {
      velCnt--;
      pos.x += vel.x;
      pos.y += vel.y;
      vel.x *= 0.92;
      vel.y *= 0.92;
    }
    if (!onRoute) {
      if (aod < std.math.PI / 2) {
	onRoute = true;
      }
    } else {
      if (aod > std.math.PI / 2) {
	gotoNextPoint();
      }
    }
    if (pos.x > fieldLimitX) {
      pos.x = fieldLimitX;
      gotoNextPoint();
    } else if (pos.x < -fieldLimitX) {
      pos.x = -fieldLimitX;
      gotoNextPoint();
    }
    if (pos.y > fieldLimitY) {
      pos.y = fieldLimitY;
      gotoNextPoint();
    } else if (pos.y < fieldLimitY / 4) {
      pos.y = fieldLimitY / 4;
      gotoNextPoint();
    }
  }

  private void controlFireCnt() {
    if (fireCnt <= 0) {
      setTopBullets();
      fireCnt = type.fireInterval;
      barragePatternIdx++;
      if (barragePatternIdx >= type.barragePatternNum)
	barragePatternIdx = 0;
    } else if (fireCnt < type.fireInterval - type.firePeriod) {
      removeTopBullets();
    }
    fireCnt--;
  }

  public override void move() {
    EnemyType.isExist[type.id] = true;
    if (!isBoss) {
      pos.x = moveBullet.bullet.pos.x;
      pos.y = moveBullet.bullet.pos.y;
    } else {
      moveBoss();
    }
    if (topBullet) {
      topBullet.bullet.pos.x = pos.x;
      topBullet.bullet.pos.y = pos.y;
    }
    damaged = false;
    for (int i = 0; i < type.batteryNum; i++) {
      BatteryType bt = type.batteryType[i];
      Battery* b = &(battery[i]);
      b.damaged = false;
      for (int j = 0; j < bt.batteryNum; j++) {
	if (b.topBullet[j]) {
	  b.topBullet[j].bullet.pos.x = pos.x + bt.batteryPos[j].x;
	  b.topBullet[j].bullet.pos.y = pos.y + bt.batteryPos[j].y;
	}
      }
    }
    if (!isBoss) {
      if (field.checkHit(pos)) {
	remove();
	return;
      }
      if (pos.y < -field.size.y / 4) {
	removeTopBullets();
      } else {
	controlFireCnt();
      }
    } else {
      float mtr;
      if (appCnt > 0) {
	if (z < 0)
	  z -= APPEARANCE_Z / 60;
	appCnt--;
	mtr = 1.0 - cast(float)appCnt / APPEARANCE_CNT;
      } else if (dstCnt > 0) {
	addFragments(1, z, 0.05, rand.nextSignedFloat(std.math.PI));
	manager.clearBullets();
	z += DESTROYED_Z / 60;
	dstCnt--;
	if (dstCnt <= 0) {
	  addFragments(25, z, 0.4, rand.nextSignedFloat(std.math.PI));
	  SoundManager.playSe(SoundManager.BOSS_DESTROYED);
	  manager.setScreenShake(60, 0.01);
	  remove();
	  manager.setBossShieldMeter(0, 0, 0, 0, 0, 0);
	  return;
	}
	mtr = cast(float)dstCnt / DESTROYED_CNT;
      } else if (timeoutCnt > 0) {
	z += DESTROYED_Z / 60;
	timeoutCnt--;
	if (timeoutCnt <= 0) {
	  remove();
	  return;
	}
	mtr = 0;
      } else {
	controlFireCnt();
	mtr = 1;
	bossTimer++;
	if (bossTimer > BOSS_TIMEOUT) {
	  timeoutCnt = TIMEOUT_CNT;
	  shield = 0;
	  removeTopBullets();
	}
      }
      manager.setBossShieldMeter
	(shield, battery[0].shield, battery[1].shield, battery[2].shield, battery[3].shield, mtr);
    }
    cnt++;
    if (appCnt <= 0 && dstCnt <= 0 && timeoutCnt <= 0)
      checkDamage();
  }

  public override void draw() {
    float ap;
    if (appCnt > 0) {
      // Appearance effect of the boss.
      P47Screen.setRetroZ(z);
      ap = cast(float) appCnt / APPEARANCE_CNT;
      P47Screen.setRetroParam(1, type.retroSize * (1 + ap * 10));
      P47Screen.setRetroColor(type.r, type.g, type.b, (1 - ap));
    } else if (dstCnt > 0) {
      P47Screen.setRetroZ(z);
      ap = cast(float) dstCnt / DESTROYED_CNT / 2 + 0.5;
      P47Screen.setRetroColor(type.r, type.g, type.b, ap);
    } else if (timeoutCnt > 0) {
      P47Screen.setRetroZ(z);
      ap = cast(float) timeoutCnt / TIMEOUT_CNT;
      P47Screen.setRetroColor(type.r, type.g, type.b, ap);
    } else {
      P47Screen.setRetroParam(1, type.retroSize);
      if (!damaged)
	P47Screen.setRetroColor(type.r, type.g, type.b, 1);
      else
	P47Screen.setRetroColor(1, 1, type.b, 1);
    }
    int ni = 1;
    for (int i = 0; i < EnemyType.BODY_SHAPE_POINT_NUM; i++, ni++) {
      if (ni >= EnemyType.BODY_SHAPE_POINT_NUM)
	ni = 0;
      P47Screen.drawLineRetro(pos.x + type.bodyShapePos[i].x, pos.y + type.bodyShapePos[i].y,
			      pos.x + type.bodyShapePos[ni].x, pos.y + type.bodyShapePos[ni].y);
    }
    if (type.type != EnemyType.SMALL) {
      glBegin(GL_TRIANGLE_FAN);
      Screen3D.setColor(P47Screen.retroR, P47Screen.retroG, P47Screen.retroB, 0);
      for (int i = 0; i < EnemyType.BODY_SHAPE_POINT_NUM; i++) {
	if (i == 2)
	  Screen3D.setColor
	    (P47Screen.retroR, P47Screen.retroG, P47Screen.retroB, P47Screen.retroA);
	glVertex3f(pos.x + type.bodyShapePos[i].x, pos.y + type.bodyShapePos[i].y, z);
      }
      glEnd();
    }
    for (int i = 0; i < type.batteryNum; i++) {
      BatteryType* bt = &(type.batteryType[i]);
      if (appCnt > 0) {
	P47Screen.setRetroColor(bt.r, bt.g, bt.b, (1 - ap));
      } else if (dstCnt > 0 || timeoutCnt > 0) {
	P47Screen.setRetroColor(bt.r, bt.g, bt.b, ap);
      } else {
	if (!battery[i].damaged)
	  P47Screen.setRetroColor(bt.r, bt.g, bt.b, 1);
	else
	  P47Screen.setRetroColor(1, 1, bt.b, 1);
      }
      ni = 1;
      if (battery[i].shield <= 0) {
	P47Screen.drawLineRetro(pos.x + bt.wingShapePos[0].x, pos.y + bt.wingShapePos[0].y,
				pos.x + bt.wingShapePos[1].x, pos.y + bt.wingShapePos[1].y);
      } else {
	for (int j = 0; j < BatteryType.WING_SHAPE_POINT_NUM; j++, ni++) {
	  if (ni >= BatteryType.WING_SHAPE_POINT_NUM)
	    ni = 0;
	  P47Screen.drawLineRetro(pos.x + bt.wingShapePos[j].x, pos.y + bt.wingShapePos[j].y,
				  pos.x + bt.wingShapePos[ni].x, pos.y + bt.wingShapePos[ni].y);
	}
	if (type.type != EnemyType.SMALL) {
	  glBegin(GL_TRIANGLE_FAN);
	  Screen3D.setColor
	    (P47Screen.retroR, P47Screen.retroG, P47Screen.retroB, P47Screen.retroA);
	  for (int j = 0; j < BatteryType.WING_SHAPE_POINT_NUM; j++) {
	    if (j == 2)
	      Screen3D.setColor
		(P47Screen.retroR, P47Screen.retroG, P47Screen.retroB, 0);
	    glVertex3f(pos.x + bt.wingShapePos[j].x, pos.y + bt.wingShapePos[j].y, z);
	  }
	  glEnd();
	}
      }
    }
    P47Screen.setRetroZ(0);
  }
}

public class EnemyInitializer: ActorInitializer {
 public:
  Field field;
  BulletActorPool bullets;
  ActorPool shots;
  ActorPool rolls;
  ActorPool locks;
  P47GameManager manager;

  public this(Field field, BulletActorPool bullets, ActorPool shots,
	      ActorPool rolls, ActorPool locks, P47GameManager manager) {
    this.field = field;
    this.bullets = bullets;
    this.shots = shots;
    this.rolls = rolls;
    this.locks = locks;
    this.manager = manager;
  }
}
