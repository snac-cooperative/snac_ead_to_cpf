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

# Originally, this script was a multiline -pi which changed the file in place. However, I couldn't get the
# utf8 pragmas to work with the BEGIN, so all that was scrapped, and now the script reads the file into
# memory, modifies it, writes a temp file, closes the temp file, and renames temp to the original.

# Change file in place. Backup original files before running this script.
# clean.pl file.xml

# > mkdir temp
# > find /data/source/findingAids/lds/ -type f | perl -ne 'print "../clean.pl $_";' > fix.sh
# > . fix.sh 

# Enable/disable various fixes by setting the if() to 1 or 0.

# Below is an example of stuff we need to comment out in EAD files. We aren't using the DTD. We aren't doing
# includes.

# <?xml version="1.0" encoding="UTF-8"?>
# <!DOCTYPE ead PUBLIC "+//ISBN 1-931666-00-8//DTD ead.dtd (Encoded Archival Description (EAD) Version 2002)//EN" "http://www.lib.usf.edu/ldsu/dtd/ead.dtd">
# <ead audience="external" relatedencoding="MARC21">

# Need utf8 so that regex will match. Using the utf8 pragma with stdin solved all of the other problems.

# The use open qw(:std :utf8); is a powerful pragma required to make Perl read stdin as utf8.

# See http://stackoverflow.com/questions/519309/how-do-i-read-utf-8-with-diamond-operator


use strict;
use utf8;
use open qw(:std :utf8);
use Getopt::Long;
my $debug = 0;

# Used to fix non-standard character entities. Hash keys are case sensitive.
my %ent = ('eacute' => '&#233;',
           'Eacute' => '&#201;',
           'copy' => '&#169;',
           'and' => '&amp;',
           'Uuml' => '&#220;',
           'uuml' => '&#252;',
           'aacute' => '&#225;',
           'oacute' => '&#243;',
           'Oacute' => '&#211;',
           'nbsp' => '&#160;',
           'egrave' => '&#232;', 
           'beta' => '&#946;',
           'ntilde' => '&#241;',
           'ccedil' => '&#231;'
          );


main();

sub main
{
    $| = 1; # unbuffer stdout
    GetOptions( 'debug!' => \$debug);

    my $out;
    my $tmp_fn = "tmp_$$.txt";
    if (! $debug)
    {
        open($out, ">", $tmp_fn) || die "Cant' open $tmp_fn for write\n";
    }
    $_ = read_file($ARGV[0]);
    work();
    if (! $debug)
    {
        print $out $_;
        close($out);
        rename($tmp_fn, $ARGV[0]);
    }
}


