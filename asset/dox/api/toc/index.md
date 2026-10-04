# mulle-core-all-load Library Documentation for AI
<!-- Keywords: static-linking, all-load, atinit, atexit, stacktrace, force-link -->

## 1. Introduction & Purpose

- `mulle-core-all-load` is a **force-linkable amalgamation** (an "all-load"
  library). It compiles the *sources* of three independent
  initialization/utility libraries (`mulle-atinit`, `mulle-atexit`,
  `mulle-stacktrace`) into a single static library, so a consumer links only
  `-lmulle-core-all-load` instead of each constituent library separately.
- It solves the static-linking dead-code elimination problem: the amalgamated
  components register startup/exit callbacks and C-level constructor/destructor
  hooks that must reach the final binary *even when no symbol of the library is
  referenced directly*. Consumers must therefore force-link the archive
  (whole-archive / `-force_load` / `/WHOLEARCHIVE:`).
- Key features:
  - One public header `<mulle-core-all-load/mulle-core-all-load.h>` that
    re-exports the full public API of all three amalgamated libraries.
  - Version helpers for the amalgam, plus a sentinel macro
    (`HAVE_INCLUDE_MULLE__CORE__ALL__LOAD`) and version probe function to prove
    the library is present at link time.
  - CMake advertises the force-link requirement through an `INTERFACE` wrapper
    target for both `add_subdirectory()` and `find_package()` consumers (see
    `AllLoadSupport.cmake`); the option `MULLE_LIBRARY_FORCE_LINK` (default
    `ON`) controls it.
- Relationship: a foundational part of `mulle-core`. Each constituent library
  is itself a `mulle-core` project whose sources are vendored in via `clib`
  (`clibmode=hardlink`) under `src/<name>` and compiled directly into the
  amalgam. The amalgam also depends on `mulle-c11`, `mulle-allocator`,
  `mulle-thread`, `mulle-dlfcn`, and optionally `libbacktrace`.

## 2. Key Concepts & Design Philosophy

- **Amalgamation, not wrapper**: the constituents are *not* linked against;
  their `.c` files are compiled into `libmulle-core-all-load.a`. Consumers
  `#include <mulle-core-all-load/mulle-core-all-load.h>` and get the merged
  header set; individual headers remain available under their own namespaces
  (e.g. `<mulle-atinit/mulle-atinit.h>`, `<mulle-atexit/mulle-atexit.h>`,
  `<mulle-stacktrace/mulle-stacktrace.h>`).
- **Force-link requirement**: because the value of the library is in
  side-effecting constructors, the linker must be told to keep every object
  file. A plain static archive needs `--whole-archive` (ELF), `-force_load`
  (macOS) or `/WHOLEARCHIVE:` (MSVC). When consumed via CMake
  (`add_subdirectory()` or `find_package()`) the target carries these as
  `INTERFACE` link options automatically. Plain C projects that do not rely on
  load-time constructors can set `MULLE_LIBRARY_FORCE_LINK=OFF`.
- **Startup ordering as a solved problem**: `mulle-atinit` provides
  deterministic, priority-ordered initialization callbacks (a stable mergesort
  runs at startup; a higher numeric `priority` executes first). `mulle-atexit`
  provides LIFO exit callbacks that survive static linking and shared-library
  unloading.
- **Backend-selectable stacktracing**: `mulle-stacktrace` chooses a backend at
  compile time (`libbacktrace`, `execinfo`, or `NONE`) and abstracts it behind
  `struct mulle_stacktrace` with pluggable symbolizer/trimmer hooks.
- The amalgam stays **static-only**: `mulle-atinit` and `mulle-atexit`
  deliberately `#error` when `MULLE_INCLUDE_DYNAMIC` is set — they are designed
  to live in the executable's "load domain" (`main()`), not in a shared library.

## 3. Core API & Data Structures

All signatures below are copied verbatim from the public headers.

### 3.1. `mulle-core-all-load.h` (amalgam header)

