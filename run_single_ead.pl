#!/usr/bin/perl


use strict;
use Getopt::Long;
use IO::Handle;


my $source_dir = "/data/source/findingAids";
my $extract_dir = "/data/extract";
my $debug = 0;
my $check_url = 1;

main();
exit();

sub usage
{
    print "Usage:\n";
    print './run_single_ead.pl --repo repo [--debug] [--check_url] > repo.log 2>&1' . "\n";
    print "for example:\n";
    print './run_single_ead.pl --repo yale > yale.log 2>&1' . "\n";
    print "--repo is the finding aid repository, aka directory in $source_dir.\n";
    print "--debug prints the commands that will be run, but runs nothing.\n";
    print "--check_url defaults to true, use -c 0 or -nocheck_url or -noc to disable\n";
    print "Extracted data written to $extract_dir.\n";
    print "Supports -x and --x unique command line option shortening for all options.\nAlso supports -x=value syntax.\n";
    exit();
}

sub main
{
    my $repo;
    GetOptions( 'repo=s' => \$repo, 'debug!' => \$debug, 'check_url!' => \$check_url);

    if (! $repo)
    {
        usage();
    }

    # Check that we have a directory that matches the repo requested.

    my @valid_repos = `find $source_dir/ -maxdepth 1 -mindepth 1 -type d -printf "%f\n"`;
    chomp(@valid_repos);

    my $valid = 0;
    foreach my $item (@valid_repos)
    {
        if ($item eq $repo)
        {
            $valid = 1;
            last;
        }
    }
    if (! $valid)
    {
        use Data::Dumper;
        die "Repo $repo is not a valid repository/directory name\n" . Dumper(@valid_repos);
    }

    # Alternative:
    # open(STDOUT_AND_ERR_LOG, ">stdout_and_err.log") or die;
    # ensure all writes are immediately flushed STDOUT_AND_ERR_LOG->autoflush(1);
    # redirect both stdout and err to the log *STDERR = *STDOUT = *STDOUT_AND_ERR_LOG;

    # Yet another alternative:
    # reassign STDOUT, STDERR
    # open my $log_fh, '>>', '/logdirectory/the-log-file';
    # *STDOUT = $log_fh;
    # *STDERR = $log_fh;


    open(my $out, '>>', "repo_$repo.log") || die $!;
    $out->autoflush(1);
    STDOUT->fdopen($out, 'w' ) or die $!;
    STDERR->fdopen($out,  'w' ) or die $!;

    printf("         date: %s\n", scalar(localtime()));
    print  "   repository: $repo\n";
    print  "       source: $source_dir\n";
    print  "      extract: $extract_dir\n";
    print  "       script: $0\n";
    printf("          cwd: %s", `/bin/pwd`); # backtick'd commands have \n
    printf("          svn: %s", `svn info | grep "Revision"`); # backtick'd commands have \n
    print ("   check urls: ");
    if ($check_url)
    {
        print "enabled\n";
    }
    else
    {
        print("disabled\n");
    }

    # Write all output to repo_xyz.log where xys is the repository (collection) name which is in $repo. Both
    # STDOUT and STDERR go into the log file.

    # We append to an existing log file. If that gets to be a mess, the log file can be fixed manually, but at
    # least we will have all the records. Just warn if the log file exists.
    if (-e "repo_$repo.log")
    {
        print  "appending log: repo_$repo.log\n";
    }
    
    print "\n";

    print "# start in the EAD-to-CPF project directory\n";
    print "cd ~/ead2cpf_pack\n";
    if ($debug)
    {
        chdir("~/ead2cpf_pack");
    }
    
    my $cmd = '';

    my $dest = "$extract_dir/ead_$repo";

    if (-e $dest and -d $dest)
    {
        print "Extract destination exists. Please delete or rename. Exiting.\n";
        exit();
    }

    # Interestingly, a symlink with no destination can exist and will fail -e test, but the -l will be true.
    # Switch to using only -l which (should be) true for existing, and symlink. Might be slightly safer to use
    # ln -f -s.
    if (-l "$repo\_cpf_final")
    {
        print "# CPF output symlink exists. Will delete and recreate: $repo\_cpf_final\n";
        $cmd = "rm -f $repo\_cpf_final";
        do_cmd($cmd, 1);
    }

    print "# Create the extract directory\n";
    $cmd = "mkdir $dest";
    do_cmd($cmd, 0);

    print "# Create a local symlink to the extract directory\n";

    # Before running this command, make sure the dest directory of a symlink does not exist, otherwise ln -s
    # will not helpfully create a symlink inside the existing symlink with the original target's name, thus a
    # symlink loop.
    $cmd = "ln -s $dest $repo\_cpf_final";
    do_cmd($cmd, 0);

    print "# Verify that the dest dir is empty, and didn't accidentally get any extra symlinks\n";
    # Trying to figure out why there is a symlink to the dest directory inside the dest directory.
    $cmd = "ls -l $dest/*";
    do_cmd($cmd, 1);

    print "# Verify the local symlink\n";
    $cmd = "ls -ld $repo*";
    do_cmd($cmd, 1);
    # lrwxrwxrwx 1 twl8n snac 22 Oct  2 13:21 aps_cpf_final -> $extract_dir/ead_aps/
    
    $cmd = "snac_transform.sh createFileLists/$repo\_list.xml eadToCpf.xsl cpfOutLocation=$repo\_cpf_final inc_orig=0 > logs/$repo.log 2>&1";
    do_cmd($cmd, 0);

    print "# head of the log file, which can help document the process\n";
    $cmd = "head -n 15 logs/$repo\.log";
    do_cmd($cmd, 1);

    # http://stackoverflow.com/questions/5106097/perl-one-liner-with-single-quote
    # Have to escape ' and $ in "" with \

    print "# tail of the log file (minus blank lines), which might help document the process\n";
    $cmd = "grep -v \'^\$\' logs/$repo\.log | tail";
    do_cmd($cmd, 1);

    $cmd = "nice find $repo\_cpf_final/ -type f | nice parallel -X nice java -jar /usr/share/jing/bin/jing.jar /projects/socialarchive/published/shared/cpf.rng {} ::: > $repo\_jing.log 2> $repo\_jing_error.log";
    do_cmd($cmd, 0);

    print "# Check that jing validates. File sizes should be zero.\n";
    $cmd = "ls -l $repo\_jing*";
    do_cmd($cmd, 1);

    print "# Print the number of finding aid source files\n";
    $cmd = "find $source_dir/$repo -type f | wc -l";
    do_cmd($cmd, 1);

    print "# Count the .c01 files to make sure something isn't awry.\n";
    $cmd = "find $dest -name \"*.c01.xml\" | wc -l";
    do_cmd($cmd, 1);

    print "# Number of CPF files with \$_av should be zero. There have been bugs related to this.\n";
    $cmd = "grep -rc \"\\\$av_\" $repo\_cpf_final/ | grep -v :0 | wc -l";
    do_cmd($cmd, 1);

    print "# Count the number of files processed in the CPF log\n";
    $cmd = "grep fn: logs/$repo.log| wc -l";
    do_cmd($cmd, 1);

    print "# Count the error messages from the CPF extraction log\n";
    $cmd = "grep -i error logs/$repo.log| wc -l";
    do_cmd($cmd, 1);

    print "# Show counts for each unique type of warning in the CPF log. Some are normal.\n";
    print "# The rawExtract empty files will have no CPF output.\n";
    $cmd = "grep -i warning logs/$repo.log| sort | uniq -c";
    do_cmd($cmd, 1);

    print "# Count the number of CPF files created\n";
    $cmd = "find $repo\_cpf_final/ -type f | wc -l";
    do_cmd($cmd, 1);

    print "# Count the number of (unique) names that are >200 chars long.\n";
    $cmd ="perl -ne 'm/normalFinal: (.{200,}) type:/; if (\$1) { printf(\"%4d: %s...\\n\", length(\$1), substr(\$1,0,70))}' logs/$repo.log| sort -u | wc -l";
    do_cmd($cmd, 1);

    $cmd = "nice ~/eac_project/find_empty_elements.pl dir=$repo\_cpf_final empty > $repo\_final_empty.log 2>&1";
    do_cmd($cmd, 0);

    print "# Check the list of unique empty elements and attributes. Some are expected.\n";
    $cmd = "grep empty: $repo\_final_empty.log| sort | uniq -c";
    do_cmd($cmd, 1);

    print "# Count the empty urls from the finding aid url file for this repository\n";
    $cmd = "grep 'url=\"\"' url_xml/$repo\_url.xml| wc -l";
    do_cmd($cmd, 1);

    print "# Count the non-empty urls\n";
    $cmd = "grep -v 'url=\"\"' url_xml/$repo\_url.xml| grep file | wc -l";
    do_cmd($cmd, 1);

    print "# Count the number of file elements in the url file\n";
    $cmd = "grep 'file' url_xml/$repo\_url.xml| wc -l";
    do_cmd($cmd, 1);

    if ($check_url)
    {
        $cmd = "nice ~/eac_project/find_empty_elements.pl dir=$repo\_cpf_final url > $repo\_final_url.log 2>&1";
        do_cmd($cmd, 0);

        print "# Confirm that we have a missing test confirmed on the URL checking.\n";
        $cmd = "head $repo\_final_url.log";
        do_cmd($cmd, 1);

        print "# Count the number of finding aids with missing/404 URLs\n";
        $cmd = "grep missing: $repo\_final_url.log| wc -l";
        do_cmd($cmd, 1);
    }
    else
    {
        print "# Not checking for missing finding aids\n";
    }
    printf("finish date: %s\n\n", scalar(localtime()));
}

# do_cmd(string the_command, boolean print_to_stdout)
# We need an easy way to run a command and print stdout, or run a command silently.

sub do_cmd
{
    printf("# start time: %s\n", scalar(localtime()));
    print "> $_[0]\n";
    if ($debug)
    {
        return;
    }
    if ($_[1])
    {
        print `$_[0]`;
    }
    else
    {
        system($_[0]);
    }
    print "\n";
}
