#!/usr/bin/perl

# Author: Tom Laudeman
# The Institute for Advanced Technology in the Humanities

# Copyright 2014 University of Virginia. Licensed under the Educational Community License, Version 2.0
# (the "License"); you may not use this file except in compliance with the License. You may obtain a
# copy of the License at

# http://www.osedu.org/licenses/ECL-2.0
# http://opensource.org/licenses/ECL-2.0

# Unless required by applicable law or agreed to in writing, software distributed under the License is
# distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
# implied. See the License for the specific language governing permissions and limitations under the
# License.

# ./report_ead_entity_part.pl dir=lc_cpf_final/ > tmp.txt

use strict;
# use session_lib qw(:all);
use XML::XPath;
use CGI; # Handles command line name=value pairs.
use Time::HiRes qw(usleep nanosleep);

my $delay_microsecs = 100000; # 100000 is 1/10 second, 250000 is 1/4 second
main();
exit();

my $usage = "Usage $0 dir=somedirectory {url empty}";

sub main
{
    $| = 1; # unbuffer stdout.    
    
    # Cache each URL that we have already checked. No reason to re-check them.
    my %check_url;

    # Yes, I know we are a commandline app, but Perl's CGI allows us
    # to use named args which is kind of nice, and as simple as it gets.

    my $qq = new CGI; 
    my %ch = $qq->Vars();

    if (! exists($ch{dir}))
    {
        die "No directory specified.\n$usage\n";
    }

    if (! -e $ch{dir} || ! -d $ch{dir})
    {
        die "Specified does not exist or is not a directory.\n$usage\n";
    }

    # The linux find command will not work on a symlinked dir that doesn't have a trailing / so check and add one.

    if ($ch{dir} !~ m/\/$/)
    {
        $ch{dir} = "$ch{dir}/";
    }

    print "Scanning: $ch{dir}\n";

    $XML::XPath::Namespaces = 0;
    my @files = `find $ch{dir} -type f`;
    chomp(@files);
    print "Find done. File count: ". scalar(@files) . "\n";
    my $xx = 0;

    foreach my $file (@files)
    {
        print "       file: $file\n";
        my $xpath = XML::XPath->new(filename => $file);

        my $empty_nodes = $xpath->find('//part');
        if ($empty_nodes)
        {
            foreach my $node ($empty_nodes->get_nodelist())
            {
                # my $val = $node->toString();
                my $val = $node->string_value();
                print "       part: $val\n";
            }
        }
        $empty_nodes = $xpath->find('//ead_entity');
        if ($empty_nodes)
        {
            foreach my $node ($empty_nodes->get_nodelist())
            {
                # my $val = $node->toString();
                my $val = $node->string_value();
                print " ead_entity: $val\n\n";
            }
        }
        $xx++;
    }
}

