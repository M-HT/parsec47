/*
 * $Id: P47Bullet.d,v 1.2 2004/01/01 11:26:42 kenta Exp $
 *
 * Copyright 2003 Kenta Cho. All rights reserved.
 */
module abagames.p47.P47Bullet;

private:
import abagames.p47.MorphBullet;

/**
 * Bullet with params of sppedRank, shape, color, size and the vertical reverse moving.
 */
public class P47Bullet: MorphBullet {
 public:
  float speedRank;
  int shape, color;
  float bulletSize;
  float xReverse;

 private:

  public this(int id) {
    super(id);
  }

  public void setParam(float sr, int sh, int cl, float sz, float xr) {
    speedRank = sr;
    shape = sh;
    color = cl;
    bulletSize = sz;
    xReverse = xr;
  }
}
