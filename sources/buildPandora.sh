#!/bin/sh

FLAGS="-fversion=USE_GLES -fversion=PANDORA -frelease -c -O2 -pipe"

rm EGLPort/*.o*
rm import/*.o*
rm src/*.o*
rm src/abagames/util/*.o*
rm src/abagames/util/bulletml/*.o*
rm src/abagames/util/sdl/*.o*
rm src/abagames/p47/*.o*

cd EGLPort
$PNDSDK/bin/pandora-gcc -c -O2 -DPANDORA -DUSE_EGL_SDL -DUSE_GLES1 -I$PNDSDK/usr/include -I$PNDSDK/usr/include/SDL eglport.c
cd ..

cd import
$PNDSDK/bin/pandora-gdc $FLAGS *.d
rm opengl.o* openglu.o*
cd ..

cd src
$PNDSDK/bin/pandora-gcc -c -O2 dirent_d.c
$PNDSDK/bin/pandora-gdc $FLAGS *.d
cd ..

cd src/abagames/util
$PNDSDK/bin/pandora-gdc $FLAGS -I../../../import -I../.. *.d
cd ../../..

cd src/abagames/util/bulletml
$PNDSDK/bin/pandora-gdc $FLAGS -I../../../../import -I../../.. *.d
cd ../../../..

cd src/abagames/util/sdl
$PNDSDK/bin/pandora-gdc $FLAGS -I../../../../import -I../../.. *.d
cd ../../../..

cd src/abagames/p47
$PNDSDK/bin/pandora-gdc $FLAGS -I../../../import -I../.. *.d
cd ../../..

#$PNDSDK/bin/pandora-gdc -o PARSEC47 -s -Wl,-rpath-link,$PNDSDK/usr/lib -L$PNDSDK/usr/lib -lGLES_CM -lSDL_mixer -lmad -lSDL -lts -lEGL EGLPort/*.o* import/*.o* src/*.o* src/abagames/util/*.o* src/abagames/util/bulletml/*.o* src/abagames/util/sdl/*.o* src/abagames/p47/*.o* lib/arm/libbulletml_d.a
$PNDSDK/bin/pandora-gdc -o PARSEC47 -s -Wl,-rpath-link,$PNDSDK/usr/lib -L$PNDSDK/usr/lib -lGLES_CM -lSDL_mixer -lmad -lSDL -lts -lEGL -lbulletml_d -L./lib/arm EGLPort/*.o* import/*.o* src/*.o* src/abagames/util/*.o* src/abagames/util/bulletml/*.o* src/abagames/util/sdl/*.o* src/abagames/p47/*.o*
