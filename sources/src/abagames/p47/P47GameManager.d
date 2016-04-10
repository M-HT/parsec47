/*
 * $Id: P47GameManager.d,v 1.6 2004/01/01 11:26:42 kenta Exp $
 *
 * Copyright 2003 Kenta Cho. All rights reserved.
 */
module abagames.p47.P47GameManager;

private:
import std.math;
import opengl;
import SDL;
import bulletml;
version (PANDORA) {
    import std.conv;
    import std.process;
}
import abagames.util.Rand;
import abagames.util.Vector;
import abagames.util.ActorPool;
import abagames.util.sdl.GameManager;
import abagames.util.sdl.Screen3D;
import abagames.util.sdl.Texture;
import abagames.util.sdl.Pad;
import abagames.util.sdl.Sound;
import abagames.p47.LuminousActorPool;
import abagames.p47.P47PrefManager;
import abagames.p47.P47Screen;
import abagames.p47.LetterRender;
import abagames.p47.Ship;
import abagames.p47.Field;
import abagames.p47.Enemy;
import abagames.p47.EnemyType;
import abagames.p47.Particle;
import abagames.p47.Fragment;
import abagames.p47.BulletActor;
import abagames.p47.BulletActorPool;
import abagames.p47.BarrageManager;
import abagames.p47.Shot;
import abagames.p47.Roll;
import abagames.p47.Lock;
import abagames.p47.Bonus;
import abagames.p47.StageManager;
import abagames.p47.Title;
import abagames.p47.SoundManager;

/**
 * Manage the game status and actor pools.
 */
public class P47GameManager: GameManager {
 public:
  bool nowait = false;
  int difficulty, parsecSlot;
  static enum {
    ROLL, LOCK,
  }
  int mode;
  static enum {
    TITLE, IN_GAME, GAMEOVER, PAUSE
  }
  int state;
 private:
  Pad pad;
  const int ENEMY_MAX = 32;
  P47PrefManager prefManager;
  P47Screen screen;
  Rand rand;
  Field field;
  Ship ship;
  ActorPool enemies;
  LuminousActorPool particles;
  LuminousActorPool fragments;
  BulletActorPool bullets;
  ActorPool shots;
  ActorPool rolls;
  ActorPool locks;
  ActorPool bonuses;
  BarrageManager barrageManager;
  StageManager stageManager;
  const int FIRST_EXTEND = 200000;
  const int EVERY_EXTEND = 500000;
  const int LEFT_MAX = 4;
  int left;
  int score, extendScore;
  int cnt;
  int pauseCnt;
  const int BOSS_WING_NUM = 4;
  int bossShield;
  int bossWingShield[BOSS_WING_NUM];
  const float[P47PrefManager.MODE_NUM] SLOWDOWN_START_BULLETS_SPEED = [30, 42];
  float interval;
  Title title;

  // Initialize actor pools, load BGMs/SEs and textures.
  public override void init() {
    pad = cast(Pad) input;
    prefManager = cast(P47PrefManager) abstPrefManager;
    screen = cast(P47Screen) abstScreen;
    rand = new Rand;
    Field.createDisplayLists();
    field = new Field;
    field.init();
    Ship.initRand();
    Ship.createDisplayLists();
    ship = new Ship;
    ship.init(pad, field, this);
    scope Particle particleClass = new Particle;
    scope ParticleInitializer pi = new ParticleInitializer;
    particles = new LuminousActorPool(128, particleClass, pi);
    scope Fragment fragmentClass = new Fragment;
    scope FragmentInitializer fi = new FragmentInitializer;
    fragments = new LuminousActorPool(128, fragmentClass, fi);
    BulletActor.createDisplayLists();
    scope BulletActorInitializer bi = new BulletActorInitializer(field, ship);
    bullets = new BulletActorPool(512, bi);
    LetterRender.createDisplayLists();
    scope Shot shotClass = new Shot;
    scope ShotInitializer shi = new ShotInitializer(field);
    shots = new ActorPool(32, shotClass, shi);
    scope Roll rollClass = new Roll;
    scope RollInitializer ri = new RollInitializer(ship, field, this);
    rolls = new ActorPool(4, rollClass, ri);
    Lock.init();
    scope Lock lockClass = new Lock;
    scope LockInitializer li = new LockInitializer(ship, field, this);
    locks = new ActorPool(4, lockClass, li);
    Enemy.initRand();
    scope Enemy enemyClass = new Enemy;
    scope EnemyInitializer ei = new EnemyInitializer
      (field, bullets, shots, rolls, locks, this);
    enemies = new ActorPool(ENEMY_MAX, enemyClass, ei);
    Bonus.init();
    scope Bonus bonusClass = new Bonus;
    scope BonusInitializer bni = new BonusInitializer(field, ship, this);
    bonuses = new ActorPool(128, bonusClass, bni);
    barrageManager = new BarrageManager;
    barrageManager.loadBulletMLs();
    EnemyType.init(barrageManager);
    stageManager = new StageManager;
    stageManager.init(this, barrageManager, field);
    title = new Title;
    title.init(pad, this, prefManager, field);
    interval = mainLoop.INTERVAL_BASE;
    SoundManager.init(this);
  }

