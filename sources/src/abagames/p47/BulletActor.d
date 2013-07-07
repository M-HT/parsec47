/*
 * $Id: BulletActor.d,v 1.5 2004/01/01 11:26:41 kenta Exp $
 *
 * Copyright 2003 Kenta Cho. All rights reserved.
 */
module abagames.p47.BulletActor;

private:
import std.math;
version (USE_GLES) {
  import opengles;
} else {
  import opengl;
}
import bulletml;
import abagames.util.Actor;
import abagames.util.ActorInitializer;
import abagames.util.Vector;
import abagames.util.sdl.Screen3D;
import abagames.util.bulletml.Bullet;
import abagames.p47.Field;
import abagames.p47.P47Bullet;
import abagames.p47.BulletActorPool;
import abagames.p47.Ship;
import abagames.p47.P47Screen;

/**
 * Actor of the bullet.
 */
public class BulletActor: Actor {
 public:
  P47Bullet bullet;
  static float totalBulletsSpeed;
 private:
  static const float FIELD_SPACE = 0.5;
  static int BULLET_DISAPPEAR_CNT = 180;
  Field field;
  Ship ship;
  static int nextId;
  bool isSimple;
  bool isTop;
  bool isVisible;
  BulletMLParser *parser;
  Vector ppos;
  const float SHIP_HIT_WIDTH = 0.2;
  int cnt;
  const float RETRO_CNT = 24;
  float rtCnt;
  bool shouldBeRemoved;
  bool backToRetro;

  public static void init() {
    nextId = 0;
  }

  public static void resetTotalBulletsSpeed() {
    totalBulletsSpeed = 0;
  }

  public override Actor newActor() {
    return new BulletActor;
  }

  public override void init(ActorInitializer ini) {
    BulletActorInitializer bi = cast(BulletActorInitializer) ini;
    field = bi.field;
    ship = bi.ship;
    bullet = new P47Bullet(nextId);
    ppos = new Vector;
    nextId++;
  }

  private void start(float speedRank, int shape, int color, float size, float xReverse) {
    isExist = true;
    isTop = false;
    isVisible = true;
    ppos.x = bullet.pos.x;
    ppos.y = bullet.pos.y;
    bullet.setParam(speedRank, shape, color, size, xReverse);
    cnt = 0;
    rtCnt = 0;
    shouldBeRemoved = false;
    backToRetro = false;
  }

  public void set(BulletMLRunner* runner,
		  float x, float y, float deg, float speed, float rank,
		  float speedRank, int shape, int color, float size, float xReverse) {
    bullet.set(runner, x, y, deg, speed, rank);
    bullet.isMorph = false;
    isSimple = false;
    start(speedRank, shape, color, size, xReverse);
  }

  public void set(BulletMLRunner* runner,
		  float x, float y, float deg, float speed, float rank,
		  float speedRank, int shape, int color, float size, float xReverse,
		  BulletMLParser *morph[], int morphNum, int morphIdx, int morphCnt) {
    bullet.set(runner, x, y, deg, speed, rank);
    bullet.setMorph(morph, morphNum, morphIdx, morphCnt);
    isSimple = false;
    start(speedRank, shape, color, size, xReverse);
  }

  public void set(float x, float y, float deg, float speed, float rank,
		  float speedRank, int shape, int color, float size, float xReverse) {
    bullet.set(x, y, deg, speed, rank);
    bullet.isMorph = false;
    isSimple = true;
    start(speedRank, shape, color, size, xReverse);
  }

  public void setInvisible() {
    isVisible = false;
  }

  public void setTop(BulletMLParser *parser) {
    this.parser = parser;
    isTop = true;
    setInvisible();
  }

  public void rewind() {
    bullet.remove();
    BulletMLRunner *runner = BulletMLRunner_new_parser(parser);
    BulletActorPool.registFunctions(runner);
    bullet.setRunner(runner);
    bullet.resetMorph();
  }

