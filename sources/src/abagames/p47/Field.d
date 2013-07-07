/*
 * $Id: Field.d,v 1.4 2004/01/01 11:26:41 kenta Exp $
 *
 * Copyright 2003 Kenta Cho. All rights reserved.
 */
module abagames.p47.Field;

private:
import std.math;
version (USE_GLES) {
  import opengles;
} else {
  import opengl;
}
import abagames.util.Vector;
import abagames.util.sdl.Screen3D;
import abagames.p47.P47GameManager;

/**
 * Stage field.
 */
public class Field {
 public:
  static const int TYPE_NUM = 4;
  Vector size;
  float eyeZ;
  float aimZ;
  float aimSpeed;
 private:
  static const int RING_NUM = 16;
  static const float RING_ANGLE_INT = 10;
  float roll, yaw;
  float z;
  float speed;
  float yawYBase, yawZBase;
  float aimYawYBase, aimYawZBase;
  float r, g, b;

  public void init() {
    size = new Vector;
    size.x = 11;
    size.y = 16;
    eyeZ = 20;
    roll = yaw = 0;
    z = aimZ = 10;
    speed = aimSpeed = 0.1;
    yawYBase = yawZBase = 0;
  }

  public void setColor(int mode) {
    switch (mode){
    case P47GameManager.ROLL:
      r = 0.2;
      g = 0.2;
      b = 0.7;
      break;
    case P47GameManager.LOCK:
      r = 0.5;
      g = 0.3;
      b = 0.6;
      break;
    default:
      break;
    }
  }

  public void move() {
    roll += speed;
    if (roll >= RING_ANGLE_INT)
      roll -= RING_ANGLE_INT;
    yaw += speed;
    z += (aimZ - z) * 0.003;
    speed += (aimSpeed - speed) * 0.004;
    yawYBase += (aimYawYBase - yawYBase) * 0.002;
    yawZBase += (aimYawZBase - yawZBase) * 0.002;
  }

  public void setType(int type) {
    switch (type) {
    case 0:
      aimYawYBase = 30;
      aimYawZBase = 0;
      break;
    case 1:
      aimYawYBase = 0;
      aimYawZBase = 20;
      break;
    case 2:
      aimYawYBase = 50;
      aimYawZBase = 10;
      break;
    case 3:
      aimYawYBase = 10;
      aimYawZBase = 30;
      break;
    default:
      break;
    }
  }

  public void draw() {
    Screen3D.setColor(r, g, b, 0.7);
    float d = -RING_NUM * RING_ANGLE_INT / 2 + roll;
    for (int i = 0; i < RING_NUM; i++) {
      for (int j = 1; j < 8; j++) {
	float sc = cast(float) j / 16 + 0.5;
	glPushMatrix();
	glTranslatef(0, 0, z);
	glRotatef(d, 1, 0, 0);
	glRotatef(sin(yaw / 180 * PI) * yawYBase, 0, 1, 0);
	glRotatef(sin(yaw / 180 * PI) * yawZBase, 0, 0, 1);
	glScalef(1, 1, sc);
	displayOneRing();
	glPopMatrix();
      }
      d += RING_ANGLE_INT;
    }
  }

  public bool checkHit(Vector p) {
    if (p.x < -size.x || p.x > size.x || p.y < -size.y || p.y > size.y)
      return true;
    return false;
  }

  public bool checkHit(Vector p, float space) {
    if (p.x < -size.x + space || p.x > size.x - space ||
	p.y < -size.y + space || p.y > size.y - space)
      return true;
    return false;
  }

  private static const int RING_POS_NUM = 16;
  private static Vector ringPos[RING_POS_NUM];
  private static const float RING_DEG = std.math.PI / 3 / (cast(float) (RING_POS_NUM / 2) + 0.5);
  private static const float RING_RADIUS = 10;
  private static const float RING_SIZE = 0.5;
  private static const int ringNumVertices1 = 15; //1 + 2 * (RING_POS_NUM / 2 - 1);
  private static const int ringNumVertices2 = 5;  //1 + 2 * (2);
  private static const int ringNumVertices3 = 15; //1 + 2 * (RING_POS_NUM / 2 - 1);
  private static GLfloat[3*ringNumVertices1] ringVertices1;
  private static GLfloat[3*ringNumVertices2] ringVertices2;
  private static GLfloat[3*ringNumVertices3] ringVertices3;

