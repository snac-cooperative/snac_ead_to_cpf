#!/usr/bin/perl

use strict;
use Getopt::Long;

my $debug = 0;

main();
exit();

sub main
{
    GetOptions( 'debug!' => \$debug);
    my $fname = $ARGV[0];
    if (! -f $fname)
    {
        die "Not a file or not existing: $fname\n";
    }
    my @lines = `cat $fname`;
    chomp(@lines);
    my $prev = "";
    my $do_mkdir = 1;
    # Must do this so the cp --parents starts from the correct origination.
    foreach my $line (@lines)
    {
        # Fixed find_empty_elements.pl to cache the bad host errors, so now we can simply check for missing,
        # and not have duplicates.

        # if ($line =~ m/(?:^missing:)|(?:bad host:)/)
        
        if ($line =~ m/missing:/)
        {
            $prev =~ m/file: .*_final\/(.*?)\/(.*)\.[cr]\d+\.xml/sm;
            my $repo = $1;
            my $dest_file = $2;

            # The CPF file is always .xml, but EAD are .xml or .XML, so we have to check with "ls", and then
            # capture the extension.
            my $source_glob = "/data/source/findingAids/$repo/$2.*";
            my $source = `ls $source_glob`;
            chomp($source);

            # Needs the leading greedy .* so that we only capture the final \..* because many files have
            # multiple . (dots). This could be more specific .xml since all files are .xml or .XML.
            # $source =~ m/.*\.(.*)$/;

            # Specifically match .xml or .XML (or even .Xml and so on). There's only one extension (case
            # insensitive) that we accept: xml. Anything else is an error.
            if ($source !~ m/\.(xml)$/i)
            {
                print "Can't get xml extention from: $source\n";
                next;
            }

            my $dest = "/data/source/findingAids/$repo\_missing\/$dest_file.$1";
            $dest =~ m/^(.*)\//;
            my $dest_path = $1;
            my $cmd1 = "mkdir -p  $dest_path";
            my $cmd2 = "mv -iv $source $dest";
            print "# $prev\n";
            if (! -d $dest_path)
            {
                print "$cmd1\n";
            }
                print "$cmd2\n";
            if (! $debug)
            {
                if (! -d $dest_path)
                {
                    print `$cmd1`;
                }
                print `$cmd2`;
            }
        }
        if ($line =~ m/^file:/)
        {
            $prev = $line;
        }
    }
}



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
