// Modern version of Fisher-Yates shuffle algorithm

#include <stdlib.h>

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

#ifndef SIZE
#define SIZE 4
#endif

int main() {
  int *a = (int *) malloc(SIZE * sizeof(int));
#ifdef KLEE
  klee_make_symbolic(a, SIZE * sizeof(int), "a"); 
#endif
  int *b = (int *) malloc(SIZE * sizeof(int));
  for (int i = 0; i < SIZE; ++i) {
#ifndef KLEE
    a[i] = symexec_new_int();
#endif
    b[i] = a[i];
  }
  for (int i = SIZE - 1; i >= 1; --i) {
    int j;
#ifdef KLEE
    klee_make_symbolic(&j, sizeof(j), "j");
#else
    j = symexec_new_int();
#endif
    symexec_assume(0 <= j && j <= i);
    int tmp = a[i];
    a[i] = a[j];
    a[j] = tmp;
  }
  for (int i = 0; i < SIZE; ++i) {
    int ok = 0;
    for (int j = 0; j < SIZE; ++j) {
      if (b[i] == a[j]) {
        ok = 1;
        break;
      }
    }
    symexec_assert(ok);
  }
  return 0;
}
