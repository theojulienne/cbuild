module build.actions;

class Action
{
	char[][char[]] params;
	
	char[] opIndex( char[] name )
	{
		return params[name];
	}
	
	int opIndexAssign( char[] value, char[] name )
	{
		params[name] = value;
		return 0;
	}
}
