/*
 * $Id: BulletsManager.d,v 1.2 2004/01/01 11:26:43 kenta Exp $
 *
 * Copyright 2003 Kenta Cho. All rights reserved.
 */
module abagames.util.bulletml.BulletsManager;

private:
import bulletml;
import abagames.util.bulletml.Bullet;

/**
 * Interface for bullet's instances manager.
 */
public interface BulletsManager {
  public void addBullet(float deg, float speed);
  public void addBullet(BulletMLState *state, float deg, float speed);
  public int getTurn();
  public void killMe(Bullet bullet);
}

