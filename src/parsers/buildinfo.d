module parsers.buildinfo;

import build.actions;
import build.tools;
import build.projects;
import build.targets;

import build.app_target;
import build.lib_target;
import build.sourcefile;

import std.stdio;
import std.stream;
import std.string;

version (macosx)
	char[] target_platform = "darwin";

class BuildInfoParser
{
	Project proj;
	
	this( char[] dir, char[] filename="BuildInfo", Project parent=null )
	{
		File file = new File;
		
		file.open( dir ~ "/" ~ filename, FileMode.In );
		
		char[][] path;
		char[] last_cmd;
		bool skipping = false;
		int skip_breakout;
		Target target;
		
		while ( !file.eof( ) ) {
			auto s = file.readLine( );
			int indents = 0;
			
			for ( int a = 0; a < s.length; a++ )
			{
				if ( s[a] != '\t' )
					break;
				
				indents++;
			}
			
			int endc = s.length;
			
			while ( endc > 0 && (s[endc-1] == '\n' || s[endc-1] == '\r') )
				endc--;
			
			char[] data = s[indents..endc];
			auto cmd_parts = split( data );
			
			if ( cmd_parts.length == 0 )
				continue;
			
			char[] cmd = cmd_parts[0];
			
			if ( indents > path.length )
			{
				path.length = indents;
				path[indents-1] = last_cmd;
				last_cmd = cmd;
			}
			else if ( indents < path.length )
			{
				path.length = indents;
				last_cmd = cmd;
				
				if ( path.length <= skip_breakout )
					skipping = false;
				else
					continue;
			}
			
			if ( skipping )
			{
				last_cmd = cmd;
				continue;
			}
			
			if ( path.length > 0 )
			{
				char[][] parms = cmd_parts[1..cmd_parts.length];
				int section_pos = path.length-1;
				char[] section = path[section_pos];
				
				while ( section == "platform" && section_pos > 0 )
				{
					section_pos--;
					section = path[section_pos];
				}
				
				if ( cmd == "platform" )
				{
					if ( parms[0] != target_platform && parms[0] != "all" )
					{
						skipping = true;
						skip_breakout = path.length;
					}
				}
				else if ( section == "info" && cmd == "name" )
				{
					proj = new Project( parms[0][1..parms[0].length-1] );
					if ( !( parent is null ) )
						parent.addTarget( proj );
				}
				else if ( section == "info" && cmd == "description" )
				{
					char[] foo = join( parms, " " );
					writefln( "%s is '%s'", proj.name, foo[1..foo.length-1] );
				}
				else if ( section == "contains" && cmd == "recurse" )
				{
					writefln( "Contains another project '%s' in '%s'", parms[0], parms[1] );
					BuildInfoParser bp = new BuildInfoParser( dir~"/"~parms[1], filename, proj );
				}
				else if ( section == "flags" && cmd == "define" )
				{
					proj.appendCFlags( "-D" ~ parms[0] );
				}
				else if ( section == "flags" && cmd == "cflags" )
				{
					char[] foo = join( parms, " " );
					proj.appendCFlags( foo[1..foo.length-1] );
				}
				else if ( section == "flags" && cmd == "ldflags" )
				{
					char[] foo = join( parms, " " );
					proj.appendLDFlags( foo[1..foo.length-1] );
				}
				else if ( cmd == "none" )
				{
					// "pass"
				}
				else if ( section == "targets" && cmd == "library")
				{
					target = new LibraryTarget( parms[0] );
					proj.addTarget( target );
				}
				else if ( section == "sources"  )
				{
					//writefln( "Adding source target: %s", dir~"/"~cmd );
					target.addTarget( new SourceFile( dir~"/"~cmd ) );
				}
				else if ( section == "flags" && cmd == "include" )
				{
					char[] foo = join( parms, " " );
					int start = 1;
					if ( foo[1] == '#' )
						start++;
					proj.appendCFlags( "-I"~foo[start..foo.length-1] );
				}
				else
				{
					//writefln( "[%s] %s .. %s", path, indents, data );
				}
			}
			
			last_cmd = cmd;
		}
		
		file.close( );
	}
}
