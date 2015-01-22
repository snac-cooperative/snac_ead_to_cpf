#!/usr/bin/perl

# Find /'s / in ead_entity.

# ./check_quote_s.pl -s aps_cpf_final > aps_quote_s.log &

# <ead_entity en_type="persname" source="ingest">"A General Officer". Pawlings's Mills</ead_entity>

# <sources>
#    <source xmlns:xlink="http://www.w3.org/1999/xlink"
#            xlink:type="simple"
#            xlink:href="http://www.amphilsoc.org/mole/view?docId=ead/Mss.B.F85inventory13-ead.xml">
#       <objectXMLWrap>
#          <container xmlns="">
#             <filename>/data/source/findingAids/aps/Mss.B.F85inventory13-ead.xml</filename>
#             <ead_entity en_type="persname" source="ingest">"A General Officer". Pawlings's Mills</ead_entity>
#          </container>
#       </objectXMLWrap>
#    </source>
# </sources>

use strict;
# use session_lib qw(:all);
use XML::XPath;
# Need this so that regex will match. Using the utf8 pragma with stdin solved all of the other problems.
use utf8;

# Powerful pragma. http://stackoverflow.com/questions/519309/how-do-i-read-utf-8-with-diamond-operator
# Required to make Perl read stdin as utf8.
use open qw(:std :utf8);

use Getopt::Long;

my $debug = 0;

main();

sub main
{
    $| = 1;                     # unbuffer stdout.
    $XML::XPath::Namespaces = 0;
    my $search_path = "aps_cpf_final";
    
    GetOptions('debug' => \$debug, 'search_path=s' => \$search_path);

    if (! -e $search_path)
    {
        die "Can't find search_path: $search_path\n";
    }

    # Add trailing / to $search_path. The regex says when there are zero or more / at the end, change to a
    # single /
    $search_path =~ s/\/{0,}$/\//;

    print "Search path: $search_path\n";

    my @list;

    if ($debug)
    {
        # Test with this single file:
        @list = `find aps_cpf_final/aps/ -name "Mss.B.F85inventory13-ead.r342.xml"`;
    }
    else
    {
        # Must / terminate the path because these CPF extraction directories are symlinks
        @list = `find $search_path -type f`;
    }

    chomp(@list);

    print "Number of files: " . scalar(@list) . "\n";

    foreach my $file (@list)
    {
        my $xpath = XML::XPath->new(filename => $file);

        my $ead_name = $xpath->find('normalize-space(/eac-cpf/control/sources/source/objectXMLWrap/container/ead_entity)');

        # print "en: $ead_name\n";

        if ($ead_name =~ m/\'s\s+/)
        {
            my $cpf_name = $xpath->find("normalize-space(/eac-cpf/cpfDescription/identity[entityType = 'person']/nameEntry/part)");
            if ($cpf_name)
            {
                print "found: file: $file ead_name: $ead_name cpf_name $cpf_name\n";
            }
        } else
        {
            # Do nothing
        }
    }
}