  public void remove() {
    shouldBeRemoved = true;
  }

  private void removeForced() {
    if (!isSimple)
      bullet.remove();
    isExist = false;
  }

  public void toRetro() {
    if (!isVisible || backToRetro)
      return;
    backToRetro = true;
    if (rtCnt >= RETRO_CNT)
      rtCnt = RETRO_CNT - 0.1;
  }

  // Check if the bullet hits the ship.
  private void checkShipHit() {
    float bmvx, bmvy, inaa;
    bmvx = ppos.x;
    bmvy = ppos.y;
    bmvx -= bullet.pos.x;
    bmvy -= bullet.pos.y;
    inaa = bmvx * bmvx + bmvy * bmvy;
    if (inaa > 0.00001) {
      float sofsx, sofsy, inab, hd;
      sofsx = ship.pos.x;
      sofsy = ship.pos.y;
      sofsx -= bullet.pos.x;
      sofsy -= bullet.pos.y;
      inab = bmvx * sofsx + bmvy * sofsy;
      if (inab >= 0 && inab <= inaa) {
	hd = sofsx * sofsx + sofsy * sofsy - inab * inab / inaa;
	if (hd >= 0 && hd <= SHIP_HIT_WIDTH) {
	  ship.destroyed();
	}
      }
    }
  }

  public override void move() {
    ppos.x = bullet.pos.x;
    ppos.y = bullet.pos.y;
    if (!isSimple) {
      bullet.move();
      if (isTop && bullet.isEnd())
	rewind();
    }
    if (shouldBeRemoved) {
      removeForced();
      return;
    }
    float sr;
    if (rtCnt < RETRO_CNT) {
      sr = bullet.speedRank * (0.3 + (rtCnt / RETRO_CNT) * 0.7);
      if (backToRetro) {
	rtCnt -= sr;
	if (rtCnt <= 0) {
	  removeForced();
	  return;
	}
      } else {
	rtCnt += sr;
      }
      if (ship.cnt < -Ship.INVINCIBLE_CNT / 2 && isVisible && rtCnt >= RETRO_CNT) {
	removeForced();
	return;
      }
    } else {
      sr = bullet.speedRank;
      if (cnt > BULLET_DISAPPEAR_CNT)
	toRetro();
    }
    bullet.pos.x +=
      (sin(bullet.deg) * bullet.speed + bullet.acc.x) * sr * bullet.xReverse;
    bullet.pos.y +=
      (cos(bullet.deg) * bullet.speed - bullet.acc.y) * sr;
    if (isVisible) {
      totalBulletsSpeed += bullet.speed * sr;
      if (rtCnt > RETRO_CNT)
	checkShipHit();
      if (field.checkHit(bullet.pos, FIELD_SPACE))
	removeForced();
    }
    cnt++;
  }

  public static const int BULLET_SHAPE_NUM = 7;
  public static const int BULLET_COLOR_NUM = 4;
  private static const float shapePos[BULLET_SHAPE_NUM][][3] =
    [
     [[-0.5, -0.5], [0.5, -0.5], [0, 1],],
     [[0, -1], [0.5, 0], [0, 1], [-0.5, 0]],
     [[-0.25, -0.66], [0.25, -0.66], [0.25, 0.66], [-0.25, 0.66]],
     [[-0.5, -0.5], [0.5, -0.5], [0.5, 0.5], [-0.5, 0.5]],
     [[-0.25, -0.5], [0.25, -0.5], [0.5, -0.25], [0.5, 0.25],
      [0.25, 0.5], [-0.25, 0.5], [-0.5, 0.25], [-0.5, -0.25]],
     [[-0.66, -0.46], [0, 0.86], [0.66, -0.46]],
     [[-0.5, -0.5], [0, -0.5], [0.5, 0], [0.5, 0.5], [0, 0.5], [-0.5, 0]],
    ];

