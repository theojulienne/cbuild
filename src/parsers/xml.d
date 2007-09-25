module parsers.xml;

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

	if (f == null)
	{
		fprintf(stderr, "pkg-config failed for (args: %.*s)\n", args);
		return null;
	}
	
    	buf = new char[1024];
    	ret = fread(cast(void*)buf.ptr, 1, 1024, f);
    
    	if (ret <= 0)
	{
		fprintf( stderr, "pkg-config not found or an error occured.\n" );
		fprintf( stderr, "Try running 'pkg-config' and see if it works.\n" );
		return null;
	}

    	buf = buf[0..ret];
    	ret = pclose(f);    
	
    	if (ret < 0)
	{
		fprintf(stderr, "pkg-config not found or an error occured.\n");
		fprintf(stderr, "Try running 'pkg-config' and see if it works.\n");
		return null;
	}

	_pkgs[args] = buf[0..length-2];
	return strip(buf);
}

class XmlParser: IParser
{
	this(char[] dir, char[] filename = "BuildInfo.xml", Project parent= null)
	{
		super(dir, filename, parent);
	}

	void run()
	{
	}
}

