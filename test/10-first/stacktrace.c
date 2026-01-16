#include "include.h"


int main( void)
{
   // Initialize stacktrace
   struct mulle_stacktrace   stacktrace;

   _mulle_stacktrace_init_default( &stacktrace);
   
   return( 0);
}
