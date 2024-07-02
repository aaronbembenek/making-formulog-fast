#include <limits.h>
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

#define SIZE 5

__attribute__((always_inline))
static inline void swap(int i, int j, int *a) {
  int tmp = a[i];
  a[i] = a[j];
  a[j] = tmp;
}

__attribute__((always_inline))
static inline int *apq_empty() {
  int *a = (int *) malloc((SIZE + 1) * sizeof(int));
  a[SIZE] = 0;
  return a;
}

__attribute__((always_inline))
static inline void apq_add(int elt, int *apq) {
  int n = apq[SIZE];
  if (n >= SIZE) {
    return;
  }
  apq[SIZE]++;
  apq[n] = elt;
}

__attribute__((always_inline))
static inline int apq_extract_min(int *apq) {
  int n = apq[SIZE];
  if (n <= 0) {
    return -1;
  }
  apq[SIZE]--;
  int min_idx = -1;
  int min = INT_MAX;
  for (int i = 0; i < n; ++i) {
    if (apq[i] < min) {
      min_idx = i;
      min = apq[i];
    }
  }
  swap(min_idx, n - 1, apq);
  return min;
}

__attribute__((always_inline))
static inline int *hpq_empty() {
  int *a = (int *) malloc((SIZE + 1) * sizeof(int));
  a[SIZE] = 0;
  return a;
}

__attribute__((always_inline))
static inline int hpq_left(int idx) {
  return 2 * idx + 1;
}

__attribute__((always_inline))
static inline int hpq_right(int idx) {
  return 2 * (idx + 1);
}

__attribute__((always_inline))
static inline int hpq_parent(int idx) {
  return (idx - 1) / 2;
}

__attribute__((always_inline))
static inline void hpq_bubble_up(int idx, int *hpq) {
  int p = hpq_parent(idx);
  while (idx > 0 && hpq[idx] < hpq[p]) {
    swap(idx, p, hpq);
    idx = p;
    p = hpq_parent(idx);
  }
}

__attribute__((always_inline))
static inline void hpq_add(int elt, int *hpq) {
  int n = hpq[SIZE];
  if (n >= SIZE) {
    return;
  }
  hpq[SIZE]++;
  hpq[n] = elt;
  hpq_bubble_up(n, hpq);
}

__attribute__((always_inline))
static inline void hpq_trickle_down(int i, int *hpq) {
  int n = hpq[SIZE];
  while (i >= 0) {
    int j = -1;
    int r = hpq_right(i);
    if (r < n && hpq[r] < hpq[i]) {
      int l = hpq_left(i);
      if (hpq[l] < hpq[r]) {
        j = l;
      } else {
        j = r;
      }
    } else {
      int l = hpq_left(i);
      if (l < n && hpq[l] < hpq[i]) {
        j = l;
      }
    }
    if (j >= 0) {
      swap(i, j, hpq);
    }
    i = j;
  }
}

__attribute__((always_inline))
static inline int hpq_extract_min(int *hpq) {
  int n = hpq[SIZE];
  if (n <= 0) {
    return -1;
  }
  hpq[SIZE]--;
  int min = hpq[0];
  hpq[0] = hpq[n - 1];
  hpq_trickle_down(0, hpq);
  return min;
}

#ifndef SYMEXEC
void print_array(int *a, int size) {
  printf("[");
  for (int i = 0; i < size; ++i) {
    printf("%d", a[i]);
    if (i < size - 1) {
      printf(", ");
    }
  }
  printf("]\n");
}
#endif

int main() {
  int *apq = apq_empty();
  int *hpq = hpq_empty();
  for (int i = 0; i < SIZE; ++i) {
    int x;
#ifdef KLEE
    klee_make_symbolic(&x, sizeof(x), "x");
#else
    x = symexec_new_int();
#endif
    apq_add(x, apq);
    hpq_add(x, hpq);
  }
  symexec_assert(apq_extract_min(apq) == hpq_extract_min(hpq));
  int x;
#ifdef KLEE
  klee_make_symbolic(&x, sizeof(x), "x");
#else
  x = symexec_new_int();
#endif
  apq_add(x, apq);
  hpq_add(x, hpq);
  symexec_assert(apq_extract_min(apq) == hpq_extract_min(hpq));
  return 0;
}
