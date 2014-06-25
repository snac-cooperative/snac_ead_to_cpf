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

# cd /data/source
# tar -hcf /lv3/data/finding_aids_`date +"%F-%H%M%S"`.tar ./findingAids/
# cd ~/ead2cpf_pack
# find /data/source/findingAids/ -type f > fix_fname.sh 
# cat fix_fname.sh | fix_fname.pl > fix.log 2>&1

use strict;

while(my $in = <>)
{
    chomp($in);

    # Fix an filenames with characters we don't like, or ".." which is marginal. Many scripts look for dot in
    # file names, so remove double dot is a good idea.

    if ($in =~ m/[^A-Za-z0-9_\-\.\/]/ || $in =~ m/\.\./)
    {
        my $new = $in;
        
        $new =~ s/\.\././g;
        $new =~ s/[^A-Za-z0-9_\-\.\/]+/_/g;

        # this must be last so space is changed to underscore, otherwise we can have "ms. .col" changed to
        # "ms..col"
        $new =~ s/ \././;

        if (-e $in)
        {
            print "rename($in, $new)\n";
            
            # Use rename() instead of mv so we don't have to worry about command line quoting. There might be
            # names with " or '
            
            rename($in, $new) || die "Rename failed for \"$in\" to \"$new\"\n$!\n";
        }
    }
}
