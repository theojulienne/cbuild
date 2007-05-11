module build.projects;

import build.targets;
import build.depends;

class Project : Target
{
	char name[];
	
	this( char[] _name )
	{
		name = _name;
	}
	
	char[] toString( )
	{
		return name ~ " (Project)";
	}
	
	void doDeps( )
	{
		
	}
}

class ProjectDepend : Depend
{
	Project proj;
	
	this( Project _proj )
	{
		proj = _proj;
	}
	
	bool isDirty( ) { return proj.dirty; }
	
	void build( )
	{
		proj.build( );
	}
}