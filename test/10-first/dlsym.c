#include "include.h"

void  find_me( void)
{
   mulle_printf( "%s\n", __FUNCTION__);
}

int  main( void)
{
   void   *adr;
   void   (*f)( void);
   char   *symbol;

   symbol = "find_me";
   adr    = dlsym( MULLE_RTLD_DEFAULT, symbol);
   if( ! adr)
   {
      mulle_fprintf( stderr, "\"%s\" not found\n", symbol);
      return( -1);
   }
   f = (void (*)( void)) adr;
   (*f)();
   return( 0);
}
