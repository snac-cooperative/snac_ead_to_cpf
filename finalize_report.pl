#!/usr/bin/perl

# find /data/extract/ -maxdepth 1 -path "/data/extract/ead_*" ! -path "/data/extract/ead_sep*" -exec snac_transform.sh qa.xml report_cpf.xsl path={} \; > report.log 2>&1 &
# find /data/extract/ead_sep_30_2014/ -maxdepth 1 -mindepth 1 -exec snac_transform.sh qa.xml report_cpf.xsl path={} \; >> report.log 2>&1 &
# cat report.log| finalize_report.pl | less

use strict;
main();

sub main
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
