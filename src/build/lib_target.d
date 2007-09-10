module build.lib_target;

import build.targets;

import std.file;
import std.process;

import build.comm;

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
		if ( !exists( getDestFile( ) ) )
		{
			this.markDirty( false );
			return;
		}
	}
	
	char[] getExt( )
	{
		version (macosx) return ".dylib";
		version (windows) return ".dll";
		return ".so";
	}
	
	char[] getFlags( )
	{
		version (macosx) return "-dynamiclib";
		return "-shared";
	}
	
	char[] getDestFile( )
	{
		return "lib"~name~getExt();
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
		
		char[] pf = getFlags( );
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
		
		cmd = app~" "~objs~" -o "~dest~" "~pf~" "~this.getLDFlags();
        writeDebugf( ">>> %s", cmd );
		
        if ( system( cmd ) != 0 )
            throw new Exception( "gcc returned error during linking" );
        
        writefln("AR %s", name);

        cmd = "ar rs lib" ~ name ~ ".a " ~ objs;

        if ( system( cmd ) != 0 )
			throw new Exception( "ar returned error during archiving" );
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
