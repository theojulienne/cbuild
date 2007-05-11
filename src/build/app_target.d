module build.app_target;

import build.targets;

class ApplicationTarget : Target
{
	char name[];
	
	this( char[] _name )
	{
		name = _name;
	}
	
	char[] toString( )
	{
		return name ~ " (Appln)";
	}
}
