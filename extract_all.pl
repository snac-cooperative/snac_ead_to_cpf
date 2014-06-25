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

# Testing and QA is run manually before running this script:

# saxon.sh qa.xml eadToCpf.xsl > qa.log 2>&1 &

# Run eadToCpf.xsl on each and every repository group list xml file, for example createFileLists/aao_list.xml

# ./extract_all.pl > ext.log 2>&1 &
# ./extract_all.pl review=1 > rev.log 2>&1 &
# ./extract_all.pl review=1 inc_orig=1 > rev.log 2>&1 &

# jun 2 2014: add localtime() so we can track how long each repo takes to run

# jun 16 2014 add command line arg "review" to make it run the review file lists

use strict;
use Data::Dumper;
use CGI; # Handles command line name=value pairs.

main();
exit();

sub main
{
    # Yes, I know we are a commandline app, but Perl's CGI allows us to use named args which is nice and
    # simple.

    my $qq = new CGI; 
    my %ch = $qq->Vars();

    my $list_dir = "createFileLists";
    my $log_dir = "logs";
    my $cpf_out = "cpf_extract";
    my $inc_orig = "";
    
    # Lazily don't support review=0 or inc_orig=0. No param equals the default.

    if (exists($ch{inc_orig}))
    {
        if ($ch{inc_orig} == 1)
        {
            $inc_orig = "inc_orig=1";
        }
        else
        {
            die "Bad value for param inc_orig: $ch{inc_orig}\n";
        }
    }        
    
    if (exists($ch{review}))
    {
        if ($ch{review} == 1)
        {
            $list_dir = "review_file_lists";
            $log_dir = "rlogs";
            $cpf_out = "cpf_review";
        }
        else
        {
            die "Bad value for param review: $ch{review}\n";
        }
    }

    my @xml_list = `find $list_dir -name "*_list.xml"`;
    chomp(@xml_list);
    printf("Found %s files in $list_dir, logging to $log_dir\n", scalar(@xml_list));
    
    if (! -d $log_dir)
    {
        system("mkdir $log_dir");
    }

    foreach my $file (@xml_list)
    {
        $file =~ m/\/(.*?)_list/;
        my $abbrev = $1;

        my $date = scalar(localtime());
        print "$abbrev $file $date\n";

        system("snac_transform.sh $file eadToCpf.xsl cpfOutLocation=$cpf_out $inc_orig > $log_dir/$abbrev.log 2>&1");
    }
}
