module build.depends;

abstract class Depend
{
	bool dirty;
	
	bool isDirty( )
	{
		return dirty;
	}
	
	void build( )
	{
		
	}
	
	long modificationTime( )
	{
		return 0;
	}
	
	bool changedSince( long when )
	{
		if ( this.modificationTime == 0 )
			return false;
		
		return when > this.modificationTime;
	}
}
