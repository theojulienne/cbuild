module parsers.buildinfo;

import build.actions;
import build.tools;
import build.projects;
import build.targets;

import build.options;

import build.app_target;
import build.lib_target;
import build.sourcefile;

import std.stdio;
import std.stream;
import std.string;
import std.file;

version (macosx)
	char[] target_platform = "darwin";
version (linux)
	char[] target_platform = "posix";
version (unix)
	char[] target_platform = "posix";
version (windows)
	char[] target_platform = "win32";

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
				char[] ssection;
				char[][] exprs;
				
				if ( cmd[0] == '(' )
				{
					exprs = split( cmd[1..cmd.length-1], "," );
					cmd = cmd_parts[1];
					parms = cmd_parts[2..cmd_parts.length];
					
					if ( exprs.length > 0 )
					{
						bool good = true;
						
						foreach ( exp; exprs )
						{
							bool negate = exp[0] == '!';
							
							if ( negate )
								exp = exp[1..exp.length];
						
							if ( exp == target_platform )
							{
								continue;
							}
							
							Option eo = Option.get( exp );
							
							if ( eo.value == "yes" )
							{
								if ( !negate )
									continue;
							}
							
							if ( negate )
								continue;
						
							good = false;
							break;
						}
						
						if ( !good )
							continue;
					}
				}
				
				while ( section == "platform" && section_pos > 0 )
				{
					section_pos--;
					section = path[section_pos];
				}
				
				if ( section_pos > 0 )
					ssection = path[section_pos-1];
				
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
					char[] foo = join( parms, " " );
					proj = new Project( foo[1..foo.length-1] );
					proj.path = getcwd( ) ~ "/" ~ dir;
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
				else if ( section == "targets" && cmd == "application")
				{
					target = new ApplicationTarget( parms[0] );
					proj.addTarget( target );
				}
				else if ( section == "sources"  )
				{
					//writefln( "Adding source target: %s", dir~"/"~cmd );
					target.addTarget( new SourceFile( cmd ) );
				}
				else if ( section == "flags" && cmd == "include" )
				{
					char[] foo = join( parms, " " );
					char[] prefix = "";
					int start = 1;
					if ( foo[1] == '#' )
					{
						prefix = getcwd( ) ~ "/";
						start++;
					}
					proj.appendCFlags( "-I"~prefix~foo[start..foo.length-1] );
				}
				else if ( section == "flags" && cmd == "libdir" )
				{
					char[] foo = join( parms, " " );
					char[] prefix = "";
					int start = 1;
					if ( foo[1] == '^' )
					{
						prefix = getcwd( ) ~ "/";
						start++;
					}
					proj.appendLDFlags( "-L"~prefix~foo[start..foo.length-1] );
				}
				else if ( section == "flags" && cmd == "library" )
				{
					proj.appendLDFlags( "-l"~parms[0][1..parms[0].length-1] );
				}
				else if ( ssection == "options" )
				{
					Option opt = Option.get( section );
					opt.is_real = true;
					if ( cmd == "description" )
					{
						char[] foo = join( parms, " " );
						opt.description = foo[1..foo.length-1];
					}
					else if ( cmd == "default" )
					{
						if ( opt.value == "" )
							opt.value = parms[0];
						
						if ( opt.value == "try" )
							opt.value = "yes";
					}
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