Includes, in order: `"include.h"`, `<stdint.h>`, then the three constituent
headers `<mulle-atinit/mulle-atinit.h>`, `<mulle-atexit/mulle-atexit.h>`,
`<mulle-stacktrace/mulle-stacktrace.h>`; finally the optional
`_mulle-core-all-load-versioncheck.h` if present.

```c
#define MULLE__CORE__ALL__LOAD_VERSION  ((0UL << 20) | (9 << 8) | 0)

static inline unsigned int   mulle_core_all_load_get_version_major( void)
static inline unsigned int   mulle_core_all_load_get_version_minor( void)
static inline unsigned int   mulle_core_all_load_get_version_patch( void)

uint32_t   mulle_core_all_load_get_version( void);
```

- **Purpose:** the single entry point for consumers; re-exports the amalgam's
  own version API plus the entire public API of the three constituents.
- `MULLE__CORE__ALL__LOAD_VERSION` — packed version `major<<20 | minor<<8 |
  patch`. Current value: 0.9.0.
- `mulle_core_all_load_get_version_major/minor/patch( void)` — `static inline`
  accessors returning `unsigned int` components.
- `mulle_core_all_load_get_version( void)` — returns the packed version as
  `uint32_t`. This is a real (non-inline) function, useful as a probe that the
  library is linked.

`include.h` defines the sentinel macro
`HAVE_INCLUDE_MULLE__CORE__ALL__LOAD` and forces
`MULLE__CORE__ALL__LOAD_GLOBAL extern` with the comment "core-all-load is
always statically linked!". The generated
`_mulle-core-all-load-include.h` pulls in `<mulle-c11/mulle-c11.h>`,
`<mulle-allocator/mulle-allocator.h>`, `<mulle-thread/mulle-thread.h>` and
`<mulle-dlfcn/mulle-dlfcn.h>`.

### 3.2. `mulle-atinit.h` (amalgamated: priority-ordered init callbacks)

- **Purpose:** register `void (*f)( void *)` callbacks that run during program
  startup, in deterministic priority order.

#### Version helpers
```c
#define MULLE__ATINIT_VERSION  ((0UL << 20) | (3 << 8) | 3)

static inline unsigned int   mulle_atinit_get_version_major( void)
static inline unsigned int   mulle_atinit_get_version_minor( void)
static inline unsigned int   mulle_atinit_get_version_patch( void)

MULLE__ATINIT_GLOBAL
uint32_t   mulle_atinit_get_version( void);
```

#### Registration
```c
typedef void   mulle_atinit_function_t( void (*f)( void *),
                                        void *userinfo,
                                        int priority,
                                        char *comment);

MULLE__ATINIT_GLOBAL
void   _mulle_atinit( void (*f)( void *),
                      void *userinfo,
                      int priority,
                      char *comment);

static inline void   mulle_atinit( void (*f)( void *),
                                   void *userinfo,
                                   int priority,
                                   char *comment)
```
- `mulle_atinit( f, userinfo, priority, comment)` is the preferred entry point.
  It calls `_mulle_atinit` directly, except on Windows dynamically-built DLLs
  where it resolves `_mulle_atinit` via `mulle_dlsym_exe`.
- `priority`: callbacks execute in ascending sort order but are popped from the
  end, so **higher numeric priority runs earlier**; equal priorities keep
  insertion order (stable mergesort). `priority == 0` is the default.
- `comment` is a free-form string used only for `MULLE_ATINIT_TRACE` debug
  output.
- Calling `_mulle_atinit( NULL, NULL, 0, NULL)` is a no-registration call used
  internally by the constructor. Callbacks registered *after* the run has
  started are invoked directly (immediately) rather than queued.
- Internal storage: dynamic array starting at capacity 32, doubling on growth.

### 3.3. `mulle-atexit.h` (amalgamated: LIFO exit callbacks)

- **Purpose:** register `void (*f)( void)` callbacks that run at program exit
  in **LIFO** order (last registered, first executed — standard `atexit`
  semantics), independent of the platform `atexit`.

