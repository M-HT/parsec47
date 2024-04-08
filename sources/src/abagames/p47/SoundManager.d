/*
 * $Id: SoundManager.d,v 1.3 2004/01/01 11:26:42 kenta Exp $
 *
 * Copyright 2003 Kenta Cho. All rights reserved.
 */
module abagames.p47.SoundManager;

private:
import abagames.util.sdl.Sound;
import abagames.p47.P47GameManager;

/**
 * Manage BGMs/SEs.
 */
public class SoundManager {
 public static:
  enum {
    SHOT, ROLL_CHARGE, ROLL_RELEASE, SHIP_DESTROYED, GET_BONUS, EXTEND,
    ENEMY_DESTROYED, LARGE_ENEMY_DESTROYED, BOSS_DESTROYED, LOCK, LASER,
  }
  const int BGM_NUM = 4;
  const int SE_NUM = 11;

 private static:
  P47GameManager manager;
  Sound[BGM_NUM] bgm;
  Sound[SE_NUM] se;

  const char[][] bgmFileName =
    ["ptn0.ogg", "ptn1.ogg", "ptn2.ogg", "ptn3.ogg"];
  const char[][] seFileName =
    ["shot.wav", "rollchg.wav", "rollrls.wav", "shipdst.wav", "getbonus.wav", "extend.wav",
    "enemydst.wav", "largedst.wav", "bossdst.wav", "lock.wav", "laser.wav"];
  const int[] seChannel =
    [0, 1, 2, 1, 3, 4,
    5, 6, 7, 1, 2];

  public static void init(P47GameManager mng) {
    manager = mng;
    if (Sound.noSound)
      return;
    for (int i = 0; i < bgm.length; i++) {
      bgm[i] = new Sound;
      bgm[i].loadSound(bgmFileName[i]);
    }
    for (int i = 0; i < se.length; i++) {
      se[i] = new Sound;
      se[i].loadChunk(seFileName[i], seChannel[i]);
    }
  }

  public static void close() {
    if (Sound.noSound)
      return;
    for (int i = 0; i < bgm.length; i++)
      bgm[i].free();
    for (int i = 0; i < se.length; i++)
      se[i].free();
  }

  public static void playBgm(int n) {
    if (Sound.noSound || manager.state != P47GameManager.IN_GAME)
      return;
    bgm[n].playMusic();
  }

  public static void playSe(int n) {
    if (Sound.noSound || manager.state != P47GameManager.IN_GAME)
      return;
    se[n].playChunk();
  }

  public static void stopSe(int n) {
    if (Sound.noSound)
      return;
    se[n].haltChunk();
  }
}
