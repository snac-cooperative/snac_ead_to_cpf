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

    <xsl:variable name="av_DatabaseName" select="'http://socialarchive.iath.virginia.edu/control/term#DatabaseName'"/>

    <xsl:variable name="av_suspiciousDate" select="'http://socialarchive.iath.virginia.edu/control/term#SuspiciousDate'"/>
    <xsl:variable name="av_active " select="'http://socialarchive.iath.virginia.edu/control/term#Active'"/>
    <xsl:variable name="av_born" select="'http://socialarchive.iath.virginia.edu/control/term#Birth'"/>
    <xsl:variable name="av_died" select="'http://socialarchive.iath.virginia.edu/control/term#Death'"/>
    <xsl:variable name="av_associatedSubject" select="'http://socialarchive.iath.virginia.edu/control/term#AssociatedSubject'"/>
    <xsl:variable name="av_associatedPlace" select="'http://socialarchive.iath.virginia.edu/control/term#AssociatedPlace'"/>

    <!--
        Oct 10 2014 I just noticed the missing "ed" in the variable name "extract" instead of "extracted". Not
        a problem as long as it used the same way everywhere. XSLT will die with an undeclared variable error
        if someone misspells it.
    -->
    <xsl:variable name="av_extractRecordId" select="'http://socialarchive.iath.virginia.edu/control/term#ExtractedRecordId'"/>

    <xsl:variable name="av_Leader06" select="'http://socialarchive.iath.virginia.edu/control/term#Leader06'"/>
    <xsl:variable name="av_Leader07" select="'http://socialarchive.iath.virginia.edu/control/term#Leader07'"/>
    <xsl:variable name="av_Leader08" select="'http://socialarchive.iath.virginia.edu/control/term#Leader08'"/>
    <xsl:variable name="av_derivedFromRole" select="'http://socialarchive.iath.virginia.edu/control/term#DerivedFromRole'"/>

    <xsl:variable name="av_CorporateBody" select="'http://socialarchive.iath.virginia.edu/control/term#CorporateBody'"/>
    <xsl:variable name="av_Family" select="'http://socialarchive.iath.virginia.edu/control/term#Family'"/>
    <xsl:variable name="av_Person" select="'http://socialarchive.iath.virginia.edu/control/term#Person'"/>
    <xsl:variable name="av_associatedWith" select="'http://socialarchive.iath.virginia.edu/control/term#associatedWith'"/>
    <xsl:variable name="av_correspondedWith" select="'http://socialarchive.iath.virginia.edu/control/term#correspondedWith'"/>
    <xsl:variable name="av_creatorOf" select="'http://socialarchive.iath.virginia.edu/control/term#creatorOf'"/>
    <xsl:variable name="av_referencedIn" select="'http://socialarchive.iath.virginia.edu/control/term#referencedIn'"/>
    <xsl:variable name="av_archivalResource" select="'http://socialarchive.iath.virginia.edu/control/term#ArchivalResource'"/>

    <!-- As far as I know these aren't used in any of Tom's XSLT that generates CPF. -->
    <xsl:variable name="av_mergedRecord" select="'http://socialarchive.iath.virginia.edu/control/term#MergedRecord'"/>
    <xsl:variable name="av_BibliographicResource" select="'http://socialarchive.iath.virginia.edu/control/term#BibliographicResource'"/>
    <xsl:variable name="av_mayBeSameAs" select="'http://socialarchive.iath.virginia.edu/control/term#mayBeSameAs'"/>
    <xsl:variable name="av_sameAs" select="'http://www.w3.org/2002/07/owl#sameAs'"/>

    <!-- New values used in EAD extraction -->

    <xsl:variable name="av_note" select="'http://socialarchive.iath.virginia.edu/control/term#ead/note'"/>
    <xsl:variable name="av_title" select="'http://socialarchive.iath.virginia.edu/control/term#ead/title'"/>
    <xsl:variable name="av_head" select="'http://socialarchive.iath.virginia.edu/control/term#ead/head'"/>
    <xsl:variable name="av_deflist" select="'http://socialarchive.iath.virginia.edu/control/term#ead/deflist'"/>
    <xsl:variable name="av_item" select="'http://socialarchive.iath.virginia.edu/control/term#ead/item'"/>
    <xsl:variable name="av_label" select="'http://socialarchive.iath.virginia.edu/control/term#ead/label'"/>
    <!-- Used for @href, found in extref, maybe other elements -->
    <xsl:variable name="av_href" select="'http://socialarchive.iath.virginia.edu/control/term#ead/href'"/>

    <!--
        As of Oct 10 2014 not used.
        New for alternativeName so Ray and Yiming know which name to match. Internal use only.
    -->
    <xsl:variable name="av_match" select="'http://socialarchive.iath.virginia.edu/control/term#Matchtarget'"/>

</xsl:stylesheet>
