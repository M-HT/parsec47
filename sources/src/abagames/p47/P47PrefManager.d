/*
 * $Id: P47PrefManager.d,v 1.2 2004/01/01 11:26:42 kenta Exp $
 *
 * Copyright 2003 Kenta Cho. All rights reserved.
 */
module abagames.p47.P47PrefManager;

private:
import std.stream;
import abagames.util.PrefManager;

/**
 * Save/Load the high score.
 */
public class P47PrefManager: PrefManager {
 public:
  static const int PREV_VERSION_NUM = 10;
  static const int VERSION_NUM = 20;
  static const char[] PREF_FILE = "p47.prf";
  static const int MODE_NUM = 2;
  static const int DIFFICULTY_NUM = 4;
  static const int REACHED_PARSEC_SLOT_NUM = 10;
  int hiScore[MODE_NUM][DIFFICULTY_NUM][REACHED_PARSEC_SLOT_NUM];
  int reachedParsec[MODE_NUM][DIFFICULTY_NUM];
  int selectedDifficulty, selectedParsecSlot, selectedMode;

  private void init() {
    for (int k = 0; k < MODE_NUM; k++) {
      for (int i = 0; i < DIFFICULTY_NUM; i++) {
	reachedParsec[k][i] = 0;
	for (int j = 0; j < REACHED_PARSEC_SLOT_NUM; j++) {
	  hiScore[k][i][j] = 0;
	}
      }
    }
    selectedDifficulty = 1;
    selectedParsecSlot = 0;
    selectedMode = 0;
  }

  private void loadPrevVersionData(File fd) {
    for (int i = 0; i < DIFFICULTY_NUM; i++) {
      fd.read(reachedParsec[0][i]);
      for (int j = 0; j < REACHED_PARSEC_SLOT_NUM; j++) {
	fd.read(hiScore[0][i][j]);
      }
    }
    fd.read(selectedDifficulty);
    fd.read(selectedParsecSlot);
  }

  public void load() {
    auto File fd = new File;
    try {
      int ver;
      fd.open(PREF_FILE);
      fd.read(ver);
      if (ver == PREV_VERSION_NUM) {
	init();
	loadPrevVersionData(fd);
	fd.close();
	return;
      } else if (ver != VERSION_NUM) {
	throw new Error("Wrong version num");
      }
      for (int k = 0; k < MODE_NUM; k++) {
	for (int i = 0; i < DIFFICULTY_NUM; i++) {
	  fd.read(reachedParsec[k][i]);
	  for (int j = 0; j < REACHED_PARSEC_SLOT_NUM; j++) {
	    fd.read(hiScore[k][i][j]);
	  }
	}
      }
      fd.read(selectedDifficulty);
      fd.read(selectedParsecSlot);
      fd.read(selectedMode);
    } catch (Error e) {
      init();
    } finally {
      fd.close();
    }
  }

  public void save() {
    auto File fd = new File;
    fd.create(PREF_FILE);
    fd.write(VERSION_NUM);
    for (int k = 0; k < MODE_NUM; k++) {
      for (int i = 0; i < DIFFICULTY_NUM; i++) {
	fd.write(reachedParsec[k][i]);
	for (int j = 0; j < REACHED_PARSEC_SLOT_NUM; j++) {
	  fd.write(hiScore[k][i][j]);
	}
      }
    }
    fd.write(selectedDifficulty);
    fd.write(selectedParsecSlot);
    fd.write(selectedMode);
    fd.close();
  }
}
