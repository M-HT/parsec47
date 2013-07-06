/*
 * $Id: P47PrefManager.d,v 1.2 2004/01/01 11:26:42 kenta Exp $
 *
 * Copyright 2003 Kenta Cho. All rights reserved.
 */
module abagames.p47.P47PrefManager;

private:
import std.stdio;
import abagames.util.PrefManager;

/**
 * Save/Load the high score.
 */
public class P47PrefManager: PrefManager {
 public:
  static const int PREV_VERSION_NUM = 10;
  static const int VERSION_NUM = 20;
  static string PREF_FILE = "p47.prf";
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
    int read_data[1];
    for (int i = 0; i < DIFFICULTY_NUM; i++) {
      fd.rawRead(read_data);
      reachedParsec[0][i] = read_data[0];
      fd.rawRead(hiScore[0][i]);
    }
    int read_data2[2];
    fd.rawRead(read_data2);
    selectedDifficulty = read_data2[0];
    selectedParsecSlot = read_data2[1];
  }

  public override void load() {
    scope File fd;
    try {
      int read_data[1];
      fd.open(PREF_FILE);
      fd.rawRead(read_data);
      if (read_data[0] == PREV_VERSION_NUM) {
	init();
	loadPrevVersionData(fd);
	fd.close();
	return;
      } else if (read_data[0] != VERSION_NUM) {
	throw new Exception("Wrong version num");
      }
      for (int k = 0; k < MODE_NUM; k++) {
	for (int i = 0; i < DIFFICULTY_NUM; i++) {
	  fd.rawRead(read_data);
	  reachedParsec[k][i] = read_data[0];
	  fd.rawRead(hiScore[k][i]);
	}
      }
      int read_data2[3];
      fd.rawRead(read_data2);
      selectedDifficulty = read_data2[0];
      selectedParsecSlot = read_data2[1];
      selectedMode = read_data2[2];
    } catch (Exception e) {
      init();
    } finally {
      fd.close();
    }
  }

  public override void save() {
    scope File fd;
    try {
      fd.open(PREF_FILE, "wb");
      int write_data[1] = [VERSION_NUM];
      fd.rawWrite(write_data);
      for (int k = 0; k < MODE_NUM; k++) {
        for (int i = 0; i < DIFFICULTY_NUM; i++) {
          write_data[0] = reachedParsec[k][i];
          fd.rawWrite(write_data);
          fd.rawWrite(hiScore[k][i]);
        }
      }
      const int write_data2[3] = [selectedDifficulty, selectedParsecSlot, selectedMode];
      fd.rawWrite(write_data2);
    } finally {
      fd.close();
    }
  }
}
