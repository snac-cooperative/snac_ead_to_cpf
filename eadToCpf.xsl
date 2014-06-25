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

    -->


    <xsl:import href="av.xsl"/>
    <xsl:import href="functions.xsl"/>
    <xsl:import href="variables.xsl"/>
    <xsl:import href="templates.xsl"/>

    <xsl:strip-space elements="*"/>
    <xsl:output indent="yes" method="xml"/>
    <xsl:key name="sourceCodeName" match="source" use="sourceCode"/>

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

    <xsl:variable name="processingType">
        <xsl:text>CPFOut</xsl:text>
        <!-- rawExtract stepOne stepTwo stepThree stepFour stepFive testCPFOut CPFOut-->
    </xsl:variable>

    <!--
        The expected, normal xml input file is something like: createFileLists/nmaia_list.xml which to base-uri() is:
        file:/lv1/home/twl8n/ead2cpf_pack/createFileLists/nmaia_list.xml
    -->
    <xsl:variable name="file2url" select="document(concat('url_xml/', replace(base-uri(), '.*/(.*?)_.*', '$1'), '_url.xml'))"/>

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
            <xsl:variable name="original_ead" select="."/>
            <!--
                Raw extraction extracts all tagged names and origination, tagged or not. For the
                latter it attemts to determine type, and if unable to do so, defaults to persname. It
                also selects out, carefully, family names that have been mistagged as persname or
                corpname. (Except for names found in controlaccess, unless that bug has been fixed.)
            -->
            <xsl:variable name="rawExtract_a">
                <!--
                    Extraction origination which is creator of the collection, or author of the materials in
                    the collection.
                -->
                <xsl:for-each select="ead/archdesc/did/origination">
                    <!-- <xsl:message> -->
                    <!--     <xsl:text>orig: </xsl:text> -->
                    <!--     <xsl:copy-of select="."/> -->
                    <!-- </xsl:message> -->

                    <xsl:choose>
                        <xsl:when test="persname | corpname | famname">
                            <xsl:for-each select="(persname | corpname | famname) [matches(.,'[\p{L}]')]">
                                <entity source="origination">
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
                                                <!-- see "note 1" elsewhere in this file -->
                                                <xsl:call-template name="attributeNormal"/>
                                            </xsl:variable>
                                            <xsl:copy-of select="$an"/>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                </entity>
                            </xsl:for-each>
                        </xsl:when>
                        <xsl:otherwise>
                            <!-- Odd looking syntax means "context not equal to the empty string". -->
                            <xsl:if test=". != ''">
                                <entity source="origination">
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
                            </xsl:if>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:for-each>

                <!--
                    extract control access aka controlaccess (this really is it, apparent cut/paste error gave
                    other entity elements have source = "controlaccess"
                    
                    Note: controlaccess may be nested in controlaccess, thus the //controlaccess is necessary.
                    
                    Due to processing the data before building the <entity> element, the data is in
                    $temp_entity_controlaccess, and the <entity> element is below.
                -->
                <xsl:for-each select="ead/archdesc//controlaccess/(persname | corpname | famname)[matches(.,'[\p{L}]')]">
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
                                    <rawExtract>
                                        <xsl:element name="{name()}">
                                            <xsl:copy-of select="@*"/>
                                            <!--
                                                If you change this you probably also need to change line 1314.
                                                
                                                Build the name that we want. We will have to clean up extraneous dots (periods) and parenthesis.
                                                
                                                Mackay, Alexander Murdoch, 1849-1890 Mechanical engineer, missionary
                                                Stokes,  Leonard Aloysius Scott . ( 1858-1925 )  architect
                                                
                                                Has both 'dates' and 'y' (other records have a date in 'y')
                                                /data/source/findingAids/ahub/gulsc/1071_2002.xml
                                            -->
                                            <xsl:variable name="nice_name">
                                                <!-- there are cases of multiple surname values "Lloyd" and "George", separate with a space -->
                                                <xsl:value-of select="emph[@altrender='surname' or @altrender='a' ]" separator=" "/>

                                                <!-- comma after surname(s) -->
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
                                            
                                            <xsl:variable name="improved_name">
                                                <xsl:value-of select="snac:removeLeadingComma(
                                                                      snac:removeFinalComma(
                                                                      snac:removeDoubleComma(
                                                                      snac:fixDates($nice_name))))"/>

                                            </xsl:variable>
                                            <xsl:value-of select="$improved_name"/>
                                            <!-- <xsl:message> -->
                                            <!--     <xsl:text>pri: </xsl:text> -->
                                            <!--     <xsl:value-of select="normalize-space($improved_name)"/> -->
                                            <!--     <xsl:value-of select="$cr"/> -->
                                            <!--     <xsl:copy-of select="."/> -->
                                            <!--     <xsl:value-of select="$cr"/> -->
                                            <!-- </xsl:message> -->
                                        </xsl:element>
                                    </rawExtract>
                                    <!--
                                        Note 1.
                                        Calling attributeNormal creates a second <persname> or whatever outside
                                        <rawExtract> but using a separate code, with the undesireable effect that
                                        the two can become different (as when fixing the emph surname bug). So,
                                        anthing you fix/do with names above probably also has to be fixed in
                                        attributeNormal.
                                    -->
                                    <xsl:call-template name="attributeNormal"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </container>
                    </xsl:variable>

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
                        <entity source="controlaccess" encodinganalog="{$temp_entity_controlaccess/container/rawExtract/(persname|famname|corpname)/@encodinganalog}">
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
                </xsl:for-each>

                <!-- extract scope and content -->

                <xsl:for-each select="ead/archdesc//scopecontent/(persname | corpname | famname)[matches(.,'[\p{L}]')]">
                    <!-- <xsl:message> -->
                    <!--     <xsl:text>scocon: </xsl:text> -->
                    <!--     <xsl:copy-of select="."/> -->
                    <!-- </xsl:message> -->
                    <entity source="scopecontent">
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
                                        <!-- <xsl:attribute name="debug" select="'two'"/> -->
                                        <xsl:copy-of select="@*"/>
                                        <xsl:value-of select="normalize-space(.)"/>
                                    </xsl:element>
                                </rawExtract>
                                <!-- see "note 1" elsewhere in this file -->
                                <xsl:call-template name="attributeNormal"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </entity>
                </xsl:for-each>

                <!-- extract dsc -->

                <xsl:for-each
                    select="ead/archdesc//dsc//(persname | corpname | famname) [matches(.,'[\p{L}]')] [not(parent::controlaccess)][not(parent::scopecontent)] ">
                    <!-- <xsl:message> -->
                    <!--     <xsl:text>nocon: </xsl:text> -->
                    <!--     <xsl:copy-of select="."/> -->
                    <!-- </xsl:message> -->
                    <!--
                        two variables: both preprocess using new routines,
                        but groups into Correspondence and not; for former, 
                        process the group to add Correspondence to the end.
                    -->
                    <entity source="dsc">
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
                                <!-- see "note 1" elsewhere in this file -->
                                <xsl:call-template name="attributeNormal"/>
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
                </xsl:for-each>
            </xsl:variable> <!-- rawExtract_a end -->

            <!--
                Check for 3 types of direct name, and convert to indirect.

                John Smith
                J Smith
                JT Smith or J T Smith
                
                Note 2: While we are looping over the data, add @ftwo to every name (normal first and last direct order name for matching).
                
                Multiple names in this field have interesting consequences since the name is parsed, and then the first and last words are pulled out.
                
                "Teddy Wedlock, Dora Wedlock, Helen M. Heynes" becomes direct order name "Dora Wedlock Teddy Wedlock" which becomes @ftwo "dora wedlock". 
            -->
            <xsl:variable name="rawExtract_b">
                <xsl:for-each select="$rawExtract_a/entity">
                    <xsl:variable name="norm_for_match">
                        <xsl:choose>
                            <xsl:when test="@ftwo">
                                <xsl:value-of select="@ftwo"/>
                            </xsl:when>
                            <xsl:when test="normal/persname">
                                <xsl:value-of
                                    select="replace(lower-case(snac:directPersnameTwo(./normal/persname)), '^(\w+).*?(\w+)(\d+|$)', '$1 $2')"/>
                                <!--
                                    See Note 2 above. Multiple names in persname are exciting.
                                -->
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
                                        <xsl:value-of select="replace(./normal/persname, '^(\w+)\s+(\w+)$|^([A-Z]+)\s+(\w+)$|^([A-Z]+\s*[A-Z]+)\s+(\w+)$', '$2, $1')"/>
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
                Another intermediate step that tries to match origination and controlaccess names.
            -->
            <xsl:variable name="rawExtract">
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
                            <entity source="origination" ftwo="{@ftwo}">
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
                <!-- <xsl:copy-of select="$rawExtract_b"/> -->
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
                                            <!-- This on normalizes those that do not have a @normal in rawExtract -->
                                            <normal type="regExed">
                                                <persname>
                                                    <xsl:value-of
                                                        select="
                                                                snac:stripStringAfterDateInPersname(
                                                                snac:removeApostropheLowercaseSSpace(
                                                                snac:removeBeforeHyphen2(
                                                                snac:fixSpacing(
                                                                snac:fixDatesReplaceActiveWithFl(
                                                                snac:fixDatesRemoveParens(
                                                                snac:fixCommaHyphen2(
                                                                snac:fixHypen2Paren(
                                                                snac:removeTrailingInappropriatePunctuation(
                                                                snac:removeInitialNonWord(
                                                                snac:removeInitialTrailingParen(
                                                                snac:removeBrackets(                            
                                                                snac:removeInitialHypen(
                                                                snac:removeQuotes(
                                                                snac:fixSpaceComma(normal/persname)))))))))))))))"
                                                        />
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

                                <xsl:when test="normal/corpname">
                                    <entity>
                                        <xsl:copy-of select="* | @*"/>
                                        <xsl:if test="normal[not(@type='attributeNormal')]/corpname">
                                            <normal type="regExed">
                                                <corpname>
                                                    <xsl:value-of
                                                        select="normalize-space(
                                                                snac:removeBeforeHyphen2(               
                                                                snac:fixDatesRemoveParens(
                                                                snac:fixCommaHyphen2(
                                                                snac:fixHypen2Paren(
                                                                snac:removeTrailingInappropriatePunctuation(
                                                                snac:removeInitialTrailingParen(
                                                                snac:removeBrackets(                                            
                                                                snac:removeInitialHypen(
                                                                snac:removeQuotes(normal/corpname))))))))))"
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

                            </xsl:choose>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:for-each>
            </xsl:variable> <!-- normalizeStepOne end -->

            <!-- NORMALIZE STEP TWO: Adds <normalForMatch> to <entity> -->

            <xsl:variable name="normalizeStepTwo">
                <xsl:for-each select="$normalizeStepOne/entity">
                    <entity>
                        <xsl:copy-of select="@* | *"/>
                        <normalForMatch>
                            <xsl:choose>
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

                        <xsl:variable name="correspondent">
                            <xsl:if test="entity/@correspondent='yes'">
                                <xsl:text>yes</xsl:text>
                            </xsl:if>
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
                                <error>Something went wrong in selecting the entity!</error>
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

                    <!-- check for each enitity/normalized for match  -->
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
            -->

            <xsl:variable name="normalizeStepFive">
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
                            <normalFinal>
                                <!--
                                    attributeNormal was lacking the /* which caused an empty entityType. Fixed
                                    and and nothing else seemed to break. jan 31 2013
                                -->
                                <xsl:choose>
                                    <xsl:when test="normal[@type='attributeNormal']">
                                        <xsl:copy-of select="normal[@type='attributeNormal']/*"/>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:copy-of select="normal[@type='regExed']/*"/>
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

            <!-- ****************************************************************** -->
            <!-- ****************************************************************** -->
            <!-- ****************************************************************** -->
            
            <!-- 
                 oneFindingAid appears never to be used. What was it supposed to do?
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
                        Limit to those with bioghist and $normalizeStepFive/otherData/bioghist
                    -->
                    <oneFindingAid source="{$eadPath}">
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
                                </xsl:variable>
                                <xsl:variable name="entitiesForCPFRelations">
                                    <!-- This entity is to collect just the information needed to create cpfRelations -->
                                    <xsl:for-each select="entity">
                                        <entity>
                                            <!-- @source = origination | controlaccess | dsc -->
                                            <xsl:copy-of select="@*"/>
                                            <xsl:copy-of select="normalFinal"/>
                                        </entity>
                                    </xsl:for-each>
                                </xsl:variable>
                                <xsl:for-each select="entity">
                                    <xsl:call-template name="CpfRoot">
                                        <xsl:with-param name="counts" tunnel="yes" select="$counts"/>
                                        <xsl:with-param name="otherData" tunnel="yes" select="$otherData"/>
                                        <xsl:with-param name="entitiesForCPFRelations" tunnel="yes" select="$entitiesForCPFRelations"/>
                                        <xsl:with-param name="debug" select="$normalizeStepFive"/>
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
                    </oneFindingAid>
                </xsl:when> <!-- $processingType='testCPFOut' -->
            </xsl:choose>

            <xsl:if test="$processingType='CPFOut'">    
                
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
                                <xsl:message>
                                    <xsl:text>multi unittitle </xsl:text>
                                    <xsl:value-of select="concat('count: ', count(otherData/did/unittitle))"/>
                                    <xsl:for-each select="otherData/did/unittitle">
                                        <xsl:value-of select="concat(' ', position(), ': ', normalize-space())"/>
                                    </xsl:for-each>
                                </xsl:message>
                            </xsl:if>
                        </xsl:variable>

                        <xsl:variable name="entitiesForCPFRelations">
                            <!-- This entity is to collect just the information needed to create cpfRelations -->
                            <xsl:for-each select="entity">
                                
                                <!-- <xsl:message> -->
                                <!--     <xsl:text>ca: </xsl:text> -->
                                <!--     <xsl:copy-of select="."/> -->
                                <!-- </xsl:message> -->

                                <entity>
                                    <!-- @source = origination | controlaccess | dsc -->
                                    <xsl:copy-of select="@*"/>
                                    <xsl:copy-of select="normalFinal"/>
                                </entity>
                            </xsl:for-each>
                        </xsl:variable>


                        <xsl:for-each select="entity">
                            <!--
                                Template CpfRoot calls all the parts of the CPF place holder XML code that
                                finally makes the output CPF XML. See templates.xsl.
                            -->
                            <xsl:call-template name="CpfRoot">
                                <xsl:with-param name="counts" tunnel="yes" select="$counts"/>
                                <xsl:with-param name="otherData" tunnel="yes" select="$otherData"/>
                                <xsl:with-param name="entitiesForCPFRelations" tunnel="yes" select="$entitiesForCPFRelations"/>
                                <xsl:with-param name="debug" select="$normalizeStepFive"/>
                                <xsl:with-param name="original_ead" select="$original_ead" tunnel="yes"/>
                            </xsl:call-template>
                        </xsl:for-each>
                    </xsl:if>
                </xsl:for-each>
            </xsl:if> <!-- $processingType='CPFOut' -->
            <!-- end of for each document(.) -->
        </xsl:for-each>
    </xsl:template> <!-- tpt_process -->

    <xsl:template name="tpt_main" match="/">
        <xsl:message>
            <xsl:value-of select="concat('cpfOutLocation: ', $cpfOutLocation, $cr)"/>
            <xsl:value-of select="concat('      base-uri: ', base-uri(), $cr)"/>
            <!-- trick XSLT into evaluating $file2url now, so we get any potential warning at the beginning -->
            <xsl:value-of select="concat('      file2url: ', string-length($file2url), $cr)"/>
            <xsl:value-of select="concat('      inc_orig: ', $inc_orig, $cr)"/>
        </xsl:message>

        <xsl:if test="matches(base-uri(), 'ahub_list.xml')">
            <xsl:message terminate="yes">
                <xsl:value-of select="'Skipping this file. See eadToCpf.xsl, line 1414'"/>
            </xsl:message>
        </xsl:if>

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
                <!-- <xsl:message> -->
                <!--     <xsl:value-of select="concat('snac:i: ', ., ' n: ', @n, ' slp: ', string-length($process), ' nprocs: ' , count($process/*))"/> -->
                <!-- </xsl:message> -->
                <xsl:choose>
                    <xsl:when test="$processingType='CPFOut'">
                        <xsl:for-each select="$process/*">
                            <xsl:variable name="recordId" select="./control/recordId" xpath-default-namespace="urn:isbn:1-931666-33-4"/>
                            <!-- <xsl:message> -->
                            <!--     <xsl:value-of select="concat('col: ', $cpfOutLocation, ' si: ', $sourceID,'/', ' rid: ', $recordId, '.xml')"/> -->
                            <!-- </xsl:message> -->
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
    </xsl:template> <!-- tpt_main match="/" -->

    <xsl:template name="attributeNormal">
        <xsl:choose>
            <xsl:when test="@normal">
                <normal type="attributeNormal">
                    <xsl:element name="{name()}">
                        <xsl:copy-of select="@*"/>
                        <xsl:value-of select="normalize-space(@normal)"/>
                    </xsl:element>
                </normal>
            </xsl:when>
            <xsl:otherwise>
                <normal type="provisional">
                    <xsl:element name="{name()}">
                        <xsl:copy-of select="@*"/>
                        <!--
                            If you change this you probably also need to change line 309.
                            
                            Build the name that we want. We will have to clean up extraneous dots (periods) and parenthesis.
                            
                            Mackay, Alexander Murdoch, 1849-1890 Mechanical engineer, missionary
                            Stokes,  Leonard Aloysius Scott . ( 1858-1925 )  architect
                        -->
                        <xsl:variable name="nice_name">
                            <xsl:choose>
                                <xsl:when test="emph">
                                    <!-- there are cases of multiple surname values "Lloyd" and "George", separate with a space -->
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
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="."/>
                                </xsl:otherwise>
                            </xsl:choose>
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

        <!-- <xsl:message> -->
        <!--     <xsl:text>gnset: </xsl:text> -->
        <!--     <xsl:copy-of select="$geognameSets"/> -->
        <!-- </xsl:message> -->


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
            <countryCode>
                <xsl:choose>
                    <xsl:when test="$sourceID='bnf' or $sourceID='anfra'">
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
            <languageOfDescription>
                <xsl:choose>
                    <xsl:when test="$sourceID='bnf' or $sourceID='anfra'">
                        <xsl:text>fre</xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text>eng</xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
            </languageOfDescription>
            <xsl:copy-of select="ead/eadheader/eadid"/>
            <xsl:copy-of select="ead/archdesc/did"/>

            <!-- Either this is wrong, or the other call to selectBioghist is wrong.  template name="aboutOriginationEntity" -->
            <!-- Calling selectBioghist here causes the entire biogHist to duplicate in this entity record. -->
            <!-- <xsl:call-template name="selectBioghist"/> -->

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
        -->

        <xsl:variable name="serial_bh">
            <xsl:apply-templates select="ead/archdesc/bioghist" mode="bh"/>
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

        <xsl:variable name="dateStringAnalyzeResultsTwo">
            <xsl:choose>
                <xsl:when test="$dateStringAnalyzeResultsOne/empty">
                    <empty/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:for-each select="$dateStringAnalyzeResultsOne/fromString">
                        <fromDate>
                            <xsl:for-each select="tokenize(.,'\s')">
                                <xsl:if test="matches(.,'fl\.?')">
                                    <active/>
                                </xsl:if>
                                <xsl:if test="matches(.,'active')">
                                    <active/>
                                </xsl:if>
                                <xsl:if test="matches(.,'ca\.?')">
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
                                <xsl:if test="matches(.,'fl\.?')">
                                    <active/>
                                </xsl:if>
                                <xsl:if test="matches(.,'active')">
                                    <active/>
                                </xsl:if>
                                <xsl:if test="matches(.,'ca\.?')">
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
                                <xsl:if test="matches(.,'fl\.?')">
                                    <active/>
                                </xsl:if>
                                <xsl:if test="matches(.,'active')">
                                    <active/>
                                </xsl:if>
                                <xsl:if test="matches(.,'ca\.?')">
                                    <circa/>
                                </xsl:if>
                                <xsl:if test="matches(.,'b\.?')">
                                    <born/>
                                </xsl:if>
                                <xsl:if test="matches(.,'d\.?')">
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

        <!-- <xsl:for-each select="$dateStringAnalyzeResultsTwo"> -->
        <!--     <xsl:message> -->
        <!--         <xsl:text>art: </xsl:text> -->
        <!--         <xsl:copy-of select="."></xsl:copy-of> -->
        <!--     </xsl:message> -->
        <!-- </xsl:for-each> -->

        <!-- Now create the existDates -->

        <xsl:choose>
            <xsl:when test="not($dateStringAnalyzeResultsTwo/normalizedValue)">
                <!-- Do nothing -->
            </xsl:when>
            <xsl:when test="$dateStringAnalyzeResultsTwo/empty">
                <!-- Do nothing -->
            </xsl:when>
            <xsl:when test="$dateStringAnalyzeResultsTwo/fromDate or $dateStringAnalyzeResultsTwo/toDate">
                <xsl:variable name="suspicousDateRange">
                    <xsl:choose>
                        <xsl:when test="$dateStringAnalyzeResultsTwo/fromDate/active or
                                        $dateStringAnalyzeResultsTwo/toDate/active">
                            <xsl:choose>
                                <xsl:when test="$dateStringAnalyzeResultsTwo/toDate != ''">
                                    <xsl:choose>
                                        <xsl:when
                                            test="$dateStringAnalyzeResultsTwo/fromDate/normalizedValue &lt;
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
                            <xsl:text>http://socialarchive.iath.virginia.edu/control/term#SuspiciousDate</xsl:text>
                        </xsl:attribute>
                    </xsl:if>
                    <dateRange>
                        <xsl:for-each select="$dateStringAnalyzeResultsTwo/fromDate">
                            <fromDate>
                                <xsl:attribute name="localType">
                                    <xsl:choose>
                                        <xsl:when test="active">
                                            <xsl:text>http://socialarchive.iath.virginia.edu/control/term#Active</xsl:text>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:text>http://socialarchive.iath.virginia.edu/control/term#Birth</xsl:text>
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
                        </xsl:for-each>

                        <xsl:for-each select="$dateStringAnalyzeResultsTwo/toDate">
                            <xsl:choose>
                                <xsl:when test=".=''">
                                    <toDate/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <toDate>
                                        <xsl:attribute name="localType">
                                            <xsl:choose>
                                                <xsl:when test="active">
                                                    <xsl:text>http://socialarchive.iath.virginia.edu/control/term#Active</xsl:text>
                                                </xsl:when>
                                                <xsl:otherwise>
                                                    <xsl:text>http://socialarchive.iath.virginia.edu/control/term#Death</xsl:text>
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
                            <fromDate localType="http://socialarchive.iath.virginia.edu/control/term#Birth">
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
                            <toDate localType="http://socialarchive.iath.virginia.edu/control/term#Death">
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
                            <toDate localType="http://socialarchive.iath.virginia.edu/control/term#Active">
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

</xsl:stylesheet>