  private static void displayOneRing() {
    glEnableClientState(GL_VERTEX_ARRAY);

    glVertexPointer(3, GL_FLOAT, 0, cast(void *)(ringVertices1.ptr));
    glDrawArrays(GL_LINE_STRIP, 0, ringNumVertices1);

    glVertexPointer(3, GL_FLOAT, 0, cast(void *)(ringVertices2.ptr));
    glDrawArrays(GL_LINE_STRIP, 0, ringNumVertices2);

    glVertexPointer(3, GL_FLOAT, 0, cast(void *)(ringVertices3.ptr));
    glDrawArrays(GL_LINE_STRIP, 0, ringNumVertices3);

    glDisableClientState(GL_VERTEX_ARRAY);
  }

  private static void prepareOneRing() {
    int ind;

    ind = 0;
    for (int i = 0; i <= RING_POS_NUM / 2 - 2; i++) {
      ringVertices1[3*ind + 0] = ringPos[i].x;
      ringVertices1[3*ind + 1] = RING_SIZE;
      ringVertices1[3*ind + 2] = ringPos[i].y;
      ind++;
    }
    for (int i = RING_POS_NUM / 2 - 2; i >= 0; i--) {
      ringVertices1[3*ind + 0] = ringPos[i].x;
      ringVertices1[3*ind + 1] = -RING_SIZE;
      ringVertices1[3*ind + 2] = ringPos[i].y;
      ind++;
    }
    ringVertices1[3*ind + 0] = ringPos[0].x;
    ringVertices1[3*ind + 1] = RING_SIZE;
    ringVertices1[3*ind + 2] = ringPos[0].y;

    ind = 0;
    ringVertices2[3*ind + 0] = ringPos[RING_POS_NUM / 2 - 1].x;
    ringVertices2[3*ind + 1] = RING_SIZE;
    ringVertices2[3*ind + 2] = ringPos[RING_POS_NUM / 2 - 1].y;
    ind++;
    ringVertices2[3*ind + 0] = ringPos[RING_POS_NUM / 2].x;
    ringVertices2[3*ind + 1] = RING_SIZE;
    ringVertices2[3*ind + 2] = ringPos[RING_POS_NUM / 2].y;
    ind++;
    ringVertices2[3*ind + 0] = ringPos[RING_POS_NUM / 2].x;
    ringVertices2[3*ind + 1] = -RING_SIZE;
    ringVertices2[3*ind + 2] = ringPos[RING_POS_NUM / 2].y;
    ind++;
    ringVertices2[3*ind + 0] = ringPos[RING_POS_NUM / 2 - 1].x;
    ringVertices2[3*ind + 1] = -RING_SIZE;
    ringVertices2[3*ind + 2] = ringPos[RING_POS_NUM / 2 - 1].y;
    ind++;
    ringVertices2[3*ind + 0] = ringPos[RING_POS_NUM / 2 - 1].x;
    ringVertices2[3*ind + 1] = RING_SIZE;
    ringVertices2[3*ind + 2] = ringPos[RING_POS_NUM / 2 - 1].y;

    ind = 0;
    for (int i = RING_POS_NUM / 2 + 1;  i <= RING_POS_NUM - 1; i++) {
      ringVertices3[3*ind + 0] = ringPos[i].x;
      ringVertices3[3*ind + 1] = RING_SIZE;
      ringVertices3[3*ind + 2] = ringPos[i].y;
      ind++;
    }
    for (int i = RING_POS_NUM - 1; i >= RING_POS_NUM / 2 + 1; i--) {
      ringVertices3[3*ind + 0] = ringPos[i].x;
      ringVertices3[3*ind + 1] = -RING_SIZE;
      ringVertices3[3*ind + 2] = ringPos[i].y;
      ind++;
    }
  }

  public static void prepareField() {
    float d = -RING_DEG * (cast(float) (RING_POS_NUM / 2) - 0.5);
    for (int i = 0; i < RING_POS_NUM; i++, d += RING_DEG) {
      ringPos[i] = new Vector;
      ringPos[i].x = sin(d) * RING_RADIUS;
      ringPos[i].y = cos(d) * RING_RADIUS;
    }
    prepareOneRing();
  }

}