```c
#define MULLE__ATEXIT_VERSION  ((0UL << 20) | (2 << 8) | 1)

static inline unsigned int   mulle_atexit_get_version_major( void)
static inline unsigned int   mulle_atexit_get_version_minor( void)
static inline unsigned int   mulle_atexit_get_version_patch( void)

MULLE__ATEXIT_GLOBAL
uint32_t   mulle_atexit_get_version( void);

typedef int   mulle_atexit_function_t( void (*f)( void));

MULLE__ATEXIT_GLOBAL
int   _mulle_atexit( void (*f)( void));

static inline int   mulle_atexit( void (*f)(void))
```
- `mulle_atexit( f)` is the preferred entry point; it forwards to
  `_mulle_atexit` (with a `mulle_dlsym_exe` indirection only on Windows dynamic
  builds).
- Registration is amortized O(1) (array doubling, initial capacity 32).
- Execution happens via the platform `atexit` mechanism using stored callbacks
  in reverse registration order; the internal list is freed when drained.

### 3.4. `mulle-stacktrace.h` (amalgamated: stacktrace generation)

- **Purpose:** capture and print the current call stack, with a pluggable
  symbolizer and selectable backend.

#### Backend selection constants (compile-time)
```c
#define MULLE_STRACKTRACE_BACKEND_NONE          0
#define MULLE_STRACKTRACE_BACKEND_LIBBACKTRACE  1
#define MULLE_STRACKTRACE_BACKEND_EXECINFO      2

#if defined( HAVE_LIB_LIBBACKTRACE) && ! defined( MULLE_STACKTRACE_NO_LIBBACKTRACE)
# define MULLE_STRACKTRACE_BACKEND   MULLE_STRACKTRACE_BACKEND_LIBBACKTRACE
#else
# if (defined( __APPLE__) || defined( __linux__) || defined( __FreeBSD__) || defined( __OpenBSD__) || defined( __NetBSD__))
#  define MULLE_STRACKTRACE_BACKEND   MULLE_STRACKTRACE_BACKEND_EXECINFO
# else
#  define MULLE_STRACKTRACE_BACKEND   MULLE_STRACKTRACE_BACKEND_NONE
# endif
#endif
```
- `HAVE_LIB_LIBBACKTRACE` selects `libbacktrace`; define
  `MULLE_STACKTRACE_NO_LIBBACKTRACE` to disable libbacktrace even when it is
  available. Fallback: `execinfo` on Apple/Linux/BSD, otherwise `NONE` (the
  "nop" backend).

#### Version helpers and main types
```c
#define MULLE__STACKTRACE_VERSION  ((0UL << 20) | (5 << 8) | 3)

static inline unsigned int   mulle_stacktrace_get_version_major( void)
static inline unsigned int   mulle_stacktrace_get_version_minor( void)
static inline unsigned int   mulle_stacktrace_get_version_patch( void)

MULLE__STACKTRACE_GLOBAL
uint32_t   mulle_stacktrace_get_version( void);

typedef char   *(mulle_stacktrace_symbolizer_t)( void *s,
                                                 size_t max,
                                                 char *buf,
                                                 size_t len,
                                                 void **userinfo);

struct mulle_stacktrace
{
   mulle_stacktrace_symbolizer_t  *symbolize;
   char                           *(*trim_belly_fat)( char *s);
   int                            (*trim_arse_fat)( char *s);
   int                            (*is_boring)( char *s, int size);
   char                           *backend;
};
```
- `symbolize` converts an address into a string; the `trim_*` / `is_boring`
  hooks filter/format frames; `backend` names the active backend.

