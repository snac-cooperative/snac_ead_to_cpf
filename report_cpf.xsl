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
        Author: Tom Laudeman
        The Institute for Advanced Technology in the Humanities
        
        Copyright 2014 University of Virginia. Licensed under the Educational Community License, Version 2.0
        (the "License"); you may not use this file except in compliance with the License. You may obtain a
        copy of the License at
        
        http://www.osedu.org/licenses/ECL-2.0
        http://opensource.org/licenses/ECL-2.0
        
        Unless required by applicable law or agreed to in writing, software distributed under the License is
        distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
        implied. See the License for the specific language governing permissions and limitations under the
        License.
        
        Deal with lc and oac being in a non-conventional directory.
        
        Dec 17 2014, add a new column for count of files with biogHist. 

        find /data/extract/ -maxdepth 1 -path "/data/extract/ead_*" ! -path "/data/extract/ead_sep*" -exec snac_transform.sh qa.xml report_cpf.xsl path={} \; > report.log 2>&1 &

        find /data/extract/ead_sep_30_2014/ -maxdepth 1 -mindepth 1 -exec snac_transform.sh qa.xml report_cpf.xsl path={} \; >> report.log 2>&1 &
        
        cat report.log| finalize_report.pl | less
    -->

    <xsl:variable name="cr" select="'&#x0A;'"/>
    <xsl:variable name="tab" select="'&#x09;'"/>

    <xsl:strip-space elements="*"/>
    <xsl:output indent="yes" method="text"/>

    <xsl:param name="path" select="'/data/extract/ead_aao/'"/>

    <xsl:param name="repository" select="'AAO (EAD)'"/>
    
    <xsl:variable name="this_year" select="year-from-date(current-date())"/>


    <xsl:template name="tpt_main" match="/">
        <!--
            https://blogs.it.ox.ac.uk/jamesc/2009/02/10/xslt2-collection-with-dynamic-collections-from-directory-listings/
        -->
        <xsl:variable name="repo_stats">
            <!-- It is kind of amazing that [] work with a function that returns a node set. -->
            <!-- <xsl:for-each select="collection('/data/extract/ead_aao/?select=*.xml;recurse=yes;')[position() &lt; 10]" > -->
            <!-- <xsl:for-each select="collection(concat($path, '?select=*.xml;recurse=yes;'))[position() &lt; 10]" > -->
            <!-- <xsl:for-each select="collection(concat($path, '?select=*.xml;recurse=yes;'))" > -->


            <xsl:for-each select="collection(concat($path, '?select=*.xml;recurse=yes;'))" >
                <!--
                    Uncomment the if statement to enable .cxx only reporting.
                -->
                <!-- <xsl:if test="matches(document-uri(/), '\.c\d+\.xml')"> -->
                <file name="{document-uri(/)}" bh_count="{count(eac:eac-cpf/eac:cpfDescription/eac:description/eac:biogHist)}">
                    <xsl:value-of select="eac:eac-cpf/eac:cpfDescription/eac:identity/eac:entityType"/>
                </file>
                <!-- </xsl:if> -->
            </xsl:for-each>
        </xsl:variable>

        <!--
            For multi-repository statistics we don't want this header line.
        -->
        <!-- <xsl:value-of -->
        <!--     select=" -->
        <!--       concat('repository', $tab, 'total', $tab, 'corporateBody', $tab, 'person', $tab, 'family', $tab, 'biogHist', $cr)"/> -->

        <!--
            jul 14 2015 Old code to print the repository name. Now handled by a param.
            lc and oac were put into a single subdir before the ead_ naming convention was invented.
        -->
        <!-- <xsl:choose> -->
        <!--     <xsl:when test="matches($repo_stats/file[1]/@name, 'ead_sep')"> -->
        <!--         <xsl:value-of select="replace($repo_stats/file[1]/@name, '^.*?/ead_sep_30_2014/(.*?)/.*$', '$1')"/> -->
        <!--     </xsl:when> -->
        <!--     <xsl:when test="matches($repo_stats/file[1]/@name, 'ead_')"> -->
        <!--         <xsl:value-of select="replace($repo_stats/file[1]/@name, '^.*?/ead_(.*?)/.*$', '$1')"/> -->
        <!--     </xsl:when> -->
        <!--     <xsl:otherwise> -->
        <!--         <xsl:value-of select="replace($repo_stats/file[1]/@name, '^.*/data/extract/(.*?)/.*$', '$1')"/> -->
        <!--     </xsl:otherwise> -->
        <!-- </xsl:choose> -->

        <xsl:value-of select="concat($repository, $tab, count($repo_stats/file))"/>
        <xsl:value-of select="concat($tab, count($repo_stats/file[text()='corporateBody']))"/>
        <xsl:value-of select="concat($tab, count($repo_stats/file[text()='person']))"/>
        <xsl:value-of select="concat($tab, count($repo_stats/file[text()='family']))"/>
        <xsl:value-of select="concat($tab, count($repo_stats/file[@bh_count >= 1]), $cr)"/>

    </xsl:template> <!-- tpt_main match="/" -->

</xsl:stylesheet>