  public override void start() {
    startTitle();
  }

  public override void close() {
    barrageManager.unloadBulletMLs();
    title.close();
    SoundManager.close();
    LetterRender.deleteDisplayLists();
    Field.deleteDisplayLists();
    Ship.deleteDisplayLists();
    BulletActor.deleteDisplayLists();
  }

  public void addScore(int sc) {
    score += sc;
    if (score > extendScore) {
      if (left < LEFT_MAX) {
	SoundManager.playSe(SoundManager.EXTEND);
	left++;
      }
      if (extendScore <= FIRST_EXTEND)
	extendScore = EVERY_EXTEND;
      else
	extendScore += EVERY_EXTEND;
    }
  }

  public void shipDestroyed() {
    if (mode == ROLL)
      releaseRoll();
    else
      releaseLock();
    clearBullets();
    left--;
    if (left < 0)
      startGameover();
  }

  public void addParticle(Vector pos, float deg, float ofs, float speed) {
    Particle pt = cast(Particle) particles.getInstanceForced();
    assert(pt);
    pt.set(pos, deg, ofs, speed);
  }

  public void addFragments(int n, float x1, float y1, float x2, float y2, float z,
			   float speed, float deg) {
    for (int i = 0; i < n; i++) {
      Fragment ft = cast(Fragment) fragments.getInstanceForced();
      assert(ft);
      ft.set(x1, y1, x2, y2, z, speed, deg);
    }
  }

  public void addEnemy(Vector pos, float d, EnemyType type, BulletMLParser *moveParser) {
    Enemy en = cast(Enemy) enemies.getInstance();
    if (!en)
      return;
    en.set(pos, d, type, moveParser);
  }

  public void clearBullets() {
    for (int i = 0; i < bullets.actor.length; i++) {
      if (!bullets.actor[i].isExist)
	continue;
      (cast(BulletActor) bullets.actor[i]).toRetro();
    }
  }

  public void addBoss(Vector pos, float d, EnemyType type) {
    Enemy en = cast(Enemy) enemies.getInstance();
    if (!en)
      return;
    en.setBoss(pos, d, type);
  }

  public void addShot(Vector pos, float deg) {
    Shot shot = cast(Shot) shots.getInstance();
    if (!shot)
      return;
    shot.set(pos, deg);
  }

  public void addRoll() {
    Roll roll = cast(Roll) rolls.getInstance();
    if (!roll)
      return;
    roll.set();
  }

  public void addLock() {
    Lock lock = cast(Lock) locks.getInstance();
    if (!lock)
      return;
    lock.set();
  }

  public void releaseRoll() {
    for (int i = 0; i < rolls.actor.length; i++) {
      if (!rolls.actor[i].isExist)
	continue;
      (cast(Roll) rolls.actor[i]).released = true;
    }
  }

  public void releaseLock() {
    for (int i = 0; i < locks.actor.length; i++) {
      if (!locks.actor[i].isExist)
	continue;
      (cast(Lock) locks.actor[i]).released = true;
    }
  }


  public void addBonus(Vector pos, Vector ofs, int num) {
    for (int i = 0; i < num; i++) {
      Bonus bonus = cast(Bonus) bonuses.getInstance();
      if (!bonus)
	return;
      bonus.set(pos, ofs);
    }
  }

  public void setBossShieldMeter(int bs, int s1, int s2, int s3, int s4, float r) {
    r *= 0.7;
    bossShield = cast(int)(bs * r);
    bossWingShield[0] = cast(int)(s1 * r);
    bossWingShield[1] = cast(int)(s2 * r);
    bossWingShield[2] = cast(int)(s3 * r);
    bossWingShield[3] = cast(int)(s4 * r);
  }

  // Difficulty.
  public enum {
    PRACTICE, NORMAL, HARD, EXTREME, QUIT
  }

