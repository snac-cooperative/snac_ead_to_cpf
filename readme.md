

Table of contents
-----------------
* [Overview of EAD to CPF](#overview-of-ead-to-cpf)


Overview of EAD to CPF
-------------------------

These scripts extract EAD-CPF (CPF) XML from EAD XML finding aids. A variety of local practices are supported in the incoming EAD. This process is intended to extract large numbers of files, and so it is designed as a bulk pipeline. Running small numbers of files is fairly easy, but the initial set up and configuration cannot be skipped.

Required steps:

0.1) symlink to session_lib.pm or copy into this dir

1) create file lists

2) create the ead urls aka "fix urls"

2.1) create the geonames xml file geo.xml. See geo.xsl.

3) run the cpf conversion

4) validate with jing

Creating the file lists
-----------------------

    cd createFileLists
    ./run_all.pl > rax.log 2>&1 &

or you can run a single collection aka dir, in this case mhs:

    ../snac_transform.sh dummy.xml createList.xsl abbreviation=\"mhs\" >> ra.log 2>&1

Creating the list of resource URLs 
----------------------------------

The URLs of the finding aids are always the same, unless a repository changed their method of determining
persistent ids. Since these URLs are static, we save computing time by building an XML data file for each
repository's URLs. When running the CPF extraction we quickly look up the URL. The external XML files are
useful for other purposes such as checking the existence of a document at each URL.

Run urls for just one collection, mhs.

    snac_transform.sh createFileLists/mhs_list.xml fix_url.xsl 2> tmp.log > url_xml/mhs_url.xml

Run all the URLs aka "fixed urls". This reads the file lists from ./createFileLists/ so the previous step must be up to date.

    ./run_fix_all.pl > rfa.log 2>&1 &        

The QA files
------------

QA and testing is a good idea. See qa.xml for comments about what each input file tests. Note that QA
cannot test URL substitution in CPF because the collection sourceCode is per-file not per-record. QA
can be run through fix_ur.xsl to generate URLs.

An entire collection is run without regard to $start and $stop. Small batches for testing are handled by qa.xml and qa2.xml.

    snac_transform.sh qa.xml eadToCpf.xsl > qa.log 2>&1 &
    snac_transform.sh qa2.xml eadToCpf.xsl > qa.log 2>&1 &

In the past, variables start and stop in variables.xsl controled how much of the xml file is processed,
unless the xml file had force="1", but now we just run the entire input.

    snac_transform.sh qa.xml eadToCpf.xsl cpfOutLocation="cpf_qa" > qa.log 2>&1 &

Use command line param inc_orig to get the original EAD in the CFP output objectXML.

    snac_transform.sh qa2.xml eadToCpf.xsl cpfOutLocation="cpf_qa" inc_orig=1 > qa.log 2>&1 &

Examples of running single collections:

    snac_transform.sh createFileLists/oac.xml eadToCpf.xsl > logs/oac.log 2>&1 &
    snac_transform.sh createFileLists/aao.xml eadToCpf.xsl > logs/aao.log 2>&1 &

Use extract_all.pl to run everything. By default extract_all.pl is non-review, original not included.

    ./extract_all.pl > ext.log 2>&1 &

For rewview data, with original EAD included:

    ./extract_all.pl review=1 inc_orig=1 > rev.log 2>&1 &

Validate with jing. The old way with find -exec works well enough. stdout and stderr can both go to
the same file, so we only need one log file.

    find ./cpf_extract/ -type f -exec java -jar /usr/share/jing/bin/jing.jar /projects/socialarchive/published/shared/cpf.rng {} + > jing.log 2>&1 &

The "parallel" utility will auto launch multiple processes which speeds up the validation.

Use two log files and the eta param, \-\-eta, that is dash dash eta

    find cpf_extract/ -type f | parallel \-\-eta -X java -jar /usr/share/jing/bin/jing.jar /projects/socialarchive/published/shared/cpf.rng {} ::: > jing.log 2> jing_error.log &

