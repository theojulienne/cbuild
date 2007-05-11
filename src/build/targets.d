module build.targets;

import build.actions;
import build.depends;

public import std.stdio;

abstract class Target
{
	Action act;
	
	Depend depends[];
	Target targets[];
	
	bool dirty;
	
	void addTarget( Target t )
	{
		int a = targets.length;
		targets.length = a + 1;
		targets[a] = t;
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
		
		writefln( "%s%s", indent, this );
		
		writefln( "%s  info:", indent );
		writefln( "%s    dirty=%s", indent, dirty );
		writefln( "%s    mtime=%s", indent, this.modificationTime );
		writefln( "%s    %s", indent, this.info() );
		writefln( "%s  depends:", indent );
		
		writefln( "%s  targets:", indent );
		
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
		
		doDeps( );
		
		// if we are dirty, we can't get any worse ;)
		if ( dirty )
			return false;
		
		version (Debug) writefln( "Checking on depends for: %s", this );
		
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
	
	void build( )
	{
		if ( dirty == false )
		{
			version (Debug) writefln( "Skipping clean target: %s", this );
			return;
		}
		
		version (Debug) writefln( "Building all depends for: %s", this );
		
		foreach ( d; depends )
		{
			d.build( );
		}
		
		version (Debug) writefln( "Building all targets for: %s", this );
		
		foreach ( t; targets )
		{
			t.build( );
		}
		
		this.runTool( );
		
		dirty = false;
	}
	
	void runTool( )
	{
		version (Debug) writefln( "Came back to Target class for runTool, doing nothing: %s", this );
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
}