  public void startStage(int difficulty, int parsecSlot, int startParsec, int mode) {
    enemies.clear();
    bullets.clear();
    this.difficulty = difficulty;
    this.parsecSlot = parsecSlot;
    this.mode = mode;
    int stageType = rand.nextInt(99999);
    switch (difficulty) {
    case PRACTICE:
      stageManager.setRank(1, 4, startParsec, stageType);
      ship.setSpeedRate(0.7);
      Bonus.setSpeedRate(0.6);
      break;
    case NORMAL:
      stageManager.setRank(10, 8, startParsec, stageType);
      ship.setSpeedRate(0.9);
      Bonus.setSpeedRate(0.8);
      break;
    case HARD:
      stageManager.setRank(22, 12, startParsec, stageType);
      ship.setSpeedRate(1);
      Bonus.setSpeedRate(1);
      break;
    case EXTREME:
      stageManager.setRank(36, 16, startParsec, stageType);
      ship.setSpeedRate(1.2);
      Bonus.setSpeedRate(1.3);
      break;
    case QUIT:
      stageManager.setRank(0, 0, 0, 0);
      ship.setSpeedRate(1);
      Bonus.setSpeedRate(1);
      break;
    default:
      break;
    }
  }

  private void initShipState() {
    left = 2;
    score = 0;
    extendScore = FIRST_EXTEND;
    ship.start();
  }

  private void startInGame() {
    state = IN_GAME;
    initShipState();
    startStage(difficulty, parsecSlot, title.getStartParsec(difficulty, parsecSlot), mode);
  }

  private void startTitle() {
    state = TITLE;
    title.start();
    initShipState();
    bullets.clear();
    ship.cnt = 0;
    startStage(difficulty, parsecSlot, title.getStartParsec(difficulty, parsecSlot), mode);
    cnt = 0;
    Sound.stopMusic();
  }

  private void startGameover() {
    state = GAMEOVER;
    bonuses.clear();
    shots.clear();
    rolls.clear();
    locks.clear();
    setScreenShake(0, 0);
    mainLoop.interval = mainLoop.INTERVAL_BASE;
    interval = mainLoop.INTERVAL_BASE;
    cnt = 0;
    if (score > prefManager.hiScore[mode][difficulty][parsecSlot])
      prefManager.hiScore[mode][difficulty][parsecSlot] = score;
    if (stageManager.parsec > prefManager.reachedParsec[mode][difficulty])
      prefManager.reachedParsec[mode][difficulty] = stageManager.parsec;
    Sound.fadeMusic();

    version (PANDORA) {
      if (difficulty == 1 && parsecSlot == 0) {
        if (mode == ROLL)
          system(escapeShellCommand("fusilli", "--cache", "push", "parsec47_roll", to!string(score), "0") ~ " >/dev/null 2>&1");
        else
          system(escapeShellCommand("fusilli", "--cache", "push", "parsec47_lock", to!string(score), "0") ~ " >/dev/null 2>&1");
      }
    }
  }

  private void startPause() {
    state = PAUSE;
    pauseCnt = 0;
  }

  private void resumePause() {
    state = IN_GAME;
  }

  private void stageMove() {
    stageManager.move();
  }

  private bool pPrsd = true;

  private void inGameMove() {
    stageMove();
    field.move();
    ship.move();
    bonuses.move();
    shots.move();
    enemies.move();
    if (mode == ROLL)
      rolls.move();
    else
      locks.move();
    BulletActor.resetTotalBulletsSpeed();
    bullets.move();
    particles.move();
    fragments.move();
    moveScreenShake();
    if (pad.keys[SDLK_p] == SDL_PRESSED) {
      if (!pPrsd) {
	pPrsd = true;
	startPause();
      }
    } else {
      pPrsd = false;
    }
    if (!nowait) {
      // Intentional slowdown when the total speed of bullets is over SLOWDOWN_START_BULLETS_SPEED
      if (BulletActor.totalBulletsSpeed > SLOWDOWN_START_BULLETS_SPEED[mode]) {
	float sm = BulletActor.totalBulletsSpeed / SLOWDOWN_START_BULLETS_SPEED[mode];
	if (sm > 1.75)
	  sm = 1.75;
	interval += (sm * mainLoop.INTERVAL_BASE - interval) * 0.1;
	mainLoop.interval = cast(int)interval;
      } else {
	interval += (mainLoop.INTERVAL_BASE - interval) * 0.08;
	mainLoop.interval = cast(int)interval;
      }
    }
  }

  private bool btnPrsd = true;

