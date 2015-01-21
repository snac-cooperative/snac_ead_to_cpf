#!/usr/bin/perl -n

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

# todo: if redirected, consider capturing the final redirect URL

# cat tmp_urls.xml | chk_url.pl > tmp.txt 2>&1 &

# Run from a special, empty subdir because sometimes wget downloads a real file. (Maybe after redirecting.)

# cd ./temp_chk
# cat ../url_xml/*.xml | perl -n -e 'if (rand() < .01) { print "$_";}' | ../chk_url.pl > tmp.txt 2>&1 &

use Time::HiRes qw(usleep nanosleep);

my $url = "";

# Put the internal variable $_ for stdin into a real variable.
$orig_input = $_;

# The only change we make to the original input line is to remove the trailing newline since \n often causes
# problems.
chomp($orig_input);

if ($orig_input =~ m/url=\"(.*?)\"/)
{
    # Sleep 250 milliseconds in an attempt to be nice to their web server.
    usleep(250000);
    $url = $1;

    # manually substitute any xml entities
    $url =~ s/\&amp;/\&/g;

    my $file = "";

    $orig_input =~ m/>findingAids\/(.*?)</;
    $file = $1;

    if ($url)
    {
        $cmd = "wget --spider \"$url\"";
        # If we are checking ncsu, must do a full GET request, so use a different cmd. 
        if ($url =~ m/ncsu\.edu/)
        {
            $cmd = "wget --delete-after \"$url\"";
        }
        $res = `$cmd 2>&1`;
        if ($res =~ m/(^Remote file exists)|(awaiting response\.\.\. 200 OK$)/sm)
        {
            # We have a hit.
            print "ok: $orig_input\n";
        }
        else
        {
            print "missing: $orig_input\n";
        }
    }
}

