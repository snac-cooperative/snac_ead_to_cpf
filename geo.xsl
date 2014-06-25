<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:ead="urn:isbn:1-931666-22-9"
                xmlns:functx="http://www.functx.com"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xlink="http://www.w3.org/1999/xlink"
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
        
        Create a file of geoname places and normative place names for quick lookup by other XSL code.
        
        Read a places xml file, call Robbie's geonames code, output a file of geonames places. Geoname parsing
        is very, very slow, and we do it every time the CPF extraction is run. So, we need to pre-parse the
        geonames and then just look up the values during the CPF extraction.
        
        Relies on a symlink (or real directory) containing Robbie's Saxon extensions. Must be run using Robbie's copy of Saxon.
        
        Requires the logging the comments geogx: (associated with geog1:, geog2:, and geog3:)
        templates.xsl. Run everything (extract_all.pl), grep out the geog names by capturing
        "<normalized>.+<\/normalized>", sort -u, and process with build_geo_xml.pl. This results in a file of
        unique names to run through this script, geo.xsl.
        
        Merging is something like:
        
        tail -n +3 geonames_files/geo_all.xml| head -n -1 > a.xml
        tail -n +3 geonames_files/geo_2014-06-02.xml | head -n -1 > b.xml
        head -n 2 geo_all.xml > head.xml
        tail -n 1 geo_all.xml > tail.xml
        cat head.xml a.xml b.xml tail.xml > geo_all.xml
        
        For any new data sets, run all this to get the new names. The Perl script build_geo_xml.pl will
        exclude any known place names from geo.xml. Use cat, head, and tail to merge the new XML with existing
        XML.
        
        grep -Po "<normalized>.+<\/normalized>" logs/*.log > geoname_files/tmp.txt
        sort -fu geoname_files/tmp.xt > geoname_files/all.txt
        ./build_geo_xml.pl geonames_files/all.txt > geonames_files/all.xml

        snac_transform.sh geonames_files/all.xml geo.xsl > geonames_files/geo_all.xml
        
        > head geonames_files/all.xml 
        <?xml version="1.0" encoding="UTF-8"?>
        <places>
        <place>
        <cpfName>Istanbul (Turkey)</cpfName>
        </place>
        <place>
        <cpfName>Smyrna (Turkey)</cpfName>
        </place>
        <place>
        <cpfName>Wales</cpfName>

        > ln -s /lv3/data/snac_saxon/SNAC-Saxon-Extensions/xslt/lib
        > ls -ld lib
        lrwxrwxrwx 1 twl8n snac 51 May 23 12:03 lib -> /lv3/data/snac_saxon/SNAC-Saxon-Extensions/xslt/lib
        
        Consider importing lib.xsl instead of copying template mode copy-no-ns here. lib.xsl has some
        variables used by the whole system. We aren't currently using any of those variables, but we
        might. For example, the localType values might be used here. (Should be used here?)
    -->

    <xsl:output indent="yes" method="xml"/>
    
    <xsl:include href="lib/java-geo-lib.xsl"/>
    
    <xsl:template name="tpt_main" match="/">
        <places>
            <xsl:for-each select="places/place">
              <xsl:variable name="geo">
                  <xsl:call-template name="tpt_query_cheshire">
                      <xsl:with-param name="geostring">
                          <xsl:copy-of select="cpfName"/>
                      </xsl:with-param>
                  </xsl:call-template>
              </xsl:variable>
              <xsl:apply-templates mode="copy-no-ns" select="$geo"/>
          </xsl:for-each>
      </places>
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

  
</xsl:stylesheet>
