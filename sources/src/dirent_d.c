#ifdef WINDOWS

#include <windows.h>

#include <stdio.h>
#include <malloc.h>

typedef struct {
	HANDLE h;
	char* prev;
} DIR;

DIR* opendir(const char* dir) {
	WIN32_FIND_DATA fd;
	HANDLE h;
	DIR* d;
	char buf[MAX_PATH];

	sprintf(buf, "%s/*", dir);
	h = FindFirstFileA(buf, &fd);
	d = (DIR*)malloc(sizeof(DIR));
	d->h = h;
	d->prev = 0;
	return d;
}

char* readdir_filename(DIR* d) {
	WIN32_FIND_DATA fd;
	BOOL ret = FindNextFileA(d->h, &fd);
	if (ret) {
		if (d->prev != 0) free(d->prev);
		d->prev = malloc(sizeof(char) * strlen(fd.cFileName));
		strcpy(d->prev, fd.cFileName);
		return d->prev;
	}
	else {
		return NULL;
	}
}

int closedir(DIR* d) {
	FindClose(d->h);
	free(d->prev);
	free(d);
}

#else // ! WINDOWS

#include "dirent.h"
#include "unistd.h"

char* readdir_filename(DIR* dir) {
	struct dirent* ent = readdir(dir);
	if (ent == NULL) return NULL;
	else return ent->d_name;
}

#endif // WINDOWS

