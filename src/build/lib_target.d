module build.lib_target;

import build.targets;

import std.process;

class LibraryTarget : Target
{
	char name[];
	
	this( char[] _name )
	{
		name = _name;
	}
	
	char[] toString( )
	{
		return name ~ " (Library)";
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
		
		writefln( "LN %s (not really)", name );
		
		char[] pf = "";
		
		version (macosx) pf = "-dynamiclib";
		
		cmd = "gcc "~objs~" -o lib"~name~".so "~this.getLDFlags()~" "~pf;
		writefln( ">>> %s", cmd );
		
		if ( system( cmd ) != 0 )
			throw new Exception( "gcc returned error during linking" );
	}
}
