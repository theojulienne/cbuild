module build.sourcefile;

import build.actions;
import build.targets;

import std.stdio;
import std.string;
import std.file;
import std.process;

class SourceFile : Target
{
	char name[];
	char dst[];
	
	this( char[] _name )
	{
		name = _name;
		
		dst = name;
		dst = std.string.replace( dst, ".c", ".o" );
		dst = std.string.replace( dst, ".m", ".o" );
		
		act = new Action( );
		act["src"] = name;
		act["dst"] = dst;
		
		if ( act["src"] == act["dst"] )
			throw new Exception( "source and destination the same for source target!" );
	}
	
	char[] toString( )
	{
		return name ~ " (Source)";
	}
	
	char[] info( )
	{
		return "SRC: " ~ act["src"] ~ "  DST: " ~ act["dst"];
	}
	
	long modificationTime( )
	{
		long c, a, m;
		getTimes( name, c, a, m );
		
		return m;
	}
	
	void doDeps( )
	{
		if ( !exists( dst ) )
		{
			this.markDirty( true );
			return;
		}
		
		long c, a, m;
		getTimes( dst, c, a, m );
		
		if ( m < this.modificationTime )
		{
			version (Debug) writefln( "Source file '%s' updated", name );
			this.markDirty( true );
		}
	}
	
	void runTool( )
	{
		char cmd[];
		
		writefln( "CC %s (not really)", name );
		
		cmd = "gcc -c "~act["src"]~" -o "~act["dst"]~" "~this.getCFlags();
		writefln( ">>> %s", cmd );
		
		if ( system( cmd ) != 0 )
			throw new Exception( "gcc returned error during source compile" );
	}
	
	char[] target( ) { return dst; }
}
