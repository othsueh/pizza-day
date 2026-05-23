/*
 * maze_core — Unbounded Vision M1 pipeline
 *
 * Generates a random maze using recursive backtracker (DFS) and writes
 * the state to a JSON file consumed by the Godot MazeBridge.
 *
 * Usage:
 *   maze_core [output_path] [seed]
 *
 * Defaults: output_path = "maze_state.json" (cwd), seed = time(NULL).
 *
 * Grid dimensions are fixed at the R1 starting size from docs/style-bible.md §4
 * (initial 20x15 → using 21x15 to keep the odd-dim DFS carve clean).
 *
 * JSON schema (v1):
 *   {
 *     "version": 1,
 *     "width":  <int>,
 *     "height": <int>,
 *     "seed":   <uint>,
 *     "tiles":  [[<int>, ...], ...]   // 0 = floor, 1 = wall, row-major
 *   }
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#define MAZE_W 21
#define MAZE_H 15
#define CELL_W ((MAZE_W - 1) / 2)
#define CELL_H ((MAZE_H - 1) / 2)

#define TILE_FLOOR 0
#define TILE_WALL  1

static int grid[MAZE_H][MAZE_W];

static const int DX[4] = { 0,  0,  1, -1};
static const int DY[4] = { 1, -1,  0,  0};

static void carve(int cx, int cy) {
    int order[4] = {0, 1, 2, 3};
    for (int i = 3; i > 0; --i) {
        int j = rand() % (i + 1);
        int tmp = order[i];
        order[i] = order[j];
        order[j] = tmp;
    }

    int x = cx * 2 + 1;
    int y = cy * 2 + 1;
    grid[y][x] = TILE_FLOOR;

    for (int i = 0; i < 4; ++i) {
        int d = order[i];
        int ncx = cx + DX[d];
        int ncy = cy + DY[d];
        if (ncx < 0 || ncx >= CELL_W || ncy < 0 || ncy >= CELL_H) continue;

        int nx = ncx * 2 + 1;
        int ny = ncy * 2 + 1;
        if (grid[ny][nx] == TILE_FLOOR) continue;

        grid[(y + ny) / 2][(x + nx) / 2] = TILE_FLOOR;
        carve(ncx, ncy);
    }
}

static int write_json(const char *path, unsigned int seed) {
    FILE *f = fopen(path, "w");
    if (!f) {
        fprintf(stderr, "maze_core: cannot open %s for writing\n", path);
        return 1;
    }

    fprintf(f,
        "{\n"
        "  \"version\": 1,\n"
        "  \"width\": %d,\n"
        "  \"height\": %d,\n"
        "  \"seed\": %u,\n"
        "  \"tiles\": [\n",
        MAZE_W, MAZE_H, seed);

    for (int y = 0; y < MAZE_H; ++y) {
        fprintf(f, "    [");
        for (int x = 0; x < MAZE_W; ++x) {
            fprintf(f, "%d", grid[y][x]);
            if (x != MAZE_W - 1) fputc(',', f);
        }
        fputc(']', f);
        if (y != MAZE_H - 1) fputc(',', f);
        fputc('\n', f);
    }

    fprintf(f, "  ]\n}\n");
    fclose(f);
    return 0;
}

int main(int argc, char **argv) {
    const char *out_path = (argc > 1) ? argv[1] : "maze_state.json";

    unsigned int seed;
    if (argc > 2) {
        seed = (unsigned int)strtoul(argv[2], NULL, 10);
    } else {
        seed = (unsigned int)time(NULL);
    }
    srand(seed);

    for (int y = 0; y < MAZE_H; ++y) {
        for (int x = 0; x < MAZE_W; ++x) {
            grid[y][x] = TILE_WALL;
        }
    }

    carve(0, 0);

    return write_json(out_path, seed);
}
