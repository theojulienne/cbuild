module build.targets;

import build.actions;
import build.depends;
import build.comm;

public import std.stdio;
import std.file;

abstract class Target
{
	Action act;
	
	Depend depends[];
	Target targets[];
	
	Target parent;
	
	bool dirty;
	
	char[] path = ".";
	char[] old_path;
	int in_dir = 0;
	
	void enterDir( )
	{
		in_dir++;
		
		if ( in_dir > 1 )
			return;
		
		if ( !( parent is null ) ) parent.enterDir( );
		
		if ( path != "." )
		{
			old_path = getcwd( );
			chdir( path );

			writeDebugf( "Entering directory '%s'", path );
		}

	}
	
	void exitDir( )
	{
		in_dir--;
		
		if ( in_dir > 0 )
			return;
		
		if ( path != "." )
		{
			chdir( old_path );
			writeDebugf( "Leaving directory '%s'", path );
		}
		
		if ( !( parent is null ) ) parent.exitDir( );
	}
	
	
	/* HACKS! These should be handled differently later! */
	char[] cflags;
	char[] ldflags;
	
	/* This is a hack. Tools/actions will handle this later. */
	void appendCFlags( char[] flags )
	{
		cflags ~= " ";
		cflags ~= flags;
	}
	
	/* This is a hack. Tools/actions will handle this later. */
	void appendLDFlags( char[] flags )
	{
		ldflags ~= " ";
		ldflags ~= flags;
	}
	
	
	char[] getCFlags( )
	{
		if ( this.parent is null )
			return cflags;
		
		return parent.getCFlags() ~ cflags;
	}
	
	char[] getLDFlags( )
	{
		if ( this.parent is null )
			return ldflags;
		
		return parent.getLDFlags() ~ ldflags;
	}
	
	
	char[][] evals;
	
	void addEval( char[] value )
	{
		int n = evals.length;
		evals.length = n + 1;
		evals[n] = value;
	}
	
	bool evaluate( )
	{
		return true;
	}
	
	
	void addTarget( Target t )
	{
		int a = targets.length;
		targets.length = a + 1;
		targets[a] = t;
		t.parent = this;
	}
	
	void addDepend( Depend d )
	{
		int a = depends.length;
		depends.length = a + 1;
		depends[a] = d;
	}
	
	void displayTree( int ind=0 )
	{
		char[] indent;
		
		indent.length = ind;
		for ( auto a = 0; a < ind; a++ )
			indent[a] = ' ';
		
		writeDebugf( "%s%s", indent, this );
		
		writeDebugf( "%s  info:", indent );
		writeDebugf( "%s    dirty=%s", indent, dirty );
		writeDebugf( "%s    mtime=%s", indent, this.modificationTime );
		writeDebugf( "%s    %s", indent, this.info() );
		writeDebugf( "%s  depends:", indent );
		
		writeDebugf( "%s  targets:", indent );
		
		foreach ( t; targets )
		{
			t.displayTree( ind+4 );
		}
	}
	
	// returns whether we actually had to make a change
	bool markDirty( bool recurse=true )
	{
		if ( this.dirty )
			return false;
		
		this.dirty = true;
		
		if ( !recurse )
			return true;
		
		foreach ( t; targets )
		{
			t.markDirty( );
		}
		
		return true;
	}
	
	bool isDirty( ) { return dirty; }
	
	// returns whether anything extra was marked dirty this time
	bool deps( )
	{
		bool marked_any = false;
		
		if ( !evaluate( ) )
			return false;
		
		enterDir( );
		scope(exit) exitDir( );
		
		doDeps( );
		
		/*// if we are dirty, we can't get any worse ;)
		if ( dirty )
			return false;*/
		
		if ( !dirty )
		{
			version (Debug) writeDebugf( "Checking on depends for: %s", this );
		
			// check out dependancies. if any are dirty, then we are dirty,
			// so are all our targets.
			foreach ( dep; depends )
			{
				if ( dep.isDirty( ) || dep.changedSince( this.modificationTime ) )
				{
					if ( this.markDirty( ) )
						marked_any = true;
				}
			}
		}
		
		// if any target is dirty, we are dirty, but our other targets
		// may NOT be.
		foreach ( t; targets )
		{
			// firstly, let the target do its dep check
			t.deps( );
			
			if ( t.isDirty( ) || t.changedSince( this.modificationTime ) )
			{
				if ( this.markDirty( false ) )
					marked_any = true;
			}
		}
		
		return marked_any;
	}
	
	bool changedSince( long when )
	{
		if ( this.modificationTime == 0 )
			return false;
		
		return when > this.modificationTime;
	}
	
	void doDeps( )
	{
		
	}
	
	void clean( )
	{
		if ( !evaluate( ) )
			return;
		
		enterDir( );
		scope(exit) exitDir( );
		
		foreach ( d; depends )
		{
			d.clean( );
		}
		
		foreach ( t; targets )
		{
			t.clean( );
		}
		
		this.runClean( );
	}
	
	void build( )
	{
		if ( !evaluate( ) )
			return;
		
		enterDir( );
		scope(exit) exitDir( );
		
		if ( dirty == false )
		{
			version (Debug) writeDebugf( "Skipping clean target: %s", this );
			return;
		}
		
		version (Debug) writeDebugf( "Building all depends for: %s", this );
		
		foreach ( d; depends )
		{
			d.build( );
		}
		
		version (Debug) writeDebugf( "Building all targets for: %s", this );
		
		foreach ( t; targets )
		{
			t.build( );
		}
		
		this.runTool( );
		
		dirty = false;
	}
	
	void runTool( )
	{
		version (Debug) writeDebugf( "Came back to Target class for runTool, doing nothing: %s", this );
	}
	
	void runClean( )
	{
		version (Debug) writeDebugf( "Came back to Target class for runClean, doing nothing: %s", this );
	}
	
	char[] info( )
	{
		return "-";
	}
	
	long modificationTime( )
	{
		return 0;
	}
	
	char[] target( ) {
		return "";
	}
	
	char[] filetype( )
	{
		return "";
	}
}
