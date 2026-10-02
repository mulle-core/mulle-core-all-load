### If you want to edit this, copy it from cmake/share to cmake. It will be
### picked up in preference over the one in cmake/share. And it will not get
### clobbered with the next upgrade.

#
# StacktraceSupport.cmake
#    Keeps the mulle-stacktrace libbacktrace backend compatible with a
#    force-linked (whole-archived) build.
#
#    Whole-archiving pulls in every object of the archive, including
#    mulle-stacktrace-backtrace.c.o. libbacktrace is marked "no-link" in the
#    sourcetree: it is neither exported nor installed with the package, so a
#    consumer can not link it. The backend is selected at compile time from
#    __has_include(<backtrace.h>) alone (mulle-stacktrace.h), so without this
#    every force-linked consumer would fail with undefined backtrace_*
#    symbols.
#
#    The backend is kept only when libbacktrace resolved to an exportable CMake
#    target, or when explicitly requested. This is a no-op for a build that is
#    not force-linked, where the object is only pulled when referenced and the
#    consumer supplies libbacktrace itself.
#
#    Include this after AllLoadSupport.cmake, so MULLE_ALL_LOAD_ACTIVE is
#    known. When AllLoadSupport was not included, the fallback below preserves
#    the old inline behaviour (guard whenever transitive linking is on).
#
# INPUT
#    LIBRARY_COMPILE_TARGET     the OBJECT library that compiles the sources,
#                               receives MULLE_STACKTRACE_NO_LIBBACKTRACE
#    LIBRARY_STAGE2_TARGET      optional second OBJECT library, ditto
#    LIBBACKTRACE_LIBRARY       resolved libbacktrace; if it is a CMake target
#                               the libbacktrace backend stays enabled
#    MULLE_ALL_LOAD_ACTIVE      ON when AllLoadSupport created the wrapper
#    MULLE_STACKTRACE_USE_LIBBACKTRACE
#                               ON    keep the libbacktrace backend even if
#                                     libbacktrace is not exportable
#    BUILD_SHARED_LIBS          no guard for shared libraries
#    MULLE_TRACE_INCLUDE        trace inclusion of this file
#
# GUARD
#    __STACKTRACE_SUPPORT__CMAKE__
#

if( NOT __STACKTRACE_SUPPORT__CMAKE__)
   set( __STACKTRACE_SUPPORT__CMAKE__ ON)

   if( MULLE_TRACE_INCLUDE)
      message( STATUS "# Include \"${CMAKE_CURRENT_LIST_FILE}\"" )
   endif()

   option( MULLE_STACKTRACE_USE_LIBBACKTRACE
           "Keep the libbacktrace backend even if libbacktrace is not exportable"
           OFF)

   if( DEFINED MULLE_ALL_LOAD_ACTIVE)
      set( _MULLE_STACKTRACE_FORCE_LINKED "${MULLE_ALL_LOAD_ACTIVE}")
   else()
      set( _MULLE_STACKTRACE_FORCE_LINKED OFF)
      if( MULLE_TRANSITIVE_LINKER_FLAGS AND NOT BUILD_SHARED_LIBS)
         set( _MULLE_STACKTRACE_FORCE_LINKED ON)
      endif()
   endif()

   if( _MULLE_STACKTRACE_FORCE_LINKED)
      if( MULLE_STACKTRACE_USE_LIBBACKTRACE)
         message( STATUS "Keeping libbacktrace backend "
                         "(MULLE_STACKTRACE_USE_LIBBACKTRACE)")
      elseif( TARGET "${LIBBACKTRACE_LIBRARY}")
         message( STATUS "Keeping libbacktrace backend "
                         "(exportable target \"${LIBBACKTRACE_LIBRARY}\")")
      else()
         message( STATUS "Disabling libbacktrace backend, it is not exportable "
                         "(set MULLE_STACKTRACE_USE_LIBBACKTRACE to override)")
         foreach( _mulle_stacktrace_target
                  "${LIBRARY_COMPILE_TARGET}"
                  "${LIBRARY_STAGE2_TARGET}")
            if( TARGET "${_mulle_stacktrace_target}")
               message( STATUS "  ${_mulle_stacktrace_target} gets "
                               "MULLE_STACKTRACE_NO_LIBBACKTRACE")
               target_compile_definitions( "${_mulle_stacktrace_target}" PRIVATE
                  MULLE_STACKTRACE_NO_LIBBACKTRACE)
            endif()
         endforeach()
         unset( _mulle_stacktrace_target)
      endif()
   endif()
   unset( _MULLE_STACKTRACE_FORCE_LINKED)
endif()
