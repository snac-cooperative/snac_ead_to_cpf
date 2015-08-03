<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:ead="urn:isbn:1-931666-22-9"
                xmlns:functx="http://www.functx.com"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xlink="http://www.w3.org/1999/xlink"
                xmlns:eac="urn:isbn:1-931666-33-4"
                xmlns:snac="http://socialarchive.iath.virginia.edu/"
                xmlns:saxext="http://example.com/saxon-extension"
                exclude-result-prefixes="#all"
                version="2.0">

    <!--
        Author: Tom Laudeman, Daniel Pitti
        The Institute for Advanced Technology in the Humanities
        
        Copyright 2013 University of Virginia. Licensed under the Educational Community License, Version 2.0
        (the "License"); you may not use this file except in compliance with the License. You may obtain a
        copy of the License at
        
        http://www.osedu.org/licenses/ECL-2.0
        http://opensource.org/licenses/ECL-2.0
        
        Unless required by applicable law or agreed to in writing, software distributed under the License is
        distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
        implied. See the License for the specific language governing permissions and limitations under the
        License.
        
        Required steps:
        
        0.05) clean the files, probably with clean.pl. Disable dtds, etc.

        0.1) symlink to session_lib.pm or copy into this dir
        
        1) create file lists
        
        2) create the ead urls aka "fix urls"
        
        2.1) create the geonames xml file geo.xml. See geo.xsl.
        
        3) run the cpf conversion
        
        4) validate with jing
        
        cd createFileLists
        ./run_all.pl > rax.log 2>&1 &
        
        or you can run a single collection aka dir, in this case mhs:
        
        ../snac_transform.sh dummy.xml createList.xsl abbreviation=\"mhs\" >> ra.log 2>&1
        
        QA and testing is a good idea. See qa.xml for comments about what each input file tests. Note that QA
        cannot test URL substitution in CPF because the collection sourceCode is per-file not per-record. QA
        can be run through fix_ur.xsl to generate URLs.
        
        snac_transform.sh qa.xml eadToCpf.xsl > qa.log 2>&1 &
        snac_transform.sh qa2.xml eadToCpf.xsl > qa.log 2>&1 &
        
        # Run urls for just one collection
        snac_transform.sh createFileLists/mhs_list.xml fix_url.xsl 2> tmp.log > url_xml/mhs_url.xml
        
        # Run all the URLs aka "fixed urls"
        ./run_fix_all.pl > rfa.log 2>&1 &        
        
        An entire collection is run without regard to $start and $stop. Small batches for testing are handled by qa.xml and qa2.xml.
        
        In the past, variables start and stop in eadToCpfVariables.xsl controled how much of the xml file is processed,
        unless the xml file had force="1", but now we just run the entire input.
        
        snac_transform.sh qa.xml eadToCpf.xsl cpfOutLocation="cpf_qa" > qa.log 2>&1 &
        
        Use command line param inc_orig to get the original EAD in the CFP output objectXML.
        
        snac_transform.sh qa2.xml eadToCpf.xsl cpfOutLocation="cpf_qa" inc_orig=1 > qa.log 2>&1 &
        
        Examples of running single collections:
        
        snac_transform.sh createFileLists/oac_list.xml eadToCpf.xsl > logs/oac.log 2>&1 &
        snac_transform.sh createFileLists/aao_list.xml eadToCpf.xsl > logs/aao.log 2>&1 &
        
        May 12 2015: cfpr_href and cfpr_href_suffix both correctly default for BnF. The long form of the
        command would be either of these (depending on how "long" you want the long form to be:

        snac_transform.sh createFileLists/bnf_list.xml eadToCpf.xsl cpfOutLocation=bnf_cpf_final inc_orig=0 cpfr_href="http://catalogue.bnf.fr/" > logs/bnf.log 2>&1 &

        snac_transform.sh createFileLists/bnf_list.xml eadToCpf.xsl cpfOutLocation=bnf_cpf_final inc_orig=0 cpfr_href="http://catalogue.bnf.fr/" cpfr_href_suffix="/PUBLIC" > logs/bnf.log 2>&1 &
        
        In fact, you should run this script via the larger wrapper, run_single_ead.pl. There are many
        requirements necessary before, during, and after the run. While you may be able to generate CPF
        without some prerequisites, the CPF will be somewhat incomplete (typically, missing resourceRelation
        xlink:href values). The complexity is largely due to inclusion of support for local practice at more
        than 50 repositories.
        
        cd createFileLists
        find /data/source/findingAids/bnf/ -iname "*.xml" | perl -pe '$_ =~ s/\/data\/source\/findingAids\//.\//g' > bnf_faList.txt 
        ../snac_transform.sh dummy.xml createList.xsl abbreviation="bnf" >> ra.log 2>&1
        cd ..
        snac_transform.sh createFileLists/bnf_list.xml fix_url.xsl 2> tmp.log > url_xml/bnf_url.xml
        mvt /data/extract/ead_bnf
        run_single_ead.pl -r bnf -noc &
        
        See repo_xyx.log (for example repo_bnf.log) for an extensive log of what was done and a number of QA tests. 

        Validate with jing. The old way with find -exec works well enough. stdout and stderr can both go to
        the same file, so we only need one log file.
        
        find ./cpf_extract/ -type f -exec java -jar /usr/share/jing/bin/jing.jar /projects/socialarchive/published/shared/cpf.rng {} + > jing.log 2>&1 &
        
        The "parallel" utility will auto launch multiple processes which speeds up the validation.
        
        Use two log files and the eta param, \-\-eta, that is dash dash eta
        
        find cpf_extract/ -type f | parallel \-\-eta -X java -jar /usr/share/jing/bin/jing.jar /projects/socialarchive/published/shared/cpf.rng {} ::: > jing.log 2> jing_error.log &
        
        For debugging, use ptype. See param ptype and variable processingType (below in this file)x. A
        different command line is necessary.
        
        snac_transform.sh createFileLists/bnf_list.xml eadToCpf.xsl ptype=stepthree cpfOutLocation=bnf_cpf_final inc_orig=0 > logs/bnf.log 2>&1

        At some point in the past there was a list of files for QA and quick review in review_file_lists. Status of this is unknown. 
        
        If you get errors related to DTDs or other processing instructions, you need to run clean.pl which
        comments out anything between ?> and <ead. It also deals with a variety of badly-formed utf8
        characters.

        fn: /data/source/findingAids/repo/xyz123.xml
        Recoverable error on line 266 of eadToCpf.xsl:
        FODC0002: I/O error reported by XML parser processing
        file:/data/source/findingAids/repo/xyz123.xml:
        /data/source/findingAids/repo/ead.dtd (No such file or directory)
    -->
    
    
    <xsl:import href="av.xsl"/>
    <xsl:import href="functions.xsl"/>
    <xsl:import href="variables.xsl"/>
    <xsl:import href="templates.xsl"/>
    
    <!--
        Mar 17 2015 (based on univ_eadToCpf.xsl)
        
        Need to make paths easier to configure, slightly more portable.
        
        No trailing / as is the convention.
    -->
    <xsl:param name="data_path_stem" select="'./data/source'"/>
    
    <!--
        Mar 17 2015 (based on univ_eadToCpf.xsl)
        Stop stem string. Used in a regex to trim off leading part of path for path-relative URL matching. see templates.xsl
        
        This is the left-most part of the path to keep. (Yes, keep, not throw away).
        
        If your files are in data/source/findindAids/repo then this is 'findingAids' and the final, matching
        path will be findingAids/repo/1234.xml.
    -->
    <xsl:param name="trim_stop_string" select="'findingAids'"/>
    
    <xsl:strip-space elements="*"/>
    <xsl:output indent="yes" method="xml"/>
    <xsl:key name="sourceCodeName" match="source" use="sourceCode"/>
    
    <!--
        May 12 2015 need this to support BnF sameAs cpfRelation href values.
        This is the cpf relation base url xlink:href aka cpfr_href.
    -->
    <xsl:param name="cpfr_href" select="'http://catalogue.bnf.fr/'" />
    <xsl:param name="cpfr_href_suffix" select="'/PUBLIC'"/>

    <xsl:param name="cpfOutLocation">
        <!-- this variable is used in building the path to the were cpf records will be serialized as files. -->
        <xsl:text>cpf_extract/</xsl:text>
    </xsl:param>
    
    <!--
        The deepest part of the original file name path that we'll remove. Everything deeper has path info
        that we keep, and a file base name used to generate unique file names for output.
    -->
    <xsl:variable name="depth_path">
        <xsl:text>findingAids</xsl:text>
    </xsl:variable>
    
    <xsl:variable name="this_year" select="year-from-date(current-date())"/>
    
    <!--
        Add command line param for cpfoutput stage to simplify testing.
    -->
    
    <xsl:param name="ptype" select="'cpfout'"/>
    
    <xsl:variable name="processingType">
        <!-- 
             Only CPFOut will produce CPF output. All the others are for debugging, and write XML to stdout,
             creating no files.
             
             When using one of the debug processing types, separate stdout and stderr to separate log files.
             
             snac_transform.sh qa2.xml eadToCpf.xsl cpfOutLocation="cpf_qa" inc_orig=0 > qa.log 2> qa_err.log &
             
             Supported values: rawExtract stepOne stepTwo stepThree stepFour stepFive testCPFOut CPFOut
        -->
        <xsl:choose>
            <xsl:when test="$ptype = 'cpfout'">
                <xsl:text>CPFOut</xsl:text>
            </xsl:when>
            <xsl:when test="$ptype = 'rawextract'">
                <xsl:text>rawExtract</xsl:text>
            </xsl:when>
            <xsl:when test="$ptype = 'stepone'">
                <xsl:text>stepOne</xsl:text>
            </xsl:when>
            <xsl:when test="$ptype = 'steptwo'">
                <xsl:text>stepTwo</xsl:text>
            </xsl:when>
            <xsl:when test="$ptype = 'stepthree'">
                <xsl:text>stepThree</xsl:text>
            </xsl:when>
            <xsl:when test="$ptype = 'stepfour'">
                <xsl:text>stepFour</xsl:text>
            </xsl:when>
            <xsl:when test="$ptype = 'stepfive'">
                <xsl:text>stepFive</xsl:text>
            </xsl:when>
            <xsl:when test="$ptype = 'testcpfout'">
                <xsl:text>testCPFOut</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message terminate="yes">
                    <xsl:value-of
                        select="concat('Bad ptype value: ', $ptype,
                        ' Allowed values: cpfout rawextract stepone steptwo stepthree stepfour stepfive (and maybe testcpfout)', $cr)"/>
                </xsl:message>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <!--
        The expected, normal xml input file is something like: createFileLists/nmaia_list.xml which to base-uri() is:
        file:/lv1/home/twl8n/ead2cpf_pack/createFileLists/nmaia_list.xml
    -->
    <xsl:variable name="file2url">
        <xsl:choose>
            <xsl:when test="matches(base-uri(), '_missing')">
                <xsl:copy-of select="document(concat('url_xml/', replace(base-uri(), '.*/(.*?_missing).*', '$1'), '_url.xml'))"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy-of select="document(concat('url_xml/', replace(base-uri(), '.*/(.*?)_.*', '$1'), '_url.xml'))"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <!--
        Do not include original data unless specifically asked to.
    -->
    <xsl:param name="inc_orig" select="false()"  as="xs:boolean"/>

    <xsl:template name="tpt_process">
        <xsl:param name="icount"/>
        <!--
            This was variable name="process". The two for-each loops (snac:list/snac:group, snac:i) have been
            moved into template name="tpt_main" match="/" below.
            
            This processes a single ead file.
        -->
        <xsl:variable name="eadPath">
            <xsl:value-of select="concat('/data/source/', .)"/>
        </xsl:variable>

        <xsl:variable name="fn">
            <xsl:value-of select="concat('/data/source/', .)"/>
        </xsl:variable>

        <xsl:message>
            <xsl:text>fn: </xsl:text>
            <xsl:value-of select="$fn"/>
        </xsl:message>

        <xsl:for-each select="document($fn)">
            <!--
                Raw extraction extracts all tagged names and origination, tagged or not. For the
                latter it attemts to determine type, and if unable to do so, defaults to persname. It
                also selects out, carefully, family names that have been mistagged as persname or
                corpname. (Except for names found in controlaccess, unless that bug has been fixed.)

                BnF (and perhaps others eventually) have persname/@source so we have to avoid
                overwriting our @source with theirs. This happened in the old code. I'd change our
                @source to some other name, but that attribute is used all over creation.
                
                Use a for-each to set var $ready_for_extract to be the context for xsl:call-template.
            -->

            <!-- May 13 2015 disable, is not necessary? -->

            <!-- <xsl:variable name="ready_for_extract"> -->
            <!--     <xsl:apply-templates mode="rename_source"/> -->
            <!-- </xsl:variable> -->
            <!-- <xsl:for-each select="$ready_for_extract"> -->
            <xsl:for-each select=".">
                <xsl:call-template name="tpt_process_inner">
                    <xsl:with-param name="icount" select="$icount"/>
                    <xsl:with-param name="fn" select="$fn"/>
                    <xsl:with-param name="eadPath" select="$eadPath"/>
                </xsl:call-template>
            </xsl:for-each>
        </xsl:for-each>
    </xsl:template>
    
    <!--
        The original tpt_process had to be broken up so we could pre-process to rename @source in all the
        names to avoid a name conflict. A few things could have been done to avoid this, and I'm not
        suggesting using namespaces which would just snarl things up.
        
        Context should be the original record, processed.
        
        Note r1:

        Extraction origination which is creator of the collection, or author of the materials in
        the collection.
        
        Nov 11 2014 Add logging for multiple names in origination. Some finding aids may what we
        consider .r names in origination instead of controlaccess.
        
        Note r2:
        
        extract control access aka controlaccess (this really is it, apparent cut/paste error gave
        other entity elements have source = "controlaccess"
        
        Note: controlaccess may be nested in controlaccess, thus the //controlaccess is necessary.
        
        Note r3:
        
        Extract dsc. Matches things that aren't origination, controlaccess, or scopecontent. For
        example: unittitle
        
        Note r4:
        
        May 18 2015 When was unittitle added to origination? Why? BnF has <persname> in <unittitle> in
        /data/source/findingAids/bnf/Hetzel_fund.xml. Perhaps other repositories have names in the
        unittitle. However, the origination extract code had an xsi:otherwise that didn't check for <persname>
        this and with BnF (at least) it turns some unittitles into names.
        
        Call template extract_origination separately for <origination> and <unittitle>. This is somewhat more
        obvious that finding the root por parent element name via an xpath function or axis.
    -->
    <xsl:template name="tpt_process_inner">
        <xsl:param name="icount"/>
        <xsl:param name="fn"/>
        <xsl:param name="eadPath"/>
        <xsl:variable name="rawExtract_a">
                <!-- Note r1 -->
                <xsl:if test="count(ead/archdesc/did/(origination|unittitle)) > 1">
                    <xsl:message>
                        <xsl:value-of select="concat('Multi-orig: ', count(ead/archdesc/did/origination), $cr)"/>
                    </xsl:message>
                </xsl:if>
                <!-- note r4 -->
                <xsl:for-each select="ead/archdesc/did/origination">
                    <xsl:call-template name="extract_origination">
                        <xsl:with-param name="parent_container" select="origination"/>
                    </xsl:call-template>
                </xsl:for-each>
                <xsl:for-each select="ead/archdesc/did/unittitle">
                    <xsl:call-template name="extract_origination">
                        <xsl:with-param name="parent_container" select="unittitle"/>
                    </xsl:call-template>
                </xsl:for-each>
                <!-- Note r2 -->
                <xsl:for-each select="ead/archdesc//controlaccess/(persname | corpname | famname)[matches(.,'[\p{L}]')]">
                    <xsl:call-template name="extract_controlaccess"/>
                </xsl:for-each>
                <xsl:for-each select="ead/archdesc//scopecontent/(persname | corpname | famname)[matches(.,'[\p{L}]')]">
                    <xsl:call-template name="extract_scopecontent"/>
                </xsl:for-each>
                <!-- Note r3 -->
                <xsl:for-each
                    select="ead/archdesc//dsc//(persname | corpname | famname) [matches(.,'[\p{L}]')] [not(parent::controlaccess)][not(parent::scopecontent)] ">
                    <xsl:call-template name="extract_other"/>
                </xsl:for-each>
                
            </xsl:variable> <!-- rawExtract_a end -->

            <!--
                May 20 2015 We need to fix authfilenumber early, before it gets used or copied elsewhere. See
                template with mode mode_authfilenumber below (near the end of this file).
            -->
            <xsl:variable name="rawExtract_afn">
                <xsl:for-each select="$rawExtract_a/entity">
                    <entity>
                        <xsl:copy-of select="@*"/>
                        <xsl:apply-templates mode="mode_authfilenumber"/>
                    </entity>
                </xsl:for-each>
            </xsl:variable>

            <!--
                May 21 2015 Bug: wrong xpath rawExtract/persname/@normal failed because there is no
                persname/@normal. Correct xpath is rawExtract/@normal.

                BnF sometimes puts the best name in @normal. This best name is often in indirect order, and
                has a date. Since the name code that follows is complex and fragile, and since the following
                code assumes that @normal is only suitable for name matching, we will look at @normal here and
                if it looks like the best name, we will substitute.
                
                "Best" is when the $normal_value does not have 4 digits, and $re_normal does have 4 digits, in
                which case we use $re_normal.
                
                For now, we will only work on <persname>. Corp and family are probably different.

                <entity ftwo="hélène cixous" source="origination" orig_source="" is_sameas="0">
                   <rawExtract>
                      <persname authfilenumber="ark:/12148/cb11896891b"
                                normal="Cixous, Hélène (1937-....)"
                                role="0580"
                                orig_source="OPP">Hélène Cixous</persname>
                   </rawExtract>
                   <normal type="attributeNormal">
                      <persname>Cixous, Hélène</persname>
                   </normal>
                </entity>
            -->

            <xsl:variable name="rawExtract_a_prime">
                <xsl:for-each select="$rawExtract_afn/entity">
                    <xsl:variable name="re_normal" select="rawExtract/persname/@normal"/>
                    <xsl:variable name="re_value" select="normalize-space(rawExtract/persname)"/>
                    <xsl:variable name="normal_value" select="normal/persname"/>
                    <xsl:choose>
                        <xsl:when test="not(matches($normal_value, '\d{4}')) and matches($re_normal, '\d{4}')">
                            <entity>
                                <xsl:copy-of select="@*"/>
                                <rawExtract>
                                    <xsl:copy-of select="rawExtract/@*"/>
                                    <persname>
                                        <xsl:copy-of select="rawExtract/persname/@*"/>
                                        <xsl:value-of select="$re_normal"/>
                                    </persname>
                                </rawExtract>
                                <normal>
                                    <xsl:copy-of select="normal/@*"/>
                                    <persname original_was="{$normal_value}">
                                        <xsl:copy-of select="rawExtract/persname/@*"/>
                                        <xsl:value-of select="$re_normal"/>
                                    </persname>
                                </normal>
                            </entity>
                        </xsl:when>
                        <xsl:otherwise>
                            <entity>
                                <xsl:copy-of select="@*|*"/>
                            </entity>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:for-each>
            </xsl:variable>

            <!--
                If you want to see the effect of choosing @normal for the best name when it has 4 digits,
                uncomment below and search the log file for "original_was".
                
                Log files are in logs/abc.log, so BnF is logs/bnf.log.
            -->

            <!-- <xsl:message> -->
            <!--     <xsl:value-of select="concat('rawExtract_a_prime: ', $cr)"/> -->
            <!--     <xsl:apply-templates mode="pretty" select="$rawExtract_a_prime"/> -->
            <!-- </xsl:message> -->

            <!--
                Check for 3 types of direct name, and convert to indirect.
                
                John Smith
                J Smith
                JT Smith or J T Smith
                
                Note 2: While we are looping over the data, add @ftwo to every name (normal first and last direct order name for matching).
                
                Multiple names in this field have interesting consequences since the name is parsed, and then
                the first and last words are pulled out.
                
                "Teddy Wedlock, Dora Wedlock, Helen M. Heynes" becomes direct order name "Dora Wedlock Teddy
                Wedlock" which becomes @ftwo "dora wedlock".
            -->
            <xsl:variable name="rawExtract_b">
                <xsl:for-each select="$rawExtract_a_prime/entity">
                    <xsl:variable name="norm_for_match">
                        <xsl:choose>
                            <xsl:when test="@ftwo">
                                <xsl:value-of select="@ftwo"/>
                            </xsl:when>
                            <xsl:when test="normal/persname">
                                <xsl:value-of
                                    select="replace(lower-case(snac:directPersnameTwo(./normal/persname)),
                                            '^(\w+).*?(\w+)(\d+|$)', '$1 $2')"/>
                            </xsl:when>
                            <!-- Otherwise nothing. I wonder how a missing @ftwo attribute effects code below? -->
                        </xsl:choose>
                    </xsl:variable>
                    <xsl:choose>
                        <xsl:when test="./normal[matches(persname, '^\w+\s+\w+$|^[A-Z]+\s+\w+$|^[A-Z]+\s*[A-Z]+\s+\w+$')]">
                            <entity ftwo="{$norm_for_match}"> 
                                <xsl:copy-of select="@*[name() != 'ftwo']"/>
                                <xsl:copy-of select="rawExtract"/>
                                <normal>
                                    <xsl:copy-of select="./normal/@*"/>
                                    <persname>
                                        <xsl:value-of
                                            select="replace(./normal/persname,
                                                    '^(\w+)\s+(\w+)$|^([A-Z]+)\s+(\w+)$|^([A-Z]+\s*[A-Z]+)\s+(\w+)$', '$2, $1')"/>
                                        <!-- <xsl:value-of select="replace(./normal/persname, '^(\w+)\s+(\w+)$', '$2, $1')"/> -->
                                    </persname>
                                </normal>
                            </entity>
                        </xsl:when>
                        <xsl:otherwise>
                            <entity ftwo="{$norm_for_match}"> 
                                <xsl:copy-of select="@*[name() != 'ftwo']"/>
                                <xsl:copy-of select="rawExtract"/>
                                <xsl:copy-of select="normal"/>
                            </entity>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:for-each>
            </xsl:variable> <!-- rawExtract_b -->
            
            <!--
                May 11 2015 Disabled because it appears to break BnF. It chose the controlaccess name over
                the origination. Simply make $rawExtract be a copy of $rawExtract_b.
                
                did/(origination|unittitle) <unittitle><persname authfilenumber="ark:/12148/cb12008284s"
                normal="Hetzel, Pierre-Jules (1814-1886)" role="0580" source="OPP">Pierre-Jules
                Hetzel</persname>. Papiers.</unittitle>
                
                controlaccess: <part>Hetzel, Pierre-Jules, pseud. P. -J. Stahl</part>

                May 11 2015 This seems odd because it causes the controlaccess name to be used instead of
                origination, and that can cause a less preferred name to go into the CPF.

                Another intermediate step that tries to match origination and controlaccess names. And I think
                it decides which name to use, and might use controlaccess rather than origination (if the
                names match, and based on some other criteria).
            -->
            <xsl:variable name="rawExtract">
                <xsl:choose>
                    <xsl:when test="true()">
                        <xsl:copy-of select="$rawExtract_b"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:for-each select="$rawExtract_b/entity">
                            <!-- <xsl:message> -->
                            <!--     <xsl:text>xent: </xsl:text> -->
                            <!--     <xsl:copy-of select="./normal/(persname|famname|corpname)"/> -->
                            <!--     <xsl:value-of select="concat(' ft: ', ./@ftwo)"/> -->
                            <!-- </xsl:message> -->

                            <xsl:variable name="orig">
                                <xsl:value-of select="normalize-space(.[@source='origination']/normal/persname)"/>
                            </xsl:variable>

                            <xsl:variable name="orig_nfm">
                                <xsl:value-of select="@ftwo"/>
                            </xsl:variable>

                            <!--
                                If someone enters two matching names in controlaccess, this xpath would return both
                                names. It turns out that ahub has at least one example of this. Only select [1].
                                
                                /data/source/findingAids/ahub/soas/196.xml
                            -->
                            <xsl:variable name="matches_ca">
                                <xsl:copy-of select="$rawExtract_b/(entity[@source='controlaccess' and @ftwo=$orig_nfm and @ftwo != ''])[1]"/>
                            </xsl:variable>

                            <xsl:variable name="matches_orig">
                                <xsl:copy-of select="$rawExtract_b/entity[@source='origination' and @ftwo=$orig_nfm and @ftwo != '']"/>
                            </xsl:variable>

                            <xsl:choose>
                                <xsl:when test="./@source = 'origination' and string-length($matches_ca) > 0">
                                    <entity source="origination" ftwo="{@ftwo}" true_source="controlaccess" is_sameas="0">
                                        <xsl:copy-of select="$matches_ca/entity/*"/>
                                    </entity>
                                    <!-- <xsl:message> -->
                                    <!--     <xsl:text>mc: </xsl:text> -->
                                    <!--     <xsl:value-of select="count($matches_ca/entity)"/> -->
                                    <!--     <xsl:text> cto: using: </xsl:text> -->
                                    <!--     <xsl:value-of select="$matches_ca/entity/normal/persname"/> -->
                                    <!--     <xsl:text> instead-of: </xsl:text> -->
                                    <!--     <xsl:value-of select="./normal/persname"/> -->
                                    <!-- </xsl:message> -->
                                </xsl:when>
                                <xsl:when test="./@source = 'origination' and string-length($matches_ca) = 0">
                                    <xsl:copy-of select="."/>
                                </xsl:when>
                                <xsl:when test="./@source = 'controlaccess' and string-length($matches_orig) = 0">
                                    <xsl:copy-of select="."/>
                                </xsl:when>
                                <xsl:when test="./@source = 'controlaccess' and string-length($matches_orig) > 0">
                                    <!-- Do nothing. This controlaccess has been converted to an origination -->
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:copy-of select="."/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:for-each>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable> <!-- rawExtract -->

            <!-- <xsl:message> -->
            <!--     <xsl:text>rexa: </xsl:text> -->
            <!--     <xsl:copy-of select="$rawExtract_a"/> -->
            <!--     <xsl:value-of select="$cr"/> -->
            <!--     <xsl:text>rexb: </xsl:text> -->
            <!--     <xsl:copy-of select="$rawExtract_b"/> -->
            <!--     <xsl:value-of select="$cr"/> -->
            <!--     <xsl:text>new rex: </xsl:text> -->
            <!--     <xsl:copy-of select="$rawExtract"/> -->
            <!--     <xsl:value-of select="$cr"/> -->
            <!--     <xsl:for-each select="$rawExtract/entity[@source='origination']/normal/persname"> -->
            <!--         <xsl:value-of select="concat('creator: ', ., $cr)"/> -->
            <!--     </xsl:for-each> -->
            <!-- </xsl:message> -->

            <xsl:if test="string-length($rawExtract) = 0">
                <!--
                    Historically, $rawExtract is empty when we failed to convert some xmlns to xmlns="".  However,
                    some records do not have any CPF entities.
                -->
                <xsl:choose>
                    <xsl:when test="namespace-uri() != ''">
                        <xsl:message>
                            <xsl:text>Warning: rawExtract possible problem.</xsl:text>
                            <xsl:value-of select="$cr"/>
                            <xsl:text>Error: incompatible namespace: </xsl:text>
                            <xsl:value-of select="namespace-uri()"/>
                        </xsl:message>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:message>
                            <xsl:text>Warning: var rawExtract is empty.</xsl:text>
                        </xsl:message>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:if>

            <xsl:if test="$rawExtract/entity[count(rawExtract) > 1]">
                <xsl:message>
                    <xsl:text>multi: </xsl:text>
                    <xsl:copy-of select="$rawExtract/entity[count(rawExtract) > 1]"/>
                    <xsl:for-each select="$rawExtract/entity[count(rawExtract) > 1]/rawExtract">
                        <xsl:value-of select="concat($cr, 'pos: ', position())"/>
                        <xsl:text> </xsl:text>
                        <xsl:copy-of select="."/>
                    </xsl:for-each>
                </xsl:message>
            </xsl:if>

            <!--
                NORMALIZE STEP ONE: Removes any entity with the words unknown or various, as these are
                dubious or combine name and not name components.  Normalizes entries that are not
                based on @normal. Every outgoing entity has a normal, either attributeNormal or regEx.
            -->
            <xsl:variable name="normalizeStepOne">
                <xsl:for-each select="$rawExtract/entity">
                    <xsl:choose>
                        <xsl:when test="contains(lower-case(rawExtract/*),'unknown') or contains(lower-case(rawExtract/*),'various')">
                            <!--
                                This removes entries that contain unknown and various, as in either
                                case, the entry is either not useful or difficult to sort out.
                            -->
                            <xsl:message>
                                <xsl:text>Removed: </xsl:text>
                                <xsl:value-of select="rawExtract"/>
                            </xsl:message>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:choose>
                                <xsl:when test="normal/persname">
                                    <entity>
                                        <xsl:copy-of select="* | @*"/>
                                        <xsl:if test="normal[not(@type='attributeNormal')]/persname">
                                            <!--
                                                If we have a normal that is not an attributeNormal, then do
                                                additional normalization, and make the type regExed. Var
                                                pers_normal is Daniel's original normalization. 
                                                
                                                Added normalize-space() to start things off because we
                                                previously weren't dealing well with embedded newlines.
                                                
                                                oct 27 2014 remove snac:removeApostropheLowercaseSSpace()
                                                which we decided does more harm than good.
                                                
                                                Note: this piece of code is only for person! (not
                                                corporateBody or family).
                                                
                                                Nov 11 2014 Add snac:removeColon() here and to normal/corpname below.
                                            -->
                                            <xsl:variable name="pers_normal">
                                                <xsl:value-of
                                                    select="
                                                            snac:removeColon(
                                                            snac:stripStringAfterDateInPersname(
                                                            snac:removeBeforeHyphen2(
                                                            snac:fixSpacing(
                                                            snac:fixDatesReplaceActiveWithFl(
                                                            snac:fixDatesRemoveParens(
                                                            snac:fixCommaHyphen2(
                                                            snac:cleanCommaHyphenEarly(
                                                            snac:fixHypen2Paren(
                                                            snac:removeTrailingInappropriatePunctuation(
                                                            snac:removeInitialNonWord(
                                                            snac:removeInitialTrailingParen(
                                                            snac:removeBrackets(                            
                                                            snac:removeInitialHypen(
                                                            snac:removeQuotes(
                                                            snac:fixSpaceComma(
                                                            normalize-space(normal/persname)))))))))))))))))"
                                                    />
                                            </xsl:variable>
                                            <normal type="regExed">
                                                <persname>
                                                    <xsl:value-of select="snac:normalize_extra($pers_normal)"/>
                                                </persname>
                                            </normal>
                                        </xsl:if>
                                        <xsl:call-template name="extractOccupationOrFunction">
                                            <xsl:with-param name="entry">
                                                <xsl:copy-of select="./rawExtract/*"/>
                                            </xsl:with-param>
                                        </xsl:call-template>
                                    </entity>
                                </xsl:when>

                                <xsl:when test="normal/famname">
                                    <entity>
                                        <xsl:copy-of select="* | @*"/>
                                        <xsl:if test="normal[not(@type='attributeNormal')]/famname">
                                            <normal type="regExed">
                                                <famname>
                                                    <xsl:choose>
                                                        <xsl:when test="not(contains(snac:removeBeforeHyphen2(normal/famname),' '))">
                                                            <xsl:value-of select="snac:removePunctuation(snac:removeBeforeHyphen2(normal/famname))"/>
                                                            <xsl:text> [family]</xsl:text>
                                                        </xsl:when>
                                                        <xsl:otherwise>
                                                            <xsl:value-of select="snac:removeBeforeHyphen2(normal/famname)"/>
                                                        </xsl:otherwise>
                                                    </xsl:choose>
                                                </famname>
                                            </normal>
                                        </xsl:if>
                                        <xsl:call-template name="extractOccupationOrFunction">
                                            <xsl:with-param name="entry">
                                                <xsl:copy-of select="./rawExtract/*"/>
                                            </xsl:with-param>
                                        </xsl:call-template>
                                    </entity>
                                </xsl:when>

                                <!--
                                    Nov 11 2014 Add snac:removeColon() here and to normal/persname above.
                                -->
                                <xsl:when test="normal/corpname">
                                    <entity>
                                        <xsl:copy-of select="* | @*"/>
                                        <xsl:if test="normal[not(@type='attributeNormal')]/corpname">
                                            <normal type="regExed">
                                                <corpname>
                                                    <xsl:value-of
                                                        select="normalize-space(
                                                                snac:removeColon(
                                                                snac:removeBeforeHyphen2(
                                                                snac:fixDatesRemoveParens(
                                                                snac:fixCommaHyphen2(
                                                                snac:cleanCommaHyphenEarly(
                                                                snac:fixHypen2Paren(
                                                                snac:removeTrailingInappropriatePunctuation(
                                                                snac:removeInitialTrailingParen(
                                                                snac:removeBrackets(
                                                                snac:removeInitialHypen(
                                                                snac:removeQuotes(normal/corpname))))))))))))"
                                                        />
                                                </corpname>
                                            </normal>
                                        </xsl:if>
                                        <xsl:call-template name="extractOccupationOrFunction">
                                            <xsl:with-param name="entry">
                                                <xsl:copy-of select="./rawExtract/*"/>
                                            </xsl:with-param>
                                        </xsl:call-template>
                                    </entity>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:message>
                                        <xsl:text>Error: normalizeStepOne fails</xsl:text>
                                        <xsl:value-of select="$cr"/>
                                    </xsl:message>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:for-each>
            </xsl:variable> <!-- normalizeStepOne end -->

            <!--
                NORMALIZE STEP TWO: Adds <normalForMatch> to <entity>
                Parses persname for dates.
            -->

            <xsl:variable name="normalizeStepTwo">
                <xsl:for-each select="$normalizeStepOne/entity">
                    <entity>
                        <xsl:copy-of select="@* | *"/>
                        <normalForMatch>
                            <xsl:choose>
                                <!-- 
                                     Newer: Note: the value of @normal is used for family, but not for
                                     persname or corporateBody. At least in NWDA some @normal values don't
                                     contain a normalized name, but instead have a curious date. It seems to
                                     be true that @normal is often normalized for matching, but we are
                                     probably better off doing our own normalization, especially for match.
                                     
                                     Old: This (referrring to the code below?) is strange because any element
                                     <normal> with @type attributeNormal will have an @normal already. In
                                     fact, I'm fairly sure that all <normal> elements have an @normal which
                                     already is normalized for matching.
                                -->
                                <xsl:when test="normal[@type='attributeNormal']">
                                    <xsl:value-of select="snac:normalizeString(normal[@type='attributeNormal'])"/>
                                </xsl:when>
                                <xsl:when test="normal[@type='regExed']">
                                    <xsl:value-of select="snac:normalizeString(normal[@type='regExed'])"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="snac:normalizeString(normal[@type='provisional'])"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </normalForMatch>

                        <!-- Make existDate for persname with dates in name -->

                        <xsl:choose>
                            <xsl:when test="normal[@type='attributeNormal']/persname">
                                <xsl:call-template name="existDateFromPersname">
                                    <xsl:with-param name="tempString">
                                        <xsl:value-of select="normal[@type='attributeNormal']/persname"/>
                                    </xsl:with-param>
                                </xsl:call-template>
                            </xsl:when>
                            <xsl:when test="normal[@type='regExed']/persname">
                                <xsl:call-template name="existDateFromPersname">
                                    <xsl:with-param name="tempString">
                                        <xsl:value-of select="normal[@type='regExed']/persname"/>
                                    </xsl:with-param>
                                </xsl:call-template>
                            </xsl:when>
                            <xsl:when test="normal[@type='provisional']/persname">
                                <xsl:call-template name="existDateFromPersname">
                                    <xsl:with-param name="tempString">
                                        <xsl:value-of select="normal[@type='provisional']/persname"/>
                                    </xsl:with-param>
                                </xsl:call-template>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:message>
                                    <xsl:text>Not parsing for date:</xsl:text>
                                    <xsl:apply-templates mode="pretty" select="normal"/>
                                </xsl:message>
                            </xsl:otherwise>
                        </xsl:choose>
                    </entity>
                </xsl:for-each>
            </xsl:variable> <!-- normalizeStepTwo end -->

            <!-- NORMALIZE STEP THREE: Eliminates exact (after punctuation and spelling normaizing) duplicates. -->

            <xsl:variable name="normalizeStepThree">
                <xsl:for-each select="$normalizeStepTwo">
                    <xsl:variable name="group">
                        <xsl:for-each-group select="entity" group-by="normalForMatch">
                            <group>
                                <xsl:for-each select="current-group()">
                                    <entity>
                                        <xsl:copy-of select="@* | *[not(self::occupation)]"/>
                                    </entity>
                                </xsl:for-each>
                                <xsl:for-each select="current-group()">
                                    <xsl:copy-of select="occupation"/>
                                </xsl:for-each>
                            </group>
                        </xsl:for-each-group>
                    </xsl:variable>
                    
                    <!--
                        Examples of $group/group where each /group is a single entity, although each entity may
                        have multiple <entity> elements within the group. Usually duplicates are
                        source="origination" and source="controlaccess", but I've seen at least one example of
                        frank duplication in origination.
                        /data/source/findingAids/oac/berkeley/bancroft/m71_293_cubanc.xml
                        <group>
                        <entity source="origination">
                        <rawExtract type="unknown">
                        <origination label="Creator">Graupner family</origination>
                        </rawExtract>
                        <normal type="tenuous">
                        <famname>Graupner family</famname>
                        </normal>
                        <normal type="regExed">
                        <famname>Graupner family</famname>
                        </normal>
                        <normalForMatch>graupner family</normalForMatch>
                        </entity>
                        </group>
                        /data/source/findingAids/oac/berkeley/bancroft/m71_293_cubanc.xml
                        <group>
                        <entity source="origination">
                        <rawExtract>
                        <persname role="creator" source="lcnaf">Sierra Club</persname>
                        </rawExtract>
                        <normal type="provisional">
                        <persname role="creator" source="lcnaf">Sierra Club</persname>
                        </normal>
                        <normal type="regExed">
                        <persname>Sierra Club</persname>
                        </normal>
                        <normalForMatch>sierra club</normalForMatch>
                        </entity>
                        </group>
                    -->
                    
                    <!-- <xsl:message> -->
                    <!--     <xsl:value-of select="concat('step 3: ', ' ')"/> -->
                    <!--     <xsl:copy-of select="$group"/> -->
                    <!--     <xsl:value-of select="$cr"/> -->
                    <!-- </xsl:message> -->

                    <xsl:for-each select="$group/group">
                        <xsl:variable name="count">
                            <!-- This is a count of <entity> elements for this single entity. -->
                            <xsl:value-of select="count(entity)"/>
                        </xsl:variable>

                        <!--
                            May 21 2015 Any member of this group who is a correspondent does not mean that the
                            origination corresponded with all (or any) of the non-origination entities. This
                            is especially true with BnF. The old code here made @correspondent true all
                            entities if the origination if the origination name was also in a non-origination
                            capacity as correspondent.
                            
                            It might be plausible for an individual .r entity to correspond with the .c
                            entity, but that is taken care of before the entities get to this step in the
                            process.
                            
                            Here we are inside normalizeStepThree.
                        -->
                        <xsl:variable name="correspondent">
                            <!-- <xsl:if test="entity/@correspondent='yes'"> -->
                            <!--     <xsl:text>yes</xsl:text> -->
                            <!--     <xsl:message> -->
                            <!--         <xsl:text>have correspondent</xsl:text> -->
                            <!--         <xsl:apply-templates mode="pretty" select="entity[@correspondent='yes']"/> -->
                            <!--     </xsl:message> -->
                            <!-- </xsl:if> -->
                        </xsl:variable>

                        <xsl:variable name="activeDates">
                            <xsl:for-each-group select="entity/activeDate" group-by=".">
                                <xsl:sort/>
                                <xsl:for-each select="current-grouping-key()">
                                    <activeDate>
                                        <xsl:value-of select="."/>
                                    </activeDate>
                                </xsl:for-each>
                            </xsl:for-each-group>
                        </xsl:variable>

                        <xsl:variable name="countActiveDates">
                            <xsl:value-of select="count($activeDates/*)"/>
                        </xsl:variable>

                        <xsl:variable name="occupations">
                            <xsl:for-each-group select="occupation" group-by=".">
                                <xsl:sort/>
                                <xsl:for-each select="current-grouping-key()">
                                    <occupation>
                                        <xsl:value-of select="."/>
                                    </occupation>
                                </xsl:for-each>
                            </xsl:for-each-group>
                        </xsl:variable>

                        <xsl:choose>
                            <!-- add correspondent to selection. -->
                            <xsl:when test="entity[@source='origination']">
                                <xsl:for-each select="entity[@source='origination'][1]">
                                    <entity>
                                        <xsl:copy-of select="@*"/>
                                        <xsl:attribute name="count">
                                            <xsl:value-of select="$count"/>
                                        </xsl:attribute>
                                        <xsl:if test="$correspondent='yes'">
                                            <xsl:attribute name="correspondent">
                                                <xsl:text>yes</xsl:text>
                                            </xsl:attribute>
                                        </xsl:if>
                                        <xsl:copy-of select="*[not(self::activeDate)]"/>
                                        <xsl:choose>
                                            <xsl:when test="$countActiveDates=0"/>
                                            <xsl:when test="$countActiveDates=1">
                                                <xsl:copy-of select="$activeDates/activeDate"/>
                                            </xsl:when>
                                            <xsl:when test="$countActiveDates &gt; 1">
                                                <xsl:copy-of select="$activeDates/activeDate[1]"/>
                                                <xsl:copy-of select="$activeDates/activeDate[position()=$countActiveDates]"/>
                                            </xsl:when>
                                        </xsl:choose>
                                        <xsl:for-each select="$occupations/occupation">
                                            <xsl:copy-of select="."/>
                                        </xsl:for-each>
                                    </entity>
                                </xsl:for-each>
                            </xsl:when>

                            <xsl:when test="entity[@source='controlaccess']">
                                <xsl:for-each select="entity[@source='controlaccess'][1]">
                                    <entity>
                                        <xsl:copy-of select="@*"/>
                                        <xsl:attribute name="count">
                                            <xsl:value-of select="$count"/>
                                        </xsl:attribute>
                                        <xsl:if test="$correspondent='yes'">
                                            <xsl:attribute name="correspondent">
                                                <xsl:text>yes</xsl:text>
                                            </xsl:attribute>
                                        </xsl:if>
                                        <xsl:copy-of select="*[not(self::activeDate)]"/>
                                        <xsl:choose>
                                            <xsl:when test="$countActiveDates=0"/>
                                            <xsl:when test="$countActiveDates=1">
                                                <xsl:copy-of select="$activeDates/activeDate"/>
                                            </xsl:when>
                                            <xsl:when test="$countActiveDates &gt; 1">
                                                <xsl:copy-of select="$activeDates/activeDate[1]"/>
                                                <xsl:copy-of select="$activeDates/activeDate[position()=$countActiveDates]"/>
                                            </xsl:when>
                                        </xsl:choose>
                                        <xsl:for-each select="$occupations/occupation">
                                            <xsl:copy-of select="."/>
                                        </xsl:for-each>
                                    </entity>
                                </xsl:for-each>
                            </xsl:when>

                            <xsl:when test="entity[@source='dsc']">
                                <xsl:for-each select="entity[@source='dsc'][1]">
                                    <entity>
                                        <xsl:copy-of select="@*"/>
                                        <xsl:attribute name="count">
                                            <xsl:value-of select="$count"/>
                                        </xsl:attribute>
                                        <xsl:if test="$correspondent='yes'">
                                            <xsl:attribute name="correspondent">
                                                <xsl:text>yes</xsl:text>
                                            </xsl:attribute>
                                        </xsl:if>
                                        <xsl:copy-of select="*[not(self::activeDate)]"/>
                                        <xsl:choose>
                                            <xsl:when test="$countActiveDates=0"/>
                                            <xsl:when test="$countActiveDates=1">
                                                <xsl:copy-of select="$activeDates/activeDate"/>
                                            </xsl:when>
                                            <xsl:when test="$countActiveDates &gt; 1">
                                                <xsl:copy-of select="$activeDates/activeDate[1]"/>
                                                <xsl:copy-of select="$activeDates/activeDate[position()=$countActiveDates]"/>
                                            </xsl:when>
                                        </xsl:choose>
                                        <xsl:for-each select="$occupations/occupation">
                                            <xsl:copy-of select="."/>
                                        </xsl:for-each>
                                    </entity>
                                </xsl:for-each>
                            </xsl:when>

                            <xsl:otherwise>
                                <xsl:message>
                                    <xsl:text>Error: Something went wrong in selecting the entity!</xsl:text>
                                </xsl:message>
                            </xsl:otherwise>

                        </xsl:choose>
                    </xsl:for-each>
                </xsl:for-each>
            </xsl:variable> <!-- normalizeStepThree end -->

            <!--
                NORMALIZE STEP FOUR: Flags for discard all entries consisting of one name component
                when the component is found in a name string with two or more components.
            -->

            <xsl:variable name="normalizeStepFour">
                <xsl:for-each select="$normalizeStepThree">
                    <xsl:variable name="singleTokenSet">
                        <xsl:for-each select="entity[normal/persname]">
                            <xsl:if test="snac:countTokens(normalForMatch) = 1">
                                <xsl:copy-of select="."/>
                            </xsl:if>
                        </xsl:for-each>
                    </xsl:variable>

                    <xsl:variable name="multipleTokenSet">
                        <xsl:for-each select="entity[normal/persname]">
                            <xsl:if test="snac:countTokens(normalForMatch) &gt; 1">
                                <xsl:copy-of select="."/>
                            </xsl:if>
                        </xsl:for-each>
                    </xsl:variable>

                    <xsl:variable name="multipleTokenString">
                        <xsl:for-each select="entity[normal/persname]">
                            <xsl:if test="snac:countTokens(normalForMatch) &gt; 1">
                                <xsl:value-of select="normalForMatch"/>
                                <xsl:text> </xsl:text>
                            </xsl:if>
                        </xsl:for-each>
                    </xsl:variable>

                    <!-- 
                         Check for each single token names enitity/normalized for match.
                         This might benefit from a log message to clarify examples of when this occurs.
                    -->
                    <xsl:for-each select="$singleTokenSet/entity">
                        <xsl:variable name="tempString" as="xs:string">
                            <xsl:value-of select="normalForMatch"/>
                        </xsl:variable>

                        <xsl:choose>
                            <xsl:when test="exists(index-of(tokenize($multipleTokenString,'\s'),normalForMatch))">
                                <entity discard="yes">
                                    <xsl:copy-of select="@* | *"/>
                                </entity>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:copy-of select="."/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:for-each>

                    <xsl:for-each select="$multipleTokenSet/entity">
                        <xsl:copy-of select="."/>
                    </xsl:for-each>

                    <xsl:for-each select="*[not(normal/persname)]">
                        <xsl:copy-of select="."/>
                    </xsl:for-each>
                </xsl:for-each>
            </xsl:variable> <!-- normalizeStepFour end -->

            <!--
                NORMALIZE STEP FIVE: Adds the identifier component for each entity, c or r, and number.
                
                Is this the final step?
                
                Put the ead source here so we don't create another var and run out of memory/string exception.
            -->

            <xsl:variable name="normalizeStepFive">
                <ead_source>
                    <xsl:copy-of select="."/>
                </ead_source>
                <xsl:variable name="selectBioghist">
                    <!--
                        tpt_selectBioghist is in namespace eac, for some good reason (like not wanting to put
                        xmlns attributes on every element). Now all the downstream code needs the eac:
                        namespace. Or we could switch all the xpath to local-name().
                    -->
                    <xsl:call-template name="tpt_selectBioghist">
                        <xsl:with-param name="icount" select="$icount"/>
                        <xsl:with-param name="fn" select="$fn"/>
                    </xsl:call-template>
                </xsl:variable>
                
                <xsl:for-each select="$normalizeStepFour">
                    <originationCount>
                        <xsl:value-of select="count(entity[@source='origination'])"/>
                    </originationCount>
                    <biogHistCount>
                        <!-- at this point, everything inside $selectBioghist is in namespace eac -->
                        <xsl:value-of select="count($selectBioghist/eac:bioghist)"/>
                    </biogHistCount>
                    <xsl:for-each select="entity[not(@discard='yes')]">
                        <entity fn="{$fn}">
                            <xsl:copy-of select="@*"/>
                            <!--
                                Becomes control/recordId in CpfControl. This new code parses the input
                                directory tree and uses that (which seems to include the sourceID)
                                rather than concating the source id, but losing the rest of the
                                path. We need the whole path to insure we have unique file names.
                                
                                Used to be . instead of / 
                                
                                <xsl:text>.</xsl:text>
                            -->
                            <xsl:attribute name="recordId">
                                <xsl:value-of select="snac:path-minus-base($depth_path, $eadPath)"/>
                                <xsl:text>/</xsl:text>
                                <xsl:value-of select="snac:getBaseIdName(snac:getFileName($eadPath))"/>
                                <xsl:choose>
                                    <xsl:when test=".[@source='origination' and not(@discard='yes')]">
                                        <!-- create .cxx record id here -->
                                        <xsl:text>.c</xsl:text>
                                        <xsl:number count="entity[@source='origination' and not(@discard='yes')]" format="01"/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <!-- create .rxxx record id here -->
                                        <xsl:text>.r</xsl:text>
                                        <xsl:number count="entity[not(@source='origination') and not(@discard='yes')]" format="001"/>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:attribute>
                            <normalFinal step="five" position="{position()}">
                                <!--
                                    attributeNormal was lacking the /* which caused an empty entityType. Fixed
                                    and and nothing else seemed to break. jan 31 2013
                                -->
                                <xsl:choose>
                                    <xsl:when test="normal[@type='attributeNormal']">
                                        <xsl:copy-of select="normal[@type='attributeNormal']/(*|@*)"/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:copy-of select="normal[@type='regExed']/(*|@*)"/>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </normalFinal>                                      
                            <xsl:copy-of select="*"/>
                        </entity>
                    </xsl:for-each>
                </xsl:for-each>
                <xsl:call-template name="aboutOriginationEntity">
                    <xsl:with-param name="eadPath" select="$eadPath"/>
                    <xsl:with-param name="selectBioghist" select="$selectBioghist"/>
                </xsl:call-template>
            </xsl:variable> <!-- normalizeStepFive end -->

            <xsl:message>
                <xsl:for-each select="$normalizeStepFive/entity/normalFinal">
                    <xsl:text>normalFinal: </xsl:text>
                    <xsl:value-of select="."/>
                    <xsl:text>   type: </xsl:text>
                    <xsl:value-of select="@type"/>
                    <xsl:text> cpf: </xsl:text>
                    <xsl:value-of select="name((persname|corpname|famname))"/>
                    <xsl:value-of select="$cr"/>
                </xsl:for-each>
            </xsl:message>

            <!-- ****************************************************************** -->
            <!-- ****************************************************************** -->
            <!-- ****************************************************************** -->
            
            <!-- 
                 Debug output. When $processingType is set to anything except CPFOutput, then the only output is a <report> element, sent to stdout.
            -->

            <xsl:choose>
                <xsl:when test="$processingType='rawExtract'">
                    <oneFindingAid source="{$eadPath}">
                        <xsl:for-each select="$rawExtract">
                            <xsl:for-each select="*">
                                <xsl:copy-of select="."/>
                            </xsl:for-each>
                        </xsl:for-each>
                    </oneFindingAid>
                </xsl:when>

                <xsl:when test="$processingType='stepOne'">
                    <oneFindingAid source="{$eadPath}">
                        <xsl:for-each select="$normalizeStepOne">
                            <xsl:for-each select="*">
                                <xsl:copy-of select="."/>
                            </xsl:for-each>
                        </xsl:for-each>
                    </oneFindingAid>
                </xsl:when>

                <xsl:when test="$processingType='stepTwo'">
                    <oneFindingAid source="{$eadPath}">
                        <xsl:for-each select="$normalizeStepTwo">
                            <xsl:for-each select="*">
                                <xsl:copy-of select="."/>
                            </xsl:for-each>
                        </xsl:for-each>
                    </oneFindingAid>
                </xsl:when>

                <xsl:when test="$processingType='stepThree'">
                    <oneFindingAid source="{$eadPath}">
                        <xsl:for-each select="$normalizeStepThree">
                            <xsl:for-each select="*">
                                <xsl:copy-of select="."/>
                            </xsl:for-each>
                        </xsl:for-each>
                    </oneFindingAid>
                </xsl:when>

                <xsl:when test="$processingType='stepFour'">
                    <oneFindingAid source="{$eadPath}">
                        <xsl:for-each select="$normalizeStepFour">
                            <xsl:for-each select="*">
                                <xsl:copy-of select="."/>
                            </xsl:for-each>
                        </xsl:for-each>
                    </oneFindingAid>
                </xsl:when>

                <xsl:when test="$processingType='stepFive'">
                    <oneFindingAid source="{$eadPath}">
                        <xsl:for-each select="$normalizeStepFive">
                            <xsl:for-each select="*">
                                <xsl:copy-of select="."/>
                            </xsl:for-each>
                        </xsl:for-each>
                    </oneFindingAid>
                </xsl:when>

                <xsl:when test="$processingType='testCPFOut'">
                    <!--
                        May 13 2015 Why does this duplicate (mostly?) CPFOut? Unless this is identical to
                        CPFOut then the debugging is limited.
                        
                        Limit to those with bioghist and $normalizeStepFive/otherData/bioghist
                    -->
                    <oneFindingAid source="{$eadPath}">
                        <xsl:for-each select="$normalizeStepFive">
                            <!-- we are inside testCPFOut so don't make production changes here -->
                            <xsl:if test="entity">
                                <xsl:variable name="counts">
                                    <xsl:for-each select="originationCount | biogHistCount">
                                        <xsl:copy-of select="."/>
                                    </xsl:for-each>
                                </xsl:variable>
                                <xsl:variable name="otherData">
                                    <xsl:for-each select="otherData/*">
                                        <xsl:copy-of select="."/>
                                    </xsl:for-each>
                                </xsl:variable>
                                <xsl:variable name="entitiesForCPFRelations">
                                    <!-- This entity is to collect just the information needed to create cpfRelations -->
                                    <!-- we are inside testCPFOut so don't make production changes here -->
                                    <xsl:for-each select="entity">
                                        <xsl:variable name="new_entity">
                                            <entity>
                                                <xsl:copy-of select="@*|*"/>
                                            </entity>
                                        </xsl:variable>
                                        <xsl:copy-of select="$new_entity"/>
                                        <xsl:message>
                                            <xsl:value-of select="'testcpfout new entity for cpf:'"/>
                                            <xsl:apply-templates mode="pretty" select="$new_entity"/>
                                        </xsl:message>
                                        <!-- we are inside testCPFOut so don't make production changes here -->
                                    </xsl:for-each>
                                </xsl:variable>
                                <xsl:for-each select="entity">
                                    <!-- $processingType='testCPFOut' -->
                                    <xsl:call-template name="CpfRoot">
                                        <xsl:with-param name="counts" tunnel="yes" select="$counts"/>
                                        <xsl:with-param name="otherData" tunnel="yes" select="$otherData"/>
                                        <xsl:with-param name="entitiesForCPFRelations" tunnel="yes" select="$entitiesForCPFRelations"/>
                                        <xsl:with-param name="debug" select="$normalizeStepFive" tunnel="yes"/>
                                    </xsl:call-template>
                                </xsl:for-each>
                                <!-- use to test added bio and subject data [not(self::entity)] -->
                                <!--source>
                                    <xsl:for-each select="*">
                                    <xsl:copy-of select="."/>
                                    </xsl:for-each>
                                    </source-->
                            </xsl:if>
                        </xsl:for-each>
                        <!-- we are inside testCPFOut so don't make production changes here -->
                    </oneFindingAid>
                </xsl:when> <!-- $processingType='testCPFOut' -->
            </xsl:choose>

            <xsl:if test="$processingType='CPFOut'">    
                <xsl:message>
                    <xsl:text>starting cpfout</xsl:text>
                </xsl:message>
                <xsl:for-each select="$normalizeStepFive">
                    <xsl:if test="entity">
                        <xsl:variable name="counts">
                            <xsl:for-each select="originationCount | biogHistCount">
                                <xsl:copy-of select="."/>
                            </xsl:for-each>
                        </xsl:variable>

                        <xsl:variable name="otherData">
                            <xsl:for-each select="otherData/*">
                                <xsl:copy-of select="."/>
                            </xsl:for-each>
                            <xsl:if test="count(otherData/did/unittitle) > 1">
                                <!-- 
                                     This logging message is here because the unittitle has been a on-going
                                     problem. The many permutations have created at least half a dozen types
                                     of failures, most of which lose some of the title text. Dates and other
                                     markup may occur anywhere in the title, along with plain text and xpath
                                     can't cope with that. See templates.xsl template parse_unittitle.
                                -->
                                <xsl:message>
                                    <xsl:text>multi unittitle </xsl:text>
                                    <xsl:value-of select="concat('count: ', count(otherData/did/unittitle))"/>
                                    <xsl:for-each select="otherData/did/unittitle">
                                        <xsl:value-of select="concat(' ', position(), ': ', normalize-space())"/>
                                    </xsl:for-each>
                                </xsl:message>
                            </xsl:if>
                        </xsl:variable>

                        <!--
                            These are all the entities from the input file, including the <origination>. Later
                            code will figure out how not to make a cpfRelation to ourself, except when a
                            sameAs cpfRelation is created. It has to come later since all the .r files are
                            created from this list as well, and each file has to deal with the sameAs (or not)
                            issue.
                        -->
                        <xsl:variable name="entitiesForCPFRelations">
                            <!-- This entity is to collect just the information needed to create cpfRelations -->
                            <xsl:for-each select="entity">
                                <xsl:variable name="new_entity">
                                    <entity>
                                        <xsl:copy-of select="@*|*"/>
                                    </entity>
                                </xsl:variable>
                                <xsl:copy-of select="$new_entity"/>
                            </xsl:for-each>
                        </xsl:variable>

                        <xsl:for-each select="entity">
                            <!--
                                Template CpfRoot calls all the parts of the CPF place holder XML code that
                                finally makes the output CPF XML. See templates.xsl.
                            -->
                            <!-- $processingType='CPFOut' -->
                            <xsl:call-template name="CpfRoot">
                                <xsl:with-param name="counts" tunnel="yes" select="$counts"/>
                                <xsl:with-param name="otherData" tunnel="yes" select="$otherData"/>
                                <xsl:with-param name="entitiesForCPFRelations" tunnel="yes" select="$entitiesForCPFRelations"/>
                                <xsl:with-param name="debug" select="$normalizeStepFive" tunnel="yes"/>
                            </xsl:call-template>
                        </xsl:for-each>
                    </xsl:if>
                </xsl:for-each>
            </xsl:if> <!-- $processingType='CPFOut' -->
    </xsl:template> <!-- tpt_proc_inner -->

    <xsl:template name="tpt_main" match="/">
        <xsl:if test="string-length($cpfr_href) = 0">
            <xsl:message terminate="yes">
                <xsl:text>Error: Param cpfr_href is required. At least for BnF.</xsl:text>
                <xsl:value-of select="$cr"/>
                <xsl:text>Usage: snac_transform.sh createFileLists/bnf_list.xml eadToCpf.xsl cpfOutLocation=bnf_cpf_final inc_orig=0 cpfr_href="http://catalogue.bnf.fr/" > logs/bnf.log 2>&amp;1 &amp;</xsl:text>
            </xsl:message>
        </xsl:if>
        <xsl:message>
            <xsl:value-of select="concat('       cpfr_href: ', $cpfr_href, $cr)"/>
            <xsl:value-of select="concat('cpfr_href_suffix: ', $cpfr_href, $cr)"/>
            <xsl:value-of select="concat('  processingType: ', $processingType, $cr)"/>
            <xsl:value-of select="concat('  cpfOutLocation: ', $cpfOutLocation, $cr)"/>
            <xsl:value-of select="concat('        base-uri: ', base-uri(), $cr)"/>
            <!-- trick XSLT into evaluating $file2url now, so we get any potential warning at the beginning -->
            <xsl:value-of select="concat('        file2url: ', string-length($file2url), $cr)"/>
            <xsl:value-of select="concat('        inc_orig: ', $inc_orig, $cr)"/>
            <xsl:value-of select="$cr"/>
            <xsl:value-of select="concat(' log file notes ', $cr)"/>
            <xsl:text>   unfixed date: shows dates not handled by snac:fixDates, logged in case we want to add some future parsing</xsl:text>
            <xsl:value-of select="$cr"/>
            <xsl:text>    normalFinal: shows the fixed/cleaned/normal version of names as a sanity check</xsl:text>
            <xsl:value-of select="$cr"/>
            <xsl:text>   geog1: geogx: are here as a necessary part of the geonames parsing. See readme.md</xsl:text>
            <xsl:value-of select="$cr"/>
        </xsl:message>

        <!--
            dec 8 2014 we have new ahub data, so we are processing their EAD. Perhaps other collections should
            not be processed? 
            
            If uncommented, this needs a clearer message.
        -->

        <!-- <xsl:if test="matches(base-uri(), 'ahub_list.xml')"> -->
        <!--     <xsl:message terminate="yes"> -->
        <!--         <xsl:value-of select="'Skipping this file. See eadToCpf.xsl, line 1414'"/> -->
        <!--     </xsl:message> -->
        <!-- </xsl:if> -->

        <xsl:for-each select="snac:list/snac:group">
            <!--
                This is the new one-file-at-a-time code which reads one EAD file, processes it, and then
                outputs the relevant CPF.
                
                This loop processes of a list of ead files from the fileList for each contributor (or possibly
                for all contributors). Start and stop were originally controlled by attributes in the snac:list
                (fileList); stop and start are @n of each snac:group; snac:group will contain a varying number
                of file paths. The for-each snac:i below processes each file from the group.
                
                This script currently has start and stop hard coded over in the variables XSLT
                (variables.xsl), mostly for dev/test/debugging.
            -->
            <xsl:for-each select="snac:i">
                <xsl:variable name="process">
                    <xsl:call-template name="tpt_process">
                        <xsl:with-param name="icount" select="@n"/>
                    </xsl:call-template>
                </xsl:variable>
                <xsl:choose>
                    <xsl:when test="$processingType='CPFOut'">
                        <xsl:for-each select="$process/*">
                            <xsl:variable name="recordId" select="./control/recordId" xpath-default-namespace="urn:isbn:1-931666-33-4"/>
                            <xsl:result-document href="{$cpfOutLocation}/{$recordId}.xml" indent="yes">
                                <xsl:processing-instruction name="oxygen">
                                    <xsl:text>RNGSchema="http://socialarchive.iath.virginia.edu/shared/cpf.rng" type="xml"</xsl:text>
                                </xsl:processing-instruction>
                                <xsl:text>&#xA;</xsl:text>
                                <xsl:copy-of select="."/>
                            </xsl:result-document>
                        </xsl:for-each>
                    </xsl:when>
                    <xsl:otherwise>
                        <ptype>
                            <xsl:value-of select="$processingType"/>
                        </ptype>
                        <report>
                            <xsl:for-each select="$process/*">
                                <xsl:copy-of select="."/>
                            </xsl:for-each>
                        </report>
                    </xsl:otherwise>
                </xsl:choose>
                <!-- end of snac:i -->
            </xsl:for-each>
            <!-- end of each fileList batch -->
        </xsl:for-each>
        <!--
            Putting this message at the end of tpt_process was not right. Ditto above with
            result-document(). In both cases we get lots of messages, not one single message at the end.
            
            This doesn't guarantee that things worked, just that we got here without a fatal XSLT error or
            Java exception.
        -->
        <xsl:if test="$processingType='CPFOut'">
            <xsl:message>
                <xsl:text>Script completes CPF output ok.</xsl:text>
            </xsl:message>
        </xsl:if>
    </xsl:template> <!-- tpt_main match="/" -->

    <xsl:template name="tpt_attributeNormal">
        <xsl:choose>
            <!--
                May 12 2015 ... except where @normal *is* a version of the name (often with dates) that is
                optimized for display, at least for BnF. 
                
                <origination label="Producteur :"> <persname authfilenumber="ark:/12148/cb120328582"
                normal="Craig, Edward Gordon (1872-1966)" role="0580" source="OPP">Edward Gordon
                Craig</persname> </origination>

                jul 21 2014 changed value to normalize-space of context. Was @normal, but that created
                problems, and wasn't entirely sensible. @normal is (supposedly) a version of the name normalized for
                matching or other purposes, not for display. The value below *will* be in output.
                
                This does not work for all names, or not the way we expect. @normal often contains a lowercase
                version of the name. The value of <normal> ends up being the of nameEntry/part, which is very
                wrong when both <origination> and <controlaccess> have better values.
                
                See /data/source/findingAids/ahub/gulsc/1080_2002.xml
                
                <persname source="gb-0247" authfilenumber="p0430" normal="ogilvie, james dean,
                c1867-1949">Ogilvie, James Dean (c1867-1949: merchant, book collector and
                bibliographer)</persname>
            -->
            <xsl:when test="@normal">
                <normal type="attributeNormal">
                    <xsl:element name="{name()}">
                        <xsl:copy-of select="@*"/>
                        <xsl:value-of select="normalize-space(.)"/>
                    </xsl:element>
                </normal>
            </xsl:when>
            <xsl:otherwise>
                <normal type="provisional">
                    <xsl:element name="{name()}">
                        <xsl:copy-of select="@*"/>
                        <!--
                            If you change this you probably also need to change variable nice_name above.
                            
                            Build the name that we want. We will have to clean up extraneous dots (periods) and parenthesis.
                            
                            Mackay, Alexander Murdoch, 1849-1890 Mechanical engineer, missionary
                            Stokes,  Leonard Aloysius Scott . ( 1858-1925 )  architect
                        -->
                        <xsl:variable name="nice_name">
                            <xsl:for-each select="*|node()">
                                
                                <!-- <xsl:message> -->
                                <!--     <xsl:text>context nn: </xsl:text> -->
                                <!--     <xsl:value-of select="concat(name(), ' ', ., $cr)"/> -->
                                <!-- </xsl:message> -->

                                <!--
                                    new: sep 18 2014 Why weed anything out? We want the full text of names,
                                    even stuff in <emph> or any other element that people may have put into
                                    the name field.
                                    
                                    old: I couldn't figure out an xpath that didn't include
                                    <emph> (perhaps because it is matching node()) so just
                                    use an xsl:if to weed out the <emph> elements.
                                -->
                                <!-- <xsl:if test="name() != 'emph'"> -->
                                <xsl:value-of select="."/>
                                <xsl:value-of select="' '"/>
                                <!-- </xsl:if> -->
                            </xsl:for-each>

                            <!-- there are cases of multiple surname values "Lloyd" and "George", separated with a space -->

                            <xsl:value-of select="emph[@altrender='surname' or @altrender='a' ]" separator=" "/>
                            
                            <!-- comma after surname(s) -->
                            <xsl:value-of select="', '"/>
                            
                            <!-- there are cases of multiple forenames, so separate with space -->
                            <xsl:value-of select="emph[@altrender='forename']" separator=" "/>
                            <xsl:for-each select="emph[@altrender='dates' or 
                                                  @altrender='y' or
                                                  @altrender='epithet']">
                                <xsl:value-of select="concat(', ', .)"/>
                            </xsl:for-each>
                        </xsl:variable>
                        <xsl:value-of select="snac:removeLeadingComma(
                                              snac:removeFinalComma(
                                              snac:removeDoubleComma(
                                              snac:fixDates($nice_name))))"/>
                    </xsl:element>
                </normal>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="aboutOriginationEntity">
        <xsl:param name="eadPath"/>
        <xsl:param name="selectBioghist"/>
        <!--
            This template extracts bioghist and occupation
        -->
        <xsl:variable name="geognamesAll">
            <xsl:for-each select="ead/archdesc/controlaccess/geogname
                                  | ead/archdesc/controlaccess/controlaccess/geogname">
                <xsl:copy-of select="."/>
            </xsl:for-each>
        </xsl:variable>

        <!--
            Records with data that has embedded elements require a more interesting xpath selector
            ".//*|node()" to prevent words concatenated without space. This only happens in the AHUB data (so
            far).
            
            <geogname source="lcsh" role="subject"><emph altrender="a">Great Britain</emph><emph
            altrender="x">History</emph><emph altrender="y">Puritan Revolution, 1642-1660</emph></geogname>
            
            The code in the variable temp below fixes this bug:
            <normalized>Great BritainHistoryPuritan Revolution, 1642-1660</normalized>
            
            This is fixed as well:
            <geogname source="lcsh" role="subject" encodinganalog="651" rules="scm">Seattle (Wash.)$xHistory$vPhotographs</geogname>
            
            Not fixed: This is just a typo, and perhaps not so common ($ with no following lower-case letter) 
            <geogname source="lcsh" rules="scm" role="subject" encodinganalog="651">Washington (State)$xHistory$Photographs</geogname>
        -->
        <xsl:variable name="geognameSets">
            <xsl:for-each select="$geognamesAll/geogname[string-length() > 0]">
                <geognameSet>
                    <raw>
                        <xsl:copy-of select="."/>
                    </raw>
                    <normalized>
                        <xsl:choose>
                            <xsl:when test="contains(.,'--')">
                                <xsl:value-of select="normalize-space(substring-before(.,'--'))"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:variable name="temp">
                                    <xsl:value-of select=".//*|node()" separator="--"/>
                                </xsl:variable>
                                <!-- <xsl:message> -->
                                <!--     <xsl:text>gtemp1: </xsl:text> -->
                                <!--     <xsl:copy-of select=".//*|node()"/> -->
                                <!--     <xsl:value-of select="snac:normalizeString($temp)"/> -->
                                <!--     <xsl:value-of select="$cr"/> -->
                                <!--     <xsl:value-of select="snac:normalizeString(replace($temp, '\$[a-z]', '\-\-'))"/> -->
                                <!-- </xsl:message> -->
                                <xsl:value-of select="replace(normalize-space(replace($temp, '\$[a-z]', '--')), '\s+--\s+', '--')"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </normalized>
                    <normalForMatch>
                        <xsl:choose>
                            <xsl:when test="contains(.,'--')">
                                <xsl:value-of select="snac:normalizeString(substring-before(.,'--'))"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:variable name="temp">
                                    <xsl:value-of select=".//*|node()" separator="--"/>
                                </xsl:variable>
                                <!-- <xsl:message> -->
                                <!--     <xsl:text>gtemp2: </xsl:text> -->
                                <!--     <xsl:value-of select="snac:normalizeString($temp)"/> -->
                                <!--     <xsl:value-of select="$cr"/> -->
                                <!--     <xsl:value-of select="snac:normalizeString(replace($temp, '\$[a-z]', '\-\-'))"/> -->
                                <!-- </xsl:message> -->
                                <xsl:value-of select="replace(snac:normalizeString(replace($temp, '\$[a-z]', '--')), '\s+--\s+', '--')"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </normalForMatch>
                </geognameSet>
            </xsl:for-each>
        </xsl:variable>

        <!--
            Some of this ends up in <resourceRelation>. This variable gets tunneled through to template
            cpfDescription.
        -->
        <otherData>
            <!-- Add a message to the log so we can find, and test multi langmaterial records -->
            <xsl:if test="count(ead/archdesc/langmaterial) > 1">
                <xsl:message>
                    <xsl:text>multi langmaterial</xsl:text>
                    <xsl:for-each select="ead/archdesc/langmaterial">
                        <xsl:copy-of select="."/>
                        <xsl:value-of select="$cr"/>
                    </xsl:for-each>
                </xsl:message>
            </xsl:if>
            <eadPath>
                <xsl:value-of select="snac:getFileName($eadPath)"/>
            </eadPath>
            <authorizedForm>
                <xsl:value-of select="$sourceID"/>
            </authorizedForm>
            <countryCode>
                <xsl:choose>
                    <xsl:when test="$sourceID='bnf' or $sourceID='anfra' or $sourceID='ccfr'">
                        <xsl:text>FR</xsl:text>
                    </xsl:when>
                    <xsl:when test="$sourceID='ahub'">
                        <xsl:text>GB</xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text>US</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
            </countryCode>
            <!--
                jun 26 2015 ccfr has langusage/language/@langcode="fre", but it isn't clear that all EAD
                follows that convention. So, we will just hardcode for repostories that we know are all
                French. $sourceID comes from variables.xsl from a *_list.xml file such as createFileLists/ccfr_list.xml.
            -->
            <languageOfDescription>
                <xsl:choose>
                    <xsl:when test="$sourceID='bnf' or $sourceID='anfra' or $sourceID='ccfr'">
                        <xsl:text>fre</xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text>eng</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
            </languageOfDescription>
            <!--
                unitid is ead/archdesc/did/unitid and may be multiple. Since we are inside $otherData, all
                this will be tunneled to templates.
            -->
            <xsl:copy-of select="ead/eadheader/eadid"/>
            <xsl:copy-of select="ead/archdesc/did"/>
            <!--
                Sep 10 2014: <citation> and resourceRelation/relationEntry are both created from unittitle and
                unitdate. (May 12 2015 Not in the code below, but over in templates.xsl.) If there is a
                repository, or something in $other_data/repo_info, <citation> will use it. Keep this in mind
                when reading the comments below.
                
                Save repository info. UNL records don't have ead/archdesc/did/repository,
                so we must rely on unitid/@repositoryCode
                
                <unitid label="Collection Number:" encodinganalog="099" countrycode="us" repositorycode="NbU">RG 12-10-50</unitid> 
                
                Some other repository variations showing multiple <repository> elements, text elements mixed
                with other elements, and an example with a <corpname> element.
                
                <repository label="Repository">David M. Rubenstein Rare Book &amp; Manuscript Library, Duke University</repository>
                <repository label="Repository">University Archives, Records and History Center, North Carolina Central University</reposi
                
                <repository encodinganalog="852$a" label="Repository: ">
                Special Collections Research Center, <lb/> Syracuse University Libraries <lb/>
                <address>
                <addressline>222 Waverly Avenue<lb/></addressline><addressline>Syracuse, NY 13244-2010<lb/></addressline>
                <addressline><ptr href="http://scrc.syr.edu"/></addressline>
                </address>
                </repository>
                
                <repository label="Repository">
                <corpname>California State Archives
                </corpname>
                <address>
                <addressline>Sacramento, California</addressline>
                </address>
                </repository>
                
                Save the whole <repository> in case something downstream needs it. Currently ignored. Put a
                serialized version of the name as we want it to appear in the <citation> into <normal>.
            -->
            <xsl:choose>
                <xsl:when test="ead/archdesc/did/repository">
                    <repo_info>
                        <xsl:copy-of select="ead/archdesc/did/repository/(*|node())"/>
                        <normal>
                            <xsl:variable name="pass1">
                                <xsl:for-each select="ead/archdesc/did/repository">
                                    <xsl:choose>
                                        <xsl:when test="corpname|extref">
                                            <xsl:for-each select="./text()|corpname|extref">
                                                <xsl:if test="self::text()">
                                                    <xsl:value-of select="concat(., ' ')"/>
                                                </xsl:if>
                                                <!-- text nodes won't go into the for-each below -->
                                                <xsl:for-each select="*|node()">
                                                    <xsl:value-of select="concat(.,' ')"/>
                                                </xsl:for-each>
                                            </xsl:for-each>
                                        </xsl:when>
                                        <xsl:when test="./text()">
                                            <!--
                                                Immediate child notes with text. We ignore non-text child elements.
                                            -->
                                            <xsl:for-each select="./text()|(./subarea/text())">
                                                <xsl:value-of select="concat(., ' ')"/>
                                            </xsl:for-each>
                                        </xsl:when>
                                        <xsl:when test="//text()">
                                            <!--
                                                As a last resort, text nodes anywhere, even inside child elements.
                                            -->
                                            <xsl:for-each select=".//text()">
                                                <xsl:value-of select="concat(., ' ')"/>
                                            </xsl:for-each>
                                        </xsl:when>
                                        <xsl:otherwise>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                    <xsl:if test="position() > 1">
                                        <xsl:value-of select="', and '"/>
                                    </xsl:if>
                                </xsl:for-each>
                            </xsl:variable>

                            <xsl:variable name="pass2">
                                <xsl:value-of select="normalize-space(
                                                      replace(
                                                      replace($pass1, ', and *$', ''), 
                                                      ' ,', ','))"/>
                            </xsl:variable>
                            <xsl:value-of select="$pass2"/>
                        </normal>
                    </repo_info>
                </xsl:when>
                <xsl:when test="ead/archdesc/did/unitid[@repositorycode = 'NbU']">
                    <repo_info>
                        <corpname>Archives &#38; Special Collections<lb/>University of Nebraska&#8212;Lincoln Libraries</corpname>
                    </repo_info>
                </xsl:when>
                <xsl:otherwise>
                    <repo_info missing="1">
                    </repo_info>
                </xsl:otherwise>
            </xsl:choose>

            <!--
                Either this is wrong, or the other call to selectBioghist is wrong.  template name="aboutOriginationEntity"
                Calling selectBioghist here causes the entire biogHist to duplicate in this entity record.
                <xsl:call-template name="selectBioghist"/>
            -->

            <xsl:copy-of select="$selectBioghist"/>

            <xsl:for-each select="$geognameSets">
                <xsl:for-each-group select="geognameSet" group-by="normalForMatch">
                    <geognameGroup>
                        <!-- <xsl:message> -->
                        <!--     <xsl:text>gng: </xsl:text> -->
                        <!--     <xsl:copy-of select="./normalized[1]"/> -->
                        <!-- </xsl:message> -->
                        <xsl:copy-of select="./normalized[1] | ./normalForMatch[1]"/>
                        <xsl:for-each select="current-group()">
                            <xsl:copy-of select="raw"/>
                        </xsl:for-each>
                    </geognameGroup>
                </xsl:for-each-group>
            </xsl:for-each>

            <xsl:for-each
                select="ead/archdesc/controlaccess/(occupation | subject | function) 
                        | ead/archdesc/controlaccess/controlaccess/(occupation | subject | function)">
                <xsl:copy-of select="."/>
            </xsl:for-each>
        </otherData>
    </xsl:template> <!-- end aboutOriginationEntity -->

    <xsl:template name="tpt_selectBioghist">
        <xsl:param name="icount"/>
        <xsl:param name="fn"/>
        <!--
            Note: from $serial_bh forward, bioghist is flattened and has no nesting of bioghist elements. This
            simplifies everything downstream, and makes quite a bit of code unnecessary.
            
            See tpt_bioghist and tpt_bioghist_nested below.
            
            Apr 7 2015. uchic has a different location for bioghist. Normally, I'd use both paths, and
            apply-templates twice, but I don't know what the downstream code expects. So, we do one xpath for
            bioghist, or the other, but not both.
        -->

        <xsl:variable name="serial_bh">
            <xsl:choose>
                <xsl:when test="ead/archdesc/bioghist">
                    <xsl:apply-templates select="ead/archdesc/bioghist" mode="bh"/>
                </xsl:when>
                <xsl:when test="ead/archdesc/descgrp/bioghist">
                    <xsl:apply-templates select="ead/archdesc/descgrp/bioghist" mode="bh"/>
                </xsl:when>
            </xsl:choose>
        </xsl:variable>

        <!-- Doesn't work. Nesting breaks it. See the old 2532 example. -->
        <!-- <xsl:for-each select="ead/archdesc/bioghist | ead/archdesc/bioghist/bioghist"> -->

        <xsl:variable name="biogHists">         
            <xsl:for-each select="$serial_bh/bioghist">
                <!--
                    The first selects a simple bioghist (neither containing or contained in another bioghist The
                    second selects a bioghist that contains both a chronlist or one or more paragraphs AND does
                    not itself contain bioghist The third selects those bioghist not selected by the second, in
                    particular, or the first.  The otherwise filters out those bioghist/bioghist that would
                    otherwise be matched separately.
                    
                    Excluded were bioghist/bioghist/bioghist as all evident were of type: .[(chronlist or
                    p)][bioghist] This may have to be reconsidered.
                -->
                
                <!-- <xsl:message> -->
                <!--     <xsl:value-of select="concat('sbh/bh ', position(), ': ')"/> -->
                <!--     <xsl:copy-of select="."/> -->
                <!-- </xsl:message> -->

                <xsl:variable name="case">
                    <xsl:choose>
                        <xsl:when test=".[not(bioghist or parent::bioghist)]">
                            <xsl:text>1</xsl:text>
                        </xsl:when>
                        <xsl:when test=".[(chronlist or p)][bioghist]">
                            <xsl:text>2</xsl:text>
                        </xsl:when>
                        <xsl:when test=".[parent::bioghist[not(chronlist or p)]]">
                            <xsl:text>3</xsl:text>
                        </xsl:when>
                        <xsl:when test=".[parent::bioghist]">
                            <!-- The logical negation of #1b above. Must come before 4x.-->
                            <xsl:text>5x</xsl:text>
                        </xsl:when>
                        <xsl:when test=".[bioghist]">
                            <!-- The logical negation of #1a above. -->
                            <xsl:text>4x</xsl:text>
                        </xsl:when>
                        <!-- 
                             We use x for eXcluded.
                        -->
                        <xsl:otherwise>
                            <xsl:text>x</xsl:text>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <bioghist pos="{position()}" case="{$case}" xmlns="urn:isbn:1-931666-33-4">
                    <xsl:copy-of select="./@*"/>
                    <xsl:copy-of select="./*"/>
                </bioghist>
            </xsl:for-each>
        </xsl:variable>

        <xsl:variable name="bcount"
                      select="count($biogHists/*) + count($biogHists/eac:biogHist)+count($biogHists/biogHist)"/>
        
        <!-- <xsl:message> -->
        <!--     <xsl:text>bh: </xsl:text> -->
        <!--     <xsl:value-of select="concat('bh: ', $bcount, $cr, ' allb: ', count($biogHists//*[local-name() = 'bioghist']), $cr)"/> -->
        <!--     <xsl:copy-of select="$biogHists"/> -->
        <!-- </xsl:message> -->

        <xsl:if test="$bcount &gt;= 1">
            <!--
                icount is the snac:i@n thus the count within the group. Handy for debugging.
                bcount is just the count of biogHist child elements
                path is the file name
            -->
            <xsl:message>
                <i icount="{$icount}" bcount="{$bcount}" path="{$fn}">
                    <xsl:if test="false()"> <!-- disabled via false() because we aren't using these debug messages -->
                        <xsl:value-of select="$cr"/>
                        <bioghist_debug>
                            <xsl:for-each select="$biogHists/*">
                                <!-- <xsl:copy-of select=".//*[not(child::*)]"/> -->
                                <!--
                                    The excitement here is that we want nodes with no children. If we
                                    wanted to stop at some node like chronitem that has chilren, then we
                                    have to name it and exclude its children (unless we want them too). We
                                    also want nodes with child:emph, but not when the parent of the emph
                                    is p. Yes, this is complicated.
                                    
                                    To add a new terminal element, "or" it to the end of the first
                                    clause (as with self::date), then "and" any child elements as
                                    not(self::child_name) in the next clause. 
                                -->
                                <!-- <xsl:for-each select=".//*[(child::emph or -->
                                <!--                       (not(child::*) and not(self::emph[parent::p])) or -->
                                <!--                       self::chronitem or -->
                                <!--                       self::defitem) and -->
                                <!--                       ( -->
                                <!--                       not(self::date) and not(self::event) and  -->
                                <!--                       not(self::label) and not(self::item) -->
                                <!--                       )]"> -->

                                <xsl:for-each select="*">
                                    <xsl:call-template name="tpt_brecurse">
                                        <xsl:with-param name="depth" select="1"/>
                                        <xsl:with-param name="ppos" select="position()"/>
                                    </xsl:call-template>
                                </xsl:for-each>

                                <!-- <xsl:for-each select=".//*"> -->
                                <!--     <xsl:call-template name="tpt_bioghist_debug"> -->
                                <!--         <xsl:with-param name="pos" select="position()"/> -->
                                <!--     </xsl:call-template> -->
                                <!-- </xsl:for-each> --> 
                                <xsl:value-of select="$cr"/>
                            </xsl:for-each>
                        </bioghist_debug>
                        <xsl:value-of select="$cr"/>
                    </xsl:if>

                    <!--
                        Enable this to output the biogHist source. fn: and @path are in the output, so one can
                        always find the original file.
                    -->
                    <!-- <xsl:copy-of select="$biogHists"/> -->
                </i>
            </xsl:message>
        </xsl:if>
        <xsl:copy-of select="$biogHists"/>
    </xsl:template> <!-- end tpt_selectBioghist -->

    <xsl:template name="tpt_brecurse">
        <xsl:param name="depth"/>
        <xsl:param name="ppos"/>
        
        <xsl:variable name="currn" select="name()"/>
        
        <!-- A big string of spaces so we can align things later. See substring below. -->
        <xsl:variable name="spaces">
            <xsl:text>                                                                                                                                </xsl:text>
        </xsl:variable>

        <xsl:choose>
            <!-- disabled via false(), it wasn't useful -->
            <xsl:when test="false() and count(node()) > 1">
                <!-- Do nothing because we want our child text node to display our depth/position. -->
                <xsl:variable name="outstr">
                    <xsl:value-of select="concat($cr, ' path:')"/>
                    <xsl:value-of select="ancestor-or-self::*/name()" separator="/"/>
                </xsl:variable>
                <xsl:value-of select="concat(' nodes:', count(node()))"/>
            </xsl:when>

            <!-- disabled via false(), it wasn't useful -->
            <xsl:when test="false() and count(node()) = 1">
                <xsl:variable name="outstr">
                    <xsl:value-of select="concat($cr, ' path:')"/>
                    <xsl:value-of select="ancestor-or-self::*/name()" separator="/"/>
                </xsl:variable>
                <xsl:value-of select="concat(' nodes:', count(node()))"/>
            </xsl:when>

            <!-- Works great, but disabled via false() until we need it. -->
            <xsl:when test="false() and count(node()) = 0">
                <xsl:variable name="outstr">
                    <xsl:value-of select="concat($cr, ' path:')"/>
                    <xsl:value-of select="ancestor-or-self::*/name()" separator="/"/>
                    
                    <xsl:if test="self::text()">
                        <!-- <xsl:value-of select="ancestor-or-self::*/name()" separator="/"/> -->
                        <xsl:text>/text()</xsl:text>
                    </xsl:if>
                    
                    <!-- <xsl:value-of select="concat(' d/p', $depth, '/', position())"/> -->
                </xsl:variable>
                <xsl:value-of select="$outstr"/>
                <xsl:value-of select="concat($cr, substring($spaces, 1, string-length($outstr)), $depth, '/', $ppos)"/>
            </xsl:when>
        </xsl:choose>

        <!-- 
             Print the count of node() for the current context so the debugging is clear about how many
             children elements to expect.
             
             If count node() is zero, then we are probably in a text node, and we don't care about the count.
             
             If count node() is 1 then we only have 1 child, and the next recursion will display it, so again
             we don't care.
        -->

        <!-- <xsl:if test="count(node()) > 1" > -->
        <!--     <xsl:value-of select="concat($cr, ' nodes:', count(node()), ' ')"/> -->
        <!--     <xsl:value-of select="ancestor-or-self::*/name()" separator="/"/> -->
        <!-- </xsl:if> -->
        
        <xsl:for-each select="node()">
            <xsl:call-template name="tpt_brecurse">
                <!-- <xsl:with-param name="depth" select="$depth+1"/> -->
                <xsl:with-param name="depth" select="$ppos"/>
                <xsl:with-param name="ppos" select="position()"/>
            </xsl:call-template>
        </xsl:for-each>
    </xsl:template> <!-- tpt_brecurse -->

    <!--
        Unused. I think all the relevant stuff goes into the log file, makeing tpt_bioghist_debug unnecessary.
        Additionally, the iterative version was missing elements, so the new version of the working code is
        recursive.
    -->
    <xsl:template name="tpt_bioghist_debug">
        <xsl:param name="pos"/>
        <!--
            Rely on the context being automatically passed in, same as the context was (is?) in the for-each
            around the call-template.
        -->
        <xsl:variable name="currn" select="name()"/>

        <xsl:if test="true()"> <!-- debug -->
            <xsl:value-of select="concat($cr, ' path:')"/>
            <xsl:value-of select="ancestor-or-self::*/name()" separator="/"/>
            <xsl:if test="text()">
                <xsl:text>/text()</xsl:text>
            </xsl:if>
            <xsl:value-of select="concat(' ', $pos)"/>
            <!-- <xsl:value-of select="concat(' pn:', preceding-sibling::*[1]/name(), ' copy: ', $cr)"/> -->
            <!-- <xsl:copy-of select="."/> -->
        </xsl:if>

        <xsl:if test="false()"> <!-- disabled -->
            <xsl:if test="preceding-sibling::*[1][name() != $currn] or not(preceding-sibling::*)">
                <xsl:variable name="tpos"> <!-- mnemonic: top position (of bioghist) -->
                    <xsl:value-of select="position()"/>
                </xsl:variable>
                <xsl:value-of select="$cr"/>
                <xsl:for-each select="ancestor-or-self::*">
                    <xsl:value-of select="concat('n:', name())"/>
                    <xsl:if test="matches(name(), 'bioghist', 'i') and not(@pos)">
                        <xsl:variable name="pbx"> <!-- mnemomic: position bioghist x (count) -->
                            <xsl:value-of
                                select="count(preceding-sibling::*[matches(name(), 'bioghist', 'i')])+1"/>
                        </xsl:variable>
                        <xsl:value-of select="concat(' ipos=&quot;', $pbx, '&quot;')"/>
                    </xsl:if>

                    <!--
                        Disabled to allow grep'ing the output.
                        Output the attributes, but not attributes named id because
                        we don't want biogHist@id, nor do we want emph@render.
                    -->
                    <!-- <xsl:for-each select="@*[name() != 'id' and name() != 'render']"> -->
                    <!--     <xsl:value-of select="concat(' ', name(), '=&quot;', ., '&quot;')"/> -->
                    <!-- </xsl:for-each> -->

                    <xsl:text>/</xsl:text><!-- slash -->

                    <xsl:if test="matches(name(), 'head|emph', 'i')">
                        <xsl:value-of select="concat(' &quot;', normalize-space(.), '&quot;')"/>
                    </xsl:if>
                </xsl:for-each>
            </xsl:if>
        </xsl:if>

        <!--
            This is all about sibling elements with the same name. If our sib
            has the same name, not print it again, just note the count of
            repeating sibs.
            
            Interestingly, some list-like constructs begin with self::emph
            instead of an enclosing element. Trying to turn these into real
            sequences (aka node sets) with real enclosing elements would be
            exciting.
        -->
        <xsl:if test="preceding-sibling::*[1][name() = $currn]">
            <xsl:if test="false()"> <!-- debug -->
                <xsl:value-of select="concat('psib: ', count(preceding-sibling::*[name() = $currn]))"/>
            </xsl:if>
            <!-- 1 and position() =  -->
            <xsl:if test="count(following-sibling::*[name() = $currn]) = 0">
                <xsl:value-of select="concat(', ', count(preceding-sibling::*[name() = $currn])+1)"/>
            </xsl:if>
            <xsl:if test="false()">
                <xsl:value-of select="'.'"/> <!-- dot -->
            </xsl:if>
        </xsl:if>

    </xsl:template> <!-- name="tpt_bioghist_debug" -->

    <xsl:template name="existDateFromPersname">
        <xsl:param name="tempString"/>

        <xsl:variable name="dateString" select="normalize-space(snac:getDateFromPersname($tempString))"/>
        <!-- takes as input a personal name string -->

        <!-- <xsl:message> -->
        <!--     <xsl:value-of select="concat('edfp: ', $tempString, ' dateString: ', $dateString, $cr)"/> -->
        <!-- </xsl:message> -->

        <!--
            snac:getDateFromPersname extracts substring from the string that matches an expected date pattern.
            Year dates can be NNN or NNNN.
        -->
        <xsl:variable name="dateStringAnalyzeResultsOne">
            <xsl:choose>
                <xsl:when test="$dateString='0'">
                    <empty/>
                </xsl:when>
                <xsl:when test="contains($dateString,'-')">
                    <!--
                        if hyphen found, creates two substrings, from and to; if not found, then a single string 
                    -->
                    <fromString>
                        <xsl:value-of select="normalize-space(substring-before($dateString,'-'))"/>
                    </fromString>
                    <toString>
                        <xsl:value-of select="normalize-space(substring-after($dateString,'-'))"/>
                    </toString>
                </xsl:when>
                <xsl:otherwise>
                    <singleString>
                        <xsl:value-of select="normalize-space($dateString)"/>
                    </singleString>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <!-- <xsl:for-each select="$dateStringAnalyzeResultsOne"> -->
        <!-- </xsl:for-each> -->

        <!--
            There are several matches inline here. Rather than risk a typo in one of the cases, use a variable
            for the match. This is actual date parsing. There is other non-parsing date cleaning in
            functions.xsl.
            
            Circa is trick. Must have a c, 1 or zero a, 1 or zero \. (Note to self: quantifier ? is 1 or zero
            by itself. Following a quantifier with ? signifies non-greedy, and in this latter case ? is a
            modifier, not a quantifier.)
        -->
        
        <xsl:variable name="florish_match" select="'fl\.?'"/>
        <xsl:variable name="circa_match" select="'ca?\.?'"/>

        <xsl:variable name="dateStringAnalyzeResultsTwo">
            <xsl:choose>
                <xsl:when test="$dateStringAnalyzeResultsOne/empty">
                    <empty/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:for-each select="$dateStringAnalyzeResultsOne/fromString">
                        <fromDate>
                            <xsl:for-each select="tokenize(.,'\s')">
                                <!--
                                    jan 2 2015 Deal with fl no dot
                                -->
                                <!-- <xsl:if test="matches(.,'fl\.?')"> -->
                                <xsl:if test="matches(., $florish_match)">
                                    <active/>
                                </xsl:if>
                                <xsl:if test="matches(.,'active')">
                                    <active/>
                                </xsl:if>
                                <!--
                                    jan 2 2015 Deal with 'ca', 'c' with and without dots
                                -->
                                <!-- <xsl:if test="matches(.,'ca\.?')"> -->
                                <xsl:if test="matches(., $circa_match)">
                                    <circa/>
                                </xsl:if>
                                <xsl:if test="matches(.,'[\d]{3,4}')">
                                    <xsl:call-template name="createDateValueInAnalzyedDates"/>
                                </xsl:if>
                            </xsl:for-each>
                        </fromDate>
                    </xsl:for-each>
                    <xsl:for-each select="$dateStringAnalyzeResultsOne/toString">
                        <toDate>
                            <xsl:for-each select="tokenize(.,'\s')">
                                <xsl:if test="matches(., $florish_match)">
                                    <active/>
                                </xsl:if>
                                <xsl:if test="matches(.,'active')">
                                    <active/>
                                </xsl:if>
                                <xsl:if test="matches(., $circa_match)">
                                    <circa/>
                                </xsl:if>
                                <xsl:if test="matches(.,'[\d]{3,4}')">
                                    <xsl:call-template name="createDateValueInAnalzyedDates"/>
                                </xsl:if>
                            </xsl:for-each>
                        </toDate>
                    </xsl:for-each>
                    <xsl:for-each select="$dateStringAnalyzeResultsOne/singleString">
                        <singleDate>
                            <xsl:for-each select="tokenize(.,'\s')">
                                <xsl:if test="matches(., $florish_match)">
                                    <active/>
                                </xsl:if>
                                <xsl:if test="matches(.,'active')">
                                    <active/>
                                </xsl:if>
                                <xsl:if test="matches(., $circa_match)">
                                    <circa/>
                                </xsl:if>
                                <!--
                                    We have birth and death dates that are 'b' no dot and 'd' no dot. 
                                -->
                                <!-- <xsl:if test="matches(.,'b\.?')"> -->
                                <xsl:if test="matches(.,'b\.*')">
                                    <born/>
                                </xsl:if>
                                <!-- <xsl:if test="matches(.,'d\.?')"> -->
                                <xsl:if test="matches(.,'d\.*')">
                                    <died/>
                                </xsl:if>
                                <xsl:if test="matches(.,'[\d]{3,4}')">
                                    <xsl:call-template name="createDateValueInAnalzyedDates"/>
                                </xsl:if>
                            </xsl:for-each>
                        </singleDate>
                    </xsl:for-each>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <!-- Now create the existDates -->

        <xsl:choose>
            <!-- <xsl:when test="not($dateStringAnalyzeResultsTwo/normalizedValue)"> -->
            <xsl:when test="not($dateStringAnalyzeResultsTwo//normalizedValue)">
                <!-- Do nothing -->
            </xsl:when>
            <xsl:when test="$dateStringAnalyzeResultsTwo/empty">
                <!-- Do nothing -->
            </xsl:when>
            <xsl:when test="($dateStringAnalyzeResultsTwo/fromDate/active != '' and $dateStringAnalyzeResultsTwo/fromDate/active &gt; $this_year) or
                            ($dateStringAnalyzeResultsTwo/toDate/active != '' and $dateStringAnalyzeResultsTwo/toDate/active &gt; $this_year) or
                            ($dateStringAnalyzeResultsTwo//normalizedValue != '' and $dateStringAnalyzeResultsTwo//normalizedValue &gt; $this_year)">
                <!--
                    Test that the date holds something we can convert to a number, or we will get an error:
                    
                    fn: /data/source/findingAids/nwda/eastern_washington_state_historical_society_northwest_museum_of_arts_and_culture/UAKMsSC1.xml
                    Validation error on line 2465 of eadToCpf.xsl:
                    FORG0001: Cannot convert string to double: ""
                    
                    
                    Do nothing (because the date is bad and will throw a validation error from jing). This
                    date is suspicious, but is also more than that since the other suspicious types don't
                    cause validation errors.
                    
                    Added Oct 1 2014 to capture dates in the future which have been slipping through.
                    
                    xlf /data/source/findingAids/nwda/pacific_lutheran_university_archives_and_special_collections_department/OPVELCA7a4_161.xml
                    
                    <persname role="subject" encodinganalog="600" rules="dacs">Lock, Otto,
                    1913-4919 </persname>
                -->
            </xsl:when>

            <xsl:when test="$dateStringAnalyzeResultsTwo/fromDate or $dateStringAnalyzeResultsTwo/toDate">

                <xsl:variable name="suspicousDateRange">
                    <xsl:choose>
                        <xsl:when test="$dateStringAnalyzeResultsTwo/fromDate/active or
                                        $dateStringAnalyzeResultsTwo/toDate/active">
                            <xsl:choose>
                                <xsl:when test="$dateStringAnalyzeResultsTwo/toDate != ''">
                                    <xsl:choose>
                                        <!-- Opps. Backward test should be &gt; -->
                                        <!-- <xsl:when -->
                                        <!--     test="$dateStringAnalyzeResultsTwo/fromDate/normalizedValue &lt; -->
                                        <!--           $dateStringAnalyzeResultsTwo/toDate/normalizedValue"> -->
                                        <!--     <xsl:text>yes</xsl:text> -->
                                        <!-- </xsl:when> -->
                                        <xsl:when
                                            test="$dateStringAnalyzeResultsTwo/fromDate/normalizedValue &gt;
                                                  $dateStringAnalyzeResultsTwo/toDate/normalizedValue">
                                            <xsl:text>yes</xsl:text>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:text>no</xsl:text>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:text>no</xsl:text>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:when>

                        <!--
                            Consider testing "active" here, or moving inside the active test above. (Really?)
                            Birth+15 gt death is suspicious, and this code checks that. However,
                            active_from+15 gt active_to could be ok, and this code doesn't handle that.
                        -->
                        <xsl:when test="$dateStringAnalyzeResultsTwo/toDate != ''">
                            <xsl:choose>
                                <xsl:when
                                    test="$dateStringAnalyzeResultsTwo/fromDate/normalizedValue + 15 &gt;
                                          $dateStringAnalyzeResultsTwo/toDate/normalizedValue">
                                    <xsl:text>yes</xsl:text>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:text>no</xsl:text>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:text>no</xsl:text>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>

                <existDates>
                    <xsl:if test="$suspicousDateRange='yes'">
                        <xsl:attribute name="localType">
                            <xsl:value-of select="$av_suspiciousDate"/>
                            <!-- <xsl:text>http://socialarchive.iath.virginia.edu/control/term#SuspiciousDate</xsl:text> -->
                        </xsl:attribute>
                    </xsl:if>
                    <dateRange>
                        <xsl:for-each select="$dateStringAnalyzeResultsTwo/fromDate">
                            <!-- <xsl:message> -->
                            <!--     <xsl:text>fd: </xsl:text> -->
                            <!--     <xsl:copy-of select="."/> -->
                            <!-- </xsl:message> -->
                            <xsl:choose>
                                <!--
                                    Empty or not a number. Jan 5 2015 discover a NaN fromDate in /data/source/findingAids/ahub/f_24292.xml
                                    
                                    Unclear how testing . ever worked.
                                    
                                    <fromDate>
                                    <normalizedValue>1642</normalizedValue>
                                    <value>1642</value>
                                    </fromDate>
                                    <toDate>
                                    <normalizedValue>1693</normalizedValue>
                                    <value>1693</value>
                                    </toDate>
                                -->
                                <!-- <xsl:when test=".='' or number(.) != ."> -->
                                <!-- <xsl:when test=".='' or not(string(.) castable as xs:integer)"> -->
                                <xsl:when test="normalizedValue = '' or not(string(normalizedValue) castable as xs:integer)">
                                    <!-- <xsl:if test=". != '' and not(string(.) castable as xs:integer)"> -->
                                    <!--     <xsl:message> -->
                                    <!--         <xsl:text>not castable: </xsl:text> -->
                                    <!--         <xsl:value-of select="."/> -->
                                    <!--     </xsl:message> -->
                                    <!-- </xsl:if> -->
                                    <fromDate/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <fromDate>
                                        <xsl:attribute name="localType">
                                            <xsl:choose>
                                                <xsl:when test="active">
                                                    <xsl:value-of select="$av_active"/>
                                                </xsl:when>
                                                <xsl:otherwise>
                                                    <xsl:value-of select="$av_born"/>
                                                </xsl:otherwise>
                                            </xsl:choose>
                                        </xsl:attribute>
                                        <xsl:if test="circa">
                                            <xsl:attribute name="notBefore">
                                                <xsl:number value="number(normalizedValue)-3" format="0001"/>
                                            </xsl:attribute>
                                            <xsl:attribute name="notAfter">
                                                <xsl:number value="number(normalizedValue)+3" format="0001"/>
                                            </xsl:attribute>
                                        </xsl:if>
                                        <xsl:attribute name="standardDate">
                                            <xsl:number value="normalizedValue" format="0001"/>
                                        </xsl:attribute>
                                        <xsl:if test="active">
                                            <xsl:text>active </xsl:text>
                                        </xsl:if>
                                        <xsl:if test="circa">
                                            <xsl:text>approximately </xsl:text>
                                        </xsl:if>
                                        <xsl:value-of select="value"/>
                                    </fromDate>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:for-each>
                        
                        <xsl:for-each select="$dateStringAnalyzeResultsTwo/toDate">
                            <xsl:choose>
                                <!--
                                    Empty or not a number. Jan 5 2015 discover a NaN fromDate in /data/source/findingAids/ahub/f_24292.xml
                                    Add NaN test here in toDate as well.
                                -->
                                <xsl:when test="normalizedValue = '' or not(string(normalizedValue) castable as xs:integer)">
                                    <toDate/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <toDate>
                                        <xsl:attribute name="localType">
                                            <xsl:choose>
                                                <xsl:when test="active">
                                                    <xsl:value-of select="$av_active"/>
                                                </xsl:when>
                                                <xsl:otherwise>
                                                    <xsl:value-of select="$av_died"/>
                                                </xsl:otherwise>
                                            </xsl:choose>
                                        </xsl:attribute>
                                        <xsl:if test="circa">
                                            <xsl:attribute name="notBefore">
                                                <xsl:number value="number(normalizedValue)-3" format="0001"/>
                                            </xsl:attribute>
                                            <xsl:attribute name="notAfter">
                                                <xsl:number value="number(normalizedValue)+3" format="0001"/>
                                            </xsl:attribute>
                                        </xsl:if>
                                        <xsl:attribute name="standardDate">
                                            <xsl:number value="normalizedValue" format="0001"/>
                                        </xsl:attribute>
                                        <xsl:if test="active">
                                            <xsl:text>active </xsl:text>
                                        </xsl:if>
                                        <xsl:if test="circa">
                                            <xsl:text>approximately </xsl:text>
                                        </xsl:if>
                                        <xsl:value-of select="value"/>
                                    </toDate>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:for-each>

                    </dateRange>
                </existDates>
            </xsl:when>
            <xsl:when test="$dateStringAnalyzeResultsTwo/singleDate[born]">
                <xsl:for-each select="$dateStringAnalyzeResultsTwo/singleDate[born]">

                    <existDates>
                        <dateRange>
                            <fromDate localType="{$av_born}">
                                <xsl:if test="circa">
                                    <xsl:attribute name="notBefore">
                                        <xsl:number value="number(normalizedValue)-3" format="0001"/>
                                    </xsl:attribute>
                                    <xsl:attribute name="notAfter">
                                        <xsl:number value="number(normalizedValue)+3" format="0001"/>
                                    </xsl:attribute>
                                </xsl:if>
                                <xsl:attribute name="standardDate">
                                    <xsl:number value="normalizedValue" format="0001"/>
                                </xsl:attribute>
                                <xsl:if test="circa">
                                    <xsl:text>approximately </xsl:text>
                                </xsl:if>
                                <xsl:value-of select="value"/>
                            </fromDate>
                            <toDate/>
                        </dateRange>
                    </existDates>
                </xsl:for-each>
            </xsl:when>
            <xsl:when test="$dateStringAnalyzeResultsTwo/singleDate[died]">

                <xsl:for-each select="$dateStringAnalyzeResultsTwo/singleDate[died]">
                    <existDates>
                        <dateRange>
                            <fromDate/>
                            <toDate localType="{$av_died}">
                                <xsl:if test="circa">
                                    <xsl:attribute name="notBefore">
                                        <xsl:number value="number(normalizedValue)-3" format="0001"/>
                                    </xsl:attribute>
                                    <xsl:attribute name="notAfter">
                                        <xsl:number value="number(normalizedValue)+3" format="0001"/>
                                    </xsl:attribute>
                                </xsl:if>
                                <xsl:attribute name="standardDate">
                                    <xsl:number value="normalizedValue" format="0001"/>
                                </xsl:attribute>
                                <xsl:if test="circa">
                                    <xsl:text>approximately </xsl:text>
                                </xsl:if>
                                <xsl:value-of select="value"/>
                            </toDate>
                        </dateRange>
                    </existDates>
                </xsl:for-each>
            </xsl:when>
            <xsl:when test="$dateStringAnalyzeResultsTwo/singleDate[active]">

                <xsl:for-each select="$dateStringAnalyzeResultsTwo/singleDate[active]">
                    <existDates>
                        <dateRange>
                            <fromDate/>
                            <toDate localType="{$av_active}">
                                <xsl:if test="circa">
                                    <xsl:attribute name="notBefore">
                                        <xsl:number value="number(normalizedValue)-3" format="0001"/>
                                    </xsl:attribute>
                                    <xsl:attribute name="notAfter">
                                        <xsl:number value="number(normalizedValue)+3" format="0001"/>
                                    </xsl:attribute>
                                </xsl:if>
                                <xsl:attribute name="standardDate">
                                    <xsl:number value="normalizedValue" format="0001"/>
                                </xsl:attribute>
                                <xsl:if test="circa">
                                    <xsl:text>approximately </xsl:text>
                                </xsl:if>
                                <xsl:value-of select="value"/>
                            </toDate>
                        </dateRange>
                    </existDates>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message>
                    <xsl:text>date unchecked: </xsl:text>
                    <xsl:copy-of select="$dateStringAnalyzeResultsTwo"/>
                </xsl:message>
            </xsl:otherwise>
        </xsl:choose>

    </xsl:template> <!-- end existDateFromPersname -->

    <xsl:template name="createDateValueInAnalzyedDates">
        <!-- goes in for-each tokenized  -->
        <xsl:choose>
            <xsl:when test="matches(.,'^[\d]{4}\?$')">
                <circa/>
                <normalizedValue>
                    <xsl:value-of select="substring-before(.,'?')"/>
                </normalizedValue>
                <value>
                    <xsl:value-of select="."/>
                </value>
            </xsl:when>
            <xsl:when test="matches(.,'^[\d]{3}\?$')">
                <circa/>
                <normalizedValue>
                    <xsl:value-of select="substring-before(.,'?')"/>
                </normalizedValue>
                <value>
                    <xsl:value-of select="."/>
                </value>
            </xsl:when>
            <xsl:when test="matches(.,'^[\d]{4}$')">
                <normalizedValue>
                    <xsl:value-of select="."/>
                </normalizedValue>
                <value>
                    <xsl:value-of select="."/>
                </value>
            </xsl:when>
            <xsl:when test="matches(.,'^[\d]{3}$')">
                <normalizedValue>
                    <xsl:value-of select="."/>
                </normalizedValue>
                <value>
                    <xsl:value-of select="."/>
                </value>
            </xsl:when>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="tpt_bioghist" match="bioghist" mode="bh">
        <bioghist new="yes">
            <!-- <xsl:copy-of select="@*|*[not(self::bioghist)]|text()"/> -->
            <xsl:for-each select="@*|*[not(self::bioghist)]|text()">
                <xsl:choose>
                    <xsl:when test="self::text()">
                        <p>
                            <xsl:value-of select="."/>
                        </p>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:copy-of select="."/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>
        </bioghist>
        <xsl:apply-templates select="bioghist" mode="bh"/>
    </xsl:template>

    <xsl:template name="tpt_bioghist_nested" match="bioghist/bioghist" mode="bh">
        <bioghist new="yes">
            <xsl:copy-of select="@*|*[not(self::bioghist)]|text()"/>
        </bioghist>
        <xsl:apply-templates select="bioghist" mode="bh"/>
    </xsl:template>

    <xsl:template name="extract_origination">
        <xsl:param name="parent_container"/>
        <xsl:choose>
            <xsl:when test="persname | corpname | famname">
                <xsl:for-each select="(persname | corpname | famname) [matches(.,'[\p{L}]')]">
                    <entity source="origination" orig_source="{@source}" is_sameas="0">
                        <xsl:choose>
                            <xsl:when test="snac:containsFamily(.)">
                                <rawExtract>
                                    <xsl:element name="{name()}">
                                        <xsl:copy-of select="@*"/>
                                        <xsl:value-of select="normalize-space(.)"/>
                                    </xsl:element>
                                </rawExtract>
                                <xsl:choose>
                                    <xsl:when test="@normal">
                                        <normal type="attributeNormal">
                                            <famname>
                                                <xsl:copy-of select="@*"/>
                                                <xsl:value-of select="normalize-space(@normal)"/>
                                            </famname>
                                        </normal>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <normal type="provisional">
                                            <famname>
                                                <xsl:copy-of select="@*"/>
                                                <xsl:value-of select="normalize-space(.)"/>
                                            </famname>
                                        </normal>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:when>
                            <xsl:otherwise>
                                <rawExtract>
                                    <xsl:element name="{name()}">
                                        <xsl:copy-of select="@*"/>
                                        <xsl:value-of select="normalize-space(.)"/>
                                    </xsl:element>
                                </rawExtract>
                                <xsl:variable name="an">
                                    <!--
                                        See "note 1" elsewhere in this file. This adds a new
                                        <normal> with a copy of the name from rawExtract. This has
                                        led to several bugs and some confusion.
                                        
                                        This is extract_origination.
                                    -->
                                    <xsl:call-template name="tpt_attributeNormal"/>
                                </xsl:variable>
                                <xsl:copy-of select="$an"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </entity>
                </xsl:for-each>
            </xsl:when>
            <!--
                Odd looking syntax ". != ''" means "context not equal to the empty string".  
                
                May 18 2015 Add checking for <origination> which is what this xsl:otherwise was originally
                created to handle. Failure to check this results in the value of unittitle being used as a
                name (when <unittitle> does not contain a <persname> or other explicit name element).
            -->
            <xsl:when test=". != '' and $parent_container='origination'">
                <entity source="origination" is_sameas="0">
                    <rawExtract type="unknown">
                        <xsl:element name="{name()}">
                            <xsl:copy-of select="@*"/>
                            <xsl:value-of select="normalize-space(.)"/>
                        </xsl:element>
                    </rawExtract>
                    <xsl:choose>
                        <xsl:when test="contains(lower-case(.),'family')">
                            <normal type="tenuous">
                                <famname>
                                    <xsl:value-of select="normalize-space(.)"/>
                                </famname>
                            </normal>
                        </xsl:when>
                        <xsl:when test="snac:containsCorporateWord(.)">
                            <normal type="tenuous">
                                <corpname>
                                    <xsl:value-of select="normalize-space(.)"/>
                                </corpname>
                            </normal>
                        </xsl:when>
                        <xsl:when test="contains(.,',')">
                            <!--
                                This is simply a wager that personal names far outnumber
                                corporate and family names, thus ... more often right than
                                wrong. Perhaps.
                            -->
                            <normal type="tenuous">
                                <persname>
                                    <xsl:value-of select="normalize-space(.)"/>
                                </persname>
                            </normal>
                        </xsl:when>
                        <xsl:otherwise>
                            <normal type="tenuous">
                                <persname>
                                    <xsl:value-of select="normalize-space(.)"/>
                                </persname>
                            </normal>
                        </xsl:otherwise>
                    </xsl:choose>
                </entity>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message>
                    <xsl:text>Name not used: </xsl:text>
                    <xsl:value-of select="."/>
                    <xsl:text> parent container: </xsl:text>
                    <xsl:value-of select="$parent_container"/>
                </xsl:message>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template> <!-- extract_origination -->
    
    <xsl:template name="extract_controlaccess">
        <!--
            Due to processing the data before building the <entity> element, the data is in
            $temp_entity_controlaccess, and the <entity> element is somewhat below that.
        -->
        <xsl:variable name="temp_entity_controlaccess">
            <container>
                <xsl:if
                    test="contains(lower-case(@role),'correspond') or
                          contains(lower-case(@role),'crp') or
                          lower-case(@role)='corr' or
                          contains(lower-case(.),'correspond')">
                    <xsl:attribute name="correspondent">
                        <xsl:text>yes</xsl:text>
                    </xsl:attribute>
                </xsl:if>
                <xsl:choose>
                    <xsl:when test="snac:containsFamily(.)">
                        <xsl:message>
                        </xsl:message>
                        <rawExtract>
                            <xsl:element name="{name()}">
                                <xsl:copy-of select="@*"/>
                                <xsl:value-of select="normalize-space(.)"/>
                            </xsl:element>
                        </rawExtract>
                        <xsl:choose>
                            <xsl:when test="@normal">
                                <normal type="attributeNormal">
                                    <famname>
                                        <xsl:copy-of select="@*"/>
                                        <xsl:value-of select="normalize-space(@normal)"/>
                                    </famname>
                                </normal>
                            </xsl:when>
                            <xsl:otherwise>
                                <normal type="provisional">
                                    <famname>
                                        <xsl:copy-of select="@*"/>
                                        <xsl:value-of select="normalize-space(.)"/>
                                    </famname>
                                </normal>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                    <xsl:otherwise>
                        <!-- 
                             Create <persname> attributes @surname and @firstname that we can use to
                             compare to the name from <origination>.  This isn't full on name parsing,
                             so it won't be perfect. The @firstname is only the first "word" of the
                             forename.
                        -->
                        <xsl:variable name="special_controlaccess_normal">
                            <xsl:element name="{name()}">
                                <xsl:copy-of select="@*"/>
                                <!--
                                    If you change this you probably also need to change variable nice_name below.
                                    (What is supposed to be at line 1314? Nothing interesting
                                    there now.)
                                    
                                    Build the name that we want. We will have to clean up extraneous dots (periods) and parenthesis.
                                    
                                    Mackay, Alexander Murdoch, 1849-1890 Mechanical engineer, missionary
                                    Stokes,  Leonard Aloysius Scott . ( 1858-1925 )  architect
                                    
                                    Has both 'dates' and 'y' (other records have a date in 'y')
                                    /data/source/findingAids/ahub/gulsc/1071_2002.xml
                                    
                                    <persname source="gb-0247" normal="marr, james, c1877-c1955"
                                    encodinganalog="jisc-hub40" authfilenumber="p0419"> <emph
                                    altrender="surname">Marr</emph> <emph
                                    altrender="forename">James</emph> <emph altrender="dates">fl
                                    1895</emph> <emph altrender="y">minister</emph> </persname>
                                    
                                    However, BNF gives us simple persname values:
                                    
                                    <persname>Kossyguine, Alexis (1904 - 1980)</persname>
                                -->
                                <xsl:variable name="nice_name">
                                    <xsl:for-each select="*|node()">
                                        <!--
                                            New: Sep 21 2014, stop removing <emph> until we find the case(s) where it was a problem. 
                                            
                                            <controlaccess id="a12">
                                            <persname rules="ncarules">
                                            <emph altrender="surname">Mackay</emph>
                                            <emph altrender="forename">Alexander Murdoch</emph>
                                            <emph altrender="dates">1849-1890</emph>
                                            <emph altrender="epithet">Mechanical engineer, missionary</emph>
                                            </persname>
                                            
                                            xlf /data/source/findingAids/ahub/birminghamspcoll/900_2002.xml
                                            less cpf_qa/ahub/birminghamspcoll/900_2002.c01.xml
                                            
                                            old: I couldn't figure out an xpath that didn't include
                                            <emph> (perhaps because it it matching node()) so just
                                            use an xsl:if to weed out the <emph> elements.
                                        -->
                                        <xsl:value-of select="."/>
                                        <xsl:value-of select="' '"/>
                                    </xsl:for-each>
                                    
                                    <!-- there are cases of multiple surname values "Lloyd" and "George", separate with a space -->
                                    <xsl:value-of select="emph[@altrender='surname' or @altrender='a' ]" separator=" "/>
                                    
                                    <!-- Comma after surname(s). Extra comma removed by a later cleaning step. -->
                                    <xsl:value-of select="', '"/>

                                    <!-- there are cases of multiple forenames, so separate with space -->
                                    <xsl:value-of select="emph[@altrender='forename']" separator=" "/>
                                    <!-- 
                                         Does an xpath with contraints connected with 'or' return
                                         the elements in order?  This is a big pita because many
                                         of these ostensibly single elements occur multiple
                                         times. Like multiple forenames. y and epithet often occur
                                         as multiples.
                                    -->
                                    <xsl:for-each select="emph[@altrender='dates' or 
                                                          @altrender='y' or
                                                          @altrender='epithet']">
                                        <xsl:value-of select="concat(', ', .)"/>
                                    </xsl:for-each>
                                </xsl:variable>
                                
                                <!--
                                    "improved" in the sense that $nice_name is just cleaned up.
                                -->
                                <xsl:variable name="improved_name">
                                    <xsl:value-of select="snac:removeLeadingComma(
                                                          snac:removeFinalComma(
                                                          snac:removeDoubleComma(
                                                          snac:fixDates($nice_name))))"/>
                                    
                                </xsl:variable>
                                <xsl:value-of select="$improved_name"/>
                            </xsl:element>
                        </xsl:variable> <!-- special_controlaccess_normal -->
                        <rawExtract>
                            <xsl:element name="{name()}">
                                <xsl:copy-of select="@*"/>
                                <xsl:value-of select="normalize-space(.)"/>
                            </xsl:element>
                            
                            <!-- Stop using $special_controlaccess_normal, and go back the the original code. -->
                            <!-- <xsl:copy-of select="$special_controlaccess_normal"/> -->
                        </rawExtract>
                        
                        <!--
                            New: Go back to calling tpt_attributeNormal.
                            
                            Note 1.
                            Calling attributeNormal creates a second <persname> or whatever outside
                            <rawExtract> but using a separate code, with the undesireable effect that
                            the two can become different (as when fixing the emph surname bug). So,
                            anthing you fix/do with names above probably also has to be fixed in
                            attributeNormal.
                            
                            May 12 2015 tpt_attributeNormal is called for all the types of EAD extractions,
                            but only in some choose/when statements, so it might not always be called,
                            depending.
                            
                            Old: In the old days we called tpt_attributNormal here, but that created
                            issues. (What issues?) The $special_controlaccess_normal is exactly
                            the same code as tpt_attributNormal runs for non-@normal names.  We
                            want $special_controlaccess_normal, and it is wrong to run anything
                            else here.
                            
                            This is extract_controlaccess.
                        -->
                        <xsl:call-template name="tpt_attributeNormal"/>
                    </xsl:otherwise>
                </xsl:choose>
            </container>
        </xsl:variable> <!-- temp_entity_controlaccess -->
        
        <!--
            Test to make sure we have at least one persname|famname|corpname that isn't empty. Then at the bottom
            when doing copy-of * use an exciting xpath constraint to only copy elements that
            contain a non-empty persname|famname|corpname.
            
            <entity source="controlaccess" ftwo="Leonard Stokes"><rawExtract><persname
            rules="ncarules">Stokes, Leonard Aloysius Scott, 1858-1925,
            architect</persname></rawExtract><normal type="provisional"><persname
            rules="ncarules">Stokes, Leonard Aloysius Scott, 1858-1925,
            architect</persname></normal></entity>
        -->
        <xsl:variable name="pn_value">
            <xsl:value-of select="$temp_entity_controlaccess/container/rawExtract/(persname|famname|corpname)"/>
        </xsl:variable>
        
        <xsl:if test="string-length($pn_value)">
            <entity source="controlaccess"
                    encodinganalog="{$temp_entity_controlaccess/container/rawExtract/(persname|famname|corpname)/@encodinganalog}"
                    is_sameas="0">
                <!-- 
                     New: all names get ftwo down in variable name rawExtract_b so we don't need
                     to create a normal-for-match name here.
                     
                     As far as I know, we want everything in <container> so it is unclear why I
                     put in a string-length() test. That test makes no sense.
                     
                     Breaking this code can make bad things happen, like persname is ok, but
                     famname disappears and then we end up with too few .rxxx files.
                -->
                <xsl:copy-of select="$temp_entity_controlaccess/container/@*"/>
                <!-- <xsl:copy-of select="$temp_entity/container/*[string-length(persname) > 0]"/> -->
                <xsl:copy-of select="$temp_entity_controlaccess/container/*"/>
            </entity>
        </xsl:if>
    </xsl:template> <!-- extract_controlaccess -->

    <xsl:template name="extract_scopecontent">

        <!-- <xsl:message> -->
        <!--     <xsl:text>scocon: </xsl:text> -->
        <!--     <xsl:copy-of select="."/> -->
        <!-- </xsl:message> -->
        <entity source="scopecontent" is_sameas="0">
            <xsl:choose>
                <xsl:when test="snac:containsFamily(.)">
                    <rawExtract>
                        <xsl:element name="{name()}">
                            <xsl:copy-of select="@*"/>
                            <xsl:value-of select="normalize-space(.)"/>
                        </xsl:element>
                    </rawExtract>
                    <xsl:choose>
                        <xsl:when test="@normal">
                            <normal type="attributeNormal">
                                <famname>
                                    <xsl:copy-of select="@*"/>
                                    <xsl:value-of select="normalize-space(@normal)"/>
                                </famname>
                            </normal>
                        </xsl:when>
                        <xsl:otherwise>
                            <normal type="provisional">
                                <famname>
                                    <xsl:copy-of select="@*"/>
                                    <xsl:value-of select="normalize-space(.)"/>
                                </famname>
                            </normal>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:otherwise>
                    <rawExtract>
                        <xsl:element name="{name()}">
                            <xsl:copy-of select="@*"/>
                            <xsl:value-of select="normalize-space(.)"/>
                        </xsl:element>
                    </rawExtract>
                    <!-- see "note 1" elsewhere in this file -->
                    <xsl:call-template name="tpt_attributeNormal"/>
                </xsl:otherwise>
            </xsl:choose>
        </entity>
    </xsl:template> <!-- extract_scopecontent -->

    <xsl:template name="extract_other">
        <!--
            two variables: both preprocess using new routines,
            but groups into Correspondence and not; for former, 
            process the group to add Correspondence to the end.
        -->
        <entity source="dsc" is_sameas="0">
            <xsl:if
                test="(ancestor::*[ancestor::dsc]/did[contains(lower-case(unittitle[1]),'correspond')] and .[parent::unittitle])
                      or
                      (ancestor::*[ancestor::dsc]/did[contains(lower-case(unittitle[1]),'letter')] and .[parent::unittitle]) or
                      contains(lower-case(@role),'correspond')                      or 
                      contains(lower-case(@role),'crp') or 
                      contains(lower-case(.),'correspond') or
                      lower-case(@role)='corr'
                      ">
                <xsl:attribute name="correspondent">
                    <xsl:text>yes</xsl:text>
                </xsl:attribute>
            </xsl:if>
            <xsl:choose>
                <xsl:when test="snac:containsFamily(.)">
                    <rawExtract>
                        <xsl:element name="{name()}">
                            <xsl:copy-of select="@*"/>
                            <xsl:value-of select="normalize-space(.)"/>
                        </xsl:element>
                    </rawExtract>
                    <xsl:choose>
                        <xsl:when test="@normal">
                            <normal type="attributeNormal">
                                <famname>
                                    <xsl:copy-of select="@*"/>
                                    <xsl:value-of select="normalize-space(@normal)"/>
                                </famname>
                            </normal>
                        </xsl:when>
                        <xsl:otherwise>
                            <normal type="provisional">
                                <famname>
                                    <xsl:copy-of select="@*"/>
                                    <xsl:value-of select="normalize-space(.)"/>
                                </famname>
                            </normal>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:otherwise>
                    <rawExtract>
                        <xsl:element name="{name()}">
                            <xsl:copy-of select="@*"/>
                            <!-- <xsl:attribute name="debug" select="'three'"/> -->
                            <xsl:value-of select="normalize-space(.)"/>
                        </xsl:element>
                    </rawExtract>
                    <!-- 
                         see "note 1" elsewhere in this file
                         This is extract_other.
                    -->
                    <xsl:call-template name="tpt_attributeNormal"/>
                </xsl:otherwise>
            </xsl:choose>

            <xsl:if test="parent::*/parent::did/unittitle/unitdate">
                <xsl:for-each select="parent::*/parent::did/unittitle/unitdate">
                    <xsl:for-each select="tokenize(snac:getDateFromUnitdate(.),'\s')">
                        <!-- looks only for tokens in the date that are NNNN, and thus ignores months and days entered as nunmbers -->
                        <xsl:if test="matches(.,'^[\d]{3,4}$')">
                            <activeDate>
                                <xsl:number value="." format="0001"/>
                            </activeDate>
                        </xsl:if>
                    </xsl:for-each>
                </xsl:for-each>
            </xsl:if>

            <xsl:if test="parent::origination/parent::did/following-sibling::controlaccess/(occupation | function)"/>
            <!--
                This will be rare, I surmise. If it occurs with any frequency, then we can grab
                them and associate with the specific entity.
            -->
            <xsl:if test="parent::origination/parent::did/following-sibling::controlaccess/(occupation | function)">
                <xsl:message>
                    <xsl:text>has sibling occ/func: </xsl:text>
                    <xsl:copy-of
                        select="parent::origination/parent::did/following-sibling::controlaccess/(occupation | function)"/>
                </xsl:message>
            </xsl:if>
        </entity>
    </xsl:template> <!-- extract_other -->

    <!--
        See note afn above.
    -->
    <xsl:function name="snac:auth_href">
        <xsl:param name="authnum" as="xs:string"/>
        <xsl:variable name="return_value">
            <xsl:choose>
                <xsl:when test="matches($authnum, '^http')">
                    <xsl:value-of select="$authnum"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat($cpfr_href,$authnum, $cpfr_href_suffix)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:message>
            <!-- log the authfilenumber hrefs for later QA and reporting -->
            <xsl:value-of select="concat('from auth href: ', $return_value)"/>
        </xsl:message>
        <xsl:value-of select="$return_value"/>
    </xsl:function>

    <!-- 
         May 11 2015 This renames certain original attributes, especially @source. This may not have been necessary since
         it is confusing if @source is in <entity> or (and/or> the children of <entity> such as <normal> and
         <normalFinal>. We need to carry @source all the way to the final template stage where is it used in
         templates relationsOrigination. We can't have our @source being overwritten by the original EAD's
         @source (apparently it was being overwritten).
    -->
    <xsl:template name="tpt_rename_source" match="*" mode="rename_source">
        <xsl:copy>
            <xsl:for-each select="@*">
                <xsl:choose>
                    <xsl:when test="name() = 'source'">
                        <xsl:attribute name="{concat('orig_', name())}" select="."/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:attribute name="{name()}" select="."/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>
            <xsl:apply-templates mode="rename_source"/>
        </xsl:copy>
    </xsl:template>

    <!--
        May 20 2015 Fix @authfilenumber in <entity>. @authfilenumber usually occurs in <persname> but there
        are several <persname> elements in various sub-trees, so we need to use the XSLT identity transform
        idiom.
        
        Working example of identity transform with changing an attribute.
    -->
    <xsl:template match="node()|@*" mode="mode_authfilenumber">
        <xsl:copy>
            <xsl:apply-templates mode="mode_authfilenumber" select="node()|@*"/>
        </xsl:copy>
    </xsl:template>

    <!--
        jun 12 2015 was "persname/@authfilenumber" which excluded corpname.
    -->
    <xsl:template match="*/@authfilenumber" mode="mode_authfilenumber">
        <xsl:attribute name="authfilenumber">
            <xsl:value-of select="snac:auth_href(.)"/>
        </xsl:attribute>
    </xsl:template>

</xsl:stylesheet>
