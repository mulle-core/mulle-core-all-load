#include "include.h"

static int init_called = 0;
static int exit_called = 0;

static void test_init( void *)
{
   init_called = 1;
   mulle_printf( "Init callback called\n");
}

static void test_exit( void)
{
   exit_called = 1;
   mulle_printf( "Exit callback called\n");
}

int main( void)
{
   // Register callbacks
   mulle_atinit( test_init, NULL, 0, NULL);
   mulle_atexit( test_exit);
   
   return( 0);
}
