#!/usr/bin/perl

# Jul 15 2015. Running report_cpf.xsl from "find -exec" has issues and was always fairly awkward. Create a
# list of hash with the necessary config and run report_cpf.xsl here to keep everything neat and
# organized. Note the config for /data/extract/ead_sep_30_2014.

# ./report_run_all.pl > run.log 2>&1 &
# Creates curr_report.csv, pending_report.csv

# Run finalize_report.pl to create formatted output, or just use the csv files in a spreadsheet.
# cat curr_report.csv| finalize_report.pl > curr_formatted.txt
# cat pending_report.csv| finalize_report.pl > pending_formatted.txt
# cat all_report.csv| finalize_report.pl > all_formatted.txt

use strict;

$| = 1; # unbuffer stdout

# curr => 1 is already done
# curr => 0 is pending
my @list = (
            {
             dir => "/data/extract/ead_aao",
             curr => 1,
             title => 'AAO (EAD)'
            },
            {
             dir => "/data/extract/britlib",
             curr => 1,
             title => 'British Library'
            },
            {
             dir => "/data/extract/ead_aar",
             curr => 1,
             title => 'AAR (EAD)'
            },
            {
             dir => "/data/extract/ead_afl",
             curr => 1,
             title => 'AFL (EAD)'
            },
            {
             dir => "/data/extract/ead_afl-ufl",
             curr => 1,
             title => 'AFL-UFL (EAD)'
            },
            {
             dir => "/data/extract/ead_ahub",
             curr => 1,
             title => 'AHUB (EAD)'
            },
            {
             dir => "/data/extract/ead_aps",
             curr => 1,
             title => 'APS (EAD)'
            },
            {
             dir => "/data/extract/ead_byu",
             curr => 1,
             title => 'BYU (EAD)'
            },
            {
             dir => "/data/extract/ead_cjh",
             curr => 1,
             title => 'CJH (EAD)'
            },
            {
             dir => "/data/extract/ead_colu",
             curr => 1,
             title => 'COLU (EAD)'
            },
            {
             dir => "/data/extract/ead_crnlu",
             curr => 1,
             title => 'CRNLU (EAD)'
            },
            {
             dir => "/data/extract/ead_duke",
             curr => 1,
             title => 'DUKE (EAD)'
            },
            {
             dir => "/data/extract/ead_fsga",
             curr => 1,
             title => 'FSGA (EAD)'
            },
            {
             dir => "/data/extract/ead_harvard",
             curr => 1,
             title => 'HARVARD (EAD)'
            },
            {
             dir => "/data/extract/ead_howard",
             curr => 1,
             title => 'HOWARD (EAD)'
            },
            {
             dir => "/data/extract/ead_inu",
             curr => 1,
             title => 'INU (EAD)'
            },
            {
             dir => "/data/extract/ead_mhs",
             curr => 1,
             title => 'MHS (EAD)'
            },
            {
             dir => "/data/extract/ead_mit",
             curr => 1,
             title => 'MIT (EAD)'
            },
            {
             dir => "/data/extract/ead_ncsu",
             curr => 1,
             title => 'NCSU (EAD)'
            },
            {
             dir => "/data/extract/ead_nlm",
             curr => 1,
             title => 'NLM (EAD)'
            },
            {
             dir => "/data/extract/ead_nmaia",
             curr => 1,
             title => 'NMAIA (EAD)'
            },
            {
             dir => "/data/extract/ead_nwda_new",
             curr => 1,
             title => 'NWDA (EAD)'
            },
            {
             dir => "/data/extract/ead_nwu",
             curr => 1,
             title => 'NWU (EAD)'
            },
            {
             dir => "/data/extract/ead_nypl",
             curr => 1,
             title => 'NYPL (EAD)'
            },
            {
             dir => "/data/extract/ead_nysa",
             curr => 1,
             title => 'NYSA (EAD)'
            },
            {
             dir => "/data/extract/ead_nyu",
             curr => 1,
             title => 'NYU (EAD)'
            },
            {
             dir => "/data/extract/ead_ohlink",
             curr => 1,
             title => 'OHLINK (EAD)'
            },
            {
             dir => "/data/extract/ead_pacscl",
             curr => 1,
             title => 'PACSCL (EAD)'
            },
            {
             dir => "/data/extract/ead_pu",
             curr => 1,
             title => 'PU (EAD)'
            },
            {
             dir => "/data/extract/ead_riamco",
             curr => 1,
             title => 'RIAMCO (EAD)'
            },
            {
             dir => "/data/extract/ead_rmoa",
             curr => 1,
             title => 'RMOA (EAD)'
            },
            {
             dir => "/data/extract/ead_rutu",
             curr => 1,
             title => 'RUTU (EAD)'
            },
            {
             dir => "/data/extract/ead_syru",
             curr => 1,
             title => 'SYRU (EAD)'
            },
            {
             dir => "/data/extract/ead_uil",
             curr => 1,
             title => 'UIL (EAD)'
            },
            {
             dir => "/data/extract/ead_uks",
             curr => 1,
             title => 'UKS (EAD)'
            },
            {
             dir => "/data/extract/ead_umd",
             curr => 1,
             title => 'UMD (EAD)'
            },
            {
             dir => "/data/extract/ead_umi",
             curr => 1,
             title => 'UMI (EAD)'
            },
            {
             dir => "/data/extract/ead_umn",
             curr => 1,
             title => 'UMN (EAD)'
            },
            {
             dir => "/data/extract/ead_unc",
             curr => 1,
             title => 'UNC (EAD)'
            },
            {
             dir => "/data/extract/ead_unl",
             curr => 1,
             title => 'UNL (EAD)'
            },
            {
             dir => "/data/extract/ead_utsa",
             curr => 1,
             title => 'UTSA (EAD)'
            },
            {
             dir => "/data/extract/ead_utsu",
             curr => 1,
             title => 'UTSU (EAD)'
            },
            {
             dir => "/data/extract/ead_uut",
             curr => 1,
             title => 'UUT (EAD)'
            },
            {
             dir => "/data/extract/ead_vah_new",
             curr => 1,
             title => 'VAH (EAD)'
            },
            {
             dir => "/data/extract/ead_yale",
             curr => 1,
             title => 'YALE (EAD)'
            },
            {
             dir => "/data/extract/nysa",
             curr => 1,
             title => 'NYSA Agencies'
            },
            {
             dir => "/data/extract/sia_agencies",
             curr => 1,
             title => 'SIA Agencies'
            },
            {
             dir => "/data/extract/sia_fb_cpf",
             curr => 1,
             title => 'SIA Fieldbooks'
            },
            {
             dir => "/data/extract/ead_uchic",
             curr => 1,
             title => 'UCHIC (EAD)'
            },
            {
             dir => "/data/extract/ead_uct",
             curr => 1,
             title => 'UCT (EAD)'
            },
            {
             dir => "/data/extract/WorldCat",
             curr => 1,
             title => 'WorldCat'
            },
            {
             dir => "/data/extract/nara",
             curr => 1,
             title => 'NARA (person)'
            },
            {
             dir => "/data/extract/lds",
             curr => 1,
             title => 'LDS (EAD)'
            },
            {
             dir => "/data/extract/henry_cpf",
             curr => 1,
             title => 'Henry'
            },
            {
             dir => "/data/extract/ead_sep_30_2014/lc",
             curr => 1,
             title => 'LC (EAD)'
            },
            {
             dir => "/data/extract/ead_sep_30_2014/oac",
             curr => 1,
             title => 'OAC (EAD)'
            },


            # Pending
            {
             dir => "/data/extract/anf",
             curr => 0,
             title => 'AnF'
            },
            {
             dir => "/data/extract/ead_bnf",
             curr => 0,
             title => 'BnF (EAD)'
            },
            {
             dir => "/data/extract/ead_ccfr",
             curr => 0,
             title => 'CCFr (EAD)'
            },
            {
             dir => "/data/extract/chaco",
             curr => 0,
             title => 'Chaco'
            },
            {
             dir => "/data/extract/ead_fivecol",
             curr => 0,
             title => 'Fivecol (EAD)'
            },
            {
             dir => "/data/extract/ead_ual",
             curr => 0,
             title => 'UAL (EAD)'
            },
            {
             dir => "/data/extract/ead_ude",
             curr => 0,
             title => 'UDE (EAD)'
            },
            {
             dir => "/data/extract/whitman",
             curr => 0,
             title => 'Whitman'
            },
           );

`echo "repository\ttotal\tcorporateBody\tperson\tfamily\tbiogHist" > curr_report.csv`;
`echo "repository\ttotal\tcorporateBody\tperson\tfamily\tbiogHist" > pending_report.csv`;

foreach my $hr (@list)
{
    my $log = 'pending_report.csv';
    if ($hr->{curr})
    {
        $log = 'curr_report.csv';
    }

    # Use sprintf with non-interpolating format string so we don't have to escape special chars like &
    
    my $cmd = sprintf('snac_transform.sh qa.xml report_cpf.xsl path=%s repository="%s" >> %s 2>&1',
                      $hr->{dir},
                      $hr->{title},
                      $log);

    print "Running: $cmd\n";
    
    `$cmd`;
    # exit after one during testing
    # exit();
}

exit();
