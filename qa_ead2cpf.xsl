<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0"
                xmlns:eac="urn:isbn:1-931666-33-4"
                xmlns="urn:isbn:1-931666-33-4"
                xpath-default-namespace="urn:isbn:1-931666-33-4"
                xmlns:lib="http://example.com/"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xlink="http://www.w3.org/1999/xlink"
                xmlns:saxon="http://saxon.sf.net/"
                xmlns:fn="http://www.w3.org/2005/xpath-functions"
                xmlns:mods="http://www.loc.gov/mods/v3"
                xmlns:snac="http://socialarchive.iath.virginia.edu/"
                exclude-result-prefixes="#all"
                >

    <!--
        Before running this XSLT script, run the full QA cpf extraction first, and use inc_orig=1 because
        there was a bug related to including the original EAD. (Although that bug only applies to QA, and not
        production because we don't include original EAD in the production CPF output.)
        
        snac_transform.sh qa.xml eadToCpf.xsl cpfOutLocation="cpf_qa" inc_orig=1 > qa.log 2>&1 &
        
        Then run these QA tests:

        snac_transform.sh qa.xml qa_ead2cpf.xsl
        
        qa.xml serves no purpose except to keep Saxon quiet, because Saxon really wants an XML file to
        transform. All the real file names that are being tested are hard coded.

        Based on ~/eac_project/qa_marc2cpf.xsl which was based on qa_report.xsl. 
        
        Note that we are (cleverly?) using xpath-default-namespace in the header above so we don't have to
        prefix every xpath element with "eac:".

        The error below usually means you are missing a file in qa_marc_list.xml, and you need to regenerate qa_marc_list.xml
        via the shell command above:
        
        SXXP0003: Error reported by XML parser: Content is not allowed in prolog.
        
        See notes below in template tpt_match_record.
    -->

    <xsl:output method="text" indent="no"/>

    <xsl:param name="debug" select="false()"/>

    <xsl:param name="input_dir" select="'cpf_qa'"/>
    
    <xsl:variable name="cr" select="'&#x0A;'"/>

    <xsl:template match="/">
        <xsl:call-template name="tpt_match_record">
            <xsl:with-param name="list" select="."/>
        </xsl:call-template>
    </xsl:template>


    <xsl:template name="tpt_match_record" xmlns="urn:isbn:1-931666-33-4">
        <xsl:param name="list"/>

        <!--
            In all the tests below we use use for-each to set the context. By setting (and using) the context,
            the test xpaths are simpler.
            
            Except where noted in comments, there is one file per test. Some tests have multiple xpaths and
            value tests connected by logical "and".
            
            Many xpaths and many values are long, so there is a fair amount of intentional line breaking for
            legibility.
            
            The output is text, either "Ok:" or "Error:" and the file name.
        -->

        <xsl:for-each select="document(concat($input_dir, '/oac/csa/alpert.c01.xml'))/*">
            <xsl:choose>
                <xsl:when test="/eac-cpf/cpfDescription/description/biogHist/list/item/span[matches(@style, 'italic')] =
                    'Standing Committees'">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error: ', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>


        <xsl:for-each select="document(concat($input_dir, '/oac/berkeley/bancroft/m88_206_cubanc.c01.xml'))/*">
            <xsl:choose>
                <xsl:when test="/eac-cpf/cpfDescription/description/biogHist/citation =
                    'From the guide to the Samuel J. and Portia Bell Hume papers, 1848-1990, 1920-1971, (The Bancroft Library)'">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error: ', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>


        <xsl:for-each select="document(concat($input_dir, '/oac/uci/spcoll/r079.c01.xml'))/*">
            <xsl:choose>
                <xsl:when test="/eac-cpf/cpfDescription/description/biogHist/chronList/chronItem[
                                date='1870s' and normalize-space(event)='Serrano Water Association began operations.']">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error: ', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>

        <xsl:for-each select="document(concat($input_dir, '/oac/cspr/first_theatre.c01.xml'))/*">
            <xsl:choose>
                <xsl:when test="matches(/eac-cpf/cpfDescription/description/biogHist, 'the Soledad, a Mexican brig')">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error: ', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>

        <xsl:for-each select="document(concat($input_dir, '/oac/csa/miligeow.c01.xml'))/*">
            <xsl:choose>
                <xsl:when test="count(/eac-cpf/cpfDescription/description//biogHist) = 1">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error: ', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>

        <xsl:for-each select="document(concat($input_dir, '/oac/csudh/spcoll/longbeachfiredepartmentead.c01.xml'))/*">
            <xsl:choose>
                <xsl:when test="/eac-cpf/cpfDescription/identity/entityType= 'corporateBody'">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error: ', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>

        <xsl:for-each select="document(concat($input_dir, '/oac/berkeley/bancroft/p1964_063_cubanc.c01.xml'))/*">
            <xsl:choose>
                <xsl:when test="/eac-cpf/cpfDescription/description/biogHist/p[matches(., 'List of abbreviations.*of Arizona, 1985.')]">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error: ', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>

        <xsl:for-each select="document(concat($input_dir, '/oac/cuc/mud/h1950.1.ead.c01.xml'))/*">
            <xsl:choose>
                <xsl:when test="/eac-cpf/cpfDescription/description/biogHist/citation = 'From the guide to the Walter R. Brookins Aviation collection, 1900-1954., (Claremont Colleges. Library. Special Collections, Honnold/Mudd Library.)'">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error: ', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>

        <xsl:for-each select="document(concat($input_dir, '/oac/cuc/mud/h1950.2_carruthers.ead.c01.xml'))/*">
            <xsl:choose>
                <xsl:when test="normalize-space(/eac-cpf/cpfDescription/description/biogHist/outline/level/item) = normalize-space('The Institute of Aeronautical History, Inc., James Gillette, executive vice president. The Institute consisted of two separate entities: ') and /eac-cpf/cpfDescription/description/biogHist/list/item/span = 'Sources:'">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error: ', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>


        <xsl:for-each select="document(concat($input_dir, '/oac/ucsf/spcoll/lifindin.c01.xml'))/*">
            <xsl:choose>
                <xsl:when test="/eac-cpf/cpfDescription/description/biogHist/p[contains(. , normalize-space('He Edited  Hormonal Proteins and Peptides, volumes 1-11, (Academic Press Inc.) 1973-83.  There are no documents relating to his editing of vol 13 (1987).'))]">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error: ', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>

        <xsl:for-each select="document(concat($input_dir, '/oac/maritime/safr_22247_p91-078.c01.xml'))/*">
            <xsl:choose>
                <xsl:when test="/eac-cpf/cpfDescription/description/biogHist/chronList/*[position() = 1 and local-name()='chronItem']">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error: ', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>

        <xsl:for-each select="document(concat($input_dir, '/oac/maritime/apl.c01.xml'))/*">
            <xsl:choose>
                <xsl:when test="/eac-cpf/cpfDescription/description/biogHist/list/item/span = 'Endnotes'">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error: ', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>


        <xsl:for-each select="document(concat($input_dir, '/oac/humboldt/schoenro.c01.xml'))/*">
            <xsl:choose>
                <xsl:when test="/eac-cpf/cpfDescription/description/biogHist/p[matches(., 'The Schoenrock Collection') and not(emph)] and
                                /eac-cpf/cpfDescription/description/biogHist/p[not(lb)] = 'Arnold R. Pilling Wayne State University Detroit, MI November 4, 1987'">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error: ', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>

        <xsl:for-each select="document(concat($input_dir, '/oac/ucsc/spcoll/ms160.c01.xml'))/*">
            <xsl:choose>
                <xsl:when test="/eac-cpf/cpfDescription/description/biogHist[not(blockquote) and not(//emph)]/p[matches(., 'From my high')]">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error: ', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>

        <xsl:for-each select="document(concat($input_dir, '/nwda/university_of_alaska_fairbanks/UAFBLUSUAFV3_32.c01.xml'))/*">
            <xsl:choose>
                <xsl:when test="/eac-cpf/cpfDescription/description/biogHist/citation = 'From the guide to the Mary TallMountain Papers, Mary Tallmountain Collection, 1968-1998, (University of Alaska Fairbanks Alaska Polar Regions Collections &amp; Archives)'">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error: ', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>

        <xsl:for-each select="document(concat($input_dir, '/umi/bentley/vpcfo.c01.xml'))/*">
            <xsl:choose>
                <xsl:when test="/eac-cpf/cpfDescription/description/biogHist/p/span = 'Chief Financial Officers of the University of Michigan' and
                                count(/eac-cpf/cpfDescription/description/biogHist/chronList) = 4">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error: ', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>


        <xsl:for-each select="document(concat($input_dir, '/umi/bentley/horace.c01.xml'))/*">
            <xsl:choose>
                <xsl:when test="count(/eac-cpf/cpfDescription/description/biogHist/outline) = 6">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error: ', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>

        <!-- ahub file names all change with new download, some files no longer exist -->

        <!-- <xsl:for-each select="document(concat($input_dir, '/ahub/aaschool/gb-1968-aa.c01.xml'))/*"> -->
        <!--     <xsl:choose> -->
        <!--         <xsl:when test="count(/eac-cpf/cpfDescription/description/biogHist/p) = 1 and  -->
        <!--                         string-length(normalize-space(/eac-cpf/cpfDescription/description/biogHist/p)) = 10717"> -->
        <!--             <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/> -->
        <!--         </xsl:when> -->
        <!--         <xsl:otherwise> -->
        <!--             <xsl:value-of select="concat('Error: ', base-uri(.), $cr)"/> -->
        <!--         </xsl:otherwise> -->
        <!--     </xsl:choose> -->
        <!-- </xsl:for-each> -->

        <xsl:for-each select="document(concat($input_dir, '/duke/classic-EADs/ncmutual.c01.xml'))/*">
            <xsl:choose>
                <xsl:when test="/eac-cpf/cpfDescription/description/biogHist/citation = 'From the guide to the North Carolina Mutual Life Insurance Company Archives, and undated, bulk 1898-2008, 1850-2008, (David M. Rubenstein Rare Book &amp; Manuscript Library, Duke University University Archives, Records and History Center, North Carolina Central University)'">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error: ', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>


        <xsl:for-each select="document(concat($input_dir, '/harvard/hua15005.c01.xml'))/*">
            <xsl:choose>
                <xsl:when test="count(/eac-cpf/cpfDescription/description/biogHist/list) = 4">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error: ', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>


        <xsl:for-each select="document(concat($input_dir, '/harvard/hua03006.c01.xml'))/*">
            <xsl:choose>
                <xsl:when test="count(/eac-cpf/cpfDescription/description/biogHist/list) = 5">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error: ', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>


        <xsl:for-each select="document(concat($input_dir, '/umi/clementsmss/ottfam_final.c01.xml'))/*">
            <xsl:choose>
                <xsl:when test="/eac-cpf/cpfDescription/description/biogHist/citation = 'From the guide to the Ott family letters, 1911-1914, (William L. Clements Library, University of Michigan)'
                                and
                                /eac-cpf/cpfDescription/relations/resourceRelation/relationEntry = 'Ott family letters, 1911-1914'">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error: ', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>


        <xsl:for-each select="document(concat($input_dir, '/umi/clementsmss/davised_final.c01.xml'))/*">
            <xsl:choose>
                <xsl:when test="/eac-cpf/cpfDescription/description/biogHist/citation =
                                'From the guide to the Edmund Davis diary, Davis, Edmund diary, 1865, (William L. Clements Library, University of Michigan)'
                                and
                                /eac-cpf/cpfDescription/relations/resourceRelation/relationEntry = 'Edmund Davis diary, Davis, Edmund diary, 1865'">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error: ', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>


        <xsl:for-each select="document(concat($input_dir, '/colu/nnc-ua/ldpd_8429267_ead.c01.xml'))/*">
            <xsl:choose>
                <xsl:when test="/eac-cpf/cpfDescription/description/biogHist/citation = 'From the guide to the Division of Student Affairs Photograph Collection, 2003-2008, [Bulk: 2003-2004], (Columbia University. Rare Book and Manuscript Library)'">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error: ', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>

        <xsl:for-each select="document(concat($input_dir, '/mit/MC.0572-ead.c01.xml'))/*">
            <xsl:choose>
                <xsl:when test="/eac-cpf/cpfDescription/description/biogHist/chronList/chronItem/dateRange[fromDate = '1927' and toDate='1928']">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error: ', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>

        <xsl:for-each select="document(concat($input_dir, '/rmoa/nmsmac418-s.c01.xml'))/*">
            <xsl:choose>
                <xsl:when
                    test="/eac-cpf/cpfDescription/description/biogHist/citation = 'From the guide to the New Mexico Historic American Building Survey (HABS), 1930-1940'">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error: ', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>

        <xsl:for-each select="document(concat($input_dir, '/syru/queen_vic.c01.xml'))/*">
            <xsl:choose>
                <xsl:when
                    test="/eac-cpf/cpfDescription/description/biogHist/citation = 'From the guide to the Queen Victoria Letter, 1866, (Special Collections Research Center, Syracuse University Libraries)'">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error: ', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>

        <xsl:for-each select="document(concat($input_dir, '/uchic/ICU.SPCL.STARRMEX.r001.xml'))/*">
            <xsl:choose>
                <xsl:when
                    test="/eac-cpf/cpfDescription/relations/resourceRelation/relationEntry = 'Starr, Frederick. Mexican Manuscripts. Collection, 1580-1918'">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error: ', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>


        <xsl:for-each select="document(concat($input_dir, '/ude/minimal_ead/mss0272.c01.xml'))/*">
            <xsl:choose>
                <xsl:when
                    test="/eac-cpf/cpfDescription/description/biogHist/citation = 'From the guide to the W. D. Snodgrass correspondence with Daniela Gioseffi, 1977–1984, (University of Delaware Library - Special Collections)'">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error: ', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>

        <xsl:for-each select="document(concat($input_dir, '/utsu/ULA_mss198.c01.xml'))/*">
            <xsl:choose>
                <xsl:when
                    test="/eac-cpf/cpfDescription/description/biogHist/p[matches(. , '^B.Y. Benson Trenton, Utah 40 shares')]">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error: ', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>

        <!-- ahub file names all change with new download, some files no longer exist -->

        <!-- <xsl:for-each select="document(concat($input_dir, '/ahub/guas/gb0248accn2949.c01.xml'))/*"> -->
        <!--     <xsl:choose> -->
        <!--         <xsl:when -->
        <!--             test="/eac-cpf/cpfDescription/description/biogHist/p[matches(. , '^During the 1970s the Ben Line')]  -->
        <!--                   and -->
        <!--                   /eac-cpf/cpfDescription/description/biogHist/p[matches(. , '^Source: http')]"> -->
        <!--             <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/> -->
        <!--         </xsl:when> -->
        <!--         <xsl:otherwise> -->
        <!--             <xsl:value-of select="concat('Error: ', base-uri(.), $cr)"/> -->
        <!--         </xsl:otherwise> -->
        <!--     </xsl:choose> -->
        <!-- </xsl:for-each> -->

        <!-- ahub file names all change with new download, some files no longer exist -->

        <!-- <xsl:for-each select="document(concat($input_dir, '/ahub/birminghamspcoll/900_2002.c01.xml'))/*"> -->
        <!--     <xsl:choose> -->
        <!--         <xsl:when -->
        <!--  test="/eac-cpf/cpfDescription/identity/nameEntry/part = 'Mackay, Alexander Murdoch, 1849-1890, Mechanical engineer, missionary'"> -->
        <!--             <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/> -->
        <!--         </xsl:when> -->
        <!--         <xsl:otherwise> -->
        <!--             <xsl:value-of select="concat('Error: ', base-uri(.), $cr)"/> -->
        <!--         </xsl:otherwise> -->
        <!--     </xsl:choose> -->
        <!-- </xsl:for-each> -->

        <xsl:variable name="aao_1">
            <!--
                The first of 2 files being tested at part of the input record. See below.
            -->
            <xsl:for-each select="document(concat($input_dir, '/aao/asu_az_state_university/bernasconi.c01.xml'))/*">
                <xsl:choose>
                    <xsl:when
                        test="/eac-cpf/cpfDescription/identity/nameEntry/part = 'Bernasconi, Socorro (Socorro Hernandez), 1941-'">
                        <xsl:value-of select="true()"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="false()"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>
        </xsl:variable>
        
        <xsl:for-each select="document(concat($input_dir, '/aao/asu_az_state_university/bernasconi.c02.xml'))/*">
            <!--
                The second of 2 files being tested at part of the input record. See above.
            -->
            <xsl:choose>
                <xsl:when
                    test="/eac-cpf/cpfDescription/identity/nameEntry/part = 'Bernasconi, Santo S., 1943-' and $aao_1=true()">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error: ', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>

        <!-- ahub files all changed names with the new download -->
        <!-- <xsl:for-each select="document(concat($input_dir, '/ahub/gulsc/1080_2002.c01.xml'))/*"> -->
        <!--     <xsl:choose> -->
        <!--         <xsl:when -->
        <!--        test="/eac-cpf/cpfDescription/description/place/placeEntry = 'Great Britain\-\-History\-\-Puritan Revolution, 1642-1660'"> -->
        <!--             <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/> -->
        <!--         </xsl:when> -->
        <!--         <xsl:otherwise> -->
        <!--             <xsl:value-of select="concat('Error: ', base-uri(.), $cr)"/> -->
        <!--         </xsl:otherwise> -->
        <!--     </xsl:choose> -->
        <!-- </xsl:for-each> -->

        <xsl:for-each select="document(concat($input_dir, '/lc/ms997010.c01.xml'))/*">
            <xsl:choose>
                <xsl:when
                    test="/eac-cpf/cpfDescription/description/biogHist/chronList/chronItem/chronItemSet/snac:placeEntry/placeEntry =
                          'Poughkeepsie, N.Y.' 
                          and
                          /eac-cpf/cpfDescription/description/biogHist/chronList/chronItem/chronItemSet/snac:placeEntry/placeEntry =
                          'Washington, D.C.' ">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error: ', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>


        <xsl:for-each select="document(concat($input_dir, '/aps/Mss.B.B121-ead.c01.xml'))/*">
            <xsl:choose>
                <xsl:when
                    test="count(/eac-cpf/cpfDescription/description/biogHist) = 0">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error: ', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>

        <xsl:for-each select="document(concat($input_dir, '/anfra/FRCAC00APH_00000006.r001.xml'))/*">
            <xsl:choose>
                <xsl:when
                    test="normalize-space(/eac-cpf/cpfDescription/identity/nameEntry/part) = 'Pétain, Philippe (1856 - 1951 ; maréchal)'">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error: ', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>


        <xsl:for-each select="document(concat($input_dir, '/lc/mu001001.r095.xml'))/*">
            <xsl:choose>
                <xsl:when
                    test="normalize-space(/eac-cpf/cpfDescription/identity/nameEntry/part) = 'Harvard Crimson'">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error: ', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>


        <xsl:variable name="lc_1">
            <!--
                Test 1 of 3. 
            -->
            <xsl:for-each select="document(concat($input_dir, '/lc/mu001001.c01.xml'))/*">
                <xsl:choose>
                    <xsl:when
                        test="/eac-cpf/cpfDescription/identity/nameEntry/part='Fine, Irving, 1914-1962'
                              and
                              /eac-cpf/cpfDescription/relations/cpfRelation[@xlink:arcrole='http://socialarchive.iath.virginia.edu/control/term#correspondedWith']/relationEntry = 'Schuman, William, 1910-1992'
                              and
                              /eac-cpf/cpfDescription/relations/cpfRelation[@xlink:arcrole='http://socialarchive.iath.virginia.edu/control/term#associatedWith']/relationEntry = 'Ballantine, Edward'">
                        <xsl:value-of select="true()"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="false()"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>
        </xsl:variable>
        
        <xsl:variable name="lc_2">
            <xsl:for-each select="document(concat($input_dir, '/lc/mu001001.r007.xml'))/*">
                <!--
                    Test 2 of 3.
                -->
                <xsl:choose>
                    <xsl:when
                        test="/eac-cpf/cpfDescription/identity/nameEntry/part='Schuman, William, 1910-1992'
                              and
                              /eac-cpf/cpfDescription/relations/cpfRelation[@xlink:arcrole='http://socialarchive.iath.virginia.edu/control/term#correspondedWith']/relationEntry = 'Fine, Irving, 1914-1962'">
                        <xsl:value-of select="true()"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="false()"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each>
        </xsl:variable>

        <xsl:for-each select="document(concat($input_dir, '/lc/mu001001.r008.xml'))/*">
            <!--
                Test 3 of 3.
            -->
            <xsl:choose>
                <xsl:when
                    test="/eac-cpf/cpfDescription/identity/nameEntry/part='Ballantine, Edward'
                          and
                          /eac-cpf/cpfDescription/relations/cpfRelation[@xlink:arcrole='http://socialarchive.iath.virginia.edu/control/term#associatedWith']/relationEntry = 'Fine, Irving, 1914-1962'
                          and $lc_1 = true()
                          and $lc_2 = true()">
                    <xsl:value-of select="concat('Ok: ', base-uri(.), $cr)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat('Error: ', base-uri(.), $cr)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>

        
    </xsl:template>
</xsl:stylesheet>
