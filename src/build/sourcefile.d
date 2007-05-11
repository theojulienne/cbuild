module build.sourcefile;

import build.actions;
import build.targets;

import std.stdio;
import std.string;
import std.file;

class SourceFile : Target
{
	char name[];
	char dst[];
	
	this( char[] _name )
	{
		name = _name;
		
		dst = std.string.replace( name, ".c", ".o" );
		
		act = new Action( );
		act["src"] = name;
		act["dst"] = dst;
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
		writefln( "CC %s (not really)", name );
	}
	
	char[] target( ) { return dst; }
}
