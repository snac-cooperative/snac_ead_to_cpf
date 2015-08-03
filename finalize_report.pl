#!/usr/bin/perl

# jul 14 2015 There were always issues with find -exec, so now use report_run_all.pl which has directory,
# label current/pending in a list of hash.

# report_run_all.pl > run.log 2>&1 &

# Don't do this.
# find /data/extract/ -maxdepth 1 -path "/data/extract/ead_*" ! -path "/data/extract/ead_sep*" -exec snac_transform.sh qa.xml report_cpf.xsl path={} \; > report.log 2>&1 &

# Don't do this either.
# find /data/extract/ead_sep_30_2014/ -maxdepth 1 -mindepth 1 -exec snac_transform.sh qa.xml report_cpf.xsl path={} \; >> report.log 2>&1 &

# Probably good to do this.
# cat report.log| finalize_report.pl | less

# cat report.log| finalize_report.pl --noheader | less


use strict;
use Getopt::Long;
use Data::Dumper;

main();

sub main
{
    $| = 1; # unbuffer stdout
    my $header = 1;
    GetOptions( 'header!' => \$header);

    # 2D list, list of lists
    my @table;

    if ($header)
    {
        # Deal with the head line
        my $temp = <>;
        chomp($temp);
        (my @cols) = split(/\t/, $temp);
        push(@table, \@cols);
    }

    # list of column sums. The first column is a label "Totals".
    my @sum = ('Totals');


    while (my $temp = <>)
    {
        # $col[0] first column hard coded as the repo name
        # Save each number, but formatted. Why don't we format later?
        chomp($temp);
        (my @cols) = split(/\t/, $temp);

        # Save the repo name in the first column
        # Note row increment vivifies the next row in the table.

        my @row = ();
        push(@row, $cols[0]);
        
        for my $col (1..$#cols)
        {
            $sum[$col] += $cols[$col];
            push(@row, format_number($cols[$col]));
        }
        push(@table, \@row);
    }

    foreach my $sum (@sum)
    {
        $sum = format_number($sum);
    }

    # Make the sums part of the table.
    push(@table, \@sum);

    # print Dumper(\@table);
    
    my @widths;

    foreach my $cols (@table)
    {
        # Hard to believe that $#{} will type cast list ref into a list.
        for my $col (0..$#{$cols})
        {
            if (length($cols->[$col]) > $widths[$col])
            {
                # Columns are wider than the data, add 3 places.
                $widths[$col] = length($cols->[$col]) + 3;
            }
        }
    }

    my $format;
    my $tween = '';
    foreach my $width (@widths)
    {
        $format .= "$tween\%$width.$width" . "s";
        $tween = ' '; 
    }
    $format .= "\n";

    foreach my $cols (@table)
    {
        printf($format, @{$cols});
    }
    

    exit();
}

sub old_main
{
    my %repoh;
    my $sum_total = 0;
    my $sum_corp = 0;
    my $sum_pers = 0;
    my $sum_family = 0;
    while (my $temp = <>)
    {
        (my $repo, my $total, my $corp, my $pers, my $family) = split(/\s+/, $temp);
        $sum_total += $total;
        $sum_corp += $corp;
        $sum_pers += $pers;
        $sum_family += $family;
        @{$repoh{$repo}} = (format_number($total), format_number($corp), format_number($pers), format_number($family));
    }

    my $max_key = 10;
    my $max_sum_total = 10;
    my $max_sum_corp = 10;
    my $max_sum_pers = 10;
    my $max_sum_family = 10;

    foreach my $key (keys(%repoh))
    {
        if ($max_key < length($key))
        {
            $max_key = length($key);
        }
    }

    if ($max_sum_total < length(format_number($sum_total)))
    {
        $max_sum_total = length(format_number($sum_total));
    }
    if ($max_sum_corp < length(format_number($sum_corp)))
    {
        $max_sum_corp = length(format_number($sum_corp));
    }
    if ($max_sum_pers < length(format_number($sum_pers)))
    {
        $max_sum_pers = length(format_number($sum_pers));
    }
    if ($max_sum_family < length(format_number($sum_family)))
    {
        $max_sum_family = length(format_number($sum_family));
    }

    my $format = sprintf("%%%d.%ds %%%d.%ds %%%d.%ds %%%d.%ds %%%d.%ds\n",
                         $max_key, $max_key,
                         $max_sum_total, $max_sum_total,
                         $max_sum_corp, $max_sum_corp,
                         $max_sum_pers, $max_sum_pers,
                         $max_sum_family, $max_sum_family);

    printf($format, "Name", "Total", "Corp", "Pers", "Family");

    foreach my $key (sort {$a cmp $b} keys(%repoh))
    {
        printf($format, $key, $repoh{$key}[0], $repoh{$key}[1], $repoh{$key}[2], $repoh{$key}[3]);
    }
    printf($format, "Total", format_number($sum_total), format_number($sum_corp), format_number($sum_pers), format_number($sum_family));
}

# This is simple and requires no extra modules.
sub format_number
{
    my $var = $_[0];
    $var =~ s/(?<=\d)(?=(?:\d{3})+\b)/,/g;
    return $var;
}
