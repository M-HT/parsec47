/*
 * $Id: Particle.d,v 1.2 2004/01/01 11:26:42 kenta Exp $
 *
 * Copyright 2003 Kenta Cho. All rights reserved.
 */
module abagames.p47.Particle;

private:
import std.math;
version (USE_GLES) {
  import opengles;
} else {
  import opengl;
}
import abagames.util.Vector;
import abagames.util.Rand;
import abagames.util.Actor;
import abagames.util.ActorInitializer;
import abagames.util.sdl.Screen3D;
import abagames.p47.LuminousActor;
import abagames.p47.P47Screen;
import abagames.p47.LineDrawData;

/**
 * Particles.
 */
public class Particle: LuminousActor {
 public:
  static const float R = 1, G = 1, B = 0.5;
 private:
  static Rand rand;
  LineDrawData drawData;
  Vector pos, ppos;
  Vector vel;
  float z, mz, pz;
  float lumAlp;
  int cnt;

  public static this() {
    rand = new Rand;
  }

  public override Actor newActor() {
    return new Particle;
  }

  public override void init(ActorInitializer ini) {
    ParticleInitializer pi = cast(ParticleInitializer) ini;
    drawData = pi.drawData;
    pos = new Vector;
    ppos = new Vector;
    vel = new Vector;
  }

  public void set(Vector p, float d, float ofs, float speed) {
    if (ofs > 0) {
      pos.x = p.x + sin(d) * ofs;
      pos.y = p.y + cos(d) * ofs;
    } else {
      pos.x = p.x;
      pos.y = p.y;
    }
    z = 0;
    float sb = rand.nextFloat(0.5) + 0.75;
    vel.x = sin(d) * speed * sb;
    vel.y = cos(d) * speed * sb;
    mz = rand.nextSignedFloat(0.7);
    cnt = 12 + rand.nextInt(48);
    lumAlp = 0.8 + rand.nextFloat(0.2);
    isExist = true;
  }

  public override void move() {
    cnt--;
    if (cnt < 0) {
      isExist = false;
      return;
    }
    ppos.x = pos.x; ppos.y = pos.y; pz = z;
    pos.add(vel);
    vel.mul(0.98);
    z += mz;
    lumAlp *= 0.98;
  }

  public override void draw() {
    drawData.vertices ~= [
      ppos.x, ppos.y, pz,
      pos.x , pos.y , z
    ];
  }

  public override void drawLuminous() {
    if (lumAlp < 0.2) return;

    drawData.vertices ~= [
      ppos.x, ppos.y, pz,
      pos.x , pos.y , z
    ];
    drawData.colors ~= [
      R * Screen3D.brightness, G * Screen3D.brightness, B * Screen3D.brightness, lumAlp,
      R * Screen3D.brightness, G * Screen3D.brightness, B * Screen3D.brightness, lumAlp
    ];
  }
}

public class ParticleInitializer: ActorInitializer {
 public:
  LineDrawData drawData;

  public this(LineDrawData drawData) {
    this.drawData = drawData;
  }
}
