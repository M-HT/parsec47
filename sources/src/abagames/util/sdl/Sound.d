/*
 * $Id: Sound.d,v 1.2 2004/01/01 11:26:43 kenta Exp $
 *
 * Copyright 2003 Kenta Cho. All rights reserved.
 */
module abagames.util.sdl.Sound;

private:
import std.string;
import std.conv;
import bindbc.sdl;
import abagames.util.sdl.SDLInitFailedException;

/**
 * BGM/SE.
 */
public class Sound {
 public:
  static bool noSound = false;
  static int fadeOutSpeed = 1280;
  static string soundsDir = "sounds/";
  static string chunksDir = "sounds/";

  public static void init() {
    if (noSound) return;

    int audio_rate;
    ushort audio_format;
    int audio_channels;
    int audio_buffers;

    if (SDL_InitSubSystem(SDL_INIT_AUDIO) < 0) {
      noSound = 1;
      throw new SDLInitFailedException
	("Unable to initialize SDL_AUDIO: " ~ to!string(SDL_GetError()));
    }

    audio_rate = 44100;
    audio_format = AUDIO_S16;
    audio_channels = 1;
    audio_buffers = 4096;
    bool sound_opened = false;
    static if (SDL_MIXER_VERSION_ATLEAST(2, 0, 2)) {
      const SDL_version *link_version = Mix_Linked_Version();
      if (SDL_version(link_version.major, link_version.minor, link_version.patch) >= SDL_version(2, 0, 2)) {
        sound_opened = true;
        if (Mix_OpenAudioDevice(audio_rate, audio_format, audio_channels, audio_buffers, null, 0xff) < 0) {
          noSound = 1;
          throw new SDLInitFailedException
            ("Couldn't open audio: " ~ to!string(SDL_GetError()));
        }
      }
    }
    if (!sound_opened) {
      if (Mix_OpenAudio(audio_rate, audio_format, audio_channels, audio_buffers) < 0) {
        noSound = 1;
        throw new SDLInitFailedException
          ("Couldn't open audio: " ~ to!string(SDL_GetError()));
      }
    }
    Mix_QuerySpec(&audio_rate, &audio_format, &audio_channels);
  }

  public static void close() {
    if (noSound) return;
    if (Mix_PlayingMusic()) {
      Mix_HaltMusic();
    }
    Mix_CloseAudio();
  }

 protected:
  Mix_Music* music;
  Mix_Chunk* chunk;
  int chunkChannel;

 private:

  // Load a sound or a chunk.

  public void loadSound(const char[] name) {
    if (noSound) return;
    const char[] fileName = soundsDir ~ name;
    music = Mix_LoadMUS(std.string.toStringz(fileName));
    if (!music) {
      noSound = true;
      throw new SDLInitFailedException("Couldn't load: " ~ fileName ~
				       " (" ~ to!string(Mix_GetError()) ~ ")");
    }
  }

  public void loadChunk(const char[] name, int ch) {
    if (noSound) return;
    const char[] fileName = chunksDir ~ name;
    chunk = Mix_LoadWAV(std.string.toStringz(fileName));
    if (!chunk) {
      noSound = true;
      throw new SDLInitFailedException("Couldn't load: " ~ fileName ~
				       " (" ~ to!string(Mix_GetError()) ~ ")");
    }
    chunkChannel = ch;
  }

  // Free a music or a chunk.
  public void free() {
    if (music) {
      stopMusic();
      Mix_FreeMusic(music);
    }
    if (chunk) {
      haltChunk();
      Mix_FreeChunk(chunk);
    }
  }

  // Play/Stop the music/chunk.

  public void playMusic() {
    if (noSound) return;
    Mix_PlayMusic(music, -1);
  }

  public static void fadeMusic() {
    if (noSound) return;
    Mix_FadeOutMusic(fadeOutSpeed);
  }

  public static void stopMusic() {
    if (noSound) return;
    if ( Mix_PlayingMusic() ) {
      Mix_HaltMusic();
    }
  }

  public void playChunk() {
    if (noSound) return;
    Mix_PlayChannel(chunkChannel, chunk, 0);
  }

  public void haltChunk() {
    if (noSound) return;
    Mix_HaltChannel(chunkChannel);
  }
}
