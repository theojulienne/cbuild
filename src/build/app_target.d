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
		if ( !exists( getDestFile( ) ) )
		{
			this.markDirty( false );
			return;
		}
	}
	
	char[] getExt( )
	{
		version (windows) return ".exe";
		return "";
	}
	
	char[] getDestFile( )
	{
		return name~getExt();
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
		
		char[] dest = getDestFile( );
		
		cmd = "gcc "~objs~" -o "~dest~" "~this.getLDFlags();
		writefln( ">>> %s", cmd );
		
		if ( system( cmd ) != 0 )
			throw new Exception( "gcc returned error during building" );
	}
	
	void runClean( )
	{
		char[] dest = getDestFile( );
		char[] cmd = "";
		
		writefln( "CLEAN %s", dest );
		
		cmd = "rm";
		version (Windows) cmd = "del";
		
		cmd ~= " " ~ dest;
		writefln( ">>> %s", cmd );
		
		if ( system( cmd ) != 0 )
			throw new Exception( "could not remove destination file "~dest );
	}
}