  private void titleMove() {
    title.move();
    if (cnt <= 8) {
      btnPrsd = true;
    } else {
      int btn = pad.getButtonState();
      if (btn & Pad.PAD_BUTTON1) {
	if (!btnPrsd) {
	  title.setStatus();
	  if (difficulty >= P47PrefManager.DIFFICULTY_NUM)
	    mainLoop.breakLoop();
	  else
	    startInGame();
	  return;
	}
      } else if (btn & Pad.PAD_BUTTON2) {
	if (!btnPrsd) {
	  title.changeMode();
	  btnPrsd = true;
	}
      } else {
	btnPrsd = false;
      }
    }
    stageMove();
    field.move();
    enemies.move();
    bullets.move();
  }

  private void gameoverMove() {
    bool gotoNextState = false;
    if (cnt <= 64) {
      btnPrsd = true;
    } else {
      if (pad.getButtonState() & (Pad.PAD_BUTTON1 | Pad.PAD_BUTTON2)) {
	if (!btnPrsd)
	  gotoNextState = true;
      } else {
	btnPrsd = false;
      }
    }
    if (cnt > 64 && gotoNextState) {
	startTitle();
    } else if (cnt > 500) {
	startTitle();
    }
    field.move();
    enemies.move();
    bullets.move();
    particles.move();
    fragments.move();
  }

  private void pauseMove() {
    pauseCnt++;
    if (pad.keys[SDLK_p] == SDL_PRESSED) {
      if (!pPrsd) {
	pPrsd = true;
	resumePause();
      }
    } else {
      pPrsd = false;
    }
  }

  public override void move() {
    if (pad.keys[SDLK_ESCAPE] == SDL_PRESSED) {
      mainLoop.breakLoop();
      return;
    }
    switch (state) {
    case IN_GAME:
      inGameMove();
      break;
    case TITLE:
      titleMove();
      break;
    case GAMEOVER:
      gameoverMove();
      break;
    case PAUSE:
      pauseMove();
      break;
    default:
    }
    cnt++;
  }

  private void inGameDraw() {
    field.draw();
    P47Screen.setRetroColor(0.2, 0.7, 0.5, 1);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    bonuses.draw();
    glBlendFunc(GL_SRC_ALPHA, GL_ONE);
    Screen3D.setColor(Particle.R, Particle.G, Particle.B, 1);
    glBegin(GL_LINES);
    particles.draw();
    glEnd();
    P47Screen.setRetroColor(Fragment.R, Fragment.G, Fragment.B, 1);
    fragments.draw();
    P47Screen.setRetroZ(0);
    ship.draw();
    P47Screen.setRetroColor(0.8, 0.8, 0.2, 0.8);
    shots.draw();
    P47Screen.setRetroColor(1.0, 0.8, 0.5, 1);
    if (mode == ROLL)
      rolls.draw();
    else
      locks.draw();
    enemies.draw();
    bullets.draw();
  }

  private void titleDraw() {
    field.draw();
    enemies.draw();
    bullets.draw();
  }

  private void gameoverDraw() {
    field.draw();
    Screen3D.setColor(Particle.R, Particle.G, Particle.B, 1);
    glBegin(GL_LINES);
    particles.draw();
    glEnd();
    P47Screen.setRetroColor(Fragment.R, Fragment.G, Fragment.B, 1);
    fragments.draw();
    P47Screen.setRetroZ(0);
    enemies.draw();
    bullets.draw();
  }

  private void inGameDrawLuminous() {
    glBegin(GL_LINES);
    particles.drawLuminous();
    fragments.drawLuminous();
    glEnd();
  }

  private void titleDrawLuminous() {
  }

  private void gameoverDrawLuminous() {
    glBegin(GL_LINES);
    particles.drawLuminous();
    fragments.drawLuminous();
    glEnd();
  }

  private void drawBoard(int x, int y, int width, int height) {
    glColor4f(0, 0, 0, 1);
    glBegin(GL_QUADS);
    glVertex2f(x, y);
    glVertex2f(x + width, y);
    glVertex2f(x + width, y + height);
    glVertex2f(x, y + height);
    glEnd();
  }

  private void drawSideBoards() {
    glDisable(GL_BLEND);
    drawBoard(0, 0, 160, 480);
    drawBoard(480, 0, 160, 480);
    glEnable(GL_BLEND);
  }

  private void drawScore() {
    LetterRender.drawNum(score, 120, 28, 25, LetterRender.TO_UP);
    LetterRender.drawNum(Bonus.bonusScore, 24, 20, 12, LetterRender.TO_UP);
  }

