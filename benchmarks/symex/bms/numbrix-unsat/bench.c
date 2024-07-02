#ifdef KLEE
#include <assert.h>
#include <klee/klee.h>
#define symexec_assume(x) klee_assume(x)
#define symexec_assert(x) assert(x)

#elif CBMC
#include <assert.h>
#define symexec_assume(x) __CPROVER_assume(x)
#define symexec_assert(x) assert(x)
int symexec_new_int();

#else // Formulog
#include <symexec.h>
#endif

#define SIZE 4
#define MAX (SIZE * SIZE)
#define select(g, i, j) g[SIZE * (i) + (j)]
#define initialize_grid(g) do {\
  select(g, 1, 1) = 1;\
  select(g, 1, 2) = 16;\
  select(g, 2, 1) = 6;\
  select(g, 3, 3) = 9;\
} while (0)

int main() {
  int grid[MAX];
#ifdef KLEE
  klee_make_symbolic(grid, sizeof(grid), "grid");
#endif
  int cnt[MAX];
  for (int i = 0; i < MAX; ++i) {
#ifndef KLEE
    grid[i] = symexec_new_int();
#endif
    cnt[i] = 0;
  }
  initialize_grid(grid);
  for (int i = 0; i < SIZE; ++i) {
    for (int j = 0; j < SIZE; ++j) {
      int val = select(grid, i, j);
      symexec_assume(val >= 1 && val <= MAX);
      int ok = 0;
      if (i > 0) {
        ok += val == select(grid, i - 1, j) + 1;
      }
      if (i < SIZE - 1) {
        ok += val == select(grid, i + 1, j) + 1;
      }
      if (j > 0) {
        ok += val == select(grid, i, j - 1) + 1;
      }
      if (j < SIZE - 1) {
        ok += val == select(grid, i, j + 1) + 1;
      }
      ok += val == 1;
      symexec_assume(ok == 1);
      cnt[val - 1]++;
      symexec_assume(cnt[val - 1] == 1);
    }
  }
  // Force analyses to see if this is reachable
  symexec_assert(0);
  return 0;
}
