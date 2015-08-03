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

# ./report_cpf_date.pl dir=cpf_qa/ > tmp.txt

use strict;
# use session_lib qw(:all);
use XML::XPath;
use CGI; # Handles command line name=value pairs.
use Time::HiRes qw(usleep nanosleep);

main();
exit();

my $usage = "Usage $0 dir=somedirectory";

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
        # print "       file: $file\n";
        my $xpath = XML::XPath->new(filename => $file);

        my $nodes = $xpath->find('/eac-cpf/control/sources/source/objectXMLWrap/container/ead_entity');
        my $tween = '';
        my $orig = '';
        my $final = '';
        my $orig_val = '';
        my $final_val = '';
        if ($nodes)
        {
            foreach my $node ($nodes->get_nodelist())
            {
                $orig_val = $node->string_value();
                while($orig_val =~ m/(\d{4})/g)
                {
                    $orig .= $tween . $1;
                    $tween = ' ';
                }
            }
        }
        $nodes = $xpath->find('/eac-cpf/cpfDescription/identity/nameEntry/part');
        $tween = '';
        if ($nodes)
        {
            foreach my $node ($nodes->get_nodelist())
            {
                $final_val = $node->string_value();
                while($final_val =~ m/(\d{4})/g)
                {
                    $final .= $tween . $1;
                    $tween = ' ';
                }
            }
        }
        print "--\nfile: $file\n";
        if ($orig ne $final)
        {
            print "mismatch:  orig: $orig\n";
            print "mismatch: final: $final\n";
            print " orig: $orig_val\n";
            print "final: $final_val\n";
        }
    }
}

