#!/usr/bin/perl

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


# Create a randomly selected reviews set of EAC-to-CPF extraction driver files just like in
# createFileLists/*_list.xml, but with 1% of the number of records. Driver xml files are in review_file_lists,
# logs are in rlogs, and CPF output is in ./cpf_review

# Usage: ./build_review_list.pl

# After running this, run something like
# ./extract_all.pl review=1 inc_orig=1 > rev.log 2>&1 &

use strict;
use session_lib qw(:all);

main();
exit();

sub main
{
    my @lists = `find ./createFileLists -name "*_list.xml"`;
    chomp(@lists);

    my $xx;
    foreach my $filename (@lists)
    {
        my $outfile = $filename;
        $outfile =~ s/createFileLists/review_file_lists/;
        my @orig = read_file_array($filename);

        if (-e $outfile)
        {
            print "File exists, not overwriting: $outfile\n";
        }
        else
        {
            open(my $out, ">", $outfile);

            print "Reading: $filename\n";
            print "Writing: $outfile\n";

            foreach my $line (@orig)
            {
                if ($line =~ m/<i n=/)
                {
                    if (rand() < .01)
                    {
                        print $out "$line\n";
                    }
                } else
                {
                    print $out "$line\n";
                }
            }
            close($out);
            # if ($xx > 3)
            # {
            #     exit();
            # }
            # $xx++;
        }
    }
}