  private void drawRetro(float d) {
    float rt = 1 - rtCnt / RETRO_CNT;
    P47Screen.setRetroParam(rt, 0.4 * bullet.bulletSize);
    P47Screen.setRetroColor(bulletColor[bullet.color][0],
			    bulletColor[bullet.color][1],
			    bulletColor[bullet.color][2], 1);
    float x, y, tx, px, py, fx, fy;
    for (int i = 0; i < shapePos[bullet.shape].length; i++) {
      px = x; py = y;
      tx = shapePos[bullet.shape][i][0] * bullet.bulletSize;
      y = shapePos[bullet.shape][i][1] * bullet.bulletSize;
      x = tx * cos(d) - y * sin(d);
      y = tx * sin(d) + y * cos(d);
      if (i > 0) {
	P47Screen.drawLineRetro(px, py, x, y);
      } else {
	fx = x; fy = y;
      }
    }
    P47Screen.drawLineRetro(x, y, fx, fy);
  }

  public override void draw() {
    if (!isVisible)
      return;
    float d;
    switch (bullet.shape) {
    case 0:
    case 2:
    case 5:
      d = -bullet.deg * (bullet.xReverse);
      break;
    case 1:
      d = cnt * 0.14;
      break;
    case 3:
      d = cnt * 0.23;
      break;
    case 4:
      d = cnt * 0.33;
      break;
    case 6:
      d = cnt * 0.08;
      break;
    default:
      break;
    }
    glPushMatrix();
    glTranslatef(bullet.pos.x, bullet.pos.y, 0);
    if (rtCnt >= RETRO_CNT) {
      drawBox(bullet.color);
      glRotatef(rtod(d), 0, 0, 1);
      glScalef(bullet.bulletSize, bullet.bulletSize, 1);
      drawShape(bullet.color, bullet.shape);
    } else {
      drawRetro(d);
    }
    glPopMatrix();
  }

  private static const float SHAPE_POINT_SIZE = 0.1;
  private static const float SHAPE_BASE_COLOR_R = 1;
  private static const float SHAPE_BASE_COLOR_G = 0.9;
  private static const float SHAPE_BASE_COLOR_B = 0.7;
  private static const float bulletColor[BULLET_COLOR_NUM][3] =
    [
     [1, 0, 0], [0.2, 1, 0.4], [0.3, 0.3, 1], [1, 1, 0],
     ];
  private static const boxNumVertices = 4;
  private static const GLfloat[3*boxNumVertices] boxVertices = [
    -SHAPE_POINT_SIZE, -SHAPE_POINT_SIZE, 0,
     SHAPE_POINT_SIZE, -SHAPE_POINT_SIZE, 0,
     SHAPE_POINT_SIZE,  SHAPE_POINT_SIZE, 0,
    -SHAPE_POINT_SIZE,  SHAPE_POINT_SIZE, 0
  ];
  private static GLfloat[4*boxNumVertices][BULLET_COLOR_NUM] boxColors;
  private static GLenum[BULLET_SHAPE_NUM] shapeDrawMode;
  private static GLfloat[][2][BULLET_SHAPE_NUM] shapeVertices;
  private static GLfloat[][2][BULLET_SHAPE_NUM][BULLET_COLOR_NUM] shapeColors;

  private static void drawBox(int color) {
    glEnableClientState(GL_VERTEX_ARRAY);
    glEnableClientState(GL_COLOR_ARRAY);

    glVertexPointer(3, GL_FLOAT, 0, cast(void *)(boxVertices.ptr));
    glColorPointer(4, GL_FLOAT, 0, cast(void *)(boxColors[color].ptr));
    glDrawArrays(GL_TRIANGLE_FAN, 0, boxNumVertices);

    glDisableClientState(GL_COLOR_ARRAY);
    glDisableClientState(GL_VERTEX_ARRAY);
  }

