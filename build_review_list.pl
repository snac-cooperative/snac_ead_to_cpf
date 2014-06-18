#!/usr/bin/perl

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
