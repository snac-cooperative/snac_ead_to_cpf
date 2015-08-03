<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet exclude-result-prefixes="#all"
		version="2.0"
		xmlns:functx="http://www.functx.com"
		xmlns:snac="http://socialarchive.iath.virginia.edu/"
		xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
		xmlns:xlink="http://www.w3.org/1999/xlink"
		xmlns:xs="http://www.w3.org/2001/XMLSchema"
		xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

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
	
	This file contains functions used by eadToCpf.xsl (and related XSL code.)
    -->

    
    <!--
	snac:css-style('underline') returns a string compatible with a style="" attribute.
    -->
    <xsl:function name="snac:css-style">
	<xsl:param name="arg"/>
	<xsl:choose>
	    <xsl:when test="$arg ='underline'">
		<xsl:text>text-decoration: underline;</xsl:text>
	    </xsl:when>
	    <xsl:when test="$arg = 'italic'">
		<xsl:text>font-style: italic;</xsl:text>
	    </xsl:when>
	    <xsl:when test="$arg = 'super'">
		<xsl:text>vertical-align: super;</xsl:text>
	    </xsl:when>
	    <xsl:when test="$arg = 'bold'">
		<xsl:text>font-weight: bold;</xsl:text>
	    </xsl:when>
	    <xsl:when test="$arg = 'bolditalic'">
		<!--
		    Yes, it is real. render="bolditalic"
		    /data/source/findingAids/cjh/ajhs-ead-snac/109173_NoahBenevolentSociety.xml
		-->
		<xsl:text>font-weight: bold;</xsl:text>
		<xsl:text> font-style: italic;</xsl:text>
	    </xsl:when>
	    <xsl:otherwise>
		<xsl:value-of select="concat('/* unknown ', $arg , '*/')"/>
		<xsl:message>
		    <xsl:value-of select="concat('Warning: unknown style: ', $arg, $cr)"/>
		</xsl:message>
	    </xsl:otherwise>
	</xsl:choose>
    </xsl:function>

    <!--
	Parse a name and return the name portion in direct order.

	I'm guessing that \p{L} is match Unicode letter
	http://www.regular-expressions.info/unicode.html
	http://stackoverflow.com/questions/14891129/regular-expression-pl-and-pn
    -->

    <xsl:function name="snac:directPersnameOne">
	<xsl:param as="xs:string" name="tempString"/>
	<xsl:choose>
	    <xsl:when test="(contains($tempString,',')) and (matches($tempString,'^[\p{L}]'))">
		<xsl:analyze-string flags="x"
				    regex="
					   ^
					   ( ([\p{{L}}]+\.?[\-'\s]?)+ )	
					   (,\s)?			
					   (([\p{{L}}]+\.?[\-'\s]?)*)			
					   (\( (([\p{{L}}]+\.?[\-'\s]?)+) \))?
					   (.*?)
					   "
				    select="normalize-space($tempString)">
		    <xsl:matching-substring>
			<xsl:variable name="buildString">
			    <xsl:value-of select="regex-group(4)"/>
			    <xsl:text> </xsl:text>
			    <xsl:value-of select="regex-group(1)"/>
			    <!--xsl:text>::1::</xsl:text>
				<xsl:value-of select="regex-group(1)"/>
				<xsl:text>::2::</xsl:text>
				<xsl:value-of select="regex-group(2)"/>
				<xsl:text>::3::</xsl:text>
				<xsl:value-of select="regex-group(3)"/>
				<xsl:text>::4::</xsl:text>
				<xsl:value-of select="regex-group(4)"/>
				<xsl:text>::5::</xsl:text>
				<xsl:value-of select="regex-group(5)"/>
				<xsl:text>::6::</xsl:text>
				<xsl:value-of select="regex-group(6)"/>
				<xsl:text>::7::</xsl:text>
				<xsl:value-of select="regex-group(7)"/>
				<xsl:text>::8::</xsl:text>
				<xsl:value-of select="regex-group(8)"/>
				<xsl:text>::9::</xsl:text>
				<xsl:value-of select="regex-group(9)"/-->
			</xsl:variable>
			
			<xsl:choose>
			    <!--
				I do not think this first when test actually works.
			    -->
			    <xsl:when test="normalize-space($buildString)=''">
				<xsl:value-of select="normalize-space($tempString)"/>
				<xsl:message>
				    <xsl:text>Look in the snac:directPersnameOne function.</xsl:text>
				</xsl:message>
			    </xsl:when>
			    <xsl:otherwise>
				<xsl:value-of select="normalize-space($buildString)"/>
			    </xsl:otherwise>
			</xsl:choose>
			
		    </xsl:matching-substring>
		    <xsl:non-matching-substring> </xsl:non-matching-substring>
		</xsl:analyze-string>
	    </xsl:when>
	    <xsl:otherwise>
		<xsl:value-of select="$tempString"/>
	    </xsl:otherwise>
	    <!-- if no , then what? -->
	</xsl:choose>
    </xsl:function>
    
    <!--
	Parse a name and return the name portion in direct order. Seems a tiny bit more robust than "one" above.

	I'm guessing that \p{L} is match Unicode letter
	http://www.regular-expressions.info/unicode.html
	http://stackoverflow.com/questions/14891129/regular-expression-pl-and-pn
    -->

    <xsl:function name="snac:directPersnameTwo">
	<xsl:param as="xs:string" name="tempString"/>
	<xsl:choose>
	    <xsl:when test="(contains($tempString,',')) and (matches($tempString,'^[\p{L}]'))">
		<xsl:analyze-string flags="x"
				    regex="
					   ^
					   ( ([\p{{L}}]+\.?[\-'\s]?)+ )	
					   (,\s)?			
					   (([\p{{L}}]+\.?[\-'\s]?)*)			
					   (\( (([\p{{L}}]+\.?[\-'\s]?)+) \))?
					   (.*?)
					   "
				    select="normalize-space($tempString)">
		    <xsl:matching-substring>
			<xsl:variable name="buildString">
			    <xsl:choose>
				<xsl:when test="regex-group(7)">
				    <xsl:value-of select="regex-group(7)"/>
				</xsl:when>
				<xsl:otherwise>
				    <xsl:value-of select="regex-group(4)"/>
				</xsl:otherwise>
			    </xsl:choose>
			    <xsl:text> </xsl:text>
			    <xsl:value-of select="regex-group(1)"/>
			    <!--xsl:text>::1::</xsl:text>
				<xsl:value-of select="regex-group(1)"/>
				<xsl:text>::2::</xsl:text>
				<xsl:value-of select="regex-group(2)"/>
				<xsl:text>::3::</xsl:text>
				<xsl:value-of select="regex-group(3)"/>
				<xsl:text>::4::</xsl:text>
				<xsl:value-of select="regex-group(4)"/>
				<xsl:text>::5::</xsl:text>
				<xsl:value-of select="regex-group(5)"/>
				<xsl:text>::6::</xsl:text>
				<xsl:value-of select="regex-group(6)"/>
				<xsl:text>::7::</xsl:text>
				<xsl:value-of select="regex-group(7)"/>
				<xsl:text>::8::</xsl:text>
				<xsl:value-of select="regex-group(8)"/>
				<xsl:text>::9::</xsl:text>
				<xsl:value-of select="regex-group(9)"/-->
			</xsl:variable>
			
			<xsl:choose>
			    <!-- I do not think this first when test actually works. -->
			    <xsl:when test="normalize-space($buildString)=''">
				<xsl:value-of select="normalize-space($tempString)"/>
				<xsl:message>
				    <xsl:text>Look in the snac:directPersnameTwo function.</xsl:text>
				</xsl:message>
			    </xsl:when>
			    <xsl:otherwise>
				<xsl:value-of select="normalize-space($buildString)"/>
			    </xsl:otherwise>
			</xsl:choose>
			
		    </xsl:matching-substring>
		    <xsl:non-matching-substring/>
		</xsl:analyze-string>
	    </xsl:when>
	    <xsl:otherwise>
		<xsl:value-of select="$tempString"/>
	    </xsl:otherwise>
	    <!-- if no, then what? -->
	</xsl:choose>
    </xsl:function>
    
    
    <xsl:function name="snac:getDateFromUnitdate">
	<!-- This function dates a string from a unitdate and returns a string with just numbers in it;
	     When called, it is tokenized an only the four digital numbers (years) are used. -->
	<xsl:param as="xs:string" name="tempString"/>
	<xsl:variable name="dateNumbersOne">
	    <xsl:value-of select="normalize-space(replace($tempString,'[^\d\-]',' '))"/>
	</xsl:variable>
	<xsl:variable name="dateNumbersTwo">
	    <!-- Complete dates that are of the following pattern: 1848-51; change to 1848-1851 -->
	    <xsl:choose>
		<xsl:when test="matches($dateNumbersOne,'^[\d]{4}-[\d]{2}$')">
		    <xsl:variable name="century">
			<xsl:value-of select="substring($dateNumbersOne,1,2)"/>
		    </xsl:variable>
		    <xsl:value-of select="normalize-space(substring-before($dateNumbersOne,'-'))"/>
		    <xsl:text> </xsl:text>
		    <xsl:value-of select="$century"/>
		    <xsl:value-of select="normalize-space(substring-after($dateNumbersOne,'-'))"/>
		</xsl:when>
		<xsl:otherwise>
		    <xsl:value-of select="normalize-space(replace($dateNumbersOne,'-',' '))"/>
		</xsl:otherwise>
	    </xsl:choose>
	</xsl:variable>
	<xsl:value-of select="$dateNumbersTwo"/>
    </xsl:function>

    <xsl:function name="snac:testDate">
	<xsl:param name="tempString" as="xs:string"/>
	<xsl:choose>
	    <xsl:when test="number($tempString) = number($tempString)">
		<xsl:choose>
		    <xsl:when test="number($tempString) &gt; 2099">
			<xsl:value-of select="boolean(0)"/>
		    </xsl:when>
		    <xsl:otherwise>
			<xsl:value-of select="boolean(1)"/>
		    </xsl:otherwise>
		</xsl:choose>		
	    </xsl:when>
	    <xsl:otherwise>
		<xsl:value-of select="boolean(0)"/>
	    </xsl:otherwise>
	</xsl:choose>
    </xsl:function>

    <!--
        Perhaps specialized. Replace ' . ' with ' '
        <relationEntry>Pierre-Jules Hetzel, . Papiers.. NAF 16932-17152., XIXe s.</relationEntry>
    -->
    <xsl:function name="snac:removeFloatingDot">
	<xsl:param name="tempString" as="xs:string"/>
	<xsl:value-of select="replace($tempString, '(\s+\.\s+)', ' ')"/>
    </xsl:function>

    <!--
        Perhaps specialized. Replace ., with '. '
        <relationEntry>Pierre-Jules Hetzel, . Papiers.. NAF 16932-17152., XIXe s.</relationEntry>
    -->
    <xsl:function name="snac:dotComma2Dot">
	<xsl:param name="tempString" as="xs:string"/>
	<xsl:value-of select="replace($tempString, '(\.,\s*)', '. ')"/>
    </xsl:function>


    <!--
        Clean . with zero or more whitespace and as many of those as possible, replace with a single '. '
        <relationEntry>Pierre-Jules Hetzel, . Papiers.. NAF 16932-17152., XIXe s.</relationEntry>
    -->
    <xsl:function name="snac:removeDoubleDot">
	<xsl:param name="tempString" as="xs:string"/>
	<xsl:value-of select="replace($tempString, '(\.\s*)+', '. ')"/>
    </xsl:function>


    <!--
	For cleaning up "Corporation, , 1901-2001" as well as "Corporation, ," and "Bowen,, Richard, "
    -->
    <xsl:function name="snac:removeDoubleComma">
	<xsl:param name="tempString" as="xs:string"/>
	<xsl:value-of select="replace($tempString, '(,\s*)+', ', ')"/>
    </xsl:function>

    <!--
	Trim off leading whitespace and comma, any number in any combination.
    -->
    <xsl:function name="snac:removeLeadingComma">
	<xsl:param name="tempString" as="xs:string"/>
	<xsl:value-of select="replace($tempString, '^[\s,]+', '')"/>
    </xsl:function>


    <xsl:function name="snac:removeFinalComma">
	<xsl:param name="tempString" as="xs:string"/>
	<xsl:choose>
	    <xsl:when test="ends-with(normalize-space($tempString),',') or ends-with(normalize-space($tempString),';')">
		<xsl:value-of select="substring(normalize-space($tempString),1,(string-length(normalize-space($tempString))-1))"/>
	    </xsl:when>
	    <xsl:otherwise>
		<xsl:value-of select="normalize-space($tempString)"/>
	    </xsl:otherwise>
	</xsl:choose>
    </xsl:function>
    
    <xsl:function name="snac:countTokens">
	<!-- This function merely counts the number of tokens in a string. -->
	<xsl:param name="tempString" as="xs:string"/>
	<xsl:value-of select="count(tokenize(normalize-space(snac:removePunctuation($tempString)),'\s'))"/>
    </xsl:function>

    
    <xsl:function name="snac:escape-for-regex" as="xs:string">
	<xsl:param name="arg" as="xs:string?"/>
	
	<xsl:variable name="var">
	    <xsl:sequence
		select=" 
			replace($arg,
			'(\.|\[|\]|\\|\||\-|\^|\$|\?|\*|\+|\{|\}|\(|\))','\\$1')
			"
		/>
	</xsl:variable>
	<xsl:value-of select="replace($var, '/', '/')"/>
    </xsl:function>

    <xsl:function name="snac:path-minus-base">
	<xsl:param name="base" as="xs:string"/>
	<xsl:param name="tempString" as="xs:string"/>
	<xsl:value-of select="replace($tempString, concat('^.*', $base, '/(.*)/.*?$'),'$1','i')"/>
    </xsl:function>

    <xsl:function name="snac:getBaseIdName">
	<xsl:param name="tempString" as="xs:string"/>
	<xsl:value-of select="replace($tempString,'(.*)(\.xml)','$1','i')"/>
    </xsl:function>

    <xsl:function name="snac:getFileName">
	<xsl:param name="tempString" as="xs:string"/>
	<xsl:value-of select="replace($tempString,'(.*/)(.*\.xml)','$2','i')"/>
    </xsl:function>
    
    <xsl:function name="snac:testYearDate">
	<xsl:param name="tempString" as="xs:string"/>
	<xsl:choose>
	    <xsl:when test="number($tempString) = number($tempString)">
		<xsl:choose>
		    <xsl:when test="number($tempString) &gt; 2099">
			<xsl:value-of select="boolean(0)"/>
		    </xsl:when>
		    <xsl:otherwise>
			<xsl:value-of select="boolean(1)"/>
		    </xsl:otherwise>
		</xsl:choose>		
	    </xsl:when>
	    <xsl:otherwise>
		<xsl:value-of select="boolean(0)"/>
	    </xsl:otherwise>
	</xsl:choose>
    </xsl:function>
    
    <xsl:function name="snac:getDateFromPersname">
        <xsl:param as="xs:string" name="tempString"/>
        <!--
            Jan 5 2015 Switch this over to bfl/dfl, etc. as in other date code, and other character classes
            for flourished and circa.
            
            May 12 2015 This won't parse (nnnn-nnnn) apparently the parens cause problems. So we clean them up
            here because cleaning in the calling code could break something. Cleaning is safer than trying to
            upgrade the regex.
        -->
        
        <xsl:variable name="clean_string" select="replace($tempString, '\(|\)', '')"/>
        
        <xsl:choose>
            <xsl:when
                test="matches($clean_string, '(^.+?\s)
                      (
                      (([fl\.]*\s*) ([ca\.]*\s*)[\d]{3,4}\??\- ([fl\.]*\s*) ([ca\.]*\s*) [\d]{3,4}\??)
                      |	
                      (([fl\.]*\s*) ([ca\.]*\s) [\d]{3,4}\??\-)
                      |
                      (([bdfl\.]*\s*) ([ca\.]*\s*)[\d]{3,4}\??)
                      )
                      ($|([\D].*$))'
                      ,
                      'x')"> 
                <xsl:choose>
                    <xsl:when test="matches($clean_string,
                                    '(^.+?\s) ((fl\.?\s*)? (ca?\.?\s*)?[\d]{3,4}\??\- (fl\.?\s*)? (ca?\.?\s*)? [\d]{3,4}\??)($|([\D].*$))', 'x')">
                        <xsl:value-of
                            select="replace($clean_string,
                                    '(^.+?\s) ((fl\.?\s*)? (ca?\.?\s*)?[\d]{3,4}\??\- (fl\.?\s*)? (ca?\.?\s*)? [\d]{3,4}\??)($|([\D].*$))'
                                    ,'$2', 'x')"/>
                    </xsl:when>
                    
                    <xsl:when test="matches($clean_string,
                                    '(^.+?\s) ((fl\.?\s*)? (ca?\.?\s*)? [\d]{3,4}\??\-)($|([\D].*$))', 'x')">
                        <xsl:value-of
                            select="replace($clean_string,
                                    '(^.+?\s) ((fl\.?\s*)? (ca?\.?\s*)? [\d]{3,4}\??\-)($|([\D].*$))'
                                    ,'$2', 'x')"/>
                    </xsl:when>
                    
                    <xsl:when test="matches($clean_string,
                                    '(^.+?\s) (([bdfl\.]*\s*) (ca?\.?\s*)?[\d]{3,4}\??) ($|([\D].*$))', 'x')">
                        <xsl:value-of
                            select="replace($clean_string,
                                    '(^.+?\s) (([bdfl\.]*\s*) (ca?\.?\s*)?[\d]{3,4}\??) ($|([\D].*$))', '$2', 'x')"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <!-- 
                             It is unclear how this code will ever execute. The top matches() has to hit first, and
                             if so, then one of the inner matches() must hit as well, thus this code never runs. If
                             you want to keep this, maybe a log message would be good.
                        -->
                        <xsl:value-of select="$clean_string"/>
                    </xsl:otherwise>
                    <!-- The original regex worked fine until a bug in Saxon stopped it from parsing. -->
                    <!-- <xsl:value-of -->
                    <!--     select="replace($clean_string,' -->
                    <!-- 	    (^.+?\s) -->
                    <!-- 	    ( -->
                    <!-- 	    ((fl\.\s)? (ca\.\s)?[\d]{3,4}\??\- (fl\.\s)? (ca\.\s)? [\d]{3,4}\??) -->
                    <!-- 	    |	 -->
                    <!-- 	    ((fl\.\s)? (ca\.\s)? [\d]{3,4}\??\-) -->
                    <!-- 	    | -->
                    <!-- 	    ((([b|d]\.\s)|(fl\.\s))(ca\.\s)?[\d]{3,4}\??)			 -->
                    <!-- 	    ) -->
                    <!-- 	    ( -->
                    <!-- 	    $ -->
                    <!-- 	    | -->
                    <!-- 	    ([\D].*$) -->
                    <!-- 	    ) -->
                    <!-- 	    ','$2','x')" -->
                    <!--     /> -->
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>0</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function> <!-- snac:getDateFromPersname -->
        
    <xsl:function name="snac:stripStringAfterDateInPersname">
        <xsl:param as="xs:string" name="tempString"/>
        <!--
            This is not code that strips "\-\-Correspondence." from the ends of names. See snac:removeBeforeHyphen2().
            
            Note that this uses simplfied character classes [bdfl\.?] and [ca\.] which seems to work well. It
            isn't as specific as some other uses, but is much simplier. Matching too much has not (yet) been a
            bug in this code. And it fixed several other bugs where the old code failed to match common date
            formats.

            Dec 18 2014 Don't do anything if there are parens around any part of the date. In this case other
            code was unable to recognize a date, so we should not do any cleaning.

            Dec 17 2014 Mod 3rd when to match "fl" and not just "fl.".
            
            Problem with strings that have internal newline:
            <persname encodinganalog="700">Grigsby, Hugh Blair, 1806-
            1881.</persname>
            
            Break the replace() into 3 passes because the single large regexp (below) crashes saxon
            with a java exception.
            
            java.lang.StringIndexOutOfBoundsException: String index out of range: 4
            at java.lang.String.charAt(String.java:686)
            at net.sf.saxon.regex.BMPString.charAt(BMPString.java:33)
            at net.sf.saxon.regex.REMatcher.subst(REMatcher.java:755)
            at net.sf.saxon.regex.ARegularExpression.replace(ARegularExpression.java:123)
            at net.sf.saxon.functions.Replace.eval(Replace.java:209)
            at net.sf.saxon.functions.Replace.evaluateItem(Replace.java:123)
            at net.sf.saxon.functions.Replace.evaluateItem(Replace.java:27)
            ...
        -->
        <xsl:variable name="result">
            <xsl:choose>
                <xsl:when test="matches($tempString, '\(.*\d+.*\)')">
                    <!--
                        Dec 18 2014 New sanity check.

                        We found a number inside parens. Don't modify $tempString. Might be like this:

                        Kipling, Charlotte. ( b.1919 d.1992)

                        /data/source/findingAids/ahub/f_6946.xml
                    -->
                    <xsl:value-of select="$tempString"/>
                </xsl:when>
                <!--
                    Change "\- " to "\s*\-\s*" because we have cases with multiple whitespace around the hyphen.
                    Use flag 'm' so that $ means end of line and not newline.
                    
                    This used to say: "[\D].*$" which says match a non-digit then zero or more of any
                    character. That means lines with a non-digit followed by a date can be
                    truncated. Fixed. Original code at the end of the function.
                    
                    fn: /data/source/findingAids/ahub/f_20516.xml
                    orig:Bell, (Arthur) Clive (Heward), 1881-1964; Bell, Vanessa, 1879-1961; Jackson, Maria, d. 1891?
                    stripStringAfterDateInPersname: result:Bell, (Arthur) Clive (Heward), 1881-1964
                -->
                
                <xsl:when test="matches($tempString,
                                '(^.+?\s) ([bfl\.\?]*\s*[ca\.]*\s*\d{3,4}[\s\?]*\-[\s\?]*[dfl\.]*\s* [ca\.]*\s*\d{3,4}\?*)($|([\D]+$))', 'xm')">
                    <!--
                        Dec 15 2014 Add alternation c\.*\s* with each ca.\s in this block so we match dates c
                        nnnnn which were not being matched, and resulted in the death date being lost.
                        
                        /data/source/findingAids/ahub/f_4188.xml
                        
                        fixDatesRemoveParens result: Robert Valentine, 1674-c. 1735, composer
                        normalFinal: Valentine, Robert., 1647-   type: regExed cpf: persname
                        
                        In pass1 we clean up an whitespace following the hyphen, but conservatively only for the
                        simply case of 3 or 4 digits.
                        
                        In pass2, $2 is the whole date: '1806- 1881' (yes it can be hyphen space)
                        Use flag 'm' so that $ means end of line and not newline.
                    -->
                    
                    <xsl:variable name="pass1">
                        <xsl:value-of
                            select="replace($tempString, '([\d]{3,4})\s*-\s*([\d]{3,4})', '$1-$2', 'm')"/>
                    </xsl:variable>
                    
                    <xsl:variable name="pass2">
                        <!--
                            The Java regex engine throws an exception if the regex gets any longer, so we have
                            to break up our cleaning into two expressions. The first is b nnnn - d|fl nnn and
                            the second is fl nnnn - d|fl nnnn. The difference being is the first date born or
                            flourished. Doing an alternation pushed Java's regex engine over the edge.
                        -->
                        <xsl:value-of
                            select="replace($pass1,
                                    '(^.+?\s) ([flb\.\?]*\s*([ca\.]*\s*)*[\d]{3,4}\??\s* \- \s*[fld\.\?]*\s*[ca\.]*\s*[\d]{3,4}\??)($|([\D]+$))',
                                    '$1$2',
                                    'xm')"/>
                        
                    </xsl:variable>
                    <xsl:value-of select="$pass2"/>
                </xsl:when>
                <xsl:when test="matches($tempString,
                                '(^.+?\s)([bfl\.\s\?]* (ca\.\s)? [\d]{3,4}\??\-)($|([\D]+$))', 'x')">
                    <!--
                        Dec 19 2014 Modify to [bfl\.\s\?]* which matches other code and seems to work better.
                        
                        Note: this has a trailing - hyphen, therefore only born/flourished date is valid.
                        
                        At the end of $tempString (the name string) the old "[\D].*$" matches "d. 1842" which
                        is part of a date, thus the old code truncated good dates of that format. The
                        modification above (matches()) and below (replace()) allows no digits following the -
                        hyphen.
                        
                        The original regex is below in a test="false()" code block.
                    -->
                    <xsl:value-of
                        select="replace($tempString,
                                '(^.+?\s)([bfl\.\s\?]* (ca\.\s)? [\d]{3,4}\??\-)($|([\D]+$))','$1$2', 'x')"/>
                </xsl:when>
                
                <xsl:when test="matches($tempString,
                                '(^.+?\s)([bdfl\.\s]*[ca\.\s]*?[\d]{3,4}\??)($|([\D]+$))', 'x')">
                    <!--
                        Dec 18 2014 Change the end of line test to not match or truncate anything with digits. Be conservative
                        
                        Note: There is no trailing - hyphen, so this could be born/died/flourished date, thus
                        the character class is [bdfl] and not [bfl] or [dfl].
                        
                        This is what used to happen:

                        orig: Brady, Mathew B., 1823 (ca.)-1896.
                        final: Brady, Mathew B., 1823
                    -->
                    <xsl:value-of
                        select="replace($tempString,
                                '(^.+?\s)([bdfl\.\s]*[ca\.\s]*?[\d]{3,4}\??)($|([\D]+$))','$1$2', 'x')"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$tempString"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:message>
            <xsl:text>stripStringAfterDateInPersname:   orig:</xsl:text>
            <xsl:value-of select="concat($tempString, $cr)"/>
            <xsl:text>stripStringAfterDateInPersname: result:</xsl:text>
            <xsl:value-of select="$result"/>
        </xsl:message>

        <xsl:value-of select="$result"/>
        
        <xsl:if test="false()">
            <!--
                This is the old code (disabled by false()) which worked just fine, but ran afoul of a bug in
                newer versions Saxon that threw the exception noted above.
            -->
            <xsl:choose>
                <xsl:when
                    test="matches($tempString,'	
                          (^.+?\s)
                          (
                          ((fl\.\s)? (ca\.\s)?[\d]{3,4}\??\- (fl\.\s)? (ca\.\s)? [\d]{3,4}\??)
                          |	
                          ((fl\.\s)? (ca\.\s)? [\d]{3,4}\??\-)
                          |
                          ((([b|d]\.\s)|(fl\.\s))(ca\.\s)?[\d]{3,4}\??)			
                          )
                          (
                          $
                          |
                          ([\D].*$)
                          )
                          ','x')">
                    <xsl:value-of
                        select="replace($tempString,'
                                (^.+?\s)
                                (
                                ((fl\.\s)? (ca\.\s)?[\d]{3,4}\??\- (fl\.\s)? (ca\.\s)? [\d]{3,4}\??)
                                |
                                ((fl\.\s)? (ca\.\s)? [\d]{3,4}\??\-)
                                |
                                ((([b|d]\.\s)|(fl\.\s))(ca\.\s)?[\d]{3,4}\??)
                                )
                                (
                                $
                                |
                                ([\D].*$)
                                )
                                ','$1$2','x')"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$tempString"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
    </xsl:function>
    
    <xsl:function name="snac:removeInitialNonWord">
        <xsl:param name="tempString"/>
        <xsl:choose>
            <xsl:when test="matches($tempString,'
                            ^
                            ([\W]+)
                            (.*)
                            $
                            ','x')">
                <xsl:value-of select="normalize-space(replace($tempString,'
                                      ^
                                      ([\W]+)
                                      (.*)
                                      $
                                      ','$2','x'))"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$tempString"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <!--
        <xsl:function name="snac:stripStringAfterDateInPersname">
        <xsl:param as="xs:string" name="tempString"/>
        <xsl:choose>
        <xsl:when test="matches($tempString,'(,?\s?([b|d]\.\s)?(active\s)?(fl\.\s)?(ca\.\s)?([\d]{3,4})\??\-?(active\s)?(fl\.\s)?(ca\.\s)?([\d]{3,4})?\??)')">
        <xsl:value-of
        select="replace($tempString,'^(.*?)(([b|d]\.\s)?(active\s)?(fl\.\s)?(ca\.\s)?([\d]{3,4})\??\-?(active\s)?(fl\.\s)?(ca\.\s)?([\d]{3,4})?\??\d+)(.*$)','$1$2.')"
        />
        </xsl:when>
        <xsl:otherwise>
        <xsl:value-of select="$tempString"></xsl:value-of>
        </xsl:otherwise>
        </xsl:choose>
        </xsl:function>
        
        
        xsl:function name="snac:stripStringAfterDateInPersname">
        <xsl:param as="xs:string" name="tempString"/>
        <xsl:choose>
        <xsl:when test="matches($tempString,'(,?\s?([b|d]\.\s)?(active\s)?(fl\.\s)?(ca\.\s)?([\d]{3,4})\??\-?(active\s)?(fl\.\s)?(ca\.\s)?([\d]{3,4})?\??)')">
        <xsl:value-of
        select="replace($tempString,'^(.*?)(([b|d]\.\s)?(active\s)?(fl\.\s)?(ca\.\s)?([\d]{3,4})\??\-?(active\s)?(fl\.\s)?(ca\.\s)?([\d]{3,4})?\??)(.*$)','$1$2.')"
        />
        </xsl:when>
        <xsl:otherwise>
        <xsl:value-of select="$tempString"></xsl:value-of>
        </xsl:otherwise>
        </xsl:choose>
        </xsl:function>
    -->
    
    <!--
        Replace any amount of space plus comma followed by space with comma space.
    -->
    <xsl:function name="snac:fixSpaceComma">
        <xsl:param name="tempString" as="xs:string"/>
        <xsl:value-of select="normalize-space(replace($tempString,'\s+,',', '))"/>
    </xsl:function>
    
    <xsl:function name="snac:removeApostropheLowercaseSSpace">
        <xsl:param as="xs:string" name="nameString"/>
        <xsl:variable name="regEx" as="xs:string">
            <xsl:text>'s\s?</xsl:text>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="matches($nameString,$regEx)">
                <xsl:value-of select="normalize-space(replace($nameString,$regEx,''))"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$nameString"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:function name="snac:changeWordToProperCase">
        <xsl:param name="tempString"/>
        <xsl:value-of select="upper-case(substring($tempString,1,1))"/>
        <xsl:value-of select="substring($tempString,2)"/>
    </xsl:function>
    
    <xsl:template name="extractOccupationOrFunction">
        <xsl:param name="entry" as="node()"/>
        <!-- this template looks for an occupation or function and if it finds one, outputs occupation or function with name entry. -->
        <xsl:for-each select="$relatorList/relator">
            <xsl:variable name="relator">
                <xsl:value-of select="."/>
            </xsl:variable>
            <xsl:variable name="relatorCode">
                <xsl:value-of select="./@code"/>
            </xsl:variable>
            <xsl:variable name="relatorRegex">
                <xsl:text>(,\s</xsl:text>
                <xsl:value-of select="lower-case(.)"/>
                <xsl:text>.*)|(and\s</xsl:text>
                <xsl:value-of select="lower-case(.)"/>
                <xsl:text>)</xsl:text>
            </xsl:variable>
            <xsl:choose>
                <!-- first it looks to see if there is a @role and then uses it. -->
                <xsl:when test="lower-case($entry/*/@role)=lower-case($relator) or lower-case($entry/*/@role)=$relatorCode">
                    <xsl:choose>
                        <xsl:when test="name($entry/*)='persname' or name($entry/*)='famame'">
                            <occupation source="roleAttribute">
                                <xsl:value-of select="$relator"/>
                            </occupation>
                        </xsl:when>
                        <xsl:otherwise>
                            <function source="roleAttribute">
                                <xsl:value-of select="$relator"/>
                            </function>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:otherwise>
                    <!-- second it looks to see if there an occupation or function like term in the name string. -->
                    <xsl:analyze-string select="$entry" regex="{$relatorRegex}">
                        <xsl:matching-substring>
                            <xsl:choose>
                                <xsl:when test="name($entry/*)='persname' or name($entry/*)='famame'">
                                    <occupation source="nameString">
                                        <xsl:value-of select="$relator"/>
                                    </occupation>
                                </xsl:when>
                                <xsl:otherwise>
                                    <function source="nameString">
                                        <xsl:value-of select="$relator"/>
                                    </function>
                                </xsl:otherwise>
                            </xsl:choose>
                        </xsl:matching-substring>
                    </xsl:analyze-string>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:function name="snac:removeBeforeHyphen2">
        <xsl:param as="xs:string" name="nameString"/>
        <xsl:choose>
            <xsl:when test="contains($nameString,'--')">
                <!--
                    This keeps everything before hyphen (do you mean "double hyphen"?) and removes everything
                    after. Also, if there is a weird paragraph character followed by -*, replace it with a
                    single hyphen.
                    
                    If the name has [\-\-\-] or other cases of multi-hyphens, this code is not indended to fix
                    that. Those names have deeper issues and should be fixed elsewhere.
                    
                    When debugging, keep in mind that this is called from xsl:if and xsl:when tests, and not
                    necessarily only when we are normalizing a name for output.
                -->

                <!-- After name-out: is always empty, even though the output is fine. Unexpected. Unclear why. -->
                
                <!-- <xsl:message> -->
                <!--     <xsl:value-of select="concat(' name-in: ', -->
                <!--                           $nameString, -->
                <!--                           ' name-out: ', -->
                <!--                           replace(normalize-space(substring-before(snac:dateHyphen2($nameString),'\-\-')),'¶(-*)','-'))"/> -->
                <!-- </xsl:message> -->
                
                <xsl:value-of select="replace(normalize-space(substring-before(snac:dateHyphen2($nameString),'--')),'¶(-*)','-')"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$nameString"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:function name="snac:dateHyphen2">
        <xsl:param as="xs:string" name="nameString"/>
        
        <!-- Commented out in Daniel's original code. -->
        <!--xsl:value-of select="replace($nameString,'[^-](\s[\d]{4}) 2','$1¶ 2')"/-->
        
        <xsl:value-of select="replace($nameString,'(\s[\d]{4})[-]{2,3}','$1¶--')"/>
    </xsl:function>
    
    <xsl:function name="snac:containsFamily" as="xs:boolean">
        <xsl:param name="tempString" as="xs:string"/>
        <!--
            This is similar to creating a normal-for-match. Lowercase, no punctuation.  The original string
            "Pease family, of Frosterley, Co. Durham." becomes "pease family of frosterley co durham".
        -->

        <xsl:variable name="normalizedString">
            <xsl:choose>
                <xsl:when test="snac:removeBeforeHyphen2($tempString)=''">
                    <xsl:value-of select="snac:normalizeString($tempString)"/>
                    <!-- test for cases of multiple hyhens used to imply a name -->
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="snac:normalizeString(snac:removeBeforeHyphen2($tempString))"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <!--
            Sep 22 2014 Name becomes zero after normalization above.
            
            <persname xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xlink="http://www.w3.org/1999/xlink">[\-\-\-] Boos; </persname>
            
            If that happens, return false. Before adding the choose/when/otherwise below we could get this Saxon error:
            
            Error on line 705 of functions.xsl:
            XTTE0780: An empty sequence is not allowed as the result of function snac:containsFamily()
            at snac:containsFamily() 
            
            Basically, analyze-string didn't run, thus nothing was returned. The w3c definition of
            analyze-string says: "The function returns the zero-length string if there is no captured substring
            with the relevant number."
            
            When working on the regex remember that "Pease family, of Frosterley, Co. Durham." becomes "pease family of frosterley co
            durham".
            
            Dec 15 2014 In addition to not(regex-group(3) allow group 3 to begin with 'of' so it will work for
            the majority of AHUB families that are tagged as <persname>
            
            xlf /data/source/findingAids/ahub/f_5178.xml
            normalFinal: Pease family, of Frosterley, Co. Durham.   type: regExed
            <persname source="aacr2" encodinganalog="ukmarc600.30" authfilenumber="134">Pease family, of Frosterley, Co. Durham.</persname>
        -->
        <xsl:choose>
            <xsl:when test="string-length($normalizedString) > 0">
                <xsl:analyze-string select="$normalizedString"
                                    regex="
                                           ^
                                           
                                           ([\p{{L}}]+\s)
                                           (family\s?)
                                           (([\p{{L}}]+\s?)*)
                                           (.*)
                                           
                                           $
                                           " flags="x">
                    <xsl:matching-substring>
                        <!-- <xsl:message> -->
                        <!--     <xsl:value-of select="$normalizedString"/> -->
                        <!--     <xsl:value-of select="$cr"/> -->
                        <!--     <xsl:value-of select="concat('re1:x', regex-group(1), 'xre2:x', regex-group(2), 'xre3:x', regex-group(3), 'x')"/> -->
                        <!-- </xsl:message> -->
                        <xsl:choose>
                            <xsl:when test="regex-group(2) and
                                            (not(regex-group(3)) or matches(regex-group(3), '^of'))">
                                <xsl:value-of select="boolean(1)"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="boolean(0)"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:matching-substring>
                    <xsl:non-matching-substring>
                        <xsl:value-of select="boolean(0)"/>
                    </xsl:non-matching-substring>
                </xsl:analyze-string>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="false()"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    
    <xsl:function name="snac:containsCorporateWord" as="xs:boolean">
        <!--
            This function examines a string to see if it contains any "corporate" words, and
            returns boolean yes if it finds one.
            
            Unfortunately, ahub often has an epithet at the end of the name, and many of those names trigger
            this code.
        -->
        
        <xsl:param name="tempString" as="xs:string"/>
        <xsl:variable name="tokenList" select="tokenize(snac:normalizeString($tempString), '\s+')"/>
        
        <!--
            Maybe we can try detecting corporate words only when they occur before (to the left of) any
            date-like digits. Or even before any digits at all.
        -->
        <xsl:message>
            <xsl:text>cword: </xsl:text>
            <xsl:value-of  select="replace(snac:normalizeString($tempString), '^(.*?)\d{4,}.*$', '$1')"/>
        </xsl:message>
        
        <!-- <xsl:variable name="tokenList" select="tokenize(replace(snac:normalizeString($tempString), '^(.*)\d{4,}.*$', '$1'), '\s+')"/> -->
        <xsl:value-of
            select="
                    exists(index-of($tokenList,'&amp;'))
                    or exists(index-of($tokenList,'agency'))
                    or exists(index-of($tokenList,'assoc'))
                    or exists(index-of($tokenList,'associates'))
                    or exists(index-of($tokenList,'association'))
                    or exists(index-of($tokenList,'board'))
                    or exists(index-of($tokenList,'bro')) 
                    or exists(index-of($tokenList,'bros'))
                    or exists(index-of($tokenList,'brother'))
                    or exists(index-of($tokenList,'brothers'))
                    or exists(index-of($tokenList,'center'))
                    or exists(index-of($tokenList,'central'))
                    or exists(index-of($tokenList,'chorus'))
                    or exists(index-of($tokenList,'cia'))
                    or exists(index-of($tokenList,'cie'))
                    or exists(index-of($tokenList,'citizens'))
                    or exists(index-of($tokenList,'city'))
                    or exists(index-of($tokenList,'club'))
                    or exists(index-of($tokenList,'cnty'))
                    or exists(index-of($tokenList,'co'))
                    or exists(index-of($tokenList,'coalition'))
                    or exists(index-of($tokenList,'college'))
                    or exists(index-of($tokenList,'commercial'))
                    or exists(index-of($tokenList,'commission'))
                    or exists(index-of($tokenList,'committee'))
                    or exists(index-of($tokenList,'company'))
                    or exists(index-of($tokenList,'conference'))
                    or exists(index-of($tokenList,'congregational'))
                    or exists(index-of($tokenList,'congress'))
                    or exists(index-of($tokenList,'consulate'))
                    or exists(index-of($tokenList,'corp'))
                    or exists(index-of($tokenList,'corporation'))
                    or exists(index-of($tokenList,'council'))
                    or exists(index-of($tokenList,'county'))
                    or exists(index-of($tokenList,'court'))
                    or exists(index-of($tokenList,'daughter'))
                    or exists(index-of($tokenList,'daughters'))
                    or exists(index-of($tokenList,'delegation'))
                    or exists(index-of($tokenList,'department'))
                    or exists(index-of($tokenList,'dept'))
                    or exists(index-of($tokenList,'dept.'))
                    or exists(index-of($tokenList,'district'))
                    or exists(index-of($tokenList,'division'))
                    or exists(index-of($tokenList,'federation'))
                    or exists(index-of($tokenList,'festival'))
                    or exists(index-of($tokenList,'firm'))
                    or exists(index-of($tokenList,'foundation'))
                    or exists(index-of($tokenList,'gallery'))
                    or exists(index-of($tokenList,'gazette'))
                    or exists(index-of($tokenList,'gesellschaft'))
                    or exists(index-of($tokenList,'governor'))
                    or exists(index-of($tokenList,'group'))
                    or exists(index-of($tokenList,'headquarters'))
                    or exists(index-of($tokenList,'herr'))
                    or exists(index-of($tokenList,'hospital'))
                    or exists(index-of($tokenList,'hotel'))
                    or exists(index-of($tokenList,'ils'))
                    or exists(index-of($tokenList,'inc'))
                    or exists(index-of($tokenList,'incorporated'))
                    or exists(index-of($tokenList,'institut'))
                    or exists(index-of($tokenList,'institute'))
                    or exists(index-of($tokenList,'international'))
                    or exists(index-of($tokenList,'laboratories'))
                    or exists(index-of($tokenList,'laboratory'))
                    or exists(index-of($tokenList,'league'))
                    or exists(index-of($tokenList,'legislature'))
                    or exists(index-of($tokenList,'legislative'))
                    or exists(index-of($tokenList,'library'))
                    or exists(index-of($tokenList,'lieutenant'))
                    or exists(index-of($tokenList,'limited'))
                    or exists(index-of($tokenList,'ltd'))
                    or exists(index-of($tokenList,'manufacture'))
                    or exists(index-of($tokenList,'manufactures'))
                    or exists(index-of($tokenList,'manufacturing'))
                    or exists(index-of($tokenList,'ministry'))
                    or exists(index-of($tokenList,'mission'))
                    or exists(index-of($tokenList,'monthly'))
                    or exists(index-of($tokenList,'museum'))
                    or exists(index-of($tokenList,'national'))
                    or exists(index-of($tokenList,'office'))
                    or exists(index-of($tokenList,'olympic'))
                    or exists(index-of($tokenList,'orchestra'))
                    or exists(index-of($tokenList,'parliament'))
                    or exists(index-of($tokenList,'party'))
                    or exists(index-of($tokenList,'powerhouse'))
                    or exists(index-of($tokenList,'press'))
                    or exists(index-of($tokenList,'product'))
                    or exists(index-of($tokenList,'products'))
                    or exists(index-of($tokenList,'project'))
                    or exists(index-of($tokenList,'pub'))
                    or exists(index-of($tokenList,'publishing'))
                    or exists(index-of($tokenList,'railroad'))
                    or exists(index-of($tokenList,'republic'))
                    or exists(index-of($tokenList,'school'))
                    or exists(index-of($tokenList,'schools'))
                    or exists(index-of($tokenList,'secretaría'))	
                    or exists(index-of($tokenList,'ship'))
                    or exists(index-of($tokenList,'steamship'))
                    or exists(index-of($tokenList,'sisters'))
                    or exists(index-of($tokenList,'societe'))
                    or exists(index-of($tokenList,'society'))
                    or exists(index-of($tokenList,'sovereign'))
                    or exists(index-of($tokenList,'state'))
                    or exists(index-of($tokenList,'station'))
                    or exists(index-of($tokenList,'steamShip'))
                    or exists(index-of($tokenList,'studio'))
                    or exists(index-of($tokenList,'technology'))
                    or exists(index-of($tokenList,'theater'))
                    or exists(index-of($tokenList,'theatre'))
                    or exists(index-of($tokenList,'u.s.s.'))
                    or exists(index-of($tokenList,'union'))
                    or exists(index-of($tokenList,'unitarian'))
                    or exists(index-of($tokenList,'united'))
                    or exists(index-of($tokenList,'universiteit'))
                    or exists(index-of($tokenList,'university'))
                    or exists(index-of($tokenList,'ymca'))"
            />
    </xsl:function>
    
    <xsl:function name="snac:normalizeString" as="xs:string">
        <!--
            This function replaces some punctuation with a blank; other it deletes, then normalizes space, and returns string in
            lower-case.
        -->
        <xsl:param name="tempString" as="xs:string"/>
        <xsl:value-of select="lower-case(snac:removePunctuation($tempString))"/>
    </xsl:function>
    
    <!--
        Less aggresive than snac:removePunctuaion(). Only remove trailing colon and associated whitespace.
        
        <part>James William Cannon:</part>
        http://shannon.village.virginia.edu:8091/xtf/data/ead_duke/duke/classic-EADs/cannon.r028.xml
    -->
    <xsl:function name="snac:removeColon">
        <xsl:param name="tempString" as="xs:string"/>
        <xsl:variable name="temp">
            <xsl:value-of
                select="normalize-space(replace($tempString, '\s*:\s*$', ''))"/>
        </xsl:variable>
        <xsl:value-of select="$temp"/>
    </xsl:function>
    
    <!--
        Remove forward slash added
    -->
    <xsl:function name="snac:removePunctuation">
        <xsl:param name="tempString" as="xs:string"/>
        <xsl:variable name="temp">
            <xsl:value-of
                select="normalize-space(replace(replace($tempString, '[/!,&quot;();:\.?{}\-&#xbf;&#xa1;&lt;>]', ' '),'[\[\]'']',''))"/>
        </xsl:variable>
        <!-- <xsl:message> -->
        <!--	 <xsl:value-of select="concat('rp: ', $tempString)"/> -->
        <!-- </xsl:message> -->
        <xsl:value-of select="$temp"/>
    </xsl:function>
    
    <xsl:function name="snac:fixSpacing">
        <xsl:param as="xs:string" name="tempString"/>
        <xsl:value-of select="replace(normalize-space(replace($tempString,'([\.,?]{1,2})','$1 ')),'([\.?])(\s)(\))','$1$3')"/>
    </xsl:function>
    
    <!--
        This removes parentheses from all dates, and inserts comma-space before date (after trapping for the
        possibility of a comma-space).
    -->
    <xsl:function name="snac:fixDatesRemoveParens">
        <xsl:param as="xs:string" name="nameString"/>

        <xsl:variable name="pass_one">
            <!--
                The old regex didn't understand c or c. or nnnn-?nnnn or some combinations with extra space in
                certain locations.
                
                Dec 19 2014 Add the [bdfl.\?\s]* modification. It seems to work better, and will match
                snac:stripStringAfterDateInPersname().
                
                Dec 22 2014 Add \s* after \( and change both alternations followed by whitespace
                "(ca\.|c|c\.)*\s*" to character class "[ca\.\s]*" Also add \s* on both sides of - hyphen.
                
                Can't easily use a single regex to correctly deal with "nnnn-" "nnnn" "nnnn nnnn"
                "nnnn-nnnn" "-nnnn", so make the hyphen required as in the original code.
                
                Try a second pass below to handle "-nnnn" and "nnnn-" and "nnnn" variants (b, d, fl, ca, etc.)
                QA check reveals nothing unexpected with this two pass version.
            -->

            <!-- <xsl:value-of -->
            <!--    select="replace($nameString,',?\s\(((b\.|d\.|active|fl\.)?\s?(ca\.)?\s?[\d]{3,4}\??\-?((b\.|d\.|active|fl\.)?\s?(ca\.)?\s?[\d]{3,4})?\??)?\)',', $1')"/> -->

            <!-- all to-from date variants -->
        <xsl:value-of
            select="replace($nameString,
  ',*?\s*\(\s*(([bdfl\.\s\?]*|\s*active[\s\?]*)*[ca\.\s]*\s*[\d]{3,4}\?*\s*\-\s*(([bdfl\.\s\?]*|\s*active[\s\?]*)*\s*[ca\.\s]*[\d]{3,4})*\??)\s*\)',
                    ', $1')"/>
        </xsl:variable>

        <!--
            Second pass to deal with all to- and from- date variants. Note hyphen in the first character class with bdfl deals with
            -nnnn while hyphen in final character class deals with nnnn-
        -->
        <xsl:variable name="result">
            <xsl:value-of
                select="replace($pass_one,
                        ',*?\s*\(\s*(([\-bdfl\.\s\?]*|\s*active[\s\?]*)*[ca\.\s]*\s*[\d]{3,4}[\?\s\-]*)\)',
                        ', $1')"/>
        </xsl:variable>

        <!--
            Only show a log message if the orig had both left and right paren and 3 or 4 digits somewhere
            between. This logging is to help catch interesting cases. We don't want to see all the ways that
            parens occur in names, many of which are no concern of ours. We only care about left paren date
            right paren.
        -->

        <xsl:if test="matches($nameString, '\(.*?\d{3,4}.*?\)')">
            <xsl:message>
                <xsl:text>fixDatesRemoveParens   orig: </xsl:text>
                <xsl:value-of select="$nameString"/>
            </xsl:message>
            <xsl:choose>
                <xsl:when test="matches($result, '[\(\)]')">
                    <xsl:message>
                        <xsl:text>fixDatesRemoveParens   warn: </xsl:text>
                        <xsl:value-of select="$result"/>
                    </xsl:message>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>
                        <xsl:text>fixDatesRemoveParens result: </xsl:text>
                        <xsl:value-of select="$result"/>
                    </xsl:message>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
        <xsl:value-of select="$result"/>
    </xsl:function>
    
    <xsl:function name="snac:fixDatesReplaceActiveWithFl">
        <xsl:param as="xs:string" name="nameString"/>
        <xsl:value-of select="replace($nameString,'
                              (\s|\-)
                              (active)
                              ((\sca\.)?\s[\d]{3,4}.*)
                              ','$1fl.$3','x')"/>
    </xsl:function>
    
    <xsl:function name="snac:fixHypen2Paren">
        <xsl:param as="xs:string" name="nameString"/>
        <xsl:choose>
            <xsl:when test="matches($nameString,'\s?--\s?\(')">
                <xsl:value-of select="normalize-space(replace($nameString,'\s?--\s?\(',' ('))"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$nameString"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <!--
        Call this before (early) most everything else, especially before snac:fixCommaHyphen2(). The double hyphen is
        necessary for later code that fixes issues such as '\-\- correspondent'. See snac:removeBeforeHyphen2.
        
        The original reason for snac:fixCommaHyphen2() is lost in the mists of time, but we should assume that
        it may be necessary somewhere.
    -->
    <xsl:function name="snac:cleanCommaHyphenEarly">
        <xsl:param as="xs:string" name="nameString"/>
        <xsl:choose>
            <xsl:when test="matches($nameString,',\s?--')">
                <xsl:value-of select="normalize-space(replace($nameString,',\s?--',' --'))"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$nameString"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    
    <xsl:function name="snac:fixCommaHyphen2">
        <xsl:param as="xs:string" name="nameString"/>
        <xsl:choose>
            <xsl:when test="matches($nameString,',\s?--')">
                <xsl:value-of select="normalize-space(replace($nameString,'(,\s?--)',', '))"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$nameString"/>
            </xsl:otherwise>
        </xsl:choose>
        
    </xsl:function>
    
    <xsl:function name="snac:removeQuotes">
        <xsl:param as="xs:string" name="nameString"/>
        <xsl:value-of select="normalize-space(translate($nameString,$quoteEscape,''))"/>
        <!-- NEW -->
    </xsl:function>
    
    <xsl:function name="snac:removeInitialHypen">
        <xsl:param as="xs:string" name="nameString"/>
        <xsl:choose>
            <xsl:when test="starts-with($nameString,'-')">
                <xsl:value-of select="normalize-space(substring($nameString,2))"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="normalize-space($nameString)"/>
            </xsl:otherwise>
        </xsl:choose>
        <!-- NEW -->
    </xsl:function>
    
    <xsl:function name="snac:removeInitialTrailingParen">
        <xsl:param as="xs:string" name="tempString"/>
        <!-- <xsl:message> -->
        <!--	 <xsl:value-of select="concat('ritp start: ', $tempString)"/> -->
        <!-- </xsl:message> -->
        <xsl:variable name="firstPass">
            <xsl:choose>
                <xsl:when test="matches($tempString,'
                                ^
                                (\()
                                (.*)
                                (\)\.?)
                                $
                                ','x')">
                    <xsl:value-of select="replace($tempString,'
                                          ^
                                          (\()
                                          (.*)
                                          (\)\.?)
                                          $				
                                          ','$2','x')"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$tempString"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="second_pass">
            <xsl:choose>
                <xsl:when test="matches($firstPass,'
                                ^
                                (\()
                                (.*)
                                (\)\.?)
                                $
                                ','x')">
                    <xsl:value-of select="replace($firstPass,'
                                          ^
                                          (\()
                                          (.*)
                                          (\)\.?)
                                          $				
                                          ','$2','x')"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$firstPass"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:value-of select="$second_pass"/>
        <!-- <xsl:message> -->
        <!--	 <xsl:value-of select="concat('ritp: ', $second_pass)"/> -->
        <!-- </xsl:message> -->
        <!-- new -->
    </xsl:function>
    
    <xsl:function name="snac:removeBrackets">
        <xsl:param as="xs:string" name="nameString"/>
        <xsl:value-of select="normalize-space(replace(
                              $nameString,'[\[\]]',''))"/>
        <!-- NEW -->
    </xsl:function>
    
    <xsl:function name="snac:removeTrailingInappropriatePunctuation">
        <xsl:param as="xs:string" name="nameString"/>
        <xsl:value-of select="
                              normalize-space(replace($nameString,'^(.+)([;,])$','$1'))
                              "/>
        <!-- NEW -->
    </xsl:function>
    
    <xsl:function name="snac:fixDates">
        <xsl:param as="xs:string" name="nameString"/>
        <!-- 
             Normalize before doing anything. Fixes active date and dates in paren; first it tests for date
             of type: (active ca. 1852-ca. 1868) or (active ca. 1852) and transforms these into
             fl. ca. 1852-ca. 1868 and fl. ca. 1852; then it fixes dates of this type: (1852-1868)
             transforming into ", 1852-1868"
             
             French date formats we don't fix due to added complexity of the regular expressions:
             
             <persname>Tito, Josip Broz (1892 -	 1980 ; maréchal)</persname>
             <persname>Elisabeth II (1926 - ....  ; reine)</persname>
             <persname>Jean-Paul II (1920 - 2005 ; pape)</persname>
             <persname>Giscard d'Estaing (Valérie (1926 - ... )</persname>
             
             1) We can't be sure there is only one token after ;
             
             2) We would have to match date \d{1,4} or [\.]+
             
             3) If a date can be 1234 - .... then a date might also be .... - 1234
             
             The bug: In <xsl:otherwise> the two commented out replace() calls made is possible for the ( to
             be removed, but the ) remains when dates are not formatted as we expect.
             
             Pétain, Philippe (1856 - 1951 ; maréchal)
             
             with the (fixed) bug it became:
             
             Pétain, Philippe, 1856 - 1951 ; maréchal)
        -->
        <xsl:variable name="norm_nameString">
            <xsl:value-of select="normalize-space($nameString)"/>
        </xsl:variable>

        <xsl:choose>
            <xsl:when test="matches($norm_nameString,'\(\s?active')">
                <xsl:value-of select="replace(replace($norm_nameString,'\s\(\s?active',', fl.'),'([\d]{1,4})(\).*$)','$1')"/>
            </xsl:when>
            <xsl:when test="matches($norm_nameString, '\s*\((\d{1,4})\s*-\s*(\d{1,4})\)')">
                <xsl:value-of select="replace($norm_nameString, '\s*\((\d{1,4})\s*-\s*(\d{1,4})\)', ', $1-$2')"/>
            </xsl:when>
            <xsl:otherwise>
                <!--
                    If the format doesn't have an explicit match, then we probably can't fix it with a simple
                    regular expression, so return the original string unchanged.
                -->
                <xsl:value-of select="$norm_nameString"/>
                
                <!--
                    If we have at least 1 digit in the name string, log it as an unparsed date. If no digits,
                    there probably isn't a date in that name string.
                    
                    If the date is already 1234-1234 then it doesn't need fixing or logging. Yes, this logs
                    some good dates, but better to log a few extras than to miss some weird date that we'd
                    like to fix.
                -->
                <xsl:if test="matches($norm_nameString, '\d+') and not(matches($norm_nameString, '\d{1,4}-\d{1,4}'))">
                    <xsl:message>
                        <xsl:text>unfixed date: </xsl:text>
                        <xsl:value-of select="$norm_nameString"/>
                    </xsl:message>
                </xsl:if>
                
                <!-- <xsl:value-of select=" -->
                <!--		      replace( -->
                <!--		      replace($norm_nameString,'\s\(([\d]{1,4})',', $1'), -->
                <!--		      '([\d]{1,4})\)','$1')" -->
                <!--	      /> -->
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!--
        This is a small, conservative normalization. The intent is to only remove extraneous info about
        correspondence from person names. Note that we specifically (case-insensitive) match only the full
        word correspondence, and not the more typical cleaning match of 'correspond'.
        
        The sanity check is for things we don't want to modify such as "United
        States-Army-Officers-Correspondence".
        
        Milroy, Mary Armitage - Correspondence
        Cobleigh, William-Correspondence
        Cobleigh Julia Adelaide Merriam-Correspondence
        Cobleigh, Esther Rose Cooley-Correspondence
        Wisenall, Christian S-Correspondence
        Shearer, Charles T. -Correspondence
        
        dec 1 2014 Just a note: this will not fix "Foster, John Edward Correspondence." because it only fixes
        (the regex) -+Correspondence (with at least one hyphen). The non-hyphen version would probably be ok, but is less
        conservative, more rare, and would need further testing. The rarity doesn't justify the extra time.
    -->
    <xsl:function name="snac:normalize_extra">
        <xsl:param as="xs:string" name="nameString"/>
        <xsl:choose>
            <xsl:when test="not(matches($nameString, 'correspondence', 'i'))">
                <xsl:value-of select="$nameString"/>            
            </xsl:when>
            <xsl:otherwise>
                <xsl:choose>
                    <xsl:when test="matches($nameString, '-+[a-z]-+[a-z]', 'i')">
                        <xsl:message>
                            <xsl:text>warning: name not fixed: </xsl:text>
                            <xsl:value-of select="$nameString"/>
                        </xsl:message>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="replace($nameString, '\s*-+\s*correspondence', '','i')"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    
</xsl:stylesheet>
