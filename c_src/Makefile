# Build maze_core for the M1 C ↔ Godot bridge.
#
# Output lives at the project root (one level up from c_src/) so the
# Godot MazeBridge can resolve it via res://../maze_core.
#
# Targets:
#   make            - build for current platform
#   make clean      - remove the binary
#
# Notes:
#   - On macOS / Linux the binary is named "maze_core".
#   - On Windows (MinGW / MSYS2 / Cygwin) it is "maze_core.exe".
#   - No external deps; pure C99 + libc.

CC      ?= cc
CFLAGS  ?= -O2 -std=c99 -Wall -Wextra -Wpedantic
SRC     := maze_core.c

ifeq ($(OS),Windows_NT)
    BIN := ../maze_core.exe
else
    BIN := ../maze_core
endif

.PHONY: all clean
all: $(BIN)

$(BIN): $(SRC)
	$(CC) $(CFLAGS) -o $@ $<

clean:
	rm -f ../maze_core ../maze_core.exe
