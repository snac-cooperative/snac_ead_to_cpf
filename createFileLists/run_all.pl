#!/usr/bin/perl

# We write output to ra.log below, so use a different log file for Perl/scripting/stderr/stdout logging.

# ./run_all.pl > rax.log 2>&1 &
# Note that the createList.xsl command below writes to ra.log.

# If you only want to run a single repo, follow this example:

# find /data/source/findingAids/aps/ -iname "*.xml" | perl -pe '$_ =~ s/\/data\/source\/findingAids\//.\//g' > aps_faList.txt
# ../snac_transform.sh dummy.xml createList.xsl abbreviation="aps" >> ra.log 2>&1


use strict;
use Data::Dumper;

main();
exit();

sub main
{
    my @dir_list = `find /data/source/findingAids/ -maxdepth 1 -mindepth 1 -type d`;
    chomp(@dir_list);
    printf("Found %s directories\n", scalar(@dir_list));
    foreach my $dir (@dir_list)
    {
        $dir =~ s/.*\/(.*)$/$1/;

        # Letting the shell do this is nice, but somewhat obscure, and the quoting would be a nightmare
        # without q().

        # This could be done with a Perl module, I'd have to find a good module, find examples, figure the
        # idioms, write the code, test the code. And I already know all about using "find".

        my $cmd = 'find /data/source/findingAids/';
        $cmd .= $dir;
        $cmd .= q(/ -iname "*.xml" | perl -pe '$_ =~ s/\/data\/source\/findingAids\//.\//g' > );
        $cmd .= $dir;
        $cmd .= '_faList.txt';
        print "$cmd\n";
        print `$cmd`;
        # system($cmd);

        # It is ok to >> into ra.log as long as the main command uses rax.log. Two processes writing to one
        # file destroys some output.

        print "../snac_transform.sh dummy.xml createList.xsl abbreviation=\"$dir\" >> ra.log 2>&1\n";

        system("../snac_transform.sh dummy.xml createList.xsl abbreviation=\"$dir\" >> ra.log 2>&1");

        printf("Done dir: $dir File count: %s", `wc -l $dir\_faList.txt`);
        print `grep -P "<i" $dir\_list.xml | wc -l`;
    }
}
