#!/usr/bin/perl

use strict;

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

# ./build_geo_xml.pl input.txt > output.xml
# if tmp.txt input file then
# ./build_geo_xml.pl > output.xml

# This script looks for geonames_files/goe_all.xml and tracks the placeEntry values. It will not output any
# placeEntry that is already known.

main();
exit();

sub main
{
    # geonames hash key is geog name string, value is an integer. We really only want to key to use for
    # exists() tests later.
    my %gn;
    if (-d "geonames_files" && -e "geonames_files/geo.xml")
    {
        open(my $in, "<", "geonames_files/geo.xml");
        while(my $temp = <$in>)
        {
            if ($temp =~ m/<placeEntry>(.*)<\/placeEntry>/)
            {
                # Just increment the value using $1 as the key. If the key exists, we get an increment. If the
                # key does not yet exist, we (essentially) get value 1.
                $gn{lc($1)}++;
            }
        }
        close($in);
    }

    # use Data::Dumper;
    # die Dumper(\%gn);
    
    my $infile = "tmp.txt";
    if (-e $ARGV[0])
    {
        $infile = $ARGV[0];
    }
    elsif (! -e $infile)
    {
        die "No input file name on command line, and file \"tmp.txt\" not found\n";
    }

    print "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
    print "<places>\n";
    open(my $in, "<", $infile);
    while(my $temp = <$in>)
    {
        $temp =~ m/<normalized>(.*)<\/normalized>/;
        my $cpf_name = $1;

        # Fix "foo -- bar" to be "foo--bar"
        $cpf_name =~ s/\s+--\s+/--/g;

        # Only output new, unique, cpfName values.
        if (! exists($gn{lc($cpf_name)}))
        {
            print "<place>\n";
            print "<cpfName>$cpf_name<\/cpfName>\n";
            print "<\/place>\n";
        }
        else
        {
            # Escape -- for xml comments.
            $cpf_name =~ s/(\-){2,}/\\-\\-/g;
            print "<!-- not unique: $cpf_name -->\n";
        }
    }
    print "<\/places>\n";
    close($in);
}
