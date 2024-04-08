/*
 * $Id: StageManager.d,v 1.4 2004/01/01 11:26:42 kenta Exp $
 *
 * Copyright 2003 Kenta Cho. All rights reserved.
 */
module abagames.p47.StageManager;

private:
import std.math;
import bulletml;
import abagames.util.Rand;
import abagames.util.Vector;
import abagames.util.sdl.Sound;
import abagames.p47.BarrageManager;
import abagames.p47.P47GameManager;
import abagames.p47.Field;
import abagames.p47.Enemy;
import abagames.p47.EnemyType;
import abagames.p47.SoundManager;

/**
 * Manage the stage data(enemies' appearance).
 */
public class StageManager {
  // Appearance point.
  static enum {
    TOP, SIDE, BACK
  }
  // Appearance pattern.
  static enum {
    ONE_SIDE, ALTERNATE, BOTH_SIDES
  }
  // Appearance position is fixed or not.
  static enum {
    RANDOM, FIXED
  }
  // Enemy type.
  static enum {
    SMALL, MIDDLE, LARGE,
  }

  private struct EnemyAppearance {
   public:
    EnemyType type;
    BulletMLParser* moveParser;
    int point, pattern, sequence;
    float pos;
    int num, interval, groupInterval;
    int cnt, left, side;
  }

 public:
  static const int STAGE_TYPE_NUM = 4;
  int parsec;
  bool bossSection;
 private:
  Rand rand;
  P47GameManager gameManager;
  BarrageManager barrageManager;
  Field field;
  const int SIMULTANEOUS_APPEARNCE_MAX = 4;
  EnemyAppearance[SIMULTANEOUS_APPEARNCE_MAX] appearance;
  const int SMALL_ENEMY_TYPE_MAX = 3;
  EnemyType[SMALL_ENEMY_TYPE_MAX] smallType;
  const int MIDDLE_ENEMY_TYPE_MAX = 4;
  EnemyType[MIDDLE_ENEMY_TYPE_MAX] middleType;
  const int LARGE_ENEMY_TYPE_MAX = 2;
  EnemyType[LARGE_ENEMY_TYPE_MAX] largeType;
  EnemyType middleBossType;
  EnemyType largeBossType;
  int apNum;
  Vector apos;
  int sectionCnt, sectionIntervalCnt, section;
  float rank, rankInc;
  int middleRushSectionNum;
  bool middleRushSection;
  int stageType;

  public void init(P47GameManager gm, BarrageManager bm, Field f) {
    gameManager = gm;
    barrageManager = bm;
    field = f;
    rand = new Rand;
    apos = new Vector;
    for (int i = 0; i < smallType.length; i++)
      smallType[i] = new EnemyType;
    for (int i = 0; i < middleType.length; i++)
      middleType[i] = new EnemyType;
    for (int i = 0; i < largeType.length; i++)
      largeType[i] = new EnemyType;
    middleBossType = new EnemyType;
    largeBossType = new EnemyType;
  }

  private void createEnemyData() {
    for (int i = 0; i < smallType.length; i++)
      smallType[i].setSmallEnemyType(rank, gameManager.mode);
    for (int i = 0; i < middleType.length; i++)
      middleType[i].setMiddleEnemyType(rank, gameManager.mode);
    for (int i = 0; i < largeType.length; i++)
      largeType[i].setLargeEnemyType(rank, gameManager.mode);
    middleBossType.setMiddleBossEnemyType(rank, gameManager.mode);
    largeBossType.setLargeBossEnemyType(rank, gameManager.mode);
  }

  private void setAppearancePattern(EnemyAppearance* ap) {
    switch (rand.nextInt(5)) {
    case 0:
      ap.pattern = ONE_SIDE;
      break;
    case 1:
    case 2:
      ap.pattern = ALTERNATE;
      break;
    case 3:
    case 4:
      ap.pattern = BOTH_SIDES;
      break;
    default:
      break;
    }
    switch (rand.nextInt(3)) {
    case 0:
      ap.sequence = RANDOM;
      break;
    case 1:
    case 2:
      ap.sequence = FIXED;
      break;
    default:
      break;
    }
  }

  private void setSmallAppearance(EnemyAppearance* ap) {
    ap.type = smallType[rand.nextInt(smallType.length)];
    int mt;
    if (rand.nextFloat(1) > 0.2) {
      ap.point = TOP;
      mt = BarrageManager.SMALLMOVE;
    } else {
      ap.point = SIDE;
      mt = BarrageManager.SMALLSIDEMOVE;
    }
    ap.moveParser = barrageManager.parser[mt][rand.nextInt(barrageManager.parserNum[mt])];
    setAppearancePattern(ap);
    if (ap.pattern == ONE_SIDE)
      ap.pattern = ALTERNATE;
    switch (rand.nextInt(4)) {
    case 0:
      ap.num = 7 + rand.nextInt(5);
      ap.groupInterval = 72 + rand.nextInt(15);
      ap.interval = 15 + rand.nextInt(5);
      break;
    case 1:
      ap.num = 5 + rand.nextInt(3);
      ap.groupInterval = 56 + rand.nextInt(10);
      ap.interval = 20 + rand.nextInt(5);
      break;
    case 2:
    case 3:
      ap.num = 2 + rand.nextInt(2);
      ap.groupInterval = 45 + rand.nextInt(20);
      ap.interval = 25 + rand.nextInt(5);
      break;
    default:
      break;
    }
  }

