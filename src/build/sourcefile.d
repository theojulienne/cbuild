module build.sourcefile;

import build.actions;
import build.targets;
import build.comm;

import std.stdio;
import std.string;
import std.file;
import std.process;

extern (C)
{
    char* getenv(char*);
    int strlen(char*);
}

class SourceFile : Target
{
	char name[];
	char type[] = "unknown-source";
	char dst[];

    static char[][char[]] source_handlers; 	
    
    static this()
    {
        source_handlers[".c"] = "gcc";
		source_handlers[".m"] = "gcc";
        source_handlers[".d"] = "gdc";
        source_handlers[".cpp"] = "g++";
        source_handlers[".cxx"] = "g++";
    }

	this( char[] _name )
	{
		name = _name;
		
		dst = name;
		
		foreach ( ext, cpl; source_handlers )
		{
			dst = std.string.replace( dst, ext, ".o" );
		}
		
		act = new Action( );
		act["src"] = name;
		act["dst"] = dst;
		
		if ( act["src"] == act["dst"] )
			throw new Exception( "source and destination the same for source target!" );
		
		int i = rfind( act["src"], "." );
		if ( i > 0 )
		{
			type = act["src"][i+1..length] ~ "-source";
		}
	}
	
	char[] filetype( )
	{
		return type;
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
		
		parent.enterDir( );
		scope(exit) parent.exitDir( );
		
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
			version (Debug) writeDebugf( "Source file '%s' updated", name );
			this.markDirty( true );
		}
	}
	
    private char[] getTool()
    {
        char[] src = act["src"];
        int i = rfind(src, ".");
        char[] extension = src[i..src.length];    
        char[] handler = source_handlers[extension];
        char * ptr = getenv("CROSS_COMPILE");
        if(!i)
           throw new Exception( "Could not determine file type for \"" ~ src ~ "\"." );             
        if(ptr == null)       
            return handler;   
        else
        {
            char[] compiler_prefix;
            compiler_prefix.length = strlen(ptr);
            for(i = 0; i < compiler_prefix.length; i++)
                compiler_prefix[i] = ptr[i];       
            return compiler_prefix ~ handler;
        }    
    }

	void runTool( )
	{
		char cmd[];
		char[] tool = getTool();

        //FIXME
		writefln( "COMPILE %s", name );
		
		cmd = tool ~ " -c "~act["src"]~" -o "~act["dst"]~" "~this.getCFlags();
		writeDebugf( ">>> %s", cmd );
		
		if ( system( cmd ) != 0 )
			throw new Exception( tool ~ " returned error during source compile" );
	}
	
	void runClean( )
	{
		char cmd[];

		if ( !exists( act["dst"] ) )
			return;

        //FIXME
		writefln( "CLEAN %s", act["dst"] );
		
		cmd = "rm";
		version (Windows)
		{
			cmd = "del";
			act["dst"] = std.string.replace( act["dst"], "/", "\\" );
		}
		cmd ~= " " ~ act["dst"];
		writeDebugf( ">>> %s", cmd );
		
		if ( system( cmd ) != 0 )
			throw new Exception( "could not remove file" );
	}
	
	char[] target( ) { return dst; }
}
