

Table of contents
-----------------
* [Overview of EAD to CPF](#overview-of-ead-to-cpf)
* [Manual command overview](#manual-command-overview)
* [Creating the file lists](#creating-the-file-lists)
* [Creating the list of resource URLs](#creating-the-list-of-resource-urls)
* [The QA files](#the-qa-files)
* [Creating geographical name data files](#creating-geographical-name-data-files)
* [Running the CPF extraction](#running-the-cpf-extraction)
* [Validate with jing](#validate-with-jing)


Overview of EAD to CPF
-------------------------

These scripts extract EAD-CPF (CPF) XML from EAD XML finding aids. A variety of local practices are supported in the incoming EAD. This process is intended to extract large numbers of files, and so it is designed as a bulk pipeline. Running small numbers of files is fairly easy, but the initial set up and configuration cannot be skipped.

Required steps:

0.1) symlink to session_lib.pm or copy into this dir

1) create file lists

2) create the ead urls aka "fix urls"

2.1) create the geonames xml data file geo.xml. See geo.xsl.

3) run the cpf extraction

4) validate with jing

In several of the examples below we use the "head" or "tail" command to show a portion of a data file of
illustrative purposes. The head command shows the first 10 lines of a file, and tail the last 10 lines. We may
also show other brief snippets of "session transcripts", that is, what you would see at the Linux command line
if you ran a certain command. Our command examples use the > prompt, and the output immediately follows. Below
is an example of the command "ls -ls lib". You should get the same (relative) output if you run these commands
on your system.


Several parts of this data processing pipeline require Saxon extensions, and thus we use Robbie Hott's
extended version of Saxon, and we create a symbolic link (shortcut) to Robbie Java function library:

    > ln -s /lv3/data/snac_saxon/SNAC-Saxon-Extensions/xslt/lib
    > ls -ld lib
    lrwxrwxrwx 1 twl8n snac 51 May 23 12:03 lib -> /lv3/data/snac_saxon/SNAC-Saxon-Extensions/xslt/lib


Manual command overview
-----------------------

You really must use the Perl scripts to run everything as a batch. But to illustrate what happens inside some
of those scripts here are commands to run the anfra data (minus running geonames lookup).

One tiny typo anywhere here and you'll get no results, or you'll overwrite existing results. 

    find /data/source/findingAids/anfra/ -iname "*.xml" | perl -pe '$_ =~ s/\/data\/source\/findingAids\//.\//g' > anfra_faList.txt
    ../snac_transform.sh dummy.xml createList.xsl abbreviation="anfra" >> ra.log 2>&1
    snac_transform.sh createFileLists/anfra_list.xml fix_url.xsl 2> tmp.log > url_xml/anfra_url.xml &
    snac_transform.sh createFileLists/anfra_list.xml eadToCpf.xsl > logs/anfra.log 2>&1 &
    snac_transform.sh createFileLists/anfra_list.xml eadToCpf.xsl cpfOutLocation="anfra_cpf" inc_orig=0 > logs/anfra.log 2>&1 &




Creating the file lists
-----------------------

The CPF extraction is performed  on files discovered in the file lists. The files typically look like:

    <?xml version="1.0" encoding="UTF-8"?>
    <list xmlns="http://socialarchive.iath.virginia.edu/"
          xmlns:snac="http://socialarchive.iath.virginia.edu/"
          sourceCode="aao"
          fileCount="1608"
          pStart="1"
          pEnd="4">
     <!--  Number of groups: 4 Group size: 500  -->
       <group n="1">
          <i n="1">findingAids/aao/ccp_center_for_creative_photography/CCPAG4.xml</i>
          <i n="2">findingAids/aao/ccp_center_for_creative_photography/CCPAG38.xml</i>
          <i n="3">findingAids/aao/ccp_center_for_creative_photography/CCPAG225.xml</i>
          <i n="4">findingAids/aao/ccp_center_for_creative_photography/CCPAG200.xml</i>
          ...
          
Large files will have many groups. Group size is limited to 500 for (possibly) historical system resource
management reasons. The data in the file lists is not for human use. File lists are created by scripts for use
by other scripts.

The system expects to find the EAD finding aids in "/data/source". See variable eadPath in eadToCpf.xsl. The full path for the first EAD finding aid above is:

    /data/source/findingAids/aao/ccp_center_for_creative_photography/CCPAG4.xml


To create the file lists, change directory into ./createFileLists, and use the Perl script run_all.pl to build
every file list.

    cd createFileLists
    ./run_all.pl > rax.log 2>&1 &

or you can run a single collection aka dir aka repository, in this case mhs:

    ../snac_transform.sh dummy.xml createList.xsl abbreviation=\"mhs\" >> ra.log 2>&1

Creating the list of resource URLs 
----------------------------------

The URLs of the finding aids are always the same, unless a repository changes their method of determining
persistent ids. Since these URLs are static, we save computing time by building an XML data file for each
repository's URLs. When running the CPF extraction, the script quickly looks up the URL from the data. The
external XML files are useful for other purposes such as checking the existence of a document at each URL.

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

Creating geographical name data files
-------------------------------------

Read a places xml file, call Robbie's geonames code, output a file of geonames places. Geoname parsing is
very, very slow. Instead of resolving each geoname every time the CPF extraction is run, we run them ahead of time,
and look up the geoname from the data file. To build the geonames data file we need to pre-parse the geonames.

Like chronlist dates, the geonames functions rely on a symlink (or real directory) containing Robbie Hott's Saxon
extensions. This must be run using Robbie's copy of Saxon.

Getting the list of geonames requires running the CPF extraction. Yes, we run the extraction without a
geonames data file, create the real data file, then re-run the CPF extraction. (In fact, the CPF extraction
has been run dozens of times for various testing purposes.) Build a file of geonames requires the logging the
comments geogx: (associated with geog1:, geog2:, and geog3:) in templates.xsl. Run everything
(extract_all.pl), grep out the geog names by capturing "<normalized>.+<\/normalized>", then remove duplicates
with sort -u, and process with build_geo_xml.pl. This results in a file of unique names to run through geo.xsl
which builds the geonames data file.

    ./extract_all.pl > ext.log 2>&1 &    
    grep -Po "<normalized>.+<\/normalized>" logs/*.log > geonames_files/tmp.txt
    sort -fu geonames_files/tmp.txt > geonames_files/all.txt
    ./build_geo_xml.pl geonames_files/all.txt > geonames_files/all.xml

    snac_transform.sh geonames_files/all.xml geo.xsl > geonames_files/geo_all.xml

    > head geonames_files/all.xml 
    <?xml version="1.0" encoding="UTF-8"?>
    <places>
    <place>
        <cpfName>Istanbul (Turkey)</cpfName>
    </place>
    <place>
        <cpfName>Smyrna (Turkey)</cpfName>
    </place>
    <place>
        <cpfName>Wales</cpfName>

    
    
For any new data sets, run all this to get the new names. The Perl script build_geo_xml.pl will
exclude any known place names from geo.xml. Use cat, head, and tail to merge the new XML with existing
XML.

Merging a new geonames file with the existing file is something like:

    tail -n +3 geonames_files/geo_all.xml| head -n -1 > a.xml
    tail -n +3 geonames_files/geo_2014-06-02.xml | head -n -1 > b.xml
    head -n 2 geo_all.xml > head.xml
    tail -n 1 geo_all.xml > tail.xml
    cat head.xml a.xml b.xml tail.xml > geo_all.xml


Running the CPF extraction
--------------------------

Each finding aid is processed and relevant CPF output files are created. The XSL script "eadToCpf.xsl" can
process a single list file. However, it is limited to a single list file. Perl is much better at automating
sequences of system commands than XSLT, so we use Perl to create automated processes. Automating the
processing of all list files is handled by a small Perl script, extract_all.pl.

Examples of running single collections:

    snac_transform.sh createFileLists/oac.xml eadToCpf.xsl > logs/oac.log 2>&1 &
    snac_transform.sh createFileLists/aao.xml eadToCpf.xsl > logs/aao.log 2>&1 &

Use extract_all.pl to run everything. By default extract_all.pl is non-review, original not included.

    ./extract_all.pl > ext.log 2>&1 &

The extract_all.pl script can take a long time to run if you have a large number of files. Each run of a file list will result in a log files in ./logs/ and you can use a command such as "ls -alt" to see which logs have recently been run.

    > ls -alt logs/* | head
    -rw-r--r-- 1 twl8n snac  332201 Jun 16 10:34 logs/sia.log
    -rw-r--r-- 1 twl8n snac 5227111 Jun 13 16:33 logs/unc.log
    -rw-r--r-- 1 twl8n snac   40477 Jun 13 16:31 logs/howard.log
    -rw-r--r-- 1 twl8n snac 3242529 Jun 13 16:31 logs/oac.log
    -rw-r--r-- 1 twl8n snac  190669 Jun 13 15:19 logs/riamco.log
    -rw-r--r-- 1 twl8n snac  327169 Jun 13 15:19 logs/syru.log
    -rw-r--r-- 1 twl8n snac 1288688 Jun 13 15:19 logs/harvard.log
    -rw-r--r-- 1 twl8n snac  350146 Jun 13 13:13 logs/mhs.log
    -rw-r--r-- 1 twl8n snac  107171 Jun 13 13:13 logs/afl-ufl.log
    -rw-r--r-- 1 twl8n snac  157361 Jun 13 13:12 logs/colu.log

You can even watch log files being written with "tail" or "watch" and "tail":

    tail logs/sia.log
    watch tail logs/sia.log

The log files have a brief section at the top which documents what was done, especially where the CPF output
is going, and the name of the file list.

    > head logs/sia.log 
    Warning: SXXP0005: The source document is in namespace http://socialarchive.iath.virginia.edu/, but
      all the template rules match elements in no namespace
    cpfOutLocation: cpf_extract/
          base-uri: file:/lv1/home/twl8n/ead2cpf_pack/createFileLists/sia_list.xml
          file2url: 0
    
    fn: /data/source/findingAids/sia/FARU7184.xml
    <i icount="1" bcount="1" path="/data/source/findingAids/sia/FARU7184.xml"/>
    Finding Aid Url of contributing respository needs to be determined!


Validate with jing
------------------

When the run is complete we suggest you validate the CPF output. While we have accounted for a variety of flavors of EAD, some data can confuse our XSLT scripts and produce non-compliant CPF output. 

If you only have a few thosand files, the old way with "find -exec" works well enough. With this method, stdout and stderr can both go to
the same file, so we only need one log file.

    find ./cpf_extract/ -type f -exec java -jar /usr/share/jing/bin/jing.jar /projects/socialarchive/published/shared/cpf.rng {} + > jing.log 2>&1 &

If jing.log is an empty file, your CPF is valid.


The "parallel" utility will auto launch multiple processes which speeds up the validation when you have hundreds of thousands or millions of CPF files.

Use two log files and the eta param, \-\-eta, that is dash dash eta

    find cpf_extract/ -type f | parallel \-\-eta -X java -jar /usr/share/jing/bin/jing.jar /projects/socialarchive/published/shared/cpf.rng {} ::: > jing.log 2> jing_error.log &




For review data, with original EAD included:

    ./extract_all.pl review=1 inc_orig=1 > rev.log 2>&1 &

