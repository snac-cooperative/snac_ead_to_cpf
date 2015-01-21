<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                exclude-result-prefixes="xs"
                version="2.0"
                xmlns:snac="http://socialarchive.iath.virginia.edu/"
                xpath-default-namespace="http://socialarchive.iath.virginia.edu/">
    <xsl:output indent="yes" method="xml"/>
    <!--
        It is best to use run_all.pl to do all the EAD repositories in /data/source/findingAids in a single
        pass. 
        
        ./run_all.pl > rax.log 2>&1 &
        
        If you decide to run this xsl script manually, the script takes an input file called something like
        xxx_faList.txt which is generated using the following "find" terminal command.
        
        File names in xxx_faList.txt must begin with ./ see line 165 below. That is why we pipe the list of
        file names to a Perl one-liner that fixes the format. Note the repository name in 3 places: 2 in the
        "find" command, and 1 in the saxon command.

        find /data/source/findingAids/mit/ -iname "*.xml" | perl -pe '$_ =~ s/\/data\/source\/findingAids\//.\//g' > mit_faList.txt
        
        ../saxon.sh dummy.xml createList.xsl abbreviation="mit" 2>&1 | less

    -->
    <xsl:variable name="cr" select="'&#x0A;'"/>
    <xsl:param name="abbreviation" select="'nysa'"/>
    <xsl:variable name="groupBy" as="xs:integer">500</xsl:variable>

    <!-- 
         aao    Arizona Archives Online
         aar    Archives of American Art
         afl    Archives Florida, Florida Center for Library Automation 
         ahub   ArchivesHub (UK)
         anfra  Archives nationales (France)
         aps    American Philosophical Society
         bnf    BibliothÃ¨que nationale de France 
         byu    BYU 
         colu   Columbia University
         crnlu  Cornell University
         duke   Duke University
         fivecol        Five Colleges
         harvard        Harvard
         inu    Indiana University
         lds    LDS
         loc    Library of Congress
         meas   Maine Archive Search
         mhs    Minnesota Historical Society
         mit    MIT
         ncsu   NC State
         nlm    National Library of Medicine
         nwda   Northwest Digital Archives (NWDA)
         nwu    Northwestern University
         nypl   NYPL
         nyu    New York University
         oac    Online Archive of California
         ohlink OhioLink
         pacscl PACSCL
         pu     Princeton University
         riamco Rhode Island Archival & Manuscript Collections Online (RIAMCO)
         rmoa   Rocky Mountain Online Archive (RMOA)
         rutu   Rutgers University
         sia    Smithsonian Archives
         syru   Syracuse University 
         taro   Texas Archival Resources Online (TARO) 
         ual    University of Alabama
         uchic  University of Chicago 
         uct    University of Connecticut
         ude    University of Delaware
         ufl    University of Florida
         uil    University of Illinois
         uks    University of Kansas
         umd    University of Maryland
         umi    Universityh of Michigan Bentley & Special Collections
         umn    University of Minnesota
         unc    UNC chapel Hill
         une    University of Nebraska
         utsa   Utah (State) Archives
         utsu   Utah State University
         uut    University of Utah
         vah    Virginia Heritage
         yale   Yale University

    -->
    <xsl:variable name="faListPath">
        <!-- look in the current directory for *_faList.txt -->
        <!-- <xsl:text>../../source/findingAids/</xsl:text> -->
        <xsl:value-of select="$abbreviation"/>
        <xsl:text>_faList.txt</xsl:text>
    </xsl:variable>

    <xsl:variable name="rawList">
        <xsl:value-of select="unparsed-text($faListPath)"/>
    </xsl:variable>

    <xsl:variable name="listLines" as="xs:string*" select="tokenize($rawList, '\s+')"/>

    <xsl:variable name="lineCount">
        <xsl:value-of select="count($listLines)-1"/>
    </xsl:variable>

    <xsl:variable name="count" as="xs:integer">
        <xsl:value-of select="ceiling($lineCount div $groupBy)"/>
    </xsl:variable>

    <xsl:variable name="listInitial">
        <list xmlns="http://socialarchive.iath.virginia.edu/">
            <xsl:for-each select="$listLines[normalize-space()]">
                <!-- 
                     Use node() or normalize-space() as a boolean to prevent processing of the empty node at
                     the end of the sequence. Our call to tokenize() creates an
                     empty string for at the end.
                -->
                <i>
                    <xsl:value-of select="."/>
                </i>
            </xsl:for-each>
        </list>
    </xsl:variable>

    <xsl:template name="tpt_main" match="/" xmlns="http://socialarchive.iath.virginia.edu/" >

        <!-- Write the output in the current directory. We can copy it elsewhere as necessary. -->
        <xsl:message>
            <xsl:value-of select="concat('Using abbreviation: ', $abbreviation, $cr)"/>
            <xsl:value-of select="concat('        Input file: ', $faListPath, $cr)"/>
            <xsl:value-of select="concat('       Output file: ', $abbreviation, '_list.xml', $cr)"/>
        </xsl:message>
        
        <xsl:result-document href="{$abbreviation}_list.xml">

            <list sourceCode="{$abbreviation}" fileCount="{$lineCount}" pStart="1" pEnd="{$count}">
                <xsl:text>&#xA; </xsl:text>
                <xsl:comment>
                    <xsl:text>  Number of groups: </xsl:text>
                    <xsl:value-of select="$count"/>
                    <xsl:text> Group size: </xsl:text>
                    <xsl:value-of select="$groupBy"/>
                    <xsl:text>  </xsl:text>
                </xsl:comment>
                <xsl:text>&#xA; </xsl:text>
                <xsl:for-each select="1 to $count">
                    <!--
                        Use a variable gpos for group position() so we don't have to figure out what the
                        context is and which block of code this position() refers too, since we have multiple
                        meanings of position() based on the (implied) context.
                    -->
                    <xsl:variable name="gpos" select="position()" as="xs:integer"/>
                    
                    <!--xsl:variable name="groupPosition" select="position()"/-->

                    <xsl:variable name="start" as="xs:integer">
                        <xsl:choose>
                            <xsl:when test="$gpos = 1">1</xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="(($gpos - 1) * $groupBy) + 1"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <group n="{$gpos}">

                        <!-- <xsl:message> -->
                        <!--     <xsl:value-of select="concat('gp: ', $gpos)"/> -->
                        <!--     <xsl:value-of select="$start"/> -->
                        <!--     <xsl:text> to </xsl:text> -->
                        <!--     <xsl:value-of select="($start + $groupBy)-1"/> -->
                        <!-- </xsl:message> -->
                        
                        <!--
                            The position() in the for-each select is in the inner context of the for-each. We
                            can't use a var for position() in the select, so we just have to know the implied
                            context. This kind of rains on our parade of using variables to clarify.
                        -->

                        <xsl:for-each
       	                    select="$listInitial/list/i[position() &gt;= $start and
                                    position() &lt;= (($start + $groupBy)-1)]">

                            <xsl:variable name="filep" select="position()"/>

                            <!-- <xsl:message> -->
                            <!--     <xsl:value-of select="concat('empty? ', boolean(normalize-space(.)))"/> -->
                            <!-- </xsl:message> -->
                            <!-- <xsl:message> -->
                            <!--     <xsl:value-of select="concat('fp: ', $filep, ' gs: ', $gpos &gt;= $start, ' gsg: ',$gpos &lt;= (($start + $groupBy)-1))"/> -->
                            <!-- </xsl:message> -->

                            <!--
                                Var filep with a name different from gpos because we have at least two
                                different (contexts) positions.
                            -->

                            <!-- <xsl:message> -->
                            <!--     <xsl:value-of select="concat('ei: (', $gpos, '/', $filep, '): ')"/> -->
                            <!--     <xsl:copy-of select="."/> -->
                            <!-- </xsl:message> -->
                            <xsl:choose>
                                <xsl:when test="contains(.,'./')">
                                    <i n="{$filep + ($start - 1)}">
                                        <!--
                                            New code has a base path that it pre-pends to the filename, so
                                            don't put ../ or ./ or any prefix on the filenames.
                                        -->
                                        <!-- <xsl:text>../findingAids/</xsl:text> -->
                                        <xsl:text>findingAids</xsl:text>
                                        <!-- <xsl:value-of select="$abbreviation"/> -->
                                        <xsl:value-of select="substring(.,2)"/>
                                    </i>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:message>
                                        <xsl:value-of select="concat('Error, filename must begin with dot slash at group/position: ',
                                                              $gpos, '/', $filep, ' value: ', ., $cr)"/>
                                    </xsl:message>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:for-each>
                    </group>
                </xsl:for-each>
            </list>
        </xsl:result-document>
    </xsl:template>

</xsl:stylesheet>