#### Lifecycle & core operations
```c
MULLE__STACKTRACE_GLOBAL
void   _mulle_stacktrace_init( struct mulle_stacktrace *stacktrace,
                               mulle_stacktrace_symbolizer_t *symbolize,
                               char *(*trim_belly_fat)( char *),
                               int (*trim_arse_fat)( char *),
                               int (*is_boring)( char *, int size));

MULLE__STACKTRACE_GLOBAL
void   _mulle_stacktrace_init_default( struct mulle_stacktrace *stacktrace);

enum mulle_stacktrace_format
{
   mulle_stacktrace_normal   = 0,
   mulle_stacktrace_trimmed  = 1,
   mulle_stacktrace_linefeed = 2,
   mulle_stacktrace_csv      = 3
};

MULLE__STACKTRACE_GLOBAL
void  _mulle_stacktrace( struct mulle_stacktrace *stacktrace,
                         int offset,
                         enum mulle_stacktrace_format format,
                         FILE *fp);

static inline void   mulle_stacktrace( struct mulle_stacktrace *stacktrace, FILE *fp)
static inline void   mulle_stacktrace_once( FILE *fp)

MULLE_C_NONNULL_RETURN
static inline char  *mulle_stacktrace_get_backend( struct mulle_stacktrace *stacktrace)

MULLE__STACKTRACE_GLOBAL
int   mulle_stacktrace_count_frames( void);

MULLE__STACKTRACE_GLOBAL
char  *mulle_stacktrace_symbolize_nothing( void *adresse, size_t max, char *buf, size_t len, void **userinfo);
```
- `_mulle_stacktrace_init_default( &st)` — recommended initialization; installs
  the default symbolizer/trimmers for the compile-time backend.
- `_mulle_stacktrace_init( &st, symbolize, trim_belly_fat, trim_arse_fat,
  is_boring)` — custom hooks; pass `0` for a hook to keep the default.
- `_mulle_stacktrace( stacktrace, offset, format, fp)` — print the stack;
  `stacktrace` may be `NULL` (defaults are used); `offset` skips that many
  frames.
- `mulle_stacktrace( &st, fp)` is the inline convenience call (offset 1,
  trimmed format). `mulle_stacktrace_once( fp)` is a one-shot variant that takes
  no `struct mulle_stacktrace`.
- `mulle_stacktrace_get_backend( &st)` returns the backend name; passing `NULL`
  uses a temporary default-initialized instance (guaranteed non-NULL return).
- `mulle_stacktrace_count_frames( void)` returns the number of frames;
  `mulle_stacktrace_symbolize_nothing(...)` is a no-op symbolizer.

## 4. Performance Characteristics

- **Amalgam overhead:** near zero; it is a thin compile-time bundle. The
  relevant costs are those of the constituents.
- **mulle-atinit:** registration is amortized O(1) (doubling array, initial
  capacity 32). Execution is O(n log n): a stable mergesort on `priority` at run
  time followed by O(n) invocations. Sorting is deferred to execution time to
  keep registration fast. Thread-safe (mutex + once init), not lock-free.
- **mulle-atexit:** registration amortized O(1); execution O(n) LIFO.
  Thread-safe (mutex + once), not lock-free.
- **mulle-stacktrace:** cost depends on the backend — `libbacktrace` and
  `execinfo` are O(frames × symbolization); the `NONE` backend is a no-op. Not
  thread-safe by itself.
- **Memory:** dynamic arrays are freed once drained; no leaks are intended in
  the standard callbacks.

## 5. AI Usage Recommendations & Patterns

- **Best Practices:**
  - Always `#include <mulle-core-all-load/mulle-core-all-load.h>` and link
    `-lmulle-core-all-load` (or `add_subdirectory` + `target_link_libraries`
    from CMake).
  - **Force-link it** when using the installed static archive (not via CMake
    `INTERFACE` options):
    - ELF/GCC/Clang: `-Wl,--whole-archive -lmulle-core-all-load -Wl,--no-whole-archive`
    - macOS: `-force_load libmulle-core-all-load.a`
    - MSVC: `/WHOLEARCHIVE:mulle-core-all-load.lib`
    Without force-linking, the constructor/destructor based atinit/atexit
    callbacks may be optimized away.
  - Register atinit/atexit callbacks via the inline wrappers `mulle_atinit(...)`
    and `mulle_atexit(...)`, not the `_`-prefixed globals.
  - Use `_mulle_stacktrace_init_default( &st)` then `mulle_stacktrace( &st, fp)`
    for ad-hoc stack dumps.
