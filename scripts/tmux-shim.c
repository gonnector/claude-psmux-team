/*
 * tmux.exe shim for psmux v0.4.10+
 *
 * Claude Code calls spawn('tmux', ...) which on Windows only finds .exe files.
 * This tiny executable intercepts "tmux -V" to return a version string that
 * passes Claude Code's version check (requires 2+), then delegates everything
 * else to tmux-real.exe (psmux v0.4.10 in tmux-compatible mode).
 *
 * Build:  gcc -O2 -o tmux.exe tmux-shim.c
 * Install: copy tmux.exe to %USERPROFILE%\.cargo\bin\
 */
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <process.h>

int main(int argc, char *argv[]) {
    /* Intercept: tmux -V */
    if (argc == 2 && strcmp(argv[1], "-V") == 0) {
        puts("tmux 3.4");
        return 0;
    }

    /* Pass everything else to tmux-real.exe (psmux v0.4.10) */
    argv[0] = "tmux-real";
    return _spawnvp(_P_WAIT, "tmux-real", (const char *const *)argv);
}
