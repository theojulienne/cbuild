module build.app_target;

import build.targets;

import std.file;
import std.process;

class ApplicationTarget : Target
{
	char name[];
	
	this( char[] _name )
	{
		name = _name;
	}
	
	char[] toString( )
	{
		return name ~ " (Appln)";
	}
	
	void doDeps( )
	{
		if ( !exists( name ) )
		{
			this.markDirty( false );
			return;
		}
	}
	
	void runTool( )
	{
		char[] cmd;
		char[] objs;
		foreach ( t; targets )
		{
			objs ~= t.target;
			objs ~= " ";
		}
		
		writefln( "LN %s", name );
		
		char[] pf = "";
		char[] ext = "";
		
		version (windows)
		{
			ext = ".exe";
		}
		
		cmd = "gcc "~objs~" -o "~name~ext~" "~this.getLDFlags()~" "~pf;
		writefln( ">>> %s", cmd );
		
		if ( system( cmd ) != 0 )
			throw new Exception( "gcc returned error during building" );
	}
}
