module build.options;

class Option
{
	static Option options[];
	char[] name;
	char[] value;
	bool is_real;
	char[] description;
	
	this( char[] _name, char[] _value )
	{
		int n = options.length;
		name = _name;
		value = _value;
		options.length = n + 1;
		options[n] = this;
	}
	
	this( char[] name ) { this( name, "" ); }
	
	static Option add( char[] _name, char[] _value )
	{
		foreach ( o; options )
		{
			if ( o.name == _name )
				return o;
		}
		
		return new Option( _name, _value );
	}
	
	static Option get( char[] _name )
	{
		foreach ( o; options )
		{
			if ( o.name == _name )
				return o;
		}
		
		return new Option( _name );
	}
}
