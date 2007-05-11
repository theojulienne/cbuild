module build.lib_target;

import build.targets;

import std.file;
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
		
		version (macosx)
		{
			pf = "-dynamiclib";
			ext = ".dylib";
		}
		version (windows)
		{
			pf = "-shared";
			ext = ".dll";
		}
		version (linux)
		{
			pf = "-shared";
			ext = ".so";
		}
		
		cmd = "gcc "~objs~" -o lib"~name~ext~" "~this.getLDFlags()~" "~pf;
		writefln( ">>> %s", cmd );
		
		if ( system( cmd ) != 0 )
			throw new Exception( "gcc returned error during linking" );
	}
}
