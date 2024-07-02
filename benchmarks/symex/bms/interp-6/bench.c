/*
 * An evaluator for a simple register machine. The commands are:
 *
 *  's' [dst_reg] [constant]  - store a constant into a register
 *  'j' [reg] [dst]           - jump if register is non-zero
 *  'a' [dst_reg] [reg] [reg] - compute and store addition
 *  'm' [dst_reg] [reg] [reg] -    "         "    multiplication
 *  'e' [dst_reg] [reg] [reg] -    "         "    equality
 *  'l' [dst_reg] [reg] [reg] -    "         "    less-than
 */

#include <stdlib.h>

#ifdef SYMEXEC
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
#else
#include <stdio.h>
#include <assert.h>
#define symexec_new_int() getchar()
#define symexec_assert(x) assert(x)
#endif

#ifndef SIZE
#define SIZE 12
#endif

#ifndef NSTEPS
#define NSTEPS 6
#endif

#ifndef NREGS
#define NREGS 5
#endif

#define check_bounds(idx, size) do { if ((idx) < 0 || (idx) >= (size)) goto DONE; } while(0);

int main() {
  int *a = (int *) malloc(SIZE * sizeof(int));
#ifdef KLEE
  klee_make_symbolic(a, SIZE * sizeof(int), "a");
#else
  for (int i = 0; i < SIZE; ++i) {
    a[i] = symexec_new_int();
  }
#endif
#ifndef SYMEXEC
  for (int i = 0; i < SIZE; ++i) {
    printf("%d\t", a[i]);
  }
  printf("\n");
#endif
  int *regs = (int *) malloc(NREGS * sizeof(int));
  for (int i = 0; i < NREGS; ++i) {
    regs[i] = 0;
  }
  int pos = 0;
  for (int i = 0; i < NSTEPS; ++i) {
    check_bounds(pos, SIZE);
    int cmd = a[pos];
    int v1;
    int v2;
    int v3;
    int ok = 0;
    int is_unary = cmd == 's' || cmd == 'j';
    int is_binary = cmd == 'a' || cmd == 'm' || cmd == 'e' || cmd == 'l';
    if (is_unary || is_binary) {
      check_bounds(pos + 2, SIZE);
      v1 = a[pos + 1];
      v2 = a[pos + 2];
      ok = 1;
    }
    if (is_binary) {
      check_bounds(pos + 3, SIZE);
      v3 = a[pos + 3];
      ok = 1;
    }
    if (!is_unary && !is_binary) {
      goto DONE;
    }

    check_bounds(v1, NREGS);
    if (cmd == 's') {
      regs[v1] = v2;
      pos += 3;
    } else if (cmd == 'j') {
      if (regs[v1] != 0) {
        pos = v2;
      } else {
        pos += 3;
      }
    } else {
      check_bounds(v2, NREGS);
      check_bounds(v3, NREGS);
      int r2 = regs[v2];
      int r3 = regs[v3];
      int res;
      if (cmd == 'a') {
        res = r2 + r3;
      } else if (cmd == 'm') {
        res = r2 * r3;
      } else if (cmd == 'e') {
        res = r2 == r3;
      } else if (cmd == 'l') {
        res = r2 < r3;
      } else {
        symexec_assert(0); // unreachable
      }
      regs[v1] = res;
      pos += 4;
    }
  }
DONE:
#ifndef SYMEXEC
  for (int i = 0; i < NREGS; ++i) {
    printf("%d: %d\n", i, regs[i]);
  }
#endif
  return 0;
}
