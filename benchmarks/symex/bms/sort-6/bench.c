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
#define SIZE 6
#endif

int main() {
  // Create array of symbolic values
  int *a = (int *) malloc(SIZE * sizeof(int));
  int check;
#ifdef KLEE
  klee_make_symbolic(a, SIZE * sizeof(int), "a");
  klee_make_symbolic(&check, sizeof(check), "check");
#else
  for (int i = 0; i < SIZE; ++i) {
    a[i] = symexec_new_int();
  }
  check = symexec_new_int();
#endif
  if (check) {
    // Sort array
    for (int i = 0; i < SIZE - 1; ++i) {
      int idx = i;
      int min = a[i];
      for (int j = i + 1; j < SIZE; ++j) {
        int x = a[j];
        if (x < min) {
          idx = j;
          min = x;
        }
      }
      a[idx] = a[i];
      a[i] = min;
    }
    // Assert that array is now sorted
    for (int i = 0; i < SIZE - 1; ++i) {
      symexec_assert(a[i] <= a[i + 1]);
    }
  } else {
    // Sort array
    for (int i = 0; i < SIZE - 1; ++i) {
      int idx = i;
      int min = a[i];
      for (int j = i + 1; j < SIZE; ++j) {
        int x = a[j];
        if (x < min) {
          idx = j;
          min = x;
        }
      }
      a[idx] = a[i];
      a[i] = min;
    }
  }
  return 0;
}
