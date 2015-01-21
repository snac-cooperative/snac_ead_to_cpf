#!/usr/bin/perl

use strict;
use Data::Dumper;

# Author: Tom Laudeman, Daniel Pitti
# The Institute for Advanced Technology in the Humanities

# Copyright 2013 University of Virginia. Licensed under the Educational Community License, Version 2.0
# (the "License"); you may not use this file except in compliance with the License. You may obtain a
# copy of the License at

# http://www.osedu.org/licenses/ECL-2.0
# http://opensource.org/licenses/ECL-2.0

# Unless required by applicable law or agreed to in writing, software distributed under the License is
# distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
# implied. See the License for the specific language governing permissions and limitations under the
# License.

# Testing and QA is run manually before running this script:

# saxon.sh qa.xml fix_url.xsl 2> fix.log > fix.xml

# Create the XML files that associate each EAD file (record) with the URL of the finding aid. For historical
# reasons this is "fixing" the URLs. This script doesn't take very long to run.

# Run this script one time when the EAD files are cleaned and ready for processing. Run this before
# eadToCpf.xsl.

# If an EAD repository is modified, you can run fix_url.xsl on a single repo without re-running
# everything. See fix_url.xsl.

# Run fix_url.xsl on each and every repository group list xml file, for example createFileLists/aao_list.xml
# The main script logs to rfa.log, saxon logging is in fix.log, and output is written to individual files in
# ./url_xml/*_url.xml.

# ./run_fix_all.pl > rfa.log 2>&1 &

main();
exit();

sub main
{
    if (! -d "url_xml")
    {
        mkdir("url_xml");
    }
    my @xml_list = `find createFileLists -name "*_list.xml"`;
    chomp(@xml_list);
    printf("Found %s files\n", scalar(@xml_list));
    unlink("fix.log");
    
    foreach my $file (@xml_list)
    {
        $file =~ m/\/(.*?)_list/;
        my $abbrev = $1;

        print "$abbrev $file\n";
        my $cmd = "snac_transform.sh $file fix_url.xsl 2>> fix.log > url_xml/$abbrev\_url.xml";
        print "$cmd\n";
        system($cmd);
    }
}
