/*
 * $Id: Rand.d,v 1.2 2004/01/01 11:26:43 kenta Exp $
 *
 * Copyright 2003 Kenta Cho. All rights reserved.
 */
module abagames.util.Rand;

private:
import std.date;
import mt;

/**
 * Random number generator.
 */
public class Rand {
  
  public this() {
    d_time timer = getUTCtime();
    init_genrand(timer);
  }

  public void setSeed(long n) {
    init_genrand(n);
  }

  public int nextInt(int n) {
    return genrand_int32() % n;
  }

  public int nextSignedInt(int n) {
    return genrand_int32() % (n * 2) - n;
  }

  public float nextFloat(float n) {
    return genrand_real1() * n;
  }

  public float nextSignedFloat(float n) {
    return genrand_real1() * (n * 2) - n;
  }
}
