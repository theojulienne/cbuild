module parsers.iparser;

import build.projects;
import std.file;

abstract class IParser
{
	Project m_proj;
	char[] m_buildfile, m_filename, m_dir;
	Project m_parent;

	this(char[] dir, char[] filename = "BuildInfo", Project parent = null)
	{
		m_buildfile = dir ~ "/" ~ filename;
		std.file.isfile(m_buildfile);
		m_parent = parent;
		m_dir = dir;
		m_filename = filename;
	}

	Project project()
	{
		return m_proj;
	}

	char[] buildfile()
	{
		return m_buildfile;
	}

	abstract void run();
}

