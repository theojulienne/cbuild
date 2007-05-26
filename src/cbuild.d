import build.actions;
import build.tools;
import build.projects;
import build.targets;

import build.options;

import build.app_target;
import build.lib_target;
import build.sourcefile;

import parsers.buildinfo;

import std.stdio;
import std.string;

import build.comm;

int main( char[][] args )
{
	bool is_clean = false;
	
	foreach ( a; args[1..args.length] )
	{
		if ( a == "-v" )
		{
			debug_quiet = false;
		}
		else if ( a[0..2] == "--" )
		{
			auto arg = a[2..a.length];
			auto nv = split( arg, "=" );
			auto arg_name = nv[0];
			char[] arg_value;
			
			if ( nv.length > 1 )
				arg_value = nv[1];
			else
				arg_value = "yes";
			
			auto parts = split( arg_name, "-" );
			
			if ( parts.length > 1 )
				arg_value = parts[0];
			
			if ( arg_value == "enable" )
				arg_value = "yes";
			
			if ( arg_value == "disable" )
				arg_value = "no";
			
			parts = parts[1..parts.length];
			arg_name = join( parts, "-" );
			
			Option.add( arg_name, arg_value );
			//writefln( "%s=%s", arg_name, arg_value );
		}
		else if ( a == "clean" )
		{
			is_clean = true;
		}
	}
	
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
	
	version (Debug) writeDebugf( "Processing deps and marking dirty targets..." );
	int n;
	for ( n = 0; n < 10; n++ )
	{
		version (Debug) writeDebugf( "[dep %d] running... ", n );
		
		// deps will return true if it changes anything.
		// if false is returned, we're finished checking deps.
		if ( p.deps( ) == false )
			break;
		
		version (Debug) writeDebugf( "[dep %d] completed.", n );
	}
	
	version (Debug)
	{
		writeDebugf( "Depends completed in %d checks.", n+1 );
		
		writeDebugf( "Here's what we have..." );
		p.displayTree( );
		
		writeDebugf( "Now going to build..." );
	}
	
	if ( is_clean )
		p.clean( );
	else
		p.build( );
	
	return 0;
}