sub work
{

    my $address;  # = read_file("vt_address.xml");
    my $contact;  # = read_file("vt_contact.xml"); 

    if ($debug)
    {
        print "file: $ARGV[0]\n";

        # Replace any unicode hex 2014 em dash, also hex 2013 en dash with a hyphen.

        # xlf /data/source/findingAids/nwda/oregon_historical_society_research_library/OHYMSS1609.xml
         
        # <persname role="subject" encodinganalog="600" rules="aacr2" source="local">Huber, Oskar—Correspondence</persname>

        if ($_ =~ m/—|–/smg)
        {
            print "clean: Will change hex 2014 em dash to ascii hyphen\n";
        }

        if ($_ =~ m/–/smg)
        {
            print "clean: Will change hex 2013 en dash to ascii hyphen\n";
        }


        # We always want to remove the namespace in the <ead> element
        if ($_ =~ /(<ead[^>]*xmlns=")(.*?)(")/smg)
        {
            print "clean: Will remove namespace in the <ead> element\n";
        }

        # fix any non-standard entities we encounter
        
        if ($_ =~ m/\&([A-Za-z]+?)\;/sm && exists($ent{$1}))
        {
            print "clean: Will fix entity $1\n";
        }

        # 4th generation due to incomplete or buggy previous fixes. This code removes comments between
        # <?xml..> and <ead...> and comments out the entire region.

        # s/// is not greedy without /g since it only substitues one instance of a match. Trim whitespace
        # before fixing $proci.

        # This was run repeatedly on files and after the first fix makes no changes to already fixed files.

        # $_ =~ s/(<?xml.*?>)(.*?)(<ead.*?>)/$1fix-data-here$3/sm;

        # \s doesn't seem to make sense. We only do the XML header if there are non whitespace chars.
        # if ($_ =~ m/(<\?xml.*?>)([\S\s]+?)(<ead.*?>)/sm)

        if ($_ =~ m/(<\?xml.*?>)([\S]+?)(<ead.*?>)/sm)
        {
            # Intentionally put the unwanted header on a separate line. Some have a prefixed \n and some
            # don't, but if we want to use | sort | uniq -c we want the message to be consistent.
            print "clean: Will comment out unwanted XML headers:\n$2\n";
        }

        if ($_ =~ m/\240/sm)
        {
            print "clean: Will change non-breaking space (decimal 160 octal 240) to space\n";
        }

        exit();
    }

    if (1 && ! $debug)
    {
        # Remove any of those darned non-breaking spaces. Most of the downstream code won't handle them
        # properly, even though they seem to match \s+
        $_ =~ s/\240/ /smg;
    }

    if (1 && ! $debug)
    {
        # Replace any unicode hex 2014 em dash, also hex 2013 en dash with a hyphen.

        # xlf /data/source/findingAids/nwda/oregon_historical_society_research_library/OHYMSS1609.xml
         
        # <persname role="subject" encodinganalog="600" rules="aacr2" source="local">Huber, Oskar—Correspondence</persname>

        $_ =~ s/—|–/-/smg;
    }

    if (0 && ! $debug)
    {
        # We always want to remove the namespace in the <ead> element
        $_ =~ s/(<ead[^>]*xmlns=")(.*?)(")/$1$3/smg;
    }

    if (0 && ! $debug)
    {
        # Not a new generation of fixes to doctype, but instead fixing &address and &contact in VT aka vah xml
        # files.
        $_ =~ s/(\&address;)/$address/;
        $_ =~ s/\&contact;/$contact/;
    }


    if (0 && ! $debug)
    {
        # fix any non-standard entities we encounter
        
        if ($_ =~ m/\&([A-Za-z]+?)\;/sm && exists($ent{$1}))
        {
            $_ =~ s/\&([A-Za-z]+?)\;/$ent{$1}/smg;
        }
    }

    if (0 && ! $debug)
    {
        # Special cleaning because someone created a URL "ead.lib.virginia.edu:" (notice the trailing colon)
        # which should be "ead.lib.virginia.edu".
        $_ =~ s/ead.lib.virginia.edu:/ead.lib.virginia.edu/smg;
    }

    if (1 && ! $debug)
    {
        # 4th generation due to incomplete or buggy previous fixes. This code removes comments between
        # <?xml..> and <ead...> and comments out the entire region.

        # s/// is not greedy without /g since it only substitues one instance of a match. Trim whitespace
        # before fixing $proci.

        # This was run repeatedly on files and after the first fix makes no changes to already fixed files.

        # $_ =~ s/(<?xml.*?>)(.*?)(<ead.*?>)/$1fix-data-here$3/sm;

        # Don't comment out whitespace. (What? the regex below will match whitespace only, as well as a
        # mixture.)

        if ($_ =~ m/<\?xml.*?>([\S\s]+?)<ead.*?>/sm)
        {
            my $proci = $1;
            $proci =~ s/^\s+//smg;
            $proci =~ s/\s+$//smg;
            $proci =~ s/<\!--\s*//smg;
            $proci =~ s/\s*-->//smg;
            if ($proci)
            {
                $_ =~ s/(<\?xml.*?>)([\S\s]+?)(<ead.*?>)/$1$<!-- $proci -->$3/sm;
                
                # The old substitution which always added an XML comment
                # $_ =~ s/fix-data-here/<!-- $proci -->/sm;
            }
            # Else after trimming whitespace and XML comments there was nothing left, so nothing to do, and we
            # certainly don't want to add a pointless XML comment.
        }
    }

    if (0 && ! $debug)
    {
        die "3 gen";
        # <!-- DOCTYPE ead PUBLIC "+//ISBN 1-931666-00-8//DTD ead.dtd (Encoded Archival Description (EAD) Version 2002)//EN" "./dtds/ead.dtd" [<!ENTITY JSP_1.2_Tag_Library_Descriptor SYSTEM "file:/C:/Program%20Files/Oxygen%20XML%20Editor%2012/templates/JSP%201.2%20Tag%20Library%20Descriptor.xml" -->
        # ]>

        if ($_ =~ m/[<![^\]>]*?-->[^\]>]*?\]>/sm)
        {
            $_ =~ s/<!-- (DOCTYPE.*?) -->.*?]>/<!-- $1] -->/sm;
        }
        # else do nothing.
    }

    if (0 && ! $debug)
    {
        die "2 gen";
        # Version 2 when I discovered 986 files like this:
    
        # <?DOCTYPE ead PUBLIC "+//ISBN 1-931666-00-8//DTD ead.dtd (Encoded Archival Description (EAD) Version 2002)//EN" " "?>
    
        $_ =~ s/<\?(DOCTYPE.*?)>/<!-- $1 -->/sm;
    }

    if (0 && ! $debug)
    {
        die "1 gen";
        $_ =~ s/<!(DOCTYPE.*?)>/<!-- $1 -->/sm;
    }
} # main


sub read_file
{
    my @stat_array = stat($_[0]);
    if ($#stat_array < 7)
      {
        die "read_file: File $_[0] not found\n";
      }
    my $buffer;

    # It is possible that someone will ask us to open a file with a leading space.
    # That requires separate args for the < and for the file name.
    # It also works for files with trailing space.

    if (! open(IN, "<", $_[0]))
    {
	die "Could not open $_[0] $!\n";
    }

    my $full = "";
    while(sysread(IN, $buffer, 100000))
    {
        $full .= $buffer;
    }
    
    close(IN);
    return $full;
}


# old, pre-pi version

# while(my $temp = <>)
# {
#     $temp =~ s/<!(DOCTYPE.*?)>/<!-- $1 -->/;
#     print $temp;
# }
