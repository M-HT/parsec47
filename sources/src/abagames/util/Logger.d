/*
 * $Id: Logger.d,v 1.2 2004/01/01 11:26:43 kenta Exp $
 *
 * Copyright 2003 Kenta Cho. All rights reserved.
 */
module abagames.util.Logger;

private:
import std.stream;

/**
 * Logger(error/info).
 */
version(Win32_release) {

import std.string;
import std.c.windows.windows;

public class Logger {

  public static void info(char[] msg) {
    // Win32 exe file crashes if it writes something to stderr.
    //stderr.writeLine("Info: " ~ msg);
  }

  public static void info(int n) {
    /*if (n >= 0)
      stderr.writeLine("Info: " ~ std.string.toString(n));
    else
    stderr.writeLine("Info: -" ~ std.string.toString(-n));*/
  }

  private static void putMessage(char[] msg) {
    MessageBoxA(null, std.string.toStringz(msg), "Error", MB_OK | MB_ICONEXCLAMATION);
  }

  public static void error(char[] msg) {
    putMessage("Error: " ~ msg);
  }

  public static void error(Exception e) {
    putMessage("Error: " ~ e.toString());
  }

  public static void error(Error e) {
    putMessage("Error: " ~ e.toString());
  }
}

} else {

public class Logger {

  public static void info(char[] msg) {
    stderr.writeLine("Info: " ~ msg);
  }

  public static void info(int n) {
    if (n >= 0)
      stderr.writeLine("Info: " ~ std.string.toString(n));
    else
      stderr.writeLine("Info: -" ~ std.string.toString(-n));
  }

  public static void error(char[] msg) {
    stderr.writeLine("Error: " ~ msg);
  }

  public static void error(Exception e) {
    stderr.writeLine("Error: " ~ e.toString());
  }

  public static void error(Error e) {
    stderr.writeLine("Error: " ~ e.toString());
    if (e.next)
      error(e.next);
  }
}

}