  private static void drawShape(int color, int shape) {
    const int shapeNumVertices = cast(int)(shapeColors[color][shape][0].length / 4);

    glEnableClientState(GL_VERTEX_ARRAY);
    glEnableClientState(GL_COLOR_ARRAY);

    glDisable(GL_BLEND);
    glVertexPointer(3, GL_FLOAT, 0, cast(void *)(shapeVertices[shape][0].ptr));
    glColorPointer(4, GL_FLOAT, 0, cast(void *)(shapeColors[color][shape][0].ptr));
    glDrawArrays(shapeDrawMode[shape], 0, shapeNumVertices);
    glEnable(GL_BLEND);

    glVertexPointer(3, GL_FLOAT, 0, cast(void *)(shapeVertices[shape][1].ptr));
    glColorPointer(4, GL_FLOAT, 0, cast(void *)(shapeColors[color][shape][1].ptr));
    glDrawArrays(GL_TRIANGLE_FAN, 0, shapeNumVertices);

    glDisableClientState(GL_COLOR_ARRAY);
    glDisableClientState(GL_VERTEX_ARRAY);
  }

  public static void prepareBullets() {
    float r, g, b;
    GLfloat size = 1.0f, sz, sz2;

    foreach (j; 0..BULLET_SHAPE_NUM) {
      switch (j) {
        case 0:
          sz = size/2;
          shapeVertices[j][0] = [
            -sz, -sz,  0,
             sz, -sz,  0,
             0, size,  0
          ];
          shapeVertices[j][1] = shapeVertices[j][0];
          break;
        case 1:
          sz = size/2;
          shapeVertices[j][0] = [
              0, -size,  0,
             sz,     0,  0,
              0,  size,  0,
            -sz,     0,  0
          ];
          shapeVertices[j][1] = shapeVertices[j][0];
          break;
        case 2:
          sz = size/4; sz2 = size/3*2;
          shapeVertices[j][0] = [
            -sz, -sz2,  0,
             sz, -sz2,  0,
             sz,  sz2,  0,
            -sz,  sz2,  0
          ];
          shapeVertices[j][1] = shapeVertices[j][0];
          break;
        case 3:
          sz = size/2;
          shapeVertices[j][0] = [
            -sz, -sz,  0,
             sz, -sz,  0,
             sz,  sz,  0,
            -sz,  sz,  0
          ];
          shapeVertices[j][1] = shapeVertices[j][0];
          break;
        case 4:
          sz = size/2;
          shapeVertices[j][0] = [
            -sz/2, -sz,  0,
             sz/2, -sz,  0,
             sz,  -sz/2,  0,
             sz,   sz/2,  0,
             sz/2,  sz,  0,
            -sz/2,  sz,  0,
            -sz,   sz/2,  0,
            -sz,  -sz/2,  0
          ];
          shapeVertices[j][1] = shapeVertices[j][0];
          break;
        case 5:
          sz = size*2/3; sz2 = size/5;
          shapeVertices[j][0] = [
            -sz, -sz+sz2,  0,
             0, sz+sz2,  0,
             sz, -sz+sz2,  0
          ];
          shapeVertices[j][1] = [
            -sz, -sz+sz2,  0,
             sz, -sz+sz2,  0,
             0, sz+sz2,  0
          ];
          break;
        case 6:
          sz = size/2;
          shapeVertices[j][0] = [
            -sz, -sz,  0,
              0, -sz,  0,
             sz,   0,  0,
             sz,  sz,  0,
              0,  sz,  0,
            -sz,   0,  0
          ];
          shapeVertices[j][1] = shapeVertices[j][0];
          break;
        default:
          break;
      }
    }

    foreach (i; 0..BULLET_COLOR_NUM) {
      r = bulletColor[i][0];
      g = bulletColor[i][1];
      b = bulletColor[i][2];
      r += (1 - r) * 0.5;
      g += (1 - g) * 0.5;
      b += (1 - b) * 0.5;
      foreach(k; 0..boxNumVertices) {
        boxColors[i][k*4 + 0] = r * Screen3D.brightness;
        boxColors[i][k*4 + 1] = g * Screen3D.brightness;
        boxColors[i][k*4 + 2] = b * Screen3D.brightness;
        boxColors[i][k*4 + 2] = 1;
      }
      foreach (j; 0..BULLET_SHAPE_NUM) {
        const int shapeNumVertices = cast(int)(shapeVertices[j][0].length / 3);
        shapeColors[i][j][0].length = 4*shapeNumVertices;
        shapeColors[i][j][1].length = 4*shapeNumVertices;
        foreach(k; 0..shapeNumVertices) {
          shapeColors[i][j][0][k*4 + 0] = r * Screen3D.brightness;
          shapeColors[i][j][0][k*4 + 1] = g * Screen3D.brightness;
          shapeColors[i][j][0][k*4 + 2] = b * Screen3D.brightness;
          shapeColors[i][j][0][k*4 + 2] = 1;
        }
        switch (j) {
        case 0:
          foreach(k; 0..shapeNumVertices) {
            if (k < 2) {
              shapeColors[i][j][1][k*4 + 0] = r * Screen3D.brightness;
              shapeColors[i][j][1][k*4 + 1] = g * Screen3D.brightness;
              shapeColors[i][j][1][k*4 + 2] = b * Screen3D.brightness;
              shapeColors[i][j][1][k*4 + 2] = 0.55;
            } else {
              shapeColors[i][j][1][k*4 + 0] = SHAPE_BASE_COLOR_R * Screen3D.brightness;
              shapeColors[i][j][1][k*4 + 1] = SHAPE_BASE_COLOR_G * Screen3D.brightness;
              shapeColors[i][j][1][k*4 + 2] = SHAPE_BASE_COLOR_B * Screen3D.brightness;
              shapeColors[i][j][1][k*4 + 2] = 0.55;
            }
          }
          break;
        case 1:
          foreach(k; 0..shapeNumVertices) {
            if (k < 2) {
              shapeColors[i][j][1][k*4 + 0] = r * Screen3D.brightness;
              shapeColors[i][j][1][k*4 + 1] = g * Screen3D.brightness;
              shapeColors[i][j][1][k*4 + 2] = b * Screen3D.brightness;
              shapeColors[i][j][1][k*4 + 2] = 0.7;
            } else {
              shapeColors[i][j][1][k*4 + 0] = SHAPE_BASE_COLOR_R * Screen3D.brightness;
              shapeColors[i][j][1][k*4 + 1] = SHAPE_BASE_COLOR_G * Screen3D.brightness;
              shapeColors[i][j][1][k*4 + 2] = SHAPE_BASE_COLOR_B * Screen3D.brightness;
              shapeColors[i][j][1][k*4 + 2] = 0.55;
            }
          }
          break;
        case 2:
          foreach(k; 0..shapeNumVertices) {
            if (k < 2) {
              shapeColors[i][j][1][k*4 + 0] = r * Screen3D.brightness;
              shapeColors[i][j][1][k*4 + 1] = g * Screen3D.brightness;
              shapeColors[i][j][1][k*4 + 2] = b * Screen3D.brightness;
              shapeColors[i][j][1][k*4 + 2] = 0.45;
            } else {
              shapeColors[i][j][1][k*4 + 0] = SHAPE_BASE_COLOR_R * Screen3D.brightness;
              shapeColors[i][j][1][k*4 + 1] = SHAPE_BASE_COLOR_G * Screen3D.brightness;
              shapeColors[i][j][1][k*4 + 2] = SHAPE_BASE_COLOR_B * Screen3D.brightness;
              shapeColors[i][j][1][k*4 + 2] = 0.55;
            }
          }
          break;
        case 3:
          foreach(k; 0..shapeNumVertices) {
            if (k < 2) {
              shapeColors[i][j][1][k*4 + 0] = r * Screen3D.brightness;
              shapeColors[i][j][1][k*4 + 1] = g * Screen3D.brightness;
              shapeColors[i][j][1][k*4 + 2] = b * Screen3D.brightness;
              shapeColors[i][j][1][k*4 + 2] = 0.7;
            } else {
              shapeColors[i][j][1][k*4 + 0] = SHAPE_BASE_COLOR_R * Screen3D.brightness;
              shapeColors[i][j][1][k*4 + 1] = SHAPE_BASE_COLOR_G * Screen3D.brightness;
              shapeColors[i][j][1][k*4 + 2] = SHAPE_BASE_COLOR_B * Screen3D.brightness;
              shapeColors[i][j][1][k*4 + 2] = 0.55;
            }
          }
          break;
        case 4:
          foreach(k; 0..shapeNumVertices) {
            if (k < 4) {
              shapeColors[i][j][1][k*4 + 0] = r * Screen3D.brightness;
              shapeColors[i][j][1][k*4 + 1] = g * Screen3D.brightness;
              shapeColors[i][j][1][k*4 + 2] = b * Screen3D.brightness;
              shapeColors[i][j][1][k*4 + 2] = 0.85;
            } else {
              shapeColors[i][j][1][k*4 + 0] = SHAPE_BASE_COLOR_R * Screen3D.brightness;
              shapeColors[i][j][1][k*4 + 1] = SHAPE_BASE_COLOR_G * Screen3D.brightness;
              shapeColors[i][j][1][k*4 + 2] = SHAPE_BASE_COLOR_B * Screen3D.brightness;
              shapeColors[i][j][1][k*4 + 2] = 0.55;
            }
          }
          break;
        case 5:
          foreach(k; 0..shapeNumVertices) {
            if (k < 2) {
              shapeColors[i][j][1][k*4 + 0] = r * Screen3D.brightness;
              shapeColors[i][j][1][k*4 + 1] = g * Screen3D.brightness;
              shapeColors[i][j][1][k*4 + 2] = b * Screen3D.brightness;
              shapeColors[i][j][1][k*4 + 2] = 0.55;
            } else {
              shapeColors[i][j][1][k*4 + 0] = SHAPE_BASE_COLOR_R * Screen3D.brightness;
              shapeColors[i][j][1][k*4 + 1] = SHAPE_BASE_COLOR_G * Screen3D.brightness;
              shapeColors[i][j][1][k*4 + 2] = SHAPE_BASE_COLOR_B * Screen3D.brightness;
              shapeColors[i][j][1][k*4 + 2] = 0.55;
            }
          }
          break;
        case 6:
          foreach(k; 0..shapeNumVertices) {
            if (k < 3) {
              shapeColors[i][j][1][k*4 + 0] = r * Screen3D.brightness;
              shapeColors[i][j][1][k*4 + 1] = g * Screen3D.brightness;
              shapeColors[i][j][1][k*4 + 2] = b * Screen3D.brightness;
              shapeColors[i][j][1][k*4 + 2] = 0.85;
            } else {
              shapeColors[i][j][1][k*4 + 0] = SHAPE_BASE_COLOR_R * Screen3D.brightness;
              shapeColors[i][j][1][k*4 + 1] = SHAPE_BASE_COLOR_G * Screen3D.brightness;
              shapeColors[i][j][1][k*4 + 2] = SHAPE_BASE_COLOR_B * Screen3D.brightness;
              shapeColors[i][j][1][k*4 + 2] = 0.55;
            }
          }
          break;
        default:
          break;
        }
      }
    }
  }

}

public class BulletActorInitializer: ActorInitializer {
 public:
  Field field;
  Ship ship;

  public this(Field field, Ship ship) {
    this.field = field;
    this.ship = ship;
  }
}