  private void setMiddleAppearance(EnemyAppearance* ap) {
    ap.type = middleType[rand.nextInt(middleType.length)];
    int mt;
    // Appearance from the backward is disabled.
    /*if (rand.nextFloat(1) > 0.1) {
      ap.point = TOP;
      mt = BarrageManager.MIDDLEMOVE;
    } else {
      ap.point = BACK;
      mt = BarrageManager.MIDDLEBACKMOVE;
      }*/
    ap.point = TOP;
    mt = BarrageManager.MIDDLEMOVE;
    ap.moveParser = barrageManager.parser[mt][rand.nextInt(barrageManager.parserNum[mt])];
    setAppearancePattern(ap);
    switch (rand.nextInt(3)) {
    case 0:
      ap.num = 4;
      ap.groupInterval = 240 + rand.nextInt(150);
      ap.interval = 80 + rand.nextInt(30);
      break;
    case 1:
      ap.num = 2;
      ap.groupInterval = 180 + rand.nextInt(60);
      ap.interval = 180 + rand.nextInt(20);
      break;
    case 2:
      ap.num = 1;
      ap.groupInterval = 150 + rand.nextInt(50);
      ap.interval = 100;
      break;
    default:
      break;
    }
  }

  private void setLargeAppearance(EnemyAppearance* ap) {
    ap.type = largeType[rand.nextInt(largeType.length)];
    int mt;
    ap.point = TOP;
    mt = BarrageManager.LARGEMOVE;
    ap.moveParser = barrageManager.parser[mt][rand.nextInt(barrageManager.parserNum[mt])];
    setAppearancePattern(ap);
    switch (rand.nextInt(3)) {
    case 0:
      ap.num = 3;
      ap.groupInterval = 400 + rand.nextInt(100);
      ap.interval = 240 + rand.nextInt(40);
      break;
    case 1:
      ap.num = 2;
      ap.groupInterval = 400 + rand.nextInt(60);
      ap.interval = 300 + rand.nextInt(20);
      break;
    case 2:
      ap.num = 1;
      ap.groupInterval = 270 + rand.nextInt(50);
      ap.interval = 200;
      break;
    default:
      break;
    }
  }

  private void setAppearance(EnemyAppearance* ap, int type) {
    switch (type) {
    case SMALL:
      setSmallAppearance(ap);
      break;
    case MIDDLE:
      setMiddleAppearance(ap);
      break;
    case LARGE:
      setLargeAppearance(ap);
      break;
    default:
      break;
    }
    ap.cnt = 0;
    ap.left = ap.num;
    ap.side = rand.nextInt(2) * 2 - 1;
    ap.pos = rand.nextFloat(1);
  }

  // [#smalltype, #middletype, #largetype]
  private const int MIDDLE_RUSH_SECTION_PATTERN = 6;
  private const int[3][][] apparancePattern =
    [
     [[1, 0, 0], [2, 0, 0], [1, 1, 0], [1, 0, 1], [2, 1, 0], [2, 0, 1], [0, 1, 1]],
     [[1, 0, 0], [1, 1, 0], [1, 1, 0], [1, 0, 1], [2, 1, 0], [1, 1, 1], [0, 1, 1]],
     ];

  private void createSectionData() {
    apNum = 0;
    if (rank <= 0)
      return;
    field.aimSpeed = 0.1 + section * 0.02;
    if (section == 4) {
      // Set the middle boss.
      scope Vector pos = new Vector;
      pos.x = 0; pos.y = field.size.y / 4 * 3;
      gameManager.addBoss(pos, std.math.PI, middleBossType);
      bossSection = true;
      sectionIntervalCnt = sectionCnt = 2 * 60;
      field.aimZ = 11;
      return;
    } else if (section == 9) {
      // Set the large boss.
      scope Vector pos = new Vector;
      pos.x = 0; pos.y = field.size.y / 4 * 3;
      gameManager.addBoss(pos, std.math.PI, largeBossType);
      bossSection = true;
      sectionIntervalCnt = sectionCnt = 3 * 60;
      field.aimZ = 12;
      return;
    } else if (section == middleRushSectionNum) {
      // In this section, no small enemy.
      middleRushSection = true;
      field.aimZ = 9;
    } else {
      middleRushSection = false;
      field.aimZ = 10 + rand.nextSignedFloat(0.3);
    }
    bossSection = false;
    if (section == 3)
      sectionIntervalCnt = 2 * 60;
    else if (section == 3)
      sectionIntervalCnt = 4 * 60;
    else
      sectionIntervalCnt = 1 * 60;
    sectionCnt = sectionIntervalCnt + 10 * 60;
    int sp = section * 3 / 7 + 1;
    int ep = 3 + section * 3 / 10;
    int ap = sp + rand.nextInt(ep - sp + 1);
    if (section == 0)
      ap = 0;
    else if (middleRushSection)
      ap = MIDDLE_RUSH_SECTION_PATTERN;
    for (int i = 0; i < apparancePattern[gameManager.mode][ap][0]; i++, apNum++) {
      EnemyAppearance* ap1 = &(appearance[apNum]);
      setAppearance(ap1, SMALL);
    }
    for (int i = 0; i < apparancePattern[gameManager.mode][ap][1]; i++, apNum++) {
      EnemyAppearance* ap1 = &(appearance[apNum]);
      setAppearance(ap1, MIDDLE);
    }
    for (int i = 0; i < apparancePattern[gameManager.mode][ap][2]; i++, apNum++) {
      EnemyAppearance* ap1 = &(appearance[apNum]);
      setAppearance(ap1, LARGE);
    }
  }

