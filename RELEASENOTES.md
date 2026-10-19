## 0.9.0































* Correct amalgamation documentation to describe sources as copied via clib instead of hardlinked






feature: propagate force-linking to `add_subdirectory` and `find_package` consumers

* mulle-core-all-load now carries its force-link requirement through an INTERFACE wrapper target, so a plain `target_link_libraries(...` mulle-core-all-load) whole-archives the library for both subproject and installed consumers
* new `MULLE_LIBRARY_FORCE_LINK` option (default ON) lets a consumer opt out of force-linking the library into every binary
* new `MULLE_TRANSITIVE_LINKER_FLAGS` switch replaces the previous inline force-link flags and falls back to `MULLE_TRANSITIVE_LINK_LIBRARIES` for existing consumers
* fix Windows DLL builds: amalgamated sub-project symbols are now compiled as dllexport instead of dllimport, eliminating undefined `__declspec(dllimport)` link failures and missing exports in the import library
* the mulle-stacktrace libbacktrace backend is disabled under whole-archive when libbacktrace is not an exportable target, preventing undefined `backtrace_*` symbols; override with `MULLE_STACKTRACE_USE_LIBBACKTRACE`



* reorganize mulle-core-all-load for improved direct header inclusion with -isystem mulle-core-all-load/src


### 0.8.2






* `_GNU_SOURCE` now defined before any system header is included in the execinfo backend, ensuring glibc-specific APIs are always exposed regardless of include order







* API documentation TOC now installed to canonical share path for mulle-sde api
* README links to API documentation summary

### 0.8.1

Various small improvements
