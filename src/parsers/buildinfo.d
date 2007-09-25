module parsers.buildinfo;

import parsers.iparser;

import build.actions;
import build.tools;
import build.projects;
import build.targets;

import build.options;

import build.app_target;
import build.lib_target;
import build.sourcefile;
import build.comm;

import std.stdio;
import std.stream;
import std.string;
import std.file;
import std.process;

import std.c.string;
import std.c.stdio;


version (macosx)
	char[] target_platform = "darwin";
version (linux)
	char[] target_platform = "posix";
version (unix)
	char[] target_platform = "posix";
version (windows)
	char[] target_platform = "win32";

extern (C)
{
    _iobuf * popen(char*, char*);
    int pclose(_iobuf*);
}

char[] run_pkg_config(char[] args)
{
    static char[][char[]] _pkgs;

	char[] cmd;
	int ret;
	char[] buf;
    FILE * f;
	
    if(args in _pkgs)
        return _pkgs[args];    
    
    cmd = "pkg-config " ~ args;
		
    f = popen(cmd.ptr, "r".ptr);

	if ( f == null )
	{
		fprintf( stderr, "pkg-config failed for (args: %s)\n", args );
		return null;
	}
	
    buf = new char[1024];

    ret = fread(cast(void*)buf.ptr, 1, 1024, f);
    
    if ( ret <= 0 )
	{
		fprintf( stderr, "pkg-config not found or an error occured.\n" );
		fprintf( stderr, "Try running 'pkg-config' and see if it works.\n" );
		return null;
	}

    buf = buf[0..ret];

    ret = pclose(f);    
	
    if ( ret < 0 )
	{
		fprintf( stderr, "pkg-config not found or an error occured.\n" );
		fprintf( stderr, "Try running 'pkg-config' and see if it works.\n" );
		return null;
	}

    _pkgs[args] = buf[0..length-2];

    return strip(buf);
}

class BuildInfoParser: IParser
{
	this(char[] dir, char[] filename = "BuildInfo", Project parent = null)
	{
		super(dir, filename, parent);
	}

	void run()
	{
		File file = new File;
		
		file.open(m_buildfile, FileMode.In);
		
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
							bool negate = (exp[0] == '!');
							char[] expr = exp;
							
							if ( negate )
								expr = exp[1..exp.length];
						
							if ( expr == target_platform )
							{
								continue;
							}
							
							Option eo = Option.get( expr );
							
							if ( eo.value == "yes" )
							{
								if ( !negate )
									continue;
							}
							else
							{
								if ( negate )
									continue;
							}
						
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
					bool skip = (parms[0] != target_platform && parms[0] != "all");
					
					if ( skip )
					{
						if ( parms[0][0] == '!' )
						{
							// negate, skip if param is target
							skip = ( parms[0][1..length] == target_platform );
						}
					}
					
					if ( skip )
					{
						skipping = true;
						skip_breakout = path.length;
					}
				}
				else if ( section == "info" && cmd == "name" )
				{
					char[] foo = join( parms, " " );
					m_proj = new Project( foo[1..foo.length-1] );
					m_proj.path = getcwd( ) ~ "/" ~ m_dir;
					if ( !( m_parent is null ) )
						m_parent.addTarget( m_proj );
				}
				else if ( section == "info" && cmd == "description" )
				{
					char[] foo = join( parms, " " );
					writeDebugf( "%s is '%s'", m_proj.name, foo[1..foo.length-1] );
				}
				else if ( section == "contains" && cmd == "recurse" )
				{
					writeDebugf( "Contains another project '%s' in '%s'", parms[0], parms[1] );
					BuildInfoParser bp = new BuildInfoParser( m_dir~"/"~parms[1], m_filename, m_proj );
				}
				else if ( section == "flags" && cmd == "define" )
				{
					m_proj.appendCFlags( "-D" ~ parms[0] );
				}
				else if ( section == "flags" && cmd == "cflags" )
				{
					char[] foo = join( parms, " " );
					m_proj.appendCFlags( foo[1..foo.length-1] );
				}
				else if ( section == "flags" && cmd == "ldflags" )
				{
					char[] foo = join( parms, " " );
					m_proj.appendLDFlags( foo[1..foo.length-1] );
				}
				else if ( section == "flags" && cmd == "pkg-config" )
				{
				    char[] pkgs = join( parms, " " );
				    pkgs = pkgs[1..pkgs.length-1];
				  				    
				    m_proj.appendCFlags(run_pkg_config("--cflags " ~ pkgs));
					m_proj.appendLDFlags(run_pkg_config("--libs " ~ pkgs));    
				}
				else if ( cmd == "none" )
				{
					// "pass"
				}
				else if ( section == "targets" && cmd == "library")
				{
					target = new LibraryTarget( parms[0] );
					m_proj.addTarget( target );
				}
				else if ( section == "targets" && cmd == "application")
				{
					target = new ApplicationTarget( parms[0] );
					m_proj.addTarget( target );
				}
				else if ( section == "sources"  )
				{
					//writefln( "Adding source target: %s", m_dir~"/"~cmd );
					target.addTarget( new SourceFile( cmd ) );
				}
				else if ( section == "flags" && cmd == "include" )
				{
					char[] foo = join( parms, " " );
					char[] prefix = "";
					int start = 1;
					if ( foo[1] == '^' || foo[1] == '#' )
					{
						prefix = getcwd( ) ~ "/";
						start++;
					}
					m_proj.appendCFlags( "-I"~prefix~foo[start..foo.length-1] );
				}
				else if ( section == "flags" && cmd == "libdir" )
				{
					char[] foo = join( parms, " " );
					char[] prefix = "";
					int start = 1;
					if ( foo[1] == '^' || foo[1] == '#' )
					{
						prefix = getcwd( ) ~ "/";
						start++;
					}
					m_proj.appendLDFlags( "-L"~prefix~foo[start..foo.length-1] );
				}
				else if ( section == "flags" && cmd == "library" )
				{
					m_proj.appendLDFlags( "-l"~parms[0][1..parms[0].length-1] );
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