  private void createStage() {
    createEnemyData();
    middleRushSectionNum = 2 + rand.nextInt(6);
    if (middleRushSectionNum <= 4)
      middleRushSectionNum++;
    field.setType(stageType % Field.TYPE_NUM);
    SoundManager.playBgm(stageType % SoundManager.BGM_NUM);
    stageType++;
  }

  private void gotoNextSection() {
    section++;
    parsec++;
    if (gameManager.state == P47GameManager.TITLE && section >= 4) {
      section = 0;
      parsec -= 4;
    }
    if (section >= 10) {
      section = 0;
      rank += rankInc;
      createStage();
    }
    createSectionData();
  }

  public void setRank(float baseRank, float inc, int startParsec, int type) {
    rank = baseRank;
    rankInc = inc;
    rank += rankInc * (startParsec / 10);
    section = -1;
    parsec = startParsec - 1;
    stageType = type;
    createStage();
    gotoNextSection();
  }

  public void move() {
    for (int i = 0; i < apNum; i++) {
      EnemyAppearance* ap = &(appearance[i]);
      ap.cnt--;
      if (ap.cnt > 0) {
	// Add the extra enemy.
	if (!middleRushSection) {
	  if (ap.type.type == EnemyType.SMALL && !EnemyType.isExist[ap.type.id]) {
	    ap.cnt = 0;
	    EnemyType.isExist[ap.type.id] = true;
	  }
	} else {
	  if (ap.type.type == EnemyType.MIDDLE && !EnemyType.isExist[ap.type.id]) {
	    ap.cnt = 0;
	    EnemyType.isExist[ap.type.id] = true;
	  }
	}
	continue;
      }
      float p;
      switch (ap.sequence) {
      case RANDOM:
	p = rand.nextFloat(1);
	break;
      case FIXED:
	p = ap.pos;
	break;
      default:
	break;
      }
      float d;
      switch (ap.point) {
      case TOP:
	switch (ap.pattern) {
	case BOTH_SIDES:
	  apos.x = (p - 0.5) * field.size.x * 1.8;
	  break;
	default:
	  apos.x = (p * 0.6 + 0.2) * field.size.x * ap.side;
	  break;
	}
	apos.y = field.size.y - Enemy.FIELD_SPACE;
	d = std.math.PI;
	break;
      case BACK:
	switch (ap.pattern) {
	case BOTH_SIDES:
	  apos.x = (p - 0.5) * field.size.x * 1.8;
	  break;
	default:
	  apos.x = (p * 0.6 + 0.2) * field.size.x * ap.side;
	  break;
	}
	apos.y = -field.size.y + Enemy.FIELD_SPACE;
	d = 0;
	break;
      case SIDE:
	switch (ap.pattern) {
	case BOTH_SIDES:
	  apos.x = (field.size.x - Enemy.FIELD_SPACE) * (rand.nextInt(2) * 2 - 1);
	  break;
	default:
	  apos.x = (field.size.x - Enemy.FIELD_SPACE) * ap.side;
	  break;
	}
	apos.y = (p * 0.4 + 0.4) * field.size.y;
	if (apos.x < 0)
	  d = std.math.PI / 2;
	else
	  d = std.math.PI / 2 * 3;
	break;
      default:
	break;
      }
      apos.x *= 0.88;
      gameManager.addEnemy(apos, d, ap.type, ap.moveParser);
      ap.left--;
      if (ap.left <= 0) {
	ap.cnt = ap.groupInterval;
	ap.left = ap.num;
	if (ap.pattern != ONE_SIDE)
	  ap.side *= -1;
	ap.pos = rand.nextFloat(1);
      } else {
	ap.cnt = ap.interval;
      }
    }
    if (!bossSection ||
	(!EnemyType.isExist[middleBossType.id] && !EnemyType.isExist[largeBossType.id]))
      sectionCnt--;
    if (sectionCnt < sectionIntervalCnt) {
      if (section == 9 && sectionCnt == sectionIntervalCnt - 1)
	Sound.fadeMusic();
      apNum = 0;
      if (sectionCnt <= 0)
	gotoNextSection();
    }
    EnemyType.clearIsExistList();
  }
}