- **Common Pitfalls:**
  - Do **not** build `mulle-atinit`/`mulle-atexit` into shared libraries — they
    deliberately `#error` under `MULLE_INCLUDE_DYNAMIC`.
  - Do **not** assume FIFO exit order: `mulle_atexit` runs callbacks LIFO.
  - Do **not** assume registration order fixes run order when atinit priorities
    differ: higher `priority` runs earlier.
  - Backend `NONE` means printed stacks may be empty; check
    `mulle_stacktrace_get_backend()`.
  - If `libbacktrace` is available but undesired, define
    `MULLE_STACKTRACE_NO_LIBBACKTRACE` before including the header.
- **Idiomatic usage:** use the amalgam in any program that needs guaranteed
  startup/exit callbacks and a debugging aid under static linking, without
  juggling many small static libraries.

## 6. Integration Examples

### Example 1: Probing the amalgam and verifying the link

```c
#include <mulle-core-all-load/mulle-core-all-load.h>

int   main( void)
{
   uint32_t   version;

   version = mulle_core_all_load_get_version();
   if( version != MULLE__CORE__ALL__LOAD_VERSION)
   {
      fprintf( stderr, "version mismatch: %u\n", version);
      return( 1);
   }
   return( 0);
}
```

### Example 2: Registering atinit and atexit callbacks (from `test/10-first/atinitexit.c`)

```c
#include <mulle-core-all-load/mulle-core-all-load.h>

static int   init_called = 0;
static int   exit_called = 0;

static void   test_init( void *)
{
   init_called = 1;
   mulle_printf( "Init callback called\n");
}

static void   test_exit( void)
{
   exit_called = 1;
   mulle_printf( "Exit callback called\n");
}

int   main( void)
{
   mulle_atinit( test_init, NULL, 0, NULL);
   mulle_atexit( test_exit);
   return( 0);
}
```
When force-linked, this prints `Init callback called` at startup (via the
constructor) and `Exit callback called` at exit (LIFO).

### Example 3: Printing a backtrace (from `test/10-first/stacktrace.c`)

```c
#include <mulle-core-all-load/mulle-core-all-load.h>

int   main( void)
{
   struct mulle_stacktrace   stacktrace;

   _mulle_stacktrace_init_default( &stacktrace);
   mulle_stacktrace( &stacktrace, stderr);
   return( 0);
}
```
`mulle_stacktrace_once( stderr)` is the one-shot variant needing no explicit
`struct mulle_stacktrace`.

## 7. Dependencies

Direct `mulle-sde` dependencies (from `.mulle/etc/sourcetree/config` and
`clib.json`):

- `mulle-c11` (alias `mulle-core`) — compiler glue; provides the version
  convention and `MULLE_C_*` helpers used throughout.
- `mulle-allocator` — allocation infrastructure used transitively by the
  stacktrace backends.
- `mulle-thread` — mutex/once primitives required by `mulle-atinit` and
  `mulle-atexit`.
- `mulle-dlfcn` — dynamic symbol lookup (`mulle_dlsym_exe`) used on Windows
  dynamic builds.
- `libbacktrace` — enables the `MULLE_STRACKTRACE_BACKEND_LIBBACKTRACE`
  stacktrace backend (optional at runtime, but listed as a dependency).

Amalgamated constituent libraries (their sources are vendored into
`src/<name>` via clib hardlinks and compiled into the archive):

- `mulle-atinit` (version 0.3.3)
- `mulle-atexit` (version 0.2.1)
- `mulle-stacktrace` (version 0.5.3)

Each constituent also ships its own API TOC, installed to
`share/<name>/dox/api/toc/index.md`; consult those for the detailed
per-library documentation.