  private void drawLeft() {
    if (left < 0)
      return;
    LetterRender.drawString("LEFT", 520, 260, 25, LetterRender.TO_DOWN);
    LetterRender.changeColor(LetterRender.RED);
    LetterRender.drawNum(left, 520, 450, 25, LetterRender.TO_DOWN);
    LetterRender.changeColor(LetterRender.WHITE);
  }

  private void drawParsec() {
    int ps = stageManager.parsec;
    if (ps < 10)
      LetterRender.drawNum(stageManager.parsec, 600, 26, 25, LetterRender.TO_DOWN);
    else if (ps < 100)
      LetterRender.drawNum(stageManager.parsec, 600, 68, 25, LetterRender.TO_DOWN);
    else
      LetterRender.drawNum(stageManager.parsec, 600, 110, 25, LetterRender.TO_DOWN);
  }

  private void drawBox(int x, int y, int w, int h) {
    if (w <= 0)
      return;
    Screen3D.setColor(1, 1, 1, 0.5);
    P47Screen.drawBoxSolid(x, y, w, h);
    Screen3D.setColor(1, 1, 1, 1);
    P47Screen.drawBoxLine(x, y, w, h);
  }

  private void drawBossShieldMeter() {
    drawBox(165, 6, bossShield, 6);
    int y = 24;
    for (int i = 0; i < BOSS_WING_NUM; i++) {
      switch (i % 2) {
      case 0:
	drawBox(165, y, bossWingShield[i], 6);
	break;
      case 1:
	drawBox(475 - bossWingShield[i], y, bossWingShield[i], 6);
	y += 12;
	break;
      default:
	break;
      }
    }
  }

  private void drawSideInfo() {
    drawSideBoards();
    drawScore();
    drawLeft();
    drawParsec();
  }

  private void inGameDrawStatus() {
    drawSideInfo();
    if (stageManager.bossSection)
      drawBossShieldMeter();
  }

  private void titleDrawStatus() {
    drawSideBoards();
    drawScore();
    title.draw();
  }

  private void gameoverDrawStatus() {
    drawSideInfo();
    if (cnt > 64) {
      LetterRender.drawString("GAME OVER", 220, 200, 15, LetterRender.TO_RIGHT);
    }
  }

  private void pauseDrawStatus() {
    drawSideInfo();
    if ((pauseCnt % 60) < 30)
      LetterRender.drawString("PAUSE", 280, 220, 12, LetterRender.TO_RIGHT);
  }

  private int screenShakeCnt;
  private float screenShakeIntense;

  public void setScreenShake(int cnt, float intense) {
    screenShakeCnt = cnt;
    screenShakeIntense = intense;
  }

  private void moveScreenShake() {
    if (screenShakeCnt > 0)
      screenShakeCnt--;
  }

  private void setEyepos() {
    float x = 0, y = 0;
    if (screenShakeCnt > 0) {
      x = rand.nextSignedFloat(screenShakeIntense * (screenShakeCnt + 10));
      y = rand.nextSignedFloat(screenShakeIntense * (screenShakeCnt + 10));
    }
    glTranslatef(x, y, -field.eyeZ);
  }

  public override void draw() {
    SDL_Event e = mainLoop.event;
    if (e.type == SDL_VIDEORESIZE) {
      SDL_ResizeEvent re = e.resize;
      if (re.w > 150 && re.h > 100)
	screen.resized(re.w, re.h);
    }
    screen.startRenderToTexture();
    glPushMatrix();
    setEyepos();
    switch (state) {
    case IN_GAME:
    case PAUSE:
      inGameDrawLuminous();
      break;
    case TITLE:
      titleDrawLuminous();
      break;
    case GAMEOVER:
      gameoverDrawLuminous();
      break;
    default:
    }
    glPopMatrix();
    screen.endRenderToTexture();

    screen.clear();
    glPushMatrix();
    setEyepos();
    switch (state) {
    case IN_GAME:
    case PAUSE:
      inGameDraw();
      break;
    case TITLE:
      titleDraw();
      break;
    case GAMEOVER:
      gameoverDraw();
      break;
    default:
    }
    glPopMatrix();

    screen.drawLuminous();

    screen.viewOrthoFixed();
    switch (state) {
    case IN_GAME:
      inGameDrawStatus();
      break;
    case TITLE:
      titleDrawStatus();
      break;
    case GAMEOVER:
      gameoverDrawStatus();
      break;
    case PAUSE:
      pauseDrawStatus();
      break;
    default:
    }
    screen.viewPerspective();
  }
}
