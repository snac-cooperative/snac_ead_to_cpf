#!/usr/bin/perl -pi

use strict;

# Change file in place. Backup original files before running this script.
# clean.pl file.xml

# > mkdir temp
# > find /data/source/findingAids/lds/ -type f | perl -ne 'print "../clean.pl $_";' > fix.sh
# > . fix.sh 

# Enable/disable various fixes by setting the if() to 1 or 0.

# Multiline match reads all input into $_ via the BEGIN, then use /sm regex to match newlines with . (dot)

# -pi auto read stdin, change in place, and print. Input is in $_ and $_ is printed after the script is
# run. So, in thise case we only need two lines of code.

# <?xml version="1.0" encoding="UTF-8"?>
# <!DOCTYPE ead PUBLIC "+//ISBN 1-931666-00-8//DTD ead.dtd (Encoded Archival Description (EAD) Version 2002)//EN" "http://www.lib.usf.edu/ldsu/dtd/ead.dtd">
# <ead audience="external" relatedencoding="MARC21">

BEGIN {undef $/;}

main();
# don't exit(), or the print of -p will not happen. 

sub main
{
    my $address;  # = read_file("vt_address.xml");
    my $contact;  # = read_file("vt_contact.xml"); 

    if (0)
    {
        # We always want to remove the namespace in the <ead> element
        $_ =~ s/(<ead[^>]*xmlns=")(.*?)(")/$1$3/smg;
    }

    if (0)
    {
        # Not a new generation of fixes to doctype, but instead fixing &address and &contact in VT aka vah xml
        # files.
        $_ =~ s/(\&address;)/$address/;
        $_ =~ s/\&contact;/$contact/;
    }


    if (1)
    {
        # fix any non-standard entities we encounter
        
        # hash keys are case sensitive
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
        if ($_ =~ m/\&([A-Za-z]+?)\;/sm && exists($ent{$1}))
        {
            $_ =~ s/\&([A-Za-z]+?)\;/$ent{$1}/smg;
        }
    }

    if (0)
    {
        # Special cleaning because someone created a URL "ead.lib.virginia.edu:" (notice the trailing colon)
        # which should be "ead.lib.virginia.edu".
        $_ =~ s/ead.lib.virginia.edu:/ead.lib.virginia.edu/smg;
    }

    if (1)
    {
        # 4th generation due to incomplete or buggy previous fixes. This code removes comments between
        # <?xml..> and <ead...> and comments out the entire region.

        # s/// is not greedy without /g since it only substitues one instance of a match. Trim whitespace
        # before fixing $proci.

        # This was run repeatedly on files and after the first fix makes no changes to already fixed files.

        $_ =~ s/(<?xml.*?>)(.*?)(<ead.*?>)/$1fix-data-here$3/sm;
        my $proci = $2;
        $proci =~ s/^\s+//smg;
        $proci =~ s/\s+$//smg;
        $proci =~ s/<\!--\s*//smg;
        $proci =~ s/\s*-->//smg;
        $_ =~ s/fix-data-here/<!-- $proci -->/sm;
    }

    if (0)
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

    if (0)
    {
        die "2 gen";
        # Version 2 when I discovered 986 files like this:
    
        # <?DOCTYPE ead PUBLIC "+//ISBN 1-931666-00-8//DTD ead.dtd (Encoded Archival Description (EAD) Version 2002)//EN" " "?>
    
        $_ =~ s/<\?(DOCTYPE.*?)>/<!-- $1 -->/sm;
    }

    if (0)
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
    my $temp;

    # It is possible that someone will ask us to open a file with a leading space.
    # That requires separate args for the < and for the file name.
    # It also works for files with trailing space.

    if (! open(IN, "<", $_[0]))
    {
	die "Could not open $_[0] $!\n";
    }
    sysread(IN, $temp, 100000); # $stat_array[7]);
    close(IN);
    return $temp;
}


# old, pre-pi version

# while(my $temp = <>)
# {
#     $temp =~ s/<!(DOCTYPE.*?)>/<!-- $1 -->/;
#     print $temp;
# }
