module build.lib_target;

import build.targets;

class LibraryTarget : Target
{
	char name[];
	
	this( char[] _name )
	{
		name = _name;
	}
	
	char[] toString( )
	{
		return name ~ " (Library)";
	}
	
	void runTool( )
	{
		char[] objs;
		foreach ( t; targets )
		{
			objs ~= t.target;
			objs ~= " ";
		}
		
		writefln( "LN %s (not really)", name );
		writefln( " [%s]", objs );
	}
}
