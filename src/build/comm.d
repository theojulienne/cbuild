module build.comm;

import std.c.stdio;
import std.format;

bool debug_quiet = true;

void writeDebugf(...)
{
	version (Debug)
	{
		if ( debug_quiet )
			return;
		
		void putc(dchar c)
		{
			fputc( c, stdout );
		}
		
		std.format.doFormat(&putc, _arguments, _argptr);
		putc('\n');
	}
}
