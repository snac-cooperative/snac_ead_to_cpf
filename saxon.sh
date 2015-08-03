#!/bin/bash
export CLASSPATH=$HOME/bin/saxon9he.jar:$CLASSPATH
java net.sf.saxon.Transform  ${1+"$@"}

# The various forum comments on using a separate resolver are beyond unclear. I don't have time to work out
# the details, so we filter incoming xml through a Perl script to remove any pesky doctype dtd declaraions.


# java net.sf.saxon.Transform  -r:org.apache.xml.resolver.tools.CatalogResolver  -x:org.apache.xml.resolver.tools.ResolvingXMLReader   -y:org.apache.xml.resolver.tools.ResolvingXMLReader ${1+"$@"}
