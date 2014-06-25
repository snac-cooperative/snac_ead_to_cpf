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
                
                <xsl:choose>
		    <xsl:when test="true()">
                        <xsl:variable name="pass_1">
		            <xsl:value-of
		                select="replace($tempString,
                                        '(^.+?\s)((fl\.\s)? (ca\.\s)?[\d]{3,4}\??\- (fl\.\s)? (ca\.\s)? [\d]{3,4}\??)($|([\D].*$))'
                                        ,'$2')"/>
                        </xsl:variable>

                        <xsl:variable name="pass_2">
		            <xsl:value-of
		                select="replace($pass_1,
                                        '(^.+?\s)((fl\.\s)? (ca\.\s)? [\d]{3,4}\??\-)($|([\D].*$))'
                                        ,'$2')"/>
                        </xsl:variable>
                        <xsl:variable name="pass_3">
		            <xsl:value-of
		                select="replace($pass_2,
                                        '(^.+?\s)((([b|d]\.\s)|(fl\.\s))(ca\.\s)?[\d]{3,4}\??)($|([\D].*$))'
                                        ,'$2')"/>
                        </xsl:variable>
                        <xsl:value-of select="$pass_3"/>
                    </xsl:when>
                    <xsl:otherwise>
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
			            ','$2','x')"
		            />
                    </xsl:otherwise>
                </xsl:choose>
	    </xsl:when>
	    <xsl:otherwise>
		<xsl:text>0</xsl:text>
	    </xsl:otherwise>
	</xsl:choose>
    </xsl:function>
    
    <xsl:function name="snac:stripStringAfterDateInPersname">
	<xsl:param as="xs:string" name="tempString"/>
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
		
                <xsl:choose>
                    <xsl:when test="true()">
                        <!--
                            Break the replace() into 3 passes because the single large regexp crashes saxon
                            with a java exception.
                        -->
                        <xsl:variable name="pass_1">
		            <xsl:value-of
		                select="replace($tempString,
                                        '(^.+?\s)((fl\.\s)? (ca\.\s)?[\d]{3,4}\??\- (fl\.\s)? (ca\.\s)? [\d]{3,4}\??)($|([\D].*$))','$1$2')"/>
                        </xsl:variable>
                        <xsl:variable name="pass_2">
		            <xsl:value-of
		                select="replace($pass_1,'(^.+?\s)((fl\.\s)? (ca\.\s)? [\d]{3,4}\??\-)($|([\D].*$))','$1$2')"/>
                        </xsl:variable>
                        <xsl:variable name="pass_3">
		            <xsl:value-of
		                select="replace($pass_2,'(^.+?\s)((([b|d]\.\s)|(fl\.\s))(ca\.\s)?[\d]{3,4}\??)($|([\D].*$))','$1$2')"/>
                        </xsl:variable>
                        <xsl:value-of select="$pass_3"/>
                    </xsl:when>
                    <xsl:otherwise>
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

		    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
	    <xsl:otherwise>
		<xsl:value-of select="$tempString"/>
	    </xsl:otherwise>
	</xsl:choose>
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
                    This keeps everything before hyphen and removes everything after.
                    Test with: /data/source/findingAids/harvard/trc00032.xml
                -->
                <xsl:if test="false()"> <!-- disabled because you can't comment out double hyphen strings. -->
                    <xsl:value-of select="replace(normalize-space(substring-before(snac:dateHyphen2($nameString),'--')),'¶(-*)','-')"/>
                </xsl:if>
                <xsl:value-of select="replace(
                                      normalize-space(
                                      concat(
                                      substring-before(snac:dateHyphen2($nameString),'--'),
                                      substring-after(snac:dateHyphen2($nameString), '--'))),'¶(-*)','-')"/>
	    </xsl:when>
	    <xsl:otherwise>
		<xsl:value-of select="$nameString"/>
	    </xsl:otherwise>
	</xsl:choose>
    </xsl:function>

    <xsl:function name="snac:dateHyphen2">
	<xsl:param as="xs:string" name="nameString"/>

	<!--xsl:value-of select="replace($nameString,'[^-](\s[\d]{4}) 2','$1¶ 2')"/-->
	<xsl:value-of select="replace($nameString,'(\s[\d]{4})[-]{2,3}','$1¶--')"/>
    </xsl:function>

    <xsl:function name="snac:containsFamily" as="xs:boolean">
	<xsl:param name="tempString" as="xs:string"/>
        <!-- <xsl:message> -->
        <!--     <xsl:value-of select="concat('ts: ', snac:removeBeforeHyphen2($tempString))"/> -->
        <!-- </xsl:message> -->
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

	<!-- <xsl:message> -->
	<!--     <xsl:value-of select="concat('t: ', $tempString, ' n: ', $normalizedString)"/> -->
	<!-- </xsl:message> -->

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
		<xsl:choose>
		    <xsl:when test="regex-group(2) and not(regex-group(3))">
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
        Remove forward slash added
    -->
    <xsl:function name="snac:removePunctuation">
	<xsl:param name="tempString" as="xs:string"/>
        <xsl:variable name="temp">
	    <xsl:value-of
	        select="normalize-space(replace(replace($tempString, '[/!,&quot;();:\.?{}\-&#xbf;&#xa1;&lt;>]', ' '),'[\[\]'']',''))"/>
        </xsl:variable>
        <!-- <xsl:message> -->
        <!--     <xsl:value-of select="concat('rp: ', $tempString)"/> -->
        <!-- </xsl:message> -->
        <xsl:value-of select="$temp"/>
    </xsl:function>

    <xsl:function name="snac:fixSpacing">
	<xsl:param as="xs:string" name="tempString"/>
	<xsl:value-of select="replace(normalize-space(replace($tempString,'([\.,?]{1,2})','$1 ')),'([\.?])(\s)(\))','$1$3')"/>
    </xsl:function>

    <xsl:function name="snac:fixDatesRemoveParens">
	<xsl:param as="xs:string" name="nameString"/>
	<xsl:value-of
	    select="replace($nameString,',?\s\(((b\.|d\.|active|fl\.)?\s?(ca\.)?\s?[\d]{3,4}\??\-?((b\.|d\.|active|fl\.)?\s?(ca\.)?\s?[\d]{3,4})?\??)?\)',',
		    $1')"/>

	<!--This removes parentheses from all dates, and inserts comma-space before date (after trapping for the possibilit of a comma-space). -->

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
	<xsl:choose>
	    <xsl:when test="matches($nameString,'\(\s?active')">
		<xsl:value-of select="replace(replace($nameString,'\s\(\s?active',', fl.'),'([\d]{1,4})(\).*$)','$1')"/>
	    </xsl:when>
	    <xsl:otherwise>
		<xsl:value-of select="
				      replace(
				      replace($nameString,'\s\(([\d]{1,4})',', $1'),
				      '([\d]{1,4})\)','$1')"
			      />
	    </xsl:otherwise>
	</xsl:choose>
	<!-- NEW 
	     fixes active date and dates in paren; first it test for date of type: (active ca. 1852-ca. 1868) or
	     (active ca. 1852) and transforms these into fl. ca. 1852-ca. 1868 and fl. ca. 1852; 
	     then it fixes dates of this type: (1852-1868) transforming into ", 1852-1868"-->
    </xsl:function>

</xsl:stylesheet>
