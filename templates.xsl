<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
    xmlns:ead="urn:isbn:1-931666-22-9"
    xmlns:eac="urn:isbn:1-931666-33-4"
    xmlns:functx="http://www.functx.com"
    xmlns:snac="http://socialarchive.iath.virginia.edu/"
    xmlns:xlink="http://www.w3.org/1999/xlink"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
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

        This module contains the templates used in creating the eac-cpf instances. See eadToCpf.xsl.
        
        This template called for each entity from the end of tpt_process (and a few other places).
        
        > ln -s /lv3/data/snac_saxon/SNAC-Saxon-Extensions/xslt/lib
        > ls -ld lib
        lrwxrwxrwx 1 twl8n snac 51 May 23 12:03 lib -> /lv3/data/snac_saxon/SNAC-Saxon-Extensions/xslt/lib
    -->
    <xsl:include href="lib/java-geo-lib.xsl"/>
    
    <xsl:template name="CpfRoot">
        <xsl:param name="counts" tunnel="yes"/>
        <xsl:param name="otherData" tunnel="yes"/>
        <xsl:param name="entitiesForCPFRelations" tunnel="yes"/>
        <xsl:param name="debug" tunnel="yes"/>
        
        <!--
            Adding xmlns:snac="http://socialarchive.iath.virginia.edu/" didn't cause it to stay only in the
            <eac-cpf> element, but Saxon puts the namespace alias into each snac: element. Apparently global
            namespace aliases are moved around by Saxon. The effect is the same, but the alias declarations
            are repeated.
        -->
        <eac-cpf xmlns="urn:isbn:1-931666-33-4" xmlns:xlink="http://www.w3.org/1999/xlink">
            <xsl:call-template name="CpfControl">
                <!--
                    All params are tunneled, so no need to list them here. Params used are: otherData, debug.
                -->
            </xsl:call-template>
        <!--
            Anything we output here will be in the CPF output.
            
            The root of the context . is <entity> but we can't select the root by name, and we don't need to
            select the root node by name. So ./@recordId is entity/@recordId.
            
            Entity values come from the context . which was <entity> way back in $normalizeStepFive.
            
            $counts/originationCount is only enties with source="origination" (not surprisingly).
            
            Disable with "false() and"
        -->
        <xsl:if test="false() and
                      matches(./@recordId, 'c01') and
                      $counts/originationCount > 1 and
                      $counts/biogHistCount > 1 and
                      $debug/entity[@source='origination']/normalFinal/persname"> 
            <xsl:message>
                <xsl:text>odph (persname only): </xsl:text>
                <xsl:value-of select="concat(' pnc: ', $counts/originationCount)"/>
                <xsl:value-of select="concat(' bhc: ', $counts/biogHistCount)"/>
                <xsl:text> name:</xsl:text>
                <xsl:value-of select="$debug/entity[@source='origination']/normalFinal/*" separator=" name: "/>
                <xsl:text> head:</xsl:text>
                <xsl:value-of select="$otherData/bioghist/head" separator=" head: "/>
            </xsl:message>
        </xsl:if>
        <xsl:call-template name="CpfDescription">
            <!-- Tunnelled params don't need to be listed. -->
            <!-- <xsl:with-param name="counts" tunnel="yes" select="$counts"/> -->
            <!-- <xsl:with-param name="otherData" tunnel="yes" select="$otherData"/> -->
            <!-- <xsl:with-param name="entitiesForCPFRelations" tunnel="yes" select="$entitiesForCPFRelations"/> -->
        </xsl:call-template>
        </eac-cpf>
    </xsl:template> <!-- CpfRoot -->

    <xsl:template name="CpfControl">
        <xsl:param name="otherData" tunnel="yes"/>
        <xsl:param name="debug" tunnel="yes"/>
        
        <control xmlns="urn:isbn:1-931666-33-4">
            <recordId>
                <xsl:value-of select="@recordId"/>
            </recordId>
            <maintenanceStatus>new</maintenanceStatus>
            <maintenanceAgency>
                <agencyName>
                    <xsl:text>SNAC: Social Networks and Archival Context Project</xsl:text>
                </agencyName>
            </maintenanceAgency>
            <languageDeclaration>
                <language languageCode="{$otherData/languageOfDescription}">
                    <xsl:value-of select="$otherData/languageOfDescription"/>
                </language>
                <script scriptCode="Latn">Latin Alphabet</script>
            </languageDeclaration>
            <maintenanceHistory>
                <maintenanceEvent>
                    <eventType>created</eventType>
                    <eventDateTime standardDateTime="{current-dateTime()}">
                        <xsl:value-of select="current-dateTime()"/>
                    </eventDateTime>
                    <agentType>machine</agentType>
                    <agent>XSLT eadToCpf.xml running under /Saxon HE 9</agent>
                    <eventDescription>Derived from EAD instance.</eventDescription>
                </maintenanceEvent>
            </maintenanceHistory>
            <sources>
                <source xlink:type="simple">
                    <xsl:call-template name="hrefToEADInstance">
                        <xsl:with-param name="otherData" tunnel="yes" select="$otherData"/>
                    </xsl:call-template>
                    <objectXMLWrap>
                        <xsl:variable name="ns" select="namespace-uri()"/>
                        <container xmlns="">
                            <filename>
                                <xsl:value-of select="@fn"/>
                            </filename>
                            <!-- 
                                 The original EAD source is part of a debug variable $normalizeStepFive. This
                                 variable is the last big variable in the main processing loop that still has
                                 the context when the context is the original data. Trying to output all of
                                 the original data when the original data is large (many Mbytes) causes a Java
                                 string array length exception java.lang.ArrayIndexOutOfBoundsException:
                                 -32768 which I take to mean there is an array somewhere with an 8 bit index
                                 limitation.
                                 
                                 The workaround is to only output what we hope are relevant parts of the
                                 original data when the original data is large.
                                 
                                 See the beginning of xsl:variable name="normalizeStepFive" in eadToCpf.xsl.
                            -->
                            <xsl:if test="$inc_orig = true()">
                                <xsl:choose>
                                   <xsl:when test="string-length($debug/ead_source) > 64000">
                                       <abbreviated_original>
                                           <xsl:copy-of select="$debug/ead_source/ead/eadheader"/>
                                           <xsl:copy-of select="$debug/ead_source/ead/archdesc/did"/>
                                           <xsl:copy-of select="$debug/ead_source/ead/archdesc//dsc//(persname | corpname | famname)"/>
                                       </abbreviated_original>
                                   </xsl:when>
                                   <xsl:otherwise>
                                       <xsl:copy-of select="$debug/ead_source"/>
                                   </xsl:otherwise>
                                </xsl:choose>
                            </xsl:if>
                            <xsl:for-each select="rawExtract/*">
                                <!-- Easier to have an element for all enties, and then use an attribute for the entity type. -->
                                <ead_entity en_type="{name(.)}">
                                    <xsl:copy-of select="@* | text() | *"/>
                                </ead_entity>
                            </xsl:for-each>
                            <!-- Anything here goes into the CPF output, which is nice for debugging. -->
                            <!-- <xsl:copy-of select="$otherData/did/unittitle"/> -->
                            <!-- <xsl:copy-of select="$otherData/did/unitdate"/> -->
                        </container>
                    </objectXMLWrap>
                </source>
            </sources>
        </control>
    </xsl:template><!-- CpfControl -->



    <xsl:template name="CpfDescription">
        <xsl:param name="counts" tunnel="yes"/>
        <xsl:param name="otherData" tunnel="yes"/>
        <xsl:param name="entitiesForCPFRelations" tunnel="yes"/>

        <!--
            Decide here if there will be a bioghist

            By the time we get here, bioghist is flattened and has no nesting of bioghist elements. This
            simplifies everything downstream, and makes quite a bit of code unnecessary. There are still
            elements p, list, chronlist, and so on, but no bioghist inside bioghist.
        -->

        <!-- <xsl:message> -->
        <!--     <xsl:value-of select="concat('bhc: ', $counts/biogHistCount, ' oc: ', $counts/originationCount)"/> -->
        <!-- </xsl:message> -->

        <!--
            Anything we output here will be in the CPF output.
            
            The root of the context . is <entity> but we can't select the root by name, and we don't need to
            select the root node by name. So ./@recordId is entity/@recordId.
            
            Entity values come from the context . which was <entity> way back in $normalizeStepFive.
            
            $counts/originationCount is only enties with source="origination" (not surprisingly).
        -->

        <!-- <objectXMLWrap type="otherData"> -->
        <!--     <xsl:copy-of select="$otherData"/> -->
        <!-- </objectXMLWrap> -->

        <!-- <objectXMLWrap type="context"> -->
        <!--     <xsl:copy-of select="."/> -->
        <!-- </objectXMLWrap> -->

        <!-- <objectXMLWrap type="otherData/bioghist"> -->
        <!--     <xsl:copy-of select="$otherData/bioghist"/> -->
        <!-- </objectXMLWrap> -->
        
        <xsl:variable name="relevantBioghist">
            <!--
                Use a copy-of that gets rid of the namespace. For perfectly good reasons bioghist comes into
                this template with ns eac, but all the following codes expects ns "".
                
                We also get rid of the bioghist attributes. After this we don't care about them. 
                
                Important: copying each bioghist element separately causes separate biogHist (capital H) in
                the output, and that's wrong.
            -->
            <xsl:if test="$otherData/eac:bioghist">
                <bioghist>
                    <xsl:for-each select="$otherData/eac:bioghist">
                        <xsl:copy-of select="*"/>
                    </xsl:for-each>
                </bioghist>
            </xsl:if>
        </xsl:variable>
        
        <!-- <objectXMLWrap type="relevantBioghist"> -->
        <!--     <xsl:copy-of select="$relevantBioghist"/> -->
        <!-- </objectXMLWrap> -->
        
        <xsl:message>
            <xsl:if test="normalFinal/persname and $relevantBioghist/HEAD">
                <entity type="edb:">
                    <!--c1>
                        <xsl:value-of select="$counts/originationCount"/>
                        </c1-->
                    <c2>
                        <xsl:value-of select="$counts/biogHistCount"/>
                    </c2>
                    <path>
                        <xsl:value-of select="$otherData/eadPath"/>
                    </path>
                    <name>
                        <xsl:value-of select="normalFinal/persname"/>
                    </name>
                    <xsl:copy-of select="$relevantBioghist"/>
                </entity>
            </xsl:if>
        </xsl:message>

        <cpfDescription xmlns="urn:isbn:1-931666-33-4">
            <identity>
                <entityType>
                    <xsl:choose>
                        <xsl:when test="normalFinal/persname">
                            <xsl:text>person</xsl:text>
                        </xsl:when>
                        <xsl:when test="normalFinal/corpname">
                            <xsl:text>corporateBody</xsl:text>
                        </xsl:when>
                        <xsl:when test="normalFinal/famname">
                            <xsl:text>family</xsl:text>
                        </xsl:when>
                    </xsl:choose>
                </entityType>
                <nameEntry xml:lang="en-Latn">
                    <part>
                        <xsl:value-of select="normalFinal"/>
                    </part>
                    <authorizedForm>
                        <xsl:value-of select="$sourceID"/>
                    </authorizedForm>
                </nameEntry>
            </identity>

            <xsl:choose>
                <xsl:when test="@source='origination'">
                    <xsl:call-template name="descriptionOriginationEntity">
                        <xsl:with-param name="otherData" select="$otherData" tunnel="yes"/>
                        <xsl:with-param name="relevantBioghist" select="$relevantBioghist"/>
                    </xsl:call-template>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:call-template name="descriptionReferencedEntity">
                        <xsl:with-param name="otherData" select="$otherData" tunnel="yes"/>
                    </xsl:call-template>
                </xsl:otherwise>
            </xsl:choose>

            <relations>
                <!-- 
                     Context here is a single entity.
                -->
                <xsl:choose>
                    <xsl:when test="@source='origination'">
                        <xsl:call-template name="relationsOrigination">
                            <xsl:with-param name="otherData" tunnel="yes" select="$otherData"/>
                            <xsl:with-param name="entitiesForCPFRelations" tunnel="yes" select="$entitiesForCPFRelations"/>
                        </xsl:call-template>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:call-template name="relationsReferenced">
                            <xsl:with-param name="otherData" tunnel="yes" select="$otherData"/>
                            <xsl:with-param name="entitiesForCPFRelations" tunnel="yes" select="$entitiesForCPFRelations"/>
                        </xsl:call-template>
                    </xsl:otherwise>
                </xsl:choose>

                <resourceRelation xmlns="urn:isbn:1-931666-33-4"
                                  xlink:role="{$av_archivalResource}"
                                  xlink:type="simple">
                    <xsl:attribute name="xlink:arcrole">
                        <xsl:choose>
                            <xsl:when test="@source='origination'">
                                <xsl:value-of select="$av_creatorOf"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="$av_referencedIn"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:attribute>
                    <!-- call a template to create the xlink:href -->
                    <xsl:call-template name="hrefToEADInstance">
                        <xsl:with-param name="otherData" tunnel="yes" select="$otherData"/>
                    </xsl:call-template>
                    <!--
                        Sep 24 2014 Rewrite unittitle completely as template parse_unittitle to deal with any
                        child text/node and unitdate.
                        
                        Old: Fixed to stop normalize-space() from breaking on multiple unittitle elements.
                        
                        Same code as citation (cite_string) below.
                        
                        One of the ahub records has an interesting unittitle containing two unitdate
                        elements. The code below needs to be more complex in order to deal with this
                        situation. Must use text() for the title, and then // to get unitdate.

                        /data/source/findingAids/ude/full_ead/mss0489.xml
                        
                        This code was fixed to deal with child elements in unittitle, which broke with the /text() version of the code below. 
                        
                        xlf /data/source/findingAids/oac/chs/ms_3598.xml
                        less cpf_qa/oac/chs/ms_3598.c01.xml
                    -->
                    <relationEntry>
                        <xsl:variable name="parsed_unittitle">
                            <xsl:call-template name="parse_unittitle">
                                <!--
                                    param name="otherData" tunneled from  tpt_process calling template CpfRoot in eadToCpf.xsl
                                -->
                            </xsl:call-template>
                        </xsl:variable>

                        <xsl:variable name="repo_info">
                            <xsl:choose>
                                <xsl:when test="$otherData/repo_info[@missing = '1']">
                                    <xsl:text>Repository Unknown</xsl:text>
                                    <xsl:message>
                                        <xsl:text>Repository unknown for file: </xsl:text>
                                        <xsl:value-of select="$otherData/eadPath"/>
                                    </xsl:message>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:value-of select="$otherData/repo_info/normal"/>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:variable>

                        <!--
                            There are rare instances with no unittitle, which results in an empty $parsed_unittitle. We
                            really don't want relationEntry to be empty, so if there's no unittitle, try to
                            use <repository>. <citation> always uses repo_info, although it surrounds it with
                            ( and ). 
                        -->
                        <xsl:choose>
                            <xsl:when test="string-length($parsed_unittitle) &gt; 0">
                                <xsl:value-of select="$parsed_unittitle"/>
                            </xsl:when>
                            <xsl:when test="string-length($repo_info) > 3">
                                <xsl:value-of select="$repo_info"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:message>
                                    <xsl:text>Warning: missing relationEntry value</xsl:text>
                                </xsl:message>
                            </xsl:otherwise>
                        </xsl:choose>
                    </relationEntry>
                    <objectXMLWrap>
                        <did xmlns="urn:isbn:1-931666-22-9">
                            <xsl:apply-templates mode="did" select="$otherData/did/*[not(self::head)]"/>
                        </did>
                    </objectXMLWrap>
                </resourceRelation>
            </relations>
        </cpfDescription>
    </xsl:template> <!-- name="CpfDescription" -->

    <xsl:template mode="did" match="*">
        <xsl:element name="{name(.)}" xmlns="urn:isbn:1-931666-22-9">
            <xsl:apply-templates mode="did" select="* | text()"/>
        </xsl:element>
    </xsl:template>

    <xsl:template mode="did" match="text()">
        <xsl:value-of select="."/>
    </xsl:template>


    <xsl:template name="hrefToEADInstance">
        <xsl:param name="otherData" tunnel="yes"/>
        <!--
            Context is <entity> 
            
            In the past, utsu/ULA-mss258.xml had a leading space before the url. Add normalize-space() here in case
            any new data has a similar issue.
            
            $trim_stop_string defaults to 'findingAids'. Variable $short_name will be something similar to:
            findingAids/repo/file1234.xml

            Change:
            /data/source/findingAids/colu/nnc-ua/ldpd_8429267_ead.xml
            
            To:
            findingAids/colu/nnc-ua/ldpd_8429267_ead.xml
        -->
        <!-- <xsl:variable name="short_name" select="replace(@fn, '/data/source/', '')"/> -->
        <xsl:variable name="short_name" select="replace(@fn, concat('^.*(', $trim_stop_string, ')'), '$1')"/>
        <xsl:variable name="url" select="$file2url/container/file[text() = $short_name]/@url"/>
        <!--
            Changing ' ' to '_' is an odd thing to do in a URL. It broke a URL, and since there's no clear
            reason what it was supposed to fix, I'm changing it to '%20' which is more URL-ish.
            
            /data/source/findingAids/afl-ufl/ufms80gm.xml
            
            Good:
            http://www.library.ufl.edu/spec/manuscript/guides/Locke%20Papers.htm
            
            Broken:
            http://www.library.ufl.edu/spec/manuscript/guides/Locke_Papers.htm
        -->
        <xsl:attribute name="xlink:href">
            <!-- <xsl:value-of select="replace(normalize-space($url), ' ', '_')"/> -->
            <xsl:value-of select="replace(normalize-space($url), ' ', '%20')"/>
            <xsl:if test="string-length($url) = 0">
            <xsl:message>
                <!-- <xsl:text>Finding Aid Url of contributing respository needs to be determined!</xsl:text> -->
                <!-- <xsl:text>warning: url: Finding Aid URL TBD</xsl:text> -->
                <!--
                    Because this is printing the log message deep in this code instead of at the top, and
                    because XSLT lacks global variables or any other way to pass back out-of-band return
                    values, this would have to be completely restructured to only log this one time per input
                    file.
                    
                    So, it is easier to add @fn and use "sort -u" to make TBD urls unique so that we can count
                    them in the log files. Counting things in log files is important.
                    
                    grep tbdfname: qa.log | sort -u | wc -l
                -->
                <xsl:value-of select="concat('error: url: Finding Aid URL TBD tbdfname: ', @fn, $cr)"/>
                <xsl:value-of select="concat('short_name: ', $short_name, $cr)"/>
                <xsl:copy-of select="$file2url"/>
            </xsl:message>
            </xsl:if>
        </xsl:attribute>
    </xsl:template>

    <!--
        May 19 2015 @recordId is not the recordId from the <ead> but is the abbreviated file name of the
        related cpfRelation. And $recordId is the current cpfRelation-abbreviated-filename. So, when @recordId
        = $recordId, then this is our self-cpfRelation. It is illogical to create a standard self-cpfRelation,
        however, if there is an ARK, then we want to create a (special) sameAs cpfRelation for the
        self-cpfRelation. Naming an attribute "recordId" was in hindsight a bad idea.
        
        recordId="bnf/FRBNFEAD000004234.c01"

        May 11 2015 These are cpfRelations from the origination entity or entities. In otherwords, cpfRelation
        elements for .c files. For BnF (and perhaps eventually other repositories) this is where sameAs
        cpfRelations go.
        
        May 11 2015 Add remove URL href for sameAs cpfRelations, added for BnF records that have
        an ARK in the @authfilenumber. 
        
        May 12 2015 Maybe more generic to check @external_href.
    -->
    <xsl:template name="relationsOrigination">
        <xsl:param name="otherData" tunnel="yes"/>
        <xsl:param name="entitiesForCPFRelations" tunnel="yes"/>
        <xsl:variable name="recordId" select="@recordId"/>
        <xsl:variable name="ent_normalFinal" select="normalFinal"/> <!-- entity normal final -->

        <!-- first the non-self cpfRelations -->
        <xsl:for-each
            select="$entitiesForCPFRelations/entity[not(@recordId = $recordId)]">
            <xsl:call-template name="cpfrel_core">
                <xsl:with-param name="sameas_yes" select="false()" as="xs:boolean"/>
            </xsl:call-template>
        </xsl:for-each>

        <!--
            then do the self-cpfRelations, if they meet all necessary criteria
            
            jun 11 2015 was normal/persname/@authfilenumber which may explain why no corporateBody entities
            got sameAs cpfRelations
        -->
        <xsl:for-each
            select="$entitiesForCPFRelations/entity[(@recordId = $recordId) and normal/*/@authfilenumber]">
            <xsl:call-template name="cpfrel_core">
                <xsl:with-param name="sameas_yes" select="true()" as="xs:boolean"/>
            </xsl:call-template>
        </xsl:for-each>
    </xsl:template> <!-- relationsOrigination -->

    <!--
        It is interesting that "The attribute axis starting at a document node will never select anything"
        requires some container element in the root, even in variables. Var cpfrel has <container>, and all
        uses of $cpfrel below must be $cpfrel/container.
    -->
    
    <xsl:template name="cpfrel_core">
        <xsl:param name="sameas_yes"/>
        <xsl:param name="rfile_yes"/>
        <xsl:param name="cfile_correspondent_yes"/>
    
    <!-- assume the context is set when the template is called -->

        <xsl:variable name="cpfrel">
            <container
                normalFinal="{normalFinal}"
                recordId="{@recordId}">
                <!--
                    Make ARK based hrefs into external hrefs just like any other external href. By doing this
                    we assume that there will never be two kinds of hrefs for a single cpfRelation. Two hrefs
                    would be impossible, right?
                    
                    jun 12 2015 Again the "normal/persname/@authfilenumber" which excludes corpname. Changed to /*/
                    Also: in eadToCpf.xsl, mode_authfilenumber also had "persname" in the match, so that was broken too.
                    Also: don't check sameas_yes for xlink:href. We always want the xlink:href if authfilenumber is available.
                    
                    jun 22 2015 Generate attr xlink:href here inside variable $cpfrel, and below do the
                    requisite testing of sameas_yes. Must have xlink:href with sameAs, but must not have
                    descriptiveNote/p/span with sameAs.
                -->
                <xsl:attribute name="xlink:href">
                    <xsl:choose>
                        <!-- <xsl:when test="normal/*/@authfilenumber and $sameas_yes"> -->
                        <xsl:when test="normal/*/@authfilenumber">
                            <xsl:value-of select="normal/*/@authfilenumber"/>
                        </xsl:when>
                    </xsl:choose>
                </xsl:attribute>

                <xsl:attribute name="xlink:role">
                    <xsl:choose>
                        <xsl:when test="normalFinal/corpname">
                            <xsl:value-of select="$av_CorporateBody"/>
                        </xsl:when>
                        <xsl:when test="normalFinal/persname">
                            <xsl:value-of select="$av_Person"/>
                        </xsl:when>
                        <xsl:when test="normalFinal/famname">
                            <xsl:value-of select="$av_Family"/>
                        </xsl:when>
                    </xsl:choose>
                </xsl:attribute>

                <!--
                    May 12 2015 BnF has sameAs cpfRelations in the arcrole. We flag those with @is_sameas='1'
                    
                    snac:associatedWith, snac:correspondedWith 
                    
                    In this loop, $recordId is the .cxx. If either .c01 or .r00x is a correspondent
                    then both are correspondedWith. Note that .cxx will never be a correspondent, so
                    we don't test for that here. See template relationsReferenced.
                    
                    <xsl:when test="@correspondent='yes' or
                    $entitiesForCPFRelations/entity[@recordId = $recordId]/@correspondent='yes'">
                -->
                <xsl:attribute name="xlink:arcrole">
                    <xsl:choose>
                        <xsl:when test="$sameas_yes">
                            <xsl:value-of select="$av_sameAs"/>
                        </xsl:when>
                        <xsl:when test="@correspondent='yes'">
                            <xsl:value-of select="$av_correspondedWith"/>
                        </xsl:when>
                        <xsl:when test="$rfile_yes and $cfile_correspondent_yes='yes'">
                            <xsl:value-of select="$av_correspondedWith"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="$av_associatedWith"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:attribute>
            </container>
        </xsl:variable> <!-- $cpfrel -->

        <!--
            jun 22 2015: No change here. The existing comment about descriptiveNote is correct. Too bad this
            concept didn't get propogated over to AnF until today. However, there was no sameAs test for the
            xlink:href, so even this code wasn't quite correct.

            sameAs cpfRelations do not use descriptiveNote 
        -->

        <cpfRelation xmlns="urn:isbn:1-931666-33-4"
                     xlink:type="simple"
                     xlink:role="{$cpfrel/container/@xlink:role}"
                     xlink:arcrole="{$cpfrel/container/@xlink:arcrole}">
            <xsl:if test="$sameas_yes and string-length($cpfrel/container/@xlink:href) > 1">
                <xsl:attribute name="xlink:href" select="$cpfrel/container/@xlink:href"/>
            </xsl:if>
            <relationEntry>
                <xsl:value-of select="$cpfrel/container/@normalFinal"/>
            </relationEntry>
            <xsl:if test="not($sameas_yes)">
                <descriptiveNote>
                    <p>
                        <span localType="{$av_extractRecordId}">
                            <xsl:value-of select="$cpfrel/container/@recordId"/>
                        </span>
                    </p>
                </descriptiveNote>
            </xsl:if>
        </cpfRelation>
    </xsl:template> <!-- cpfrel_core, called from relationsOrigination -->
    
    <!--
        May 19 2015 Daniel says to create sameAs for all entities with ARK (authfilenumber) values.

        May 11 2015 These are cpfRelations from non-origination entity or entities. In other words,
        cpfRelation elements for .r files.
        
        May 18 2015 .r files should not be creating sameAs entries, so skip those. When not skipped a sameAs
        entry simply generates a duplicate of the cpfRelation back to the .cxx file.
    -->
    <xsl:template name="relationsReferenced">
        <xsl:param name="otherData" tunnel="yes"/>
        <xsl:param name="entitiesForCPFRelations" tunnel="yes"/>
        <xsl:variable name="recordId" select="@recordId"/>
        <xsl:variable name="ent_normalFinal" select="normalFinal"/> <!-- entity normal final -->

        <!-- <xsl:for-each select="$entitiesForCPFRelations/entity[@source='origination' and (not(@is_sameas) or @is_sameas != '1')]"> -->
        <!-- <xsl:for-each select="$entitiesForCPFRelations/entity[@source='origination' or @is_sameas = '1']"> -->

        <xsl:for-each select="$entitiesForCPFRelations/entity[@source='origination']">
            <xsl:call-template name="cpfrel_core">
                <xsl:with-param name="rfile_yes" select="true()" as="xs:boolean"/>
                <xsl:with-param name="cfile_correspondent_yes"
                                select="$entitiesForCPFRelations/entity[@recordId = $recordId]/@correspondent"/>
            </xsl:call-template>
        </xsl:for-each>
        
        <!-- 
             Then do the self-cpfRelations, if they meet all necessary criteria.
             
             jun 12 2015 was normal/persname/@authfilenumber which may explain why no corporateBody entities
             got sameAs cpfRelations.
        -->
        <xsl:for-each
            select="$entitiesForCPFRelations/entity[(@recordId = $recordId) and normal/*/@authfilenumber]">
            <xsl:call-template name="cpfrel_core">
                <xsl:with-param name="sameas_yes" select="true()" as="xs:boolean"/>
                <xsl:with-param name="rfile_yes" select="true()" as="xs:boolean"/>
                <xsl:with-param name="cfile_correspondent_yes"
                                select="$entitiesForCPFRelations/entity[@recordId = $recordId]/@correspondent"/>
            </xsl:call-template>
        </xsl:for-each>
    </xsl:template> <!-- relationsReferenced -->

    <xsl:template name="descriptionOriginationEntity">
        <xsl:param name="otherData" tunnel="yes"/>
        <xsl:param name="relevantBioghist"/>
        <xsl:if
            test="activeDate | 
                  existDates | 
                  function | 
                  occupation | 
                  $otherData/subject | 
                  $otherData/geogname | 
                  $otherData/function |
                  $otherData/occupation | $relevantBioghist/bioghist">

            <description xmlns="urn:isbn:1-931666-33-4">
                <xsl:call-template name="existDates">
                    <xsl:with-param name="otherData" select="$otherData" tunnel="yes"/>
                </xsl:call-template>

                <!--
                    Oct 6 2014 added [string-length() &gt; 0] to fix empty functions, first discovered in NWDA.
                    
                    xlf /data/source/findingAids/nwda/pacific_lutheran_university_archives_and_special_collections_department/OPVSIEmss_22.xml
                    less cpf_qa/nwda/pacific_lutheran_university_archives_and_special_collections_department/OPVSIEmss_22.c01.xml
                -->
                <xsl:for-each select="function | $otherData/function[string-length() &gt; 0]">
                    <!-- FUNCTION -->
                    <function xmlns="urn:isbn:1-931666-33-4">
                        <xsl:if test="@source='roleAttribute' or @source='nameString'">
                            <xsl:attribute name="localType">
                                <xsl:value-of select="$av_derivedFromRole"/>
                            </xsl:attribute>
                        </xsl:if>
                        <term>
                            <xsl:value-of select="."/>
                        </term>
                    </function>
                </xsl:for-each>

                <!--
                    Oct 6 2014 Added [string-length() &gt; 0] to fix empty occupation.
                    
                    xlf /data/source/findingAids/nwda/university_of_alaska_fairbanks/AkUV5_59.xml
                    less cpf_qa/nwda/university_of_alaska_fairbanks/AkUV5_59.c01.xml
                -->
                <xsl:for-each select="occupation | $otherData/occupation[string-length() &gt; 0]">
                    <!-- OCCUPATION -->
                    <occupation xmlns="urn:isbn:1-931666-33-4">
                        <xsl:if test="@source='roleAttribute' or @source='nameString'">
                            <xsl:attribute name="localType">
                                <xsl:value-of select="$av_derivedFromRole"/>
                            </xsl:attribute>
                        </xsl:if>
                        <term>
                            <xsl:value-of select="."/>
                        </term>
                    </occupation>
                </xsl:for-each>

                <!--
                    Oct 6 2014 Added [string-length() &gt; 0] to fix empty subject.
                    
                    xlf /data/source/findingAids/nwda/lewis_and_clark_college/OLPb039PSA.xml
                    less cpf_qa/nwda/lewis_and_clark_college/OLPb039PSA.c01.xml
                -->
                <xsl:for-each select="$otherData/subject[string-length() &gt; 0]">
                    <!-- SUBJECT -->
                    <localDescription localType="{$av_associatedSubject}">
                        <term>
                            <xsl:value-of select="."/>
                        </term>
                    </localDescription>
                </xsl:for-each>
                
                <xsl:for-each select="$otherData/geognameGroup">
                    <!--
                        For how geo data is constructed, see geo.xsl. We prepare all the geographic data in a
                        batch beforehand because it is a slow process.

                        PLACE, geonames, geonames-cheshire, placeEntry
                        
                        less cpf_qa/umi/bentley/titush.c01.xml
                        less cpf_qa/ahub/soas/196.c01.xml
                        less cpf_qa/ude/full_ead/mss0489.c01.xml
                    -->
                    <place localType="{$av_associatedPlace}">
                        <xsl:message>
                            <xsl:text>geog1: geogx: </xsl:text>
                            <xsl:copy-of select="normalized"/>
                        </xsl:message>
                        <xsl:variable name="geo">
                            <xsl:call-template name="tpt_lookup_geo">
                                <xsl:with-param name="geostring">
                                    <xsl:copy-of select="normalized"/>
                                </xsl:with-param>
                            </xsl:call-template>
                        </xsl:variable>
                        <xsl:choose>
                            <xsl:when test="$geo//*[@latitude != '' or @longitude != '' or @countryCode != '' or @administrationCode != '']">
                                <xsl:copy-of select="$geo"/>
                            </xsl:when>
                            <xsl:when test="$geo/normalized">
                                <placeEntry>
                                    <xsl:value-of select="$geo"/>
                                </placeEntry>
                            </xsl:when>
                        </xsl:choose>
                    </place>
                </xsl:for-each>

                <!--
                    Most namespaces are "" but at some point (below) the bioghist ns becomes eac. Some
                    previous code uses eac, but following code can't deal with that so we need a fatal error
                    check because this breaks all the time.
                -->

                <xsl:variable name="bhns"
                              select="$relevantBioghist/*[local-name() = 'bioghist'][1]/namespace-uri()"/>
                
                <xsl:if test="$bhns != ''">
                    <xsl:message terminate="yes">
                        <xsl:value-of select="concat('Error: bioghist namespace should be &quot;&quot; but has namespace-uri: ', $bhns, $cr)"/>
                    </xsl:message>
                </xsl:if>

                <xsl:for-each select="$relevantBioghist/bioghist">
                    <xsl:call-template name="tpt_bioghist_parse">
                        <xsl:with-param name="otherData" select="$otherData" tunnel="yes"/>
                    </xsl:call-template>
                </xsl:for-each>
            </description>
        </xsl:if>
    </xsl:template> <!-- descriptionOriginationEntity -->

    <xsl:template name="descriptionReferencedEntity">
        <xsl:param name="otherData" tunnel="yes"/>
        <xsl:if test="activeDate | 
                      existDates | 
                      function | 
                      occupation
                      ">
            <description xmlns="urn:isbn:1-931666-33-4">

                <xsl:call-template name="existDates">
                    <xsl:with-param name="otherData" select="$otherData" tunnel="yes"/>
                </xsl:call-template>

                <xsl:for-each select="function ">
                    <!-- FUNCTION -->
                    <function localType="{$av_derivedFromRole}"
                              xmlns="urn:isbn:1-931666-33-4">
                        <term>
                            <xsl:value-of select="."/>
                        </term>
                    </function>
                </xsl:for-each>

                <xsl:for-each select="occupation">
                    <!-- OCCUPATION -->
                    <occupation localType="{$av_derivedFromRole}"
                                xmlns="urn:isbn:1-931666-33-4">
                        <term>
                            <xsl:value-of select="."/>
                        </term>
                    </occupation>
                </xsl:for-each>
            </description>
        </xsl:if>
    </xsl:template>

    <xsl:template name="existDates">
        <xsl:param name="otherData" tunnel="yes"/>

        <!-- existDates -->
        <xsl:choose>
            <xsl:when test="existDates">
                <!-- explicit use of xsl:element necessary to get the namespace correct -->
                <xsl:element name="existDates" xmlns="urn:isbn:1-931666-33-4">
                    <xsl:copy-of select="existDates/@*"/>
                    <xsl:choose>
                        <xsl:when test="existDates/dateRange">
                            <xsl:element name="dateRange" xmlns="urn:isbn:1-931666-33-4">
                                <xsl:for-each select="existDates/dateRange/*">
                                    <xsl:element name="{name(.)}" xmlns="urn:isbn:1-931666-33-4">
                                        <xsl:copy-of select="@* | text()" copy-namespaces="yes"/>
                                    </xsl:element>
                                </xsl:for-each>
                            </xsl:element>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:element name="date" xmlns="urn:isbn:1-931666-33-4">
                                <xsl:copy-of select="existDates/date/(@* | text())"/>
                            </xsl:element>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:element>
            </xsl:when>
            <xsl:when test="activeDate">
                <xsl:choose>
                    <xsl:when test="activeDate[1] > $this_year">
                        <!-- Bad date, do nothing. Some code (and cpf.rng) seems to use 2099 as the max. -->
                    </xsl:when>
                    <xsl:when test="count(activeDate)=1 or (count(activeDate)=2 and activeDate[2] > $this_year)">
                        <existDates xmlns="urn:isbn:1-931666-33-4">
                            <date localType="{$av_active}" standardDate="{activeDate[1]}"
                                  xmlns="urn:isbn:1-931666-33-4">
                                <xsl:text>active </xsl:text>
                                <xsl:value-of select="activeDate[1]"/>
                            </date>
                        </existDates>
                    </xsl:when>
                    <xsl:when test="count(activeDate)=2">
                        <existDates xmlns="urn:isbn:1-931666-33-4">
                            <dateRange xmlns="urn:isbn:1-931666-33-4">
                                <fromDate localType="{$av_active}" standardDate="{activeDate[1]}"
                                          xmlns="urn:isbn:1-931666-33-4">
                                    <xsl:text>active </xsl:text>
                                    <xsl:value-of select="activeDate[1]"/>
                                </fromDate>
                                <toDate localType="{$av_active}" standardDate="{activeDate[2]}"
                                        xmlns="urn:isbn:1-931666-33-4">
                                    <xsl:text>active </xsl:text>
                                    <xsl:value-of select="activeDate[2]"/>
                                </toDate>
                            </dateRange>
                        </existDates>
                    </xsl:when>
                </xsl:choose>
            </xsl:when>
        </xsl:choose>
    </xsl:template>

    <!--
        biogHist (capital H) created here. apply-templates used to transform child elements as necessary.
        
        The debug logging is done via brecurse in eacToCpf.xsl
    -->

    <xsl:template name="tpt_bioghist_parse"  xmlns="urn:isbn:1-931666-33-4">
        <xsl:param name="otherData" tunnel="yes"/>
        <!-- <xsl:message terminate="yes"> -->
        <!--     <xsl:value-of select="concat('otherdata: ', $cr)"/> -->
        <!--     <xsl:apply-templates mode="pretty" select="$otherData"/> -->
        <!-- </xsl:message> -->
        <biogHist>
            <!--
                Are we copying the attributes mostly for debugging? Copy the attributes from bioghist (which happens to be the context).
                
                This must be the first thing in here or we'll get the message: Warning: at xsl:copy-of on line
                821 of templates.xsl: Creating an attribute here will fail if previous instructions
                create any children
            -->
            <xsl:copy-of select="@*"/>

            <xsl:apply-templates select="node()" mode="mode_bioghist"/>

            <!--
                May 14 2015 Add some ability to detect BnF (or any repo) and use a special citation
                prefix. Relies on <authorizedForm> which was added to <otherData> around line 1684 of
                eadToCpf.xsl just to support this featured. 

                sep 24 2014 Use new template parse_unittitle, but citation needs a trailing comma, so retain that code.
                
                Old: cite_string aka citation. unittitle with child or sibling unitdate. Same code as relationEntry above.

                Fixed to stop normalize-space() from breaking on multiple unittitle element.
                
                Historically delicate code, but this algo seems robust. Earlier versions of this code did not
                cope correctly with multiple dates. Historically, this has been broken in other ways too
                (missing space, and so on).
            -->


            <xsl:variable name="citation_prefix">
                <xsl:choose>
                    <xsl:when test="normalize-space($otherData/authorizedForm) = 'bnf'">
                        <xsl:text>Extrait de l’instrument de recherche de la </xsl:text>
                        <!-- <xsl:text>Information extraite de la notice des </xsl:text> -->
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:text>From the guide to the </xsl:text>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>


            <xsl:variable name="cite_string">
                <xsl:variable name="parsed_unittitle">
                    <!--
                        Previous unititle code was frail. Update and replace, especially since unittitle is
                        used in two places (here and in relationEntry).
                    -->
                    <xsl:call-template name="parse_unittitle">
                        <!--
                            param name="otherData" tunneled from  tpt_process calling template CpfRoot in eadToCpf.xsl
                        -->
                    </xsl:call-template>
                </xsl:variable>

                <!--
                    See eadToCpf.xsl "Save repository info"
                    
                    Some records have missing repo info, and we don't want empty () at the end of the
                    citation.
                -->
                <xsl:variable name="repo_info">
                    <xsl:choose>
                        <xsl:when test="$otherData/repo_info[@missing = '1']">
                            <xsl:text>Repository Unknown</xsl:text>
                            <xsl:message>
                                <xsl:text>Repository unknown for file: </xsl:text>
                                <xsl:value-of select="$otherData/eadPath"/>
                            </xsl:message>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="$otherData/repo_info/normal"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:variable>
                <!-- 
                     Only do the $citation_prefix (for example "From the guide...") if we have a
                     unittitle. Don't worry about extra spaces in $cite_string because it is run through
                     normalize-space() just below.
                     
                     May 14 2015 Example from BnF:

                     less bnf_cpf_final/bnf/FRBNFEAD000004234.c01.xml
                     
                     <citation>Extrait de l’instrument de recherche de la Bibliothèque nationale de
                     France. Département des arts du spectacle: Fonds Edward Gordon Craig
                     (FRBNFEAD000004234)</citation>

                     Possible formats (trailing commas stripped later, unittitle includes unitdate when
                     available):
                     
                     unittitle-text, (repository-text)
                     unittitle-text
                     repository-text
                -->
                <xsl:choose>
                    <xsl:when test="string-length($parsed_unittitle) &gt; 0">
                        <xsl:choose>
                            <xsl:when test="normalize-space($otherData/authorizedForm) = 'bnf'">
                                <xsl:variable name="trailing_colon">
                                    <xsl:choose>
                                        <xsl:when test="string-length($repo_info) > 3">
                                            <xsl:value-of select="': '"/>
                                        </xsl:when>
                                    </xsl:choose>
                                </xsl:variable>
                                <xsl:value-of select="concat($citation_prefix, $repo_info, $trailing_colon, $parsed_unittitle)"/>
                                <xsl:if test="string-length($otherData/eadid) &gt; 0">
                                    <xsl:value-of select="concat(' (', $otherData/eadid, ')')"/>
                                </xsl:if>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="$citation_prefix"/>
                                <xsl:value-of select="normalize-space($parsed_unittitle)"/>
                                <xsl:if test="string-length($repo_info) > 3">
                                    <xsl:value-of select="concat(', (',$repo_info, ')')"/>
                                </xsl:if>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                    <xsl:when test="string-length($repo_info) > 3">
                        <xsl:value-of select="$repo_info"/>
                    </xsl:when>
                </xsl:choose>
            </xsl:variable> <!-- end cite_string  -->

            <!--
                May 14 2015 Write citation to the log file so we can easily review them for sanity.

                The string can end up with an extra space before comma: "...1924-1932 , (School..."
                Remove it here with a simple regex.
                
                Remove trailing comma too. It doesn't look like snac:removeFinalComma() can deal with
                whitespace following the final comma, and this regex does that.
            -->
            <xsl:variable name="final_citation">
                <xsl:value-of select="replace(replace(snac:removeDoubleComma(normalize-space($cite_string)), ' ,', ','), ',\s*$', '')"/>
            </xsl:variable>
            <xsl:message>
                <xsl:value-of select="concat('citation: ', $final_citation)"/>
            </xsl:message>
            <citation>
                <xsl:value-of select="$final_citation"/>
            </citation>
        </biogHist>
    </xsl:template> <!-- tpt_bioghist_parse -->


    <xsl:template match="head">
        <plain-head/>
        <xsl:copy-of select="."/>
    </xsl:template>

    <xsl:template mode="mode_bioghist" match="text()"  xmlns="urn:isbn:1-931666-33-4">
        <p>
            <xsl:value-of select="."/>
        </p>
    </xsl:template>

    <!--
        bioghist/head becomes bioghist/p/span@localType="ead/head"
    -->
    <xsl:template mode="mode_bioghist" match="head"  xmlns="urn:isbn:1-931666-33-4">
        <!-- Oct 22 2014 new policy via email, do nothing. -->
        <!-- <p> -->
        <!--     <span localType="{$av_head}"> -->
        <!--         <xsl:value-of select="."/> -->
        <!--     </span> -->
        <!-- </p> -->
    </xsl:template>

    <!--
        list/head becomes list/item/span@localType="ead/head"
    -->
    <xsl:template mode="mode_list" match="head"  xmlns="urn:isbn:1-931666-33-4">
        <item>
            <span localType="{$av_head}">
                <xsl:value-of select="."/>
            </span>
        </item>
    </xsl:template>

    <xsl:template mode="outline" match="head"  xmlns="urn:isbn:1-931666-33-4">
        Oct 22 2014 new policy via email, do nothing.
        <span localType="{$av_head}">
            <xsl:value-of select="."/>
        </span>
    </xsl:template>

    <!--
        Intermediate template for p/list. We need to lose the enclosing p, but retain everything else.
        
        This should probably say not(self::item) instead of self::head since anything that isn't an item is
        forbidden and should be turned into an item. Except list, but outlines are handled elsewhere.
    -->
    <xsl:template mode="mode_plist" match="list"  xmlns="urn:isbn:1-931666-33-4">
        <list>
            <xsl:for-each select="*">
                <xsl:choose>
                    <xsl:when test="self::head">
                        <xsl:apply-templates select="." mode="mode_list"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:apply-templates select="." mode="mode_bioghist"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>
        </list>
    </xsl:template>

    <!--
        Catchall for p/list/head and similar from mode_plist above.
    -->
    <xsl:template mode="mode_list" match="*"  xmlns="urn:isbn:1-931666-33-4">
        <item>
            <xsl:value-of select="normalize-space()"/>
        </item>
    </xsl:template>



    <!--
        p/list gets special treatment.
        
        p/table gets special treatment (probably not fully implemented, not tested).
        
        Otherwise p/* runs through a for-each select="node()" seems to the same as select="*|text()". We're
        using for-each because choose/when/test="whatever" doesn't catch text nodes.
        
        See less cpf_extract/oac/cspr/first_theatre.c01.xml which has <p>text<emph>Soledad</emph>more text...</p>
        
        We could have the same problem with <item>, so I already changed it over to using for-each, but I
        don't have any mixed text/element examples.
        
        At least one case is <p><emph>...</emph><chronlist>...</chronlist></p> so we must for-each over all
        the nodes in <p>, testing each.

    -->
    <xsl:template mode="mode_bioghist" match="p"  xmlns="urn:isbn:1-931666-33-4">
        <xsl:choose>
            <xsl:when test="string-length() = 0">
                <!-- do nothing -->
            </xsl:when>
            <xsl:when test="list">
                <!-- 
                     We really only want p/list to ditch the p, then process <list> as usual.
                -->
                <xsl:apply-templates select="list" mode="mode_bioghist"/>
            </xsl:when>
            <xsl:when test="table">
                <!--
                    This is pretty crude, but it is hard to anticipate what people might put in a table.
                -->
                <p>
                    <xsl:apply-templates select="*" mode="mode_bioghist"/>
                </p>
            </xsl:when>
            <xsl:when test="chronlist"> <!-- CPF uses camel case chronList -->
                <!--
                    Quick fix for less -N cpf_extract/umi/bentley/vpcfo.c01.xml to wrap non-chronlist in <p>
                    and not wrap chronlist.
                -->
                <xsl:for-each select="*">
                    <xsl:choose>
                        <xsl:when test="self::chronlist">
                            <xsl:apply-templates select="." mode="mode_bioghist"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <p>
                                <xsl:apply-templates select="." mode="mode_bioghist"/>
                            </p>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:for-each>
            </xsl:when>
            <xsl:when test="count(*) = 1 and not(text())  and not(emph) and not(p)">
                <!--
                    New: we need the outer p, but we want to flatten the inner text.
                    
                    Old: Deal with p/note/list in oac/berkeley/bancroft/p1964_063_cubanc.xml where we lose the
                    outer p.
                -->
                <p>
                    <xsl:apply-templates select="*" mode="mode_bioghist"/>
                </p>
            </xsl:when>
            <xsl:otherwise>
                <!--
                    Aggressively flatten any cases not above.
                    
                    Prior to disabling p/old_p above. this otherwise processes text() nodes, so we preserve
                    this functionality.  Maybe other inline elements to process? Maybe apply-temlates with
                    another mode.
                    
                    This changes text like "the <emph render="italic">Soledad</emph>, a Mexican brig" to "the Soledad, a Mexican brig".
                    
                    Without the normalize-space() and replace() there would be a space before the comma, and two spaces before Soledad.
                -->
                <xsl:variable name="temp">
                    <xsl:value-of select="*|node()" separator=" "/>
                </xsl:variable>
                <p>
                    <xsl:value-of select="normalize-space(replace($temp, ' ,', ','))"/>
                </p>
                <!-- <p> -->
                <!--     <xsl:apply-templates select="node()" mode="mode_bioghist"/> -->
                <!-- </p> -->
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!--
        emph anywhere in biogHist is transformed. Well, not really, since <emph> inside <p> is simply thrown
        away in some other template.
    -->
    <xsl:template match="emph" mode="mode_bioghist" xmlns="urn:isbn:1-931666-33-4">
        <xsl:variable name="rstyle">
            <xsl:choose>
                <xsl:when test="@render">
                    <xsl:value-of select="@render"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="'italic'"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="temp">
            <xsl:if test="string-length(normalize-space()) > 0">
                <span style="{snac:css-style($rstyle)}">
                    <xsl:value-of select="normalize-space()"/>
                </span>
            </xsl:if>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="../self::bioghist">
                <p>
                    <xsl:copy-of select="$temp"/>
                </p>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy-of select="$temp"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!--
        Child elements of item get individualized special treatment.
    -->
    <xsl:template match="item" mode="mode_bioghist"  xmlns="urn:isbn:1-931666-33-4">
        <item>
            <xsl:for-each select="node()">
                <xsl:choose>
                    <xsl:when test="local-name() = 'emph' or local-name() = 'title'">
                        <!-- 
                             This should be when item has a child emph, however, I suspect that first text<emph>second
                             text</emph>third text might hit here and produce the wrong results.
                             
                             Curiously, before adding the for-each test="emph" was fine, but now we have to
                             use local-name(). Unclear why since this isn't an issue with p/emph.
                        -->
                    <xsl:apply-templates select="." mode="mode_bioghist"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:apply-templates mode="simple" select="."/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>
        </item>
    </xsl:template>

    <!--
       Need a test case for list@type='deflist' 
       Maybe less cpf_extract/oac/berkeley/bancroft/p1964_063_cubanc.c01.xml
    -->
    <xsl:template match="list[@type='deflist']" mode="mode_bioghist" priority="100"  xmlns="urn:isbn:1-931666-33-4">
        <list localType="{$av_deflist}">
            <xsl:for-each select="defitem">
                <item>
                    <span localType="{$av_label}">
                        <xsl:value-of select="normalize-space(label)"/>
                    </span>
                    <span localType="{$av_item}">
                        <xsl:value-of select="normalize-space(item)"/>
                    </span>
                </item>
            </xsl:for-each>
        </list>
    </xsl:template>

    <xsl:template match="*" mode="error" xmlns="urn:isbn:1-931666-33-4">
        <xsl:choose>
            <xsl:when test="self::defitem">
                <item>
                    <span localType="{$av_label}">
                        <xsl:value-of select="concat(normalize-space(./label), ': ')"/>
                    </span>
                    <xsl:value-of select="normalize-space(./item)"/>
                </item>
            </xsl:when>
            <xsl:otherwise>
                <list-error>
                    <xsl:copy-of select="."/>
                </list-error>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!--
        list/head specially transformed by mode_list template(s)
        
        list/item transformed
        
        list/item/list untested

        everything else would probably be dropped on the floor if not for the untested error mode.
        
        The old, commented out code was not working.
        
        Very important to use ".//" which means "anywhere in context" and not "//" which means anywhere in
        document. In other words, "//" has a known implicit *feature* that switches scope. Programmers hate it
        when code quietly changes scope.
    -->
    <xsl:template match="list[not(@type='deflist')]" mode="mode_bioghist" xmlns="urn:isbn:1-931666-33-4">
        <xsl:choose>
            <xsl:when test=".//*[local-name() = 'list']">
                <outline>
                    <level>
                        <!-- 
                             Fixes cpf_extract/umi/bentley/horace.c01.xml where the first element is <item> and we
                             have a mixture, but might break something else.
                             
                             See: cpf_extract/oac/cuc/mud/h1950.2_carruthers.ead.c01.xml
                             
                             The outline, list, level, item code currently works with horace and carruthers as of
                             Feb 20 2014.
                        -->
                        <xsl:for-each select="*">
                            <xsl:variable name="temp">
                                <xsl:choose>
                                    <xsl:when test="not(self::item) and not(self::list)">
                                        <item>
                                            <xsl:apply-templates mode="outline" select="."/>
                                        </item>
                                    </xsl:when>
                                    <xsl:otherwise>
                                        <xsl:apply-templates mode="outline" select="."/>
                                    </xsl:otherwise>
                                </xsl:choose>
                            </xsl:variable>
                            <xsl:choose>
                                <xsl:when test="position() = 1 or name($temp/*[1]) = 'level'">
                                    <xsl:for-each select="$temp">
                                        <xsl:call-template name="fix-level">
                                            <xsl:with-param name="action" select="'remove'"/>
                                        </xsl:call-template>
                                    </xsl:for-each>
                                    <!-- <remove> -->
                                    <!--     <xsl:copy-of select="$temp"/> -->
                                    <!-- </remove> -->
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:for-each select="$temp">
                                        <xsl:call-template name="fix-level">
                                            <xsl:with-param name="action" select="'add'"/>
                                        </xsl:call-template>
                                    </xsl:for-each>
                                    <!-- <add> -->
                                    <!--     <xsl:copy-of select="$temp"/> -->
                                    <!-- </add> -->
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:for-each>
                    </level>
                </outline>
                <!-- </list-level> -->
            </xsl:when>
            <xsl:otherwise>
                <list>
                    <xsl:apply-templates select="head" mode="mode_list"/>
                    <xsl:apply-templates select="item[not(list)]" mode="mode_bioghist"/>
                    <xsl:apply-templates select="*[not(self::item) and not(self::head)]" mode="error"/>
                </list>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!--
        If more than 1 child then for-each and wrap each child in <level>.
    -->
    <xsl:template match="list" mode="outline" xmlns="urn:isbn:1-931666-33-4">
        <xsl:param name="no_level"/>
        <xsl:choose>
            <!-- <xsl:when test="count(./*) > 1"> -->
            <xsl:when test="true()">
                <!-- <xsl:comment> -->
                <!--     <xsl:value-of select="concat('list parent: ', name(..))"/> -->
                <!-- </xsl:comment> -->
                <xsl:for-each select="*">
                    <!--
                        The first element in a <level> must be an <item>, but all the rest of the elements
                        must be inside <level> elements. Must check to make sure the parent item is not
                        already a <level>.
                        
                        So we need a variable $temp.
                    -->
                    <xsl:variable name="temp">
                        <xsl:choose>
                            <xsl:when test="not(self::item) and not(self::list)">
                                <item>
                                    <xsl:apply-templates mode="outline" select="."/>
                                </item>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:apply-templates mode="outline" select="."/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    
                    <xsl:choose>
                        <!-- <xsl:when test="position() = 1 and name(..) = 'list'"> -->
                        <!-- <xsl:when test="position() = 1 and $no_level = '1'"> -->
                        <xsl:when test="position() = 1">
                            <!-- <xsl:comment> -->
                            <!--     <xsl:value-of select="concat('elpos1: ', position(), ' elpar1: ', name(..))"/> -->
                            <!-- </xsl:comment> -->
                            <level>
                                <xsl:copy-of select="$temp"/>
                            </level>
                        </xsl:when>
                        <xsl:otherwise>
                            <level>
                                <!-- <xsl:comment> -->
                                <!--     <xsl:value-of select="concat('elpos2: ', position(), ' elpar2: ', name(..))"/> -->
                                <!-- </xsl:comment> -->
                                <xsl:copy-of select="$temp"/>
                            </level>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:for-each>
            </xsl:when>
            <!-- <xsl:when test="count(./*) = 1 and item"> -->
            <!--     <level> -->
            <!--         <xsl:apply-templates mode="outline" select="*"/> -->
            <!--     </level> -->
            <!-- </xsl:when> -->
            <xsl:otherwise>
                <list-outline-otherwise>
                    <xsl:apply-templates mode="outline" select="*"/>
                </list-outline-otherwise>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- 
         Items that contain a descendent list become lists. Text nodes inside these item-list become items.

         This fixes items as containers of both inline and block elements (which seems somehow wrong in the first place).

         <list><item>text<list><item>text</item></list></item></list>
         
         See: cpf_extract/oac/cuc/mud/h1950.2_carruthers.ead.c01.xml
         
         When we encounter things that aren't legal in CPF such as "<item>text<list></item>text" we will
         promote the child list to a sibling.
         
         Position 1 should (probably?) always be <item> but things change after that, and non-list elements
         should (almost certainly) be <level><item> to maintain correct cpf outline-level format.
         
         Confirm with:
         
         xlf /data/source/findingAids/ude/full_ead/mss0583.xml

         less -N cpf_extract/ude/full_ead/mss0583.c01.xml
    -->
    <xsl:template match="item[.//list]" mode="outline" xmlns="urn:isbn:1-931666-33-4">
        <!-- <ilevel> -->
        <xsl:variable name="temp">
            <xsl:for-each select="node()">
                <xsl:choose>
                    <xsl:when test="self::emph or self::subject or self::lb or self::note or self::corpname or self::extref">
                        <xsl:value-of select="normalize-space(.)"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:copy-of select="."/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>
        </xsl:variable>

        <xsl:for-each select="$temp/node()">
            <!-- <par attr="{concat(name(), ' ',  position())}"/> -->
            <xsl:choose>
                <xsl:when test="boolean(..[name() = 'list'])">
                    <item>
                        <xsl:apply-templates select="text()" mode="outline"/>
                    </item>
                </xsl:when>
                <xsl:when test="name() = 'list'">
                    <xsl:apply-templates select="." mode="outline"/>
                </xsl:when>
                <xsl:when test="position() = 1">
                    <item>
                        <xsl:apply-templates select="." mode="outline"/>
                    </item>
                </xsl:when>
                <xsl:when test="position() > 1">
                    <level>
                        <item>
                            <xsl:apply-templates select="." mode="outline"/>
                        </item>
                    </level>
                </xsl:when>
                <xsl:otherwise>
                    <!-- We should never get here since the previous two when's will logically act like otherwise. -->
                    <item debug="{concat('item-list-node ln:', local-name(), ' pos:', position)}">
                        <xsl:apply-templates select="." mode="outline"/>
                    </item>
                </xsl:otherwise>
            </xsl:choose>
            <!-- <xsl:apply-templates select="*" mode="outline"/> -->
            <!-- </ilevel> -->
        </xsl:for-each>
    </xsl:template>

    <!--
        Add the ability to detect item as a container of inline stuff like text, as opposed to item as a
        container of block stuff like <list>.
    -->
    <xsl:template match="item[not(.//list)]" mode="outline" xmlns="urn:isbn:1-931666-33-4">
        <item>
            <xsl:for-each select="node()">
                <xsl:choose>
                    <xsl:when test="local-name() = 'emph' or local-name() = 'title'">
                        <!-- 
                             This should be when item has a child emph, however, I suspect that first text<emph>second
                             text</emph>third text might hit here and produce the wrong results.
                             
                             Curiously, before adding the for-each test="emph" was fine, but now we have to
                             use local-name(). Unclear why since this isn't an issue with p/emph.
                        -->
                        <xsl:apply-templates select="." mode="outline"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <!-- <item-outline ln="{local-name()}"> -->

                        <xsl:apply-templates mode="outline" select="."/>

                        <!-- </item-outline> -->
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>

            <!-- <xsl:apply-templates mode="#default" select="text() | *[not(name(.)='list')]"/> -->
            <!-- Nope. Drops through to catchall_4 -->
            <!-- <xsl:apply-templates mode="#default" select="*"/> -->
        </item>
    </xsl:template>

    <xsl:template match="extref" mode="outline" xmlns="urn:isbn:1-931666-33-4">
        <xsl:value-of select="normalize-space(.)"/>
    </xsl:template>

    <xsl:template match="emph" mode="outline" xmlns="urn:isbn:1-931666-33-4">
        <xsl:variable name="rstyle">
            <xsl:choose>
                <xsl:when test="@render">
                    <xsl:value-of select="@render"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="'italic'"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <span style="{snac:css-style($rstyle)}">
            <xsl:value-of select="normalize-space()"/>
        </span>
    </xsl:template>

    <xsl:template match="item" mode="simple" xmlns="urn:isbn:1-931666-33-4">
        <item>
            <xsl:value-of select="normalize-space(.[not(list)])"/>
        </item>
    </xsl:template>

    <xsl:template match="title" mode="outline" xmlns="urn:isbn:1-931666-33-4">
        <span localType="{$av_title}">
            <xsl:value-of select="normalize-space(.[not(list)])"/>
        </span>
    </xsl:template>

    <!--
        Important safety net <catchall> to find out what is slipping through our template rules.
    -->
    <xsl:template match="*" mode="outline" xmlns="urn:isbn:1-931666-33-4">
        <xsl:choose>
            <xsl:when test="self::chronlist">
                <xsl:apply-templates select="." mode="mode_bioghist"/>
            </xsl:when>
            <xsl:when test="self::ref or self::persname or self::bibref or self::subject or self::corpname or self::name">
                <xsl:value-of select="normalize-space(.)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="normalize-space()"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="*" mode="simple"  xmlns="urn:isbn:1-931666-33-4">
        <!--
            Mostly we throw out attributes, but href his a good one to keep.
        -->
        <xsl:value-of select="."/>
        <xsl:if test="@href">
            <span localType="{$av_href}">
                <xsl:value-of select="@href"/>
            </span>
        </xsl:if>

    </xsl:template>

    <xsl:template mode="copy-no-ns" match="*" >
        <xsl:param name="ns"/>
        <!--
            Print elements withtout the pesky namespace, or with a new namespace. Does a deep copy. (It
            appears that recursing on the context sends children nodes to the recursive apply-templates. Note
            that copy-no-ns matches on "*" which is probably part of the reason the context recursive
            call/apply works.)
            
            This is mostly for debugging where the namespace is just extraneous text that interferes with
            legibility. Seems that we need to replace this line to prevent namespace from printing.
            <xsl:element name="{name(.)}"  namespace="{namespace-uri(.)}">
            
            Using local-name() works way better than name(). In fact, if you ask
            this template to print something with a namespace unknown to this
            file, it throws an error when using name().
            
            Interestingly, having a namespace such as the following in the
            stylesheet header causes that namespace to output regardless of the
            tricks below.
            
            xmlns="http://www.loc.gov/MARC21/slim"
            
            Also interesting is that if we put xmlns="urn:isbn:1-931666-33-4"
            into the opening template element above, that problem goes
            away. Putting the xmlns into the apply-templates or the outer
            template in eac-cpf.xsl changes nothing.
            
        -->
        <xsl:element name="{local-name(.)}" namespace="{$ns}">
            <xsl:copy-of select="@*"/>
            <xsl:apply-templates mode="copy-no-ns">
                <xsl:with-param name="ns" select="$ns"/>
            </xsl:apply-templates>
        </xsl:element>
    </xsl:template>

    
    <!-- 
         Non-conforming data like a <chronlist><head>Chronology</head><chronitem> means that the <head> will simply disappear.
    -->
    <xsl:template match="chronlist" mode="mode_bioghist"  xmlns="urn:isbn:1-931666-33-4">
        <chronList>
            <xsl:for-each select="chronitem">
                <!--
                    Dates returned by the date-parser() need some wrapping in the correct elements, and a bit
                    of sanity checking. We build a variable with a correct date, and then output below in
                    <chronitem>.
                    
                    Very weird bug: <return><date> changed to <return><name> by xsl:copy-of. Unclear
                    why. Identity copy works fine, so we use copy-no-ns instead of copy-of. 
                    
                    The odp: message is here (currently commented out) in case someone wants to look at all of
                    the dates. I did look at them by grep'ing out stuff we know how to parse. The remainder
                    were 73 (or 82, depending on the regexp) non-date strings.
                -->
                <xsl:variable name="parsed_date">
                    <!-- <xsl:message> -->
                    <!--     <xsl:text>odp: </xsl:text> -->
                    <!--     <xsl:value-of select="date"/> -->
                    <!-- </xsl:message> -->
                    <xsl:variable name="dp_dates" select="saxext:date-parser(date)"/>

                    <xsl:variable name="seq">
                        <xsl:apply-templates mode="copy-fix-std-date" select="$dp_dates">
                        </xsl:apply-templates>
                    </xsl:variable>

                    <xsl:choose>
                        <xsl:when test="count($seq/return/*) = 1">
                            <xsl:choose>
                                <xsl:when test="$seq//dateRange">
                                    <xsl:copy-of select="$seq//dateRange"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <!--
                                        Build a single date. If the date doesn't have @standarDate then it did
                                        not parse and we will not use standardDate since CFP does not allow
                                        standardDate="" (empty).
                                    -->
                                    <date>
                                        <xsl:if test="$seq/return/date/@standardDate">
                                            <xsl:choose>
                                                <xsl:when test="matches($seq/return/date/@standardDate, '^\d+$') and $seq/return/date/@standardDate > 2099">
                                                    <!--
                                                        Bad value. Don't include @standardDate.
                                                        All digits and a number greater than 2099.
                                                    -->
                                                </xsl:when>
                                                <xsl:otherwise>
                                                    <xsl:attribute name="standardDate">
                                                        <xsl:value-of select="$seq/return/date/@standardDate"/>
                                                    </xsl:attribute>
                                                </xsl:otherwise>
                                            </xsl:choose>
                                        </xsl:if>
                                        <xsl:value-of select="$seq/return/date"/>
                                    </date>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:when>
                        <xsl:when test="count($seq/return/*) > 1">
                            <xsl:message>
                                <xsl:value-of select="'dateset: '"/>
                                <xsl:copy-of select="$seq"/>
                            </xsl:message>
                            <dateSet>
                                <!-- jun 09 2014: originalDate is not in cpf.rng. Was it just a debug attribute? -->
                                <!-- <xsl:attribute name="originalDate" select="date"/> -->
                                <xsl:copy-of select="$seq/return/date"/>
                                <xsl:copy-of select="$seq/return/dateRange"/>
                            </dateSet>
                        </xsl:when>
                    </xsl:choose>
                </xsl:variable> <!-- end parsed_date -->
                <chronItem>
                    <xsl:apply-templates mode="copy-no-ns" select="$parsed_date">
                        <xsl:with-param name="ns" select="'urn:isbn:1-931666-33-4'"/>
                    </xsl:apply-templates>
                    <xsl:choose>
                        <xsl:when test="event">
                            <xsl:choose>
                                <xsl:when test="count(event/geogname) &gt; 1">
                                    <chronItemSet>
                                        <xsl:for-each select="event/geogname">
                                            <xsl:variable name="geo_norm" xmlns="">
                                                <normalized><xsl:value-of select="normalize-space(snac:removeFinalComma(.))"/></normalized>
                                            </xsl:variable>
                                            <xsl:message>
                                                <xsl:text>cis1: geog2: geogx: </xsl:text>
                                                <xsl:copy-of select="$geo_norm"/>
                                            </xsl:message>
                                            <xsl:variable name="geo">
                                                <xsl:call-template name="tpt_lookup_geo">
                                                    <xsl:with-param name="geostring">
                                                        <xsl:copy-of select="$geo_norm"/>
                                                    </xsl:with-param>
                                                </xsl:call-template>
                                            </xsl:variable>
                                            <xsl:choose>
                                                <xsl:when test="$geo//*[@latitude != '' or @longitude != '' or @countryCode != '' or @administrationCode != '']">
                                                    <xsl:copy-of select="$geo"/>
                                                </xsl:when>
                                                <xsl:when test="$geo/normalized">
                                                    <placeEntry>
                                                        <xsl:value-of select="$geo"/>
                                                    </placeEntry>
                                                </xsl:when>
                                            </xsl:choose>
                                        </xsl:for-each>
                                        <event>
                                            <xsl:value-of select="event"/>
                                        </event>
                                    </chronItemSet>
                                </xsl:when>
                                <xsl:otherwise>
                                    <event>
                                        <xsl:value-of select="event"/>
                                    </event>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:when>
                        <xsl:when test="eventgrp">
                            <xsl:for-each select="eventgrp/event[geogname]">
                                <chronItemSet>
                                    <xsl:for-each select="geogname">
                                        <xsl:variable name="geo_norm" xmlns="">
                                            <normalized><xsl:value-of select="normalize-space(snac:removeFinalComma(.))"/></normalized>
                                        </xsl:variable>
                                        <xsl:message>
                                            <xsl:text>cis2: geog3: geogx: </xsl:text>
                                            <xsl:copy-of select="$geo_norm"/>
                                        </xsl:message>
                                        <xsl:variable name="geo">
                                            <xsl:call-template name="tpt_lookup_geo">
                                                <xsl:with-param name="geostring">
                                                    <xsl:copy-of select="$geo_norm"/>
                                                </xsl:with-param>
                                            </xsl:call-template>
                                        </xsl:variable>
                                        <xsl:choose>
                                            <xsl:when test="$geo//*[@latitude != '' or @longitude != '' or @countryCode != '' or @administrationCode != '']">
                                                <xsl:copy-of select="$geo"/>
                                            </xsl:when>
                                            <xsl:when test="$geo/normalized">
                                                <placeEntry>
                                                    <xsl:value-of select="$geo"/>
                                                </placeEntry>
                                            </xsl:when>
                                        </xsl:choose>
                                        <!-- <xsl:copy-of select="$geo"/> -->
                                        <!-- <xsl:value-of select="snac:removeFinalComma(.)"/> -->
                                    </xsl:for-each>
                                    <event>
                                        <xsl:value-of select="."/>
                                    </event>
                                </chronItemSet>
                            </xsl:for-each>

                            <xsl:if test="eventgrp/event[not(geogname)]">
                                <chronItemSet>
                                    <xsl:for-each select="eventgrp/event[not(geogname)]">
                                        <event>
                                            <xsl:value-of select="."/>
                                        </event>
                                    </xsl:for-each>
                                </chronItemSet>
                            </xsl:if>

                        </xsl:when>
                    </xsl:choose>
                </chronItem>
            </xsl:for-each>
        </chronList>
    </xsl:template> <!-- end match="chronlist" mode="mode_bioghist" -->

    <xsl:template name="msg">
        <xsl:param name="arg" select="*"/>
        <xsl:param name="label" select="'star'"/>
        <xsl:message>
            <xsl:value-of select="concat('msg: ', $label, ' ')"/>
            <xsl:copy-of select="$arg"/>
        </xsl:message>
    </xsl:template>

    <xsl:template match="*">
        <catchall_4>
            <xsl:copy-of select="."/>
        </catchall_4>
    </xsl:template>


    <!--
        Catchall for mode_bioghist. 
        
        Leave enabled always so we can catch cases where the data will otherwise be lost.
        
        At one point there was a bug that caused things to be run through the templates twice, or something
        weird. Some stuff like bioghist/p. This template is good for finding things that appear in the output
        for no apparent reason.
    -->
    <xsl:template match="*" mode="mode_bioghist" xmlns="urn:isbn:1-931666-33-4">
        <xsl:choose>
            <xsl:when test="local-name() = 'title'">
                <xsl:variable name="temp">
                    <span localType="{$av_title}">
                        <xsl:value-of select="normalize-space()"/>
                    </span>
                </xsl:variable>
                <!-- deal with bioghist/title (in retrospect we should have flattened anything strange.) -->
                <xsl:choose>
                    <xsl:when test="../self::bioghist">
                        <p>
                            <xsl:copy-of select="$temp"/>
                        </p>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:copy-of select="$temp"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="local-name() = 'note'">
                <xsl:choose>
                    <xsl:when test="parent::node()[name() = 'p']">
                        <span localType="{$av_note}">
                            <xsl:variable name="temp">
                                <xsl:apply-templates mode="copy-normalize-space" select="*"/>
                            </xsl:variable>
                            <xsl:value-of select="normalize-space($temp)"/>
                        </span>
                    </xsl:when>
                    <xsl:otherwise>
                        <p>
                            <span localType="{$av_note}">
                                <xsl:variable name="temp">
                                    <xsl:apply-templates mode="copy-normalize-space" select="*"/>
                                </xsl:variable>
                                <xsl:value-of select="normalize-space($temp)"/>
                            </span>
                        </p>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:when test="../name() = 'p'">
                <xsl:variable name="temp">
                    <xsl:apply-templates mode="copy-normalize-space" select="."/>
                </xsl:variable>
                <xsl:copy-of select="$temp"/>
            </xsl:when>
            <xsl:otherwise>
                <p>
                    <xsl:variable name="temp">
                        <xsl:apply-templates mode="copy-normalize-space" select="."/>
                    </xsl:variable>
                    <xsl:copy-of select="$temp"/>
                </p>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:template mode="copy-fix-std-date" match="*" >
        <xsl:param name="ns"/>
        <!--
            Based on copy-no-ns.
            
            Copies, namespace, but does not copy attributes with empty values, and won't
            copy any attribute with a numerical value that is greater than or equal to 2099. This is very
            specific to date values in some chronList elements in some EAD finding aids.
            
            This is primarily to fix standardDate="18881" and similar bad dates.
            
            Doing the copy with out namespace is just to save a call to copy-no-ns.
        -->
        <xsl:element name="{local-name(.)}" namespace="{$ns}">
            <xsl:copy-of select="@*[(matches(., '^\d+$') and number(.) &lt; 2099) or matches(., '[^\d]+')]"/>
            <xsl:apply-templates mode="copy-fix-std-date">
                <xsl:with-param name="ns" select="$ns"/>
            </xsl:apply-templates>
        </xsl:element>
    </xsl:template>


    <xsl:template mode="copy-normalize-space" match="*|node()" >
        <!--
            Based on copy-no-ns.
        -->
        <xsl:choose>
            <!-- <xsl:when test="count(.//node()) = 1"> -->
            <xsl:when test="count(*) = 0 and boolean(normalize-space())">
                <!-- <xsl:value-of select="concat(local-name() , ' ', normalize-space(), $cr)"/> -->
                <!-- <cnsfirst> -->
                    <xsl:value-of select="normalize-space()"/>
                    <xsl:text> </xsl:text>
                <!-- </cnsfirst> -->
            </xsl:when>
            <xsl:otherwise>
                <!-- <cnsotherwise> -->
                    <xsl:apply-templates mode="copy-normalize-space" select="*|node()"/>
                <!-- </cnsotherwise> -->
            </xsl:otherwise>
        </xsl:choose>
        <!-- </recurse> -->
        <!-- <xsl:value-of select="$cr"/> -->
    </xsl:template>

    <xsl:template name="fix-level" xmlns="urn:isbn:1-931666-33-4">
        <xsl:param name="action"/>
        <xsl:choose>
            <xsl:when test="$action = 'add' and not(name(*[1]) = 'level')">
                <!-- <add/> -->
                <level>
                    <xsl:copy-of select="child::*[position() = 1]"/>
                </level>
                <xsl:copy-of select="child::*[position() > 1]"/>
            </xsl:when>
            <xsl:when test="$action = 'remove' and name(*[1]) = 'level'">
                <!-- <remove/> -->
                <xsl:copy-of select="child::*[position() = 1]"/>
                <xsl:copy-of select="child::*[position() > 1]"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy-of select="."/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- 
         Fix countryCode="" in $geo_list by removing @contryCode when empty. It depends on apply-templates and
         mode="geo". This implicitly calls tpt_place_copy and tpt_fix_cc. The identity transform is somewhat
         delicate in that tpt_place_copy needs to match on @*|node() although I'm not quite sure why we need
         this deviation from the traditional identity transform.
         
         Below is tpt_lookup_geo which looks up geo names <place> elements based on a normative form of the
         place name. It uses an xsl:key named ft_key which speeds the look up by 10x. It is based very closely
         on prior code used with British Library, bl2cpf.xsl.

         From bl2cfp.xsl
         
         > head geonames_files/geo.xml 
         <?xml version="1.0" encoding="UTF-8"?>
         <places>
             <placeEntry >
                 <placeEntry>Istanbul (Turkey)</placeEntry>
                 <placeEntryLikelySame vocabularySource="http://www.geonames.org/745044"
                     certaintyScore="0.25"
                     latitude="41.01384"
                     longitude="28.94966"
                     countryCode="TR"
                     administrativeCode="34">İstanbul</placeEntryLikelySame>

         Weird because match and child element have same name. Might want to fix that.
    -->

    <xsl:variable name="geo_orig" select="document('geonames_files/geo.xml')/*"/>

    <xsl:variable name="geo_list">
        <xsl:copy>
            <xsl:apply-templates select="$geo_orig" mode="geo"/>
        </xsl:copy>
    </xsl:variable>

    <xsl:template name="tpt_place_copy" mode="geo" match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates mode="geo" select="@*|node()"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template name="tpt_fix_cc" mode="geo" match="snac:placeEntryBestMaybeSame|snac:placeEntryLikelySame|snac:placeEntryMaybeSame">
        <xsl:element name="{name()}">
            <xsl:copy-of select="@*[name() != 'countryCode']"/>
            <xsl:if test="@countryCode != ''">
                <xsl:copy-of select="@countryCode"/>
            </xsl:if>
            <xsl:value-of select="."/>
        </xsl:element>
    </xsl:template>

    <xsl:key name="ft_key" match="places/snac:placeEntry" use="placeEntry" />
    <xsl:template name="tpt_lookup_geo">
        <xsl:param name="geostring"/>
        <!-- 
             Use for-each to set the context so we can use key(). Non-key time was 28 seconds
             for 95 lookups. Using key() took 2 seconds.
        -->
        <!-- <xsl:message> -->
        <!--     <xsl:text>gstr: </xsl:text> -->
        <!--     <xsl:copy-of select="$geostring"/> -->
        <!-- </xsl:message> -->

        <xsl:variable name="geo_found">
            <xsl:for-each select="$geo_list">
                <xsl:copy-of select="key('ft_key', $geostring/normalized)"/>
            </xsl:for-each>
        </xsl:variable>
        <xsl:choose>
            <!--
                Everything with a certaintyScore seems to have (most) other attributes as well.
            -->
            <xsl:when test="$geo_found/snac:placeEntry//@certaintyScore != ''">
                <xsl:copy-of select="$geo_found"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy-of select="$geostring"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template name="parse_unittitle">
        <xsl:param name="otherData" tunnel="yes"/>
        <!--
            param name="otherData" tunneled from tpt_process (or tpt_proc_inner) calling template CpfRoot in
            eadToCpf.xsl
        -->

        <xsl:variable name="date">
            <xsl:for-each select="$otherData/did//unitdate">
                <xsl:if test="not(position() = 1)">
                    <xsl:value-of select="', '"/>
                </xsl:if>
                <xsl:value-of select="normalize-space(.)"/>
            </xsl:for-each>
        </xsl:variable>

        <!--
            First, build a sequence of simply normalized unititle values, with no child elements, just text.
        -->
        <xsl:variable name="norm_title">
            <xsl:for-each select="$otherData/did/unittitle/(*|node())">
                <xsl:if test="local-name() != 'unitdate'">
                    <unittitle>
                        <xsl:value-of select="normalize-space(.)"/>
                    </unittitle>
                </xsl:if>
            </xsl:for-each>
        </xsl:variable>

        <!--
            Second, concat into a serialized string, but ignore exact duplicate text. This de-duplicates titles.
        -->
        <xsl:variable name="no_dup_title">
            <xsl:for-each select="$norm_title/unittitle[not(following::text()=text())]">
                <xsl:if test="not(position() = 1)">
                    <xsl:value-of select="', '"/>
                </xsl:if>
                <xsl:value-of select="normalize-space(.)"/>
            </xsl:for-each>
        </xsl:variable>

        <!--
            May 12 2015 BnF shelfmarks use the unitid, and this seems like a fine idea for all EAD extracted
            CPF. Concat with leading space and trailing dot space. We clean extra space below in $fuller_title
            and if the date is added, again when concat'ing $fuller_title and $date.
            
            /data/source/findingAids/bnf/Hetzel_fund.xml <unitid type="cote">NAF 16932-17152</unitid>
            less bnf_cpf_final/bnf/Hetzel_fund.c01.xml
        -->
        <xsl:variable name="shelfmark_unitid">
            <xsl:for-each select="$otherData/did/unitid">
                <xsl:value-of select="concat(' ', text(),'. ')"/>
            </xsl:for-each>
        </xsl:variable>

        <xsl:variable name="fuller_title">
            <xsl:value-of select="snac:removeDoubleDot(
                                  snac:dotComma2Dot(
                                  snac:removeFloatingDot(
                                  snac:removeFinalComma(
                                  snac:fixSpaceComma(
                                  snac:removeDoubleComma(
                                  normalize-space(
                                  concat($no_dup_title, $shelfmark_unitid))))))))"/>
        </xsl:variable>

        <xsl:if test="$date">
            <xsl:value-of select="snac:removeFinalComma(
                                  snac:fixSpaceComma(
                                  snac:removeDoubleComma(
                                  normalize-space(
                                  concat($fuller_title, ', ', $date)))))"/>
        </xsl:if>
    </xsl:template> <!-- end of parse_unittitle -->

    <!--
        This seems to be a pretty printer for xsl:message (after being modified with its own mode). Created by
        John Morgan. From http://www.dpawson.co.uk/xsl/sect2/pretty.html
    -->
    
    <xsl:param name="indent-increment" select="'  '"/>

    <xsl:template match="*" mode="pretty">
        <xsl:param name="indent" select="'&#xA;'"/>

        <xsl:value-of select="$indent"/>
        <xsl:copy>
            <xsl:copy-of select="@*" />
            <xsl:apply-templates mode="pretty">
                <xsl:with-param name="indent"
                                select="concat($indent, $indent-increment)"/>
            </xsl:apply-templates>
            <xsl:if test="*">
                <xsl:value-of select="$indent"/>
            </xsl:if>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="comment()|processing-instruction()" mode="pretty">
        <xsl:copy />
    </xsl:template>

    <!-- WARNING: this is dangerous. Handle with care -->
    <xsl:template match="text()[normalize-space(.)='']" mode="pretty"/>
    
</xsl:stylesheet>
