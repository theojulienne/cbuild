module build.app_target;

import build.targets;

import std.file;
import std.process;

import build.comm;

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
		char[] app = "gcc";
		
		// HACK: if any sources are d, use gdc to link
		foreach ( t; targets )
		{
			if ( t.filetype == "d-source" )
			{
				app = "gdc";
				break;
			}
			
			if ( t.filetype == "cpp-source" )
			{
				app = "g++";
				break;
			}
		}
		
		cmd = app~" "~objs~" -o "~dest~" "~this.getLDFlags();
		writeDebugf( ">>> %s", cmd );
		
		if ( system( cmd ) != 0 )
			throw new Exception( "gcc returned error during building" );
	}
	
	void runClean( )
	{
		char[] dest = getDestFile( );
		char[] cmd = "";
		
		if ( !exists( dest ) )
			return;
		
		writefln( "CLEAN %s", dest );
		
		cmd = "rm";
		version (Windows)
		{
			cmd = "del";
			dest = std.string.replace( dest, "/", "\\" );
		}
		
		cmd ~= " " ~ dest;
		writeDebugf( ">>> %s", cmd );
		
		if ( system( cmd ) != 0 )
			throw new Exception( "could not remove destination file "~dest );
	}
}
