import build.actions;
import build.tools;
import build.projects;
import build.targets;

import build.app_target;
import build.lib_target;
import build.sourcefile;

import parsers.buildinfo;

import std.stdio;

int main( )
{
	auto bp = new BuildInfoParser( ".", "BuildInfo" );
	
	/*
	return 0;
	
	Project p = new Project( "claro" );
	
	auto b = new Project( "base" );
	p.addTarget( b );
	
	auto bt = new LibraryTarget( "claro-base" );
	b.addTarget( bt );
	
	auto a = new SourceFile( "src/claro/base/claro.c");
	//a.dirty = true;
	bt.addTarget( a );
	bt.addTarget( new SourceFile( "src/claro/base/object.c") );
	bt.addTarget( new SourceFile( "src/claro/base/memory.c") );
	
	
	auto g = new Project( "graphics" );
	p.addTarget( g );
	
	auto gt = new LibraryTarget( "claro-graphics" );
	g.addTarget( gt );
	
	g.addDepend( new ProjectDepend( b ) );
	
	gt.addTarget( new SourceFile( "src/claro/graphics/widget.c") );
	gt.addTarget( new SourceFile( "src/claro/graphics/widgets/stock.c") );
	*/
	
	auto p = bp.proj;
	
	version (Debug) writefln( "Processing deps and marking dirty targets..." );
	int n;
	for ( n = 0; n < 10; n++ )
	{
		version (Debug) writefln( "[dep %d] running... ", n );
		
		// deps will return true if it changes anything.
		// if false is returned, we're finished checking deps.
		if ( p.deps( ) == false )
			break;
		
		version (Debug) writefln( "[dep %d] completed.", n );
	}
	
	version (Debug)
	{
		writefln( "Depends completed in %d checks.", n+1 );
		
		writefln( "Here's what we have..." );
		p.displayTree( );
		
		writefln( "Now going to build..." );
	}
	p.build( );
	
	return 0;
}
