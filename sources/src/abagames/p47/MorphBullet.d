/*
 * $Id: MorphBullet.d,v 1.2 2004/01/01 11:26:42 kenta Exp $
 *
 * Copyright 2003 Kenta Cho. All rights reserved.
 */
module abagames.p47.MorphBullet;

private:
import bulletml;
import abagames.util.bulletml.Bullet;

/**
 * Bullet with the bulletsmorph.
 */
public class MorphBullet: Bullet {
 public:
  static const int MORPH_MAX = 8;
  BulletMLParser *morphParser[MORPH_MAX];
  int morphNum;
  int morphIdx;
  int morphCnt;
  int baseMorphIdx;
  int baseMorphCnt;
  bool isMorph;

  public this(int id) {
    super(id);
  }

  public void setMorph(BulletMLParser *mrp[], int num, int idx, int cnt) {
    if (cnt <= 0) {
      isMorph = false;
      return;
    }
    isMorph = true;
    baseMorphCnt = morphCnt = cnt;
    morphNum = num;
    for (int i = 0; i < num; i++) {
      morphParser[i] = mrp[i];
    }
    morphIdx = idx;
    if (morphIdx >= morphNum)
      morphIdx = 0;
    baseMorphIdx = morphIdx;
  }

  public void resetMorph() {
    morphIdx = baseMorphIdx;
    morphCnt = baseMorphCnt;
  }
}
