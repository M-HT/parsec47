#!/bin/sh

FLAGS="-frelease -fdata-sections -ffunction-sections -c -O2 -Wall -pipe -fversion=PYRA -fversion=BindSDL_Static -fversion=SDL_201 -fversion=SDL_Mixer_202 -I`pwd`/import"

rm import/*.o*
rm import/sdl/*.o*
rm import/bindbc/sdl/*.o*
rm src/*.o*
rm src/abagames/util/*.o*
rm src/abagames/util/bulletml/*.o*
rm src/abagames/util/sdl/*.o*
rm src/abagames/p47/*.o*

cd import
find . -maxdepth 1 -name \*.d -type f -exec gdc $FLAGS \{\} \;
cd sdl
find . -maxdepth 1 -name \*.d -type f -exec gdc $FLAGS \{\} \;
cd ../bindbc/sdl
find . -maxdepth 1 -name \*.d -type f -exec gdc $FLAGS \{\} \;
cd ../../..

cd src
gcc -c -O2 dirent_d.c
find . -maxdepth 1 -name \*.d -type f -exec gdc $FLAGS \{\} \;
cd ..

cd src/abagames/util
find . -maxdepth 1 -name \*.d -type f -exec gdc $FLAGS -I../.. \{\} \;
cd ../../..

cd src/abagames/util/bulletml
find . -maxdepth 1 -name \*.d -type f -exec gdc $FLAGS -I../../.. \{\} \;
cd ../../../..

cd src/abagames/util/sdl
find . -maxdepth 1 -name \*.d -type f -exec gdc $FLAGS -I../../.. \{\} \;
cd ../../../..

cd src/abagames/p47
find . -maxdepth 1 -name \*.d -type f -exec gdc $FLAGS -I../.. \{\} \;
cd ../../..

gdc -o PARSEC47 -s -Wl,--gc-sections -static-libphobos import/*.o* src/*.o* src/abagames/util/*.o* import/sdl/*.o* import/bindbc/sdl/*.o*  src/abagames/util/bulletml/*.o* src/abagames/util/sdl/*.o* src/abagames/p47/*.o* -lGL -lSDL2_mixer -lSDL2 -lbulletml_d -L./lib/armhf
