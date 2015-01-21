#!/usr/bin/perl 

# ../url_download.pl ahub_newalluris.txt ahub_url_list.txt > ud.log 2>&1 &

use strict;
use Time::HiRes qw(usleep nanosleep);
my $delay_microsecs = 100000; # 100000 is 1/10 second, 250000 is 1/4 second

main();

sub main
{
    my $in;
    my $out;

    print "input: $ARGV[0] output: $ARGV[1]\n";

    if (-f $ARGV[0])
    {
        open($in, "<", $ARGV[0]) || die "Error: Can't open $ARGV[0] for read: $!\n";
        print "Open in succeeds for $ARGV[0]\n";
    }
    else
    {
        die "Open in failed\n";
    }

    open($out, ">", $ARGV[1]) || die "Error: Can't open $ARGV[1] for write: $!\n";
    print "Open out succeeds for $ARGV[1]\n";


    # First read the list of URLs and create a new file that is URL\tnew_filename

    my $xx = 1; # Counting number, not data index, so it starts at 1.
    while(my $temp = <$in>)
    {
        chomp($temp);
        my $out_file = "f_$xx.xml";
        print $out "$temp\t$out_file\n";
        $xx++;
    }
    close($in);
    close($out);

    # Now do the downloads, opening the output file we just created.

    open($in, "<", $ARGV[1]) || die "Error: Can't open $ARGV[1] for read: $!\n";

    # -p creates parents, also makes existing dir error go away.

    system("mkdir -p downloads");
    
    while(my $temp = <$in>)
    {
        chomp($temp);
        (my $url, my $safe_fn) = split("\t", $temp);
        my $cmd = "wget -O downloads/$safe_fn \"$url\"";
        print "cmd: $cmd\n";
        system($cmd);
        # Sleep (typically 100 or 250 milliseconds) in an attempt to be nice to their web server.
        usleep($delay_microsecs);
    }
    close($in);
}

