<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:ead="urn:isbn:1-931666-22-9"
                xmlns:functx="http://www.functx.com"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xlink="http://www.w3.org/1999/xlink"
                xmlns:eac="urn:isbn:1-931666-33-4"
                xmlns:snac="snac"
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

        av_ is mnemonic for Attribute Value. These constitute a controlled vocabulary of values for attributes
        like localType in CPF. This used to be in lib.xsl, but we're using it in at least two projects, thus
        the need for this separate file.
    -->

    <!-- Seems to be only used by a single henry script, henry_fix.xsl
         example:
         /eac-cpf/control/otherRecordId@localType
         file /data/extract/henry_cpf/SIA.Henry.31170.xml
    -->
    <xsl:variable name="av_DatabaseName" select="'http://socialarchive.iath.virginia.edu/control/term#DatabaseName'"/>

    <!-- example:
         existDates/date@localType
         existDate/dateRange/(fromDate|toDate)@localType
         http://socialarchive.iath.virginia.edu/snac/data/99166-w6j17vgd.xml
         <part>Trumbull, John, 1714 or -15-1757.</part>
    -->
    <xsl:variable name="av_suspiciousDate" select="'http://socialarchive.iath.virginia.edu/control/term#SuspiciousDate'"/>

    <!--
        person example:
        existDates/dateRange/(fromDate|toDate)@localType
        http://socialarchive.iath.virginia.edu/snac/data/99166-w63b6gns.xml
        
        Probably also applies to existDates/date@localType. Probably also used anywhere existDates occur, for
        example cpfRelation/relationEntry.
    -->
    <xsl:variable name="av_active " select="'http://socialarchive.iath.virginia.edu/control/term#Active'"/>

    <!-- 
         example:
         existDates/dateRange/(fromDate|toDate)@localType
         http://socialarchive.iath.virginia.edu/snac/data/99166-w6m61h6r.xml
    -->
    <xsl:variable name="av_born" select="'http://socialarchive.iath.virginia.edu/control/term#Birth'"/>
    <xsl:variable name="av_died" select="'http://socialarchive.iath.virginia.edu/control/term#Death'"/>

    <!--
        example:
        http://socialarchive.iath.virginia.edu/snac/data/99166-w66w9mgs.xml
        description/localDescription@localType
    -->
    <xsl:variable name="av_associatedSubject" select="'http://socialarchive.iath.virginia.edu/control/term#AssociatedSubject'"/>


    <!-- example:
         file /data/extract/WorldCat/dev_3/OCLC-AU064-225851373.c.xml
         <part>Mabo, Eddie, 1936-1992.</part>
         
         The merged file doesn't have the same place elements:
         http://socialarchive.iath.virginia.edu/snac/data/99166-w6st7wtd.xml
         
         cpfDescription/description/place@localType
         http://socialarchive.iath.virginia.edu/snac/data/99166-w6s52kmj.xml
    -->
    <xsl:variable name="av_associatedPlace" select="'http://socialarchive.iath.virginia.edu/control/term#AssociatedPlace'"/>

    <!--
        Oct 10 2014 I just noticed the missing "ed" in the variable name "extract" instead of "extracted". Not
        a problem as long as it used the same way everywhere. XSLT will die with an undeclared variable error
        if someone misspells it.
        
        example:
        cpfRelation/descriptiveNote/span@localtype
        file (only occurs in extracted CPF, not merged) /data/extract/WorldCat/dev_27/OCLC-EUX-607641328.c.xml
        <part>Smith, Alexander, fl. 1872-1881.</part>        
    -->
    <xsl:variable name="av_extractRecordId" select="'http://socialarchive.iath.virginia.edu/control/term#ExtractedRecordId'"/>

    <!-- example:
         resourceRelation/descriptiveNoce (only MARC derived records)
         http://socialarchive.iath.virginia.edu/snac/data/99166-w63b6gns.xml
    -->
    <xsl:variable name="av_Leader06" select="'http://socialarchive.iath.virginia.edu/control/term#Leader06'"/>
    <xsl:variable name="av_Leader07" select="'http://socialarchive.iath.virginia.edu/control/term#Leader07'"/>
    <xsl:variable name="av_Leader08" select="'http://socialarchive.iath.virginia.edu/control/term#Leader08'"/>

    <!-- example:
         cpfDescription/description/occupation@localType
         http://socialarchive.iath.virginia.edu/snac/data/99166-w6ct0j3g.xml
    -->
    <xsl:variable name="av_derivedFromRole" select="'http://socialarchive.iath.virginia.edu/control/term#DerivedFromRole'"/>

    <!--
        example:
        cpfRelation@xlink:role
        http://socialarchive.iath.virginia.edu/snac/data/99166-w6zs7327.xml
        <part>Thos. Agnew and Sons Ltd.</part> cpfRelation associatedWith <relationEntry>Duveen Brothers</relationEntry>
    -->
    <xsl:variable name="av_CorporateBody" select="'http://socialarchive.iath.virginia.edu/control/term#CorporateBody'"/>

    <!-- 
         example:
         cpfRelation@xlink:role
         http://socialarchive.iath.virginia.edu/snac/data/99166-w6wv3r9s.xml
    -->
    <xsl:variable name="av_Family" select="'http://socialarchive.iath.virginia.edu/control/term#Family'"/>

    <!-- example:
         cpfRelation@xlink:role
         http://socialarchive.iath.virginia.edu/snac/data/99166-w63b6gns.xml
    -->
    <xsl:variable name="av_Person" select="'http://socialarchive.iath.virginia.edu/control/term#Person'"/>

    <!-- example:
         cpfRelation@xlink:arcrole
         http://socialarchive.iath.virginia.edu/snac/data/99166-w63b6gns.xml
    -->
    <xsl:variable name="av_associatedWith" select="'http://socialarchive.iath.virginia.edu/control/term#associatedWith'"/>

    <!-- example:
        cpfRelation@xlink:arcrole
        http://socialarchive.iath.virginia.edu/snac/data/99166-w66w9mgs.xml
    -->
    <xsl:variable name="av_correspondedWith" select="'http://socialarchive.iath.virginia.edu/control/term#correspondedWith'"/>
    
    <!-- example:
         resourceRelation/@xlink:arcrole
         http://socialarchive.iath.virginia.edu/snac/data/99166-w63b6gns.xml
    -->
    <xsl:variable name="av_creatorOf" select="'http://socialarchive.iath.virginia.edu/control/term#creatorOf'"/>


    <!-- example:
        resourceRelation@xlink:arcrole
        http://socialarchive.iath.virginia.edu/snac/data/99166-w66w9mgs.xml
    -->
    <xsl:variable name="av_referencedIn" select="'http://socialarchive.iath.virginia.edu/control/term#referencedIn'"/>

    <!-- example:
         resourceRelation@xlink:role
         http://socialarchive.iath.virginia.edu/snac/data/99166-w63b6gns.xml
    -->
    <xsl:variable name="av_archivalResource" select="'http://socialarchive.iath.virginia.edu/control/term#ArchivalResource'"/>

    <!--
        May 8 2015 Only used by the Whitman data resourceRelations which have a URL pointing to a
        transcription, and/or digitized version. And the Whitman data doesn't use any XSLT, so this value is
        copied here to keep av.pm (a Perl module) and av.xsl in sync. As of May 8 2015 Perl extraction code
        uses this value (but no XSLT), and therefore the value is in extracted CPF.
        
        example:
        resourceRelation@xlink:role
        file /data/extract/whitman/wwuid_9.xml
    -->
    <xsl:variable name="av_DigitalArchivalResource" select="'http://socialarchive.iath.virginia.edu/control/term#DigitalArchivalResource'"/>


    <!-- 
         Apr 15 2015 I thought someone at NARA said "contributor" was a misnomer, and the only relationship is
         creatorOf. You'll have to check the code to be sure.

         Jan 26 2015 Added for NARA. In SNAC parlance, contributor may simply be creator, but for now, it is
         separate.
    -->
    <xsl:variable name="av_contributorTo" select="'http://socialarchive.iath.virginia.edu/control/term#contributorTo'"/>


    <xsl:variable name="av_donorOf" select="'http://socialarchive.iath.virginia.edu/control/term#donorOf'"/>


    <!-- As far as I know these aren't used in any of Tom's XSLT that generates CPF. -->
    <xsl:variable name="av_mergedRecord" select="'http://socialarchive.iath.virginia.edu/control/term#MergedRecord'"/>
    <xsl:variable name="av_BibliographicResource" select="'http://socialarchive.iath.virginia.edu/control/term#BibliographicResource'"/>
    <xsl:variable name="av_mayBeSameAs" select="'http://socialarchive.iath.virginia.edu/control/term#mayBeSameAs'"/>

    <!-- Used for NARA authority records starting Feb 24 2015 -->
    <xsl:variable name="av_sameAs" select="'http://www.w3.org/2002/07/owl#sameAs'"/>

    <!--
        aug 3 2015, found this in merge CPF from Yiming. Not used in Tom's extraction code.
        example:
        http://socialarchive.iath.virginia.edu/snac/data/99166-w63b6gns.xml
    -->
    <xsl:variable name="av_snac_sameAs" select="'http://socialarchive.iath.virginia.edu/control/term#sameAs'"/>

    <!--
        New values used in EAD extraction. eac/href is used for @href, found in extref, maybe other elements.
        
        example:
        biogHist/p/span@localType 
        term#ead/note
        http://socialarchive.iath.virginia.edu/snac/data/99166-w6x20xp1.xml
        
        biogHist/list/item/span@localType
        http://socialarchive.iath.virginia.edu/snac/data/99166-w6s52kmj.xml
        term#ead/title
        
        biogHist/list/item/span@localType
        http://socialarchive.iath.virginia.edu/snac/data/99166-w69q6c5x.xml
        term#ead/head
        
        term#ead/deflist
        term#ead/item
        term#ead/label

        biogHist/list/item/span@localType
        http://socialarchive.iath.virginia.edu/snac/data/99166-w6wv3r9s.xml
        term#ead/href
    -->

    <xsl:variable name="av_note" select="'http://socialarchive.iath.virginia.edu/control/term#ead/note'"/>
    <xsl:variable name="av_title" select="'http://socialarchive.iath.virginia.edu/control/term#ead/title'"/>
    <xsl:variable name="av_head" select="'http://socialarchive.iath.virginia.edu/control/term#ead/head'"/>
    <xsl:variable name="av_deflist" select="'http://socialarchive.iath.virginia.edu/control/term#ead/deflist'"/>
    <xsl:variable name="av_item" select="'http://socialarchive.iath.virginia.edu/control/term#ead/item'"/>
    <xsl:variable name="av_label" select="'http://socialarchive.iath.virginia.edu/control/term#ead/label'"/>
    <xsl:variable name="av_href" select="'http://socialarchive.iath.virginia.edu/control/term#ead/href'"/>

    <!-- 
         Feb 4 2015 The allowed values for cpfDescription/identity/nameEntry/(authorizedForm|alternativeForm)
         
         First used by nara_das2cpf.xsl, and hard coded elsewhere. This is an odd value since (nearly?)
         everything else in this file is an attribute, but his is an element name. 
         
         example: element name, not an attribute value.
         identity/nameEntry/(authorizedForm|alternativeForm)
         http://socialarchive.iath.virginia.edu/snac/data/99166-w63b6gns.xml
    -->
    <xsl:variable name="av_authorizedForm" select="'authorizedForm'"/>
    <xsl:variable name="av_alternativeForm" select="'alternativeForm'"/>

    <!--
        Jul 21 2015 I discovered that this was used in British Library person alt names.
        (not true) As of Oct 10 2014 not used.
        New for alternativeName so Ray and Yiming know which name to match. Internal use only.
    -->
    <xsl:variable name="av_match" select="'http://socialarchive.iath.virginia.edu/control/term#Matchtarget'"/>

</xsl:stylesheet>
