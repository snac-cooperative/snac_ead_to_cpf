<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:ead="urn:isbn:1-931666-22-9"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:eac="urn:isbn:1-931666-33-4"
                xmlns:snac="http://socialarchive.iath.virginia.edu/"
                xmlns:xlink="http://www.w3.org/1999/xlink"
                exclude-result-prefixes="#all"
                version="2.0">

    <xsl:import href="variables.xsl"/>
    
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
         
         Creating urls of EAD finding aids is a separate part of the pipeline. File-to-url conversion data is
         stored in url_xml/*.xml. I think "fix" was chosen in the name because the urls often do not work as
         specified in the EAD <eadid>, so some of them need to be "fixed".
         
         Run urls for just one collection (mhs):
         
         snac_transform.sh createFileLists/mhs_list.xml fix_url.xsl 2> tmp.log > url_xml/mhs_url.xml
         
         Run all the URLs aka "fixed urls":

         ./run_fix_all.pl > rfa.log 2>&1 &        
         
         Conversion eadid to URL for ufl which is now part of afl and is called afl-ufl. For an example
         findingAids/afl-ufl/ufms272.xml

    -->

    <!-- 
         Data files for conversion of filename prefix to dirname for the URL.
         Yes, we lazily load them all for every run, regardless. 
    -->
    <xsl:variable name="ufl" select="document('ufl_e2u.xml')"/>

    <!-- <xsl:variable name="unl" select="document('unl_e2u.xml')"/> -->

    <xsl:variable name="vah" select="document('vah_e2u.xml')"/>
    
    <xsl:variable name="fsga" select="document('fsga_e2u.xml')"/>

    <xsl:variable name="howard" select="document('howard_e2u.xml')"/>

    <xsl:variable name="aps" select="document('aps_e2u.xml')"/>

    <xsl:variable name="ahub" select="document('ahub_e2u.xml')"/>

    <xsl:variable name="unc" select="document('unc_e2u.xml')"/>

    <xsl:variable name="sia" select="document('sia_e2u.xml')"/>
    
    <xsl:strip-space elements="*"/>
    <xsl:output indent="yes" method="xml"/>

    <xsl:template name="tpt_main" match="/">
        <!-- <xsl:message> -->
        <!--     <xsl:value-of select="concat('cpfOutLocation:', ' override ', $cpfOutLocation)"/> -->
        <!-- </xsl:message> -->
        <container>
            <xsl:for-each select="snac:list/snac:group">
                <!--
                    This is the new one-file-at-a-time code which reads one EAD file, processes it, and then
                    outputs the relevant CPF.
                    
                    This loop processes of a list of ead files from the fileList for each contributor (or possibly
                    for all contributors). Start and stop were originally controlled by attributes in the snac:list
                    (fileList); stop and start are @n of each snac:group; snac:group will contain a varying number
                    of file paths. The for-each snac:i below processes each file from the group.
                    
                    This script currently has start and stop hard coded over in the variables XSLT
                    (eadToCPFVariables.xsl or variables.xsl), mostly for dev/test/debugging.
                -->
                <xsl:for-each select="snac:i">
                    <xsl:call-template name="tpt_process">
                        <xsl:with-param name="icount" select="@n"/>
                    </xsl:call-template>
                </xsl:for-each>
            </xsl:for-each>
        </container>
    </xsl:template>

    <xsl:template name="tpt_process">
        <xsl:param name="icount"/>
        <!--
            This processes a single ead file.
        -->
        <xsl:variable name="ofile">
            <!-- original file via the context of the call-template. -->
            <xsl:value-of select="."/>
        </xsl:variable>
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

        <xsl:variable name="repo">
            <xsl:value-of select="replace($fn, '^.*/findingAids/(.*?)/.*$', '$1')"/>
        </xsl:variable>

        <xsl:variable name="base">
            <!--
                The file name of the full $fn file path, so not strictly what "basename" usually is. (I think
                it usually is the file name without suffix.)
                
                For:
                /data/source/findingAids/ccfr/FRCGMNOV-751055117-02a.xml
                
                $base is: FRCGMNOV-751055117-02a.xml
            -->
            <xsl:value-of select="replace($fn, '^.*/(.*?)$', '$1')"/>
        </xsl:variable>

        <xsl:variable name="strict_base">
            <!--
                Stricly speaking, the base filename. The other var $base really should have been named
                something less confusing.
            -->
            <xsl:value-of select="replace($fn, '^.*/(.*?).xml$', '$1','i')"/>
        </xsl:variable>

        <xsl:for-each select="document($fn)">
            <xsl:choose>
                <xsl:when test="$repo = 'aao' or $repo = 'aao_missing'">
                    <xsl:variable name="prefix">
                        <xsl:choose>
                            <xsl:when test="$repo = 'aao'">
                                <xsl:value-of select="replace($fn, '^.*/aao/(.*?)_.*/.*$', '$1')"/>
                            </xsl:when>
                            <xsl:when test="$repo = 'aao_missing'">
                                <xsl:value-of select="replace($fn, '^.*/aao_missing/(.*?)_.*/.*$', '$1')"/>
                            </xsl:when>
                        </xsl:choose>
                    </xsl:variable>
                    <file url="{concat('http://www.azarchivesonline.org/xtf/view?docId=ead/',$prefix, '/', $base)}">
                        <xsl:value-of select="$ofile"/>
                    </file>
                    <!-- An attribute (above) is easier than a sibling (below) or child element -->
                    <!-- <url> -->
                    <!--     <xsl:value-of select="concat('http://www.azarchivesonline.org/xtf/view?docId=ead/',$prefix, '/', $base)"/> -->
                    <!-- </url> -->
                </xsl:when>
                <xsl:when test="$repo = 'aar' or $repo = 'aar_missing'">
                    <file url="{concat('http://www.aaa.si.edu/collections/findingaids/', $base)}">
                        <xsl:value-of select="$ofile"/>
                    </file>
                </xsl:when>
                <xsl:when test="$repo = 'afl' or $repo = 'afl_missing'">
                    <xsl:variable name="ead" select="document($fn)"/>
                    <xsl:variable name="pid" select="replace($fn, '.*findingAids/afl/(\d+)_.*', '$1')"/>
                    <file url="{concat('http://digitool.fcla.edu/webclient/DeliveryManager?pid=', $pid, '&amp;custom_att_2=direct')}">
                        <xsl:value-of select="$ofile"/>
                    </file>
                </xsl:when>
                <xsl:when test="$repo = 'ahub' or $repo = 'ahub_missing'">
                    <xsl:variable name="url" select="replace($ahub/container/row[@file=$base]/@url, '.xml$', '')"/>
                    <file url="{$url}">
                        <xsl:value-of select="$ofile"/>
                    </file>
                </xsl:when>
                <xsl:when test="$repo = 'anfra' or $repo = 'anfra_missing'">
                    <file url="missing:">
                        <xsl:value-of select="$ofile"/>
                    </file>
                </xsl:when>
                <xsl:when test="$repo = 'aps' or $repo = 'aps_missing'">
                    <xsl:variable name="ead" select="document($fn)"/>
                    <xsl:variable name="url_from_base" select="concat('http://www.amphilsoc.org/mole/view?docId=ead/', $base)"/>
                    <!--
                       APS normally uses eadid/@url, but when missing $base seems to work, and when there is a
                       mismatch between @url and the filename, use the filename which accurately reflects the
                       unitid.
                       
                       We also have URLs manually gathered by Scott for URLs that were 404 by the usual techniques.
                       
                       Use Scott's hand created URLs in preference to any others.
                    -->
                    <xsl:choose>
                        <xsl:when test="$aps/container/row[@file=$base]/@url">
                            <xsl:variable name="url" select="$aps/container/row[@file=$base]/@url"/>
                            <file type="missing, using aps_e2u.xml"
                                  url="{$url}">
                                <xsl:value-of select="$ofile"/>
                            </file>
                        </xsl:when>
                        <xsl:when test="$ead/ead/eadheader/eadid/@url != '' and
                                        $ead/ead/eadheader/eadid/@url = $url_from_base">
                            <!-- <xsl:value-of select="$ead/ead/eadheader/eadid/@url"/> -->
                            <file type="using url attr" url="{$ead/ead/eadheader/eadid/@url}">
                                <xsl:value-of select="$ofile"/>
                            </file>
                        </xsl:when>
                        <xsl:when test="$ead/ead/eadheader/eadid/@url != '' and
                                        $ead/ead/eadheader/eadid/@url != $url_from_base">
                            <!-- <xsl:message> -->
                            <!--     <xsl:value-of select="concat($fn, $cr)"/> -->
                            <!--     <xsl:value-of select="concat('warning: at_url does not match url_from_base', $cr)"/> -->
                            <!--     <xsl:value-of select="concat('at_url: ', $ead/ead/eadheader/eadid/@url, $cr)"/> -->
                            <!--     <xsl:value-of select="concat('url_from_base: ', $url_from_base, $cr)"/> -->
                            <!-- </xsl:message> -->
                            <file type="url mismatch, using filename"
                                  orig_url_attr="{$ead/ead/eadheader/eadid/@url}"
                                  url="{concat('http://www.amphilsoc.org/mole/view?docId=ead/', $base)}">
                                <xsl:value-of select="$ofile"/>
                            </file>
                        </xsl:when>
                        <xsl:otherwise>
                            <!-- <xsl:value-of select="concat('http://www.amphilsoc.org/mole/view?docId=ead/', $base)"/> -->
                            <!-- <xsl:message> -->
                            <!--     <xsl:value-of select="concat($fn, $cr)"/> -->
                            <!--     <xsl:value-of select="concat('warning: at_url does not match url_from_base', $cr)"/> -->
                            <!--     <xsl:value-of select="concat('at_url: ', $ead/ead/eadheader/eadid/@url, $cr)"/> -->
                            <!--     <xsl:value-of select="concat('url_from_base: ', $url_from_base, $cr)"/> -->
                            <!-- </xsl:message> -->
                            <file type="missing, using filename"
                                  url="{concat('http://www.amphilsoc.org/mole/view?docId=ead/', $base)}">
                                <xsl:value-of select="$ofile"/>
                            </file>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:when test="$repo = 'bnf' or $repo = 'bnf_missing'">
                    <xsl:variable name="ead" select="document($fn)"/>
                    <xsl:variable name="eadid" select="normalize-space($ead/ead/eadheader/eadid)"/>
                    <file url="{concat('http://archivesetmanuscrits.bnf.fr/ead.html?id=', $eadid)}">
                        <xsl:value-of select="$ofile"/>
                    </file>
                </xsl:when>
                <xsl:when test="$repo = 'byu' or $repo = 'byu_missing'">
                    <xsl:variable name="ead" select="document($fn)"/>
                    <!--
                        Seems to work to parse out "UA 5399" from eadid@publicid.
                        /data/source/findingAids/byu/UPB_UA5399.xml 
                    -->
                    <xsl:variable name="publicid" select="replace($ead/ead/eadheader/eadid/@publicid, '.*//TEXT.*?::.*?::(.*)::.*//EN','$1')"/>
                    <file url="{concat('http://findingaid.lib.byu.edu/viewItem/', replace($publicid, ' ', '%20'))}">
                        <xsl:value-of select="$ofile"/>
                    </file>
                </xsl:when>
                <xsl:when test="$repo = 'ccfr' or $repo = 'ccfr_missing'">
                    <file url="{concat('http://ccfr.bnf.fr/portailccfr/jsp/index_view_direct_anonymous.jsp?record=eadcgm:EADI:', $base)}">
                        <xsl:value-of select="$ofile"/>
                    </file>
                </xsl:when>
                <xsl:when test="$repo = 'cjh' or $repo = 'cjh_missing'">
                    <!-- <xsl:variable name="ead" select="document($fn)"/> -->
                    <!-- Get a pid from the filename. -->
                    <file url="{concat('http://findingaids.cjh.org/?pID=', replace($fn, '^.*/(\d+)_.*$', '$1'))}">
                        <xsl:value-of select="$ofile"/>
                    </file>

                    <!-- eadid not reliable for url generation -->
                    <!-- <xsl:variable name="eadid" select="$ead/ead/eadheader/eadid"/> -->
                    <!-- <file url="{concat('http://findingaids.cjh.org/', $eadid, '.html')}"> -->
                    <!--     <xsl:value-of select="$ofile"/> -->
                    <!-- </file> -->
                </xsl:when>
                <xsl:when test="$repo = 'colu' or $repo = 'colu_missing'">
                    <xsl:variable name="ead" select="document($fn)"/>
                    <xsl:variable name="eadid" select="normalize-space(replace($ead/ead/eadheader/eadid, '_ead.xml', ''))"/>
                    <xsl:variable name="magency" select="$ead/ead/eadheader/eadid/@mainagencycode"/>
                    <file url="{concat('http://findingaids.cul.columbia.edu/ead/', $magency,'/', $eadid)}">
                        <xsl:value-of select="$ofile"/>
                    </file>
                </xsl:when>
                <xsl:when test="$repo = 'crnlu' or $repo = 'crnlu_missing'">
                    <xsl:variable name="ead" select="document($fn)"/>
                    <xsl:variable name="eadid" select="normalize-space($ead/ead/eadheader/eadid)"/>
                    <file url="{concat('http://rmc.library.cornell.edu/EAD/xml/dlxs/', $eadid)}">
                        <xsl:value-of select="$ofile"/>
                    </file>
                </xsl:when>
                <xsl:when test="$repo = 'duke' or $repo = 'duke_missing'">
                    <xsl:variable name="ead" select="document($fn)"/>
                    <xsl:variable name="url" select="$ead/ead/eadheader/eadid/@url"/>
                    <file url="{$url}">
                        <xsl:value-of select="$ofile"/>
                    </file>
                </xsl:when>
                <xsl:when test="$repo = 'fivecol' or $repo = 'fivecol_missing'">
                    <xsl:variable name="m2code">
                        <ma code="smitharchives">manosca</ma>
                        <ma code="mountholyoke">mshm</ma>
                        <ma code="amherst">ma</ma>
                        <ma code="hampshire">mah</ma>
                        <ma code="mortimer">manoscmr</ma>
                        <ma code="sophiasmith">mnsss</ma>
                        <ma code="umass">mu</ma>
                    </xsl:variable>
                        
                    <xsl:variable name="ead" select="document($fn)"/>
                    <xsl:variable name="eadid" select="normalize-space($ead/ead/eadheader/eadid)"/>
                    <xsl:variable name="magency" select="$ead/ead/eadheader/eadid/@mainagencycode"/>
                    <file url="{concat('http://asteria.fivecolleges.edu/findaids/', $m2code/ma[text()=$magency]/@code,'/', $eadid, '.html')}">
                        <xsl:value-of select="$ofile"/>
                    </file>
                </xsl:when>
                <xsl:when test="$repo = 'fsga' or $repo = 'fsga_missing'">
                    <xsl:variable name="ead" select="document($fn)"/>
                    <xsl:variable name="unittitle" select="$ead/ead/archdesc/did/unittitle"/>
                    <xsl:variable name="url" select="$fsga/container/row[@title=$unittitle]/@url"/>
                    <file url="{$url}">
                        <xsl:value-of select="$ofile"/>
                    </file>
                </xsl:when>
                <xsl:when test="$repo = 'harvard' or $repo = 'harvard_missing'">
                    <xsl:variable name="ead" select="document($fn)"/>
                    <xsl:variable name="eadid" select="normalize-space($ead/ead/eadheader/eadid)"/>
                    <file url="{concat('http://oasis.lib.harvard.edu//oasis/deliver/deepLink?_collection=oasis&amp;uniqueId=', $eadid)}">
                        <xsl:value-of select="$ofile"/>
                    </file>
                </xsl:when>
                <xsl:when test="$repo = 'howard' or $repo = 'howard_missing'">
                    <xsl:variable name="ead" select="document($fn)"/>
                    <xsl:variable name="unitid" select="normalize-space($ead/ead/archdesc/did/unitid)"/>
                    <xsl:variable name="url" select="$howard/container/row[@collection_no=$unitid]/@url"/>
                    <file url="{$url}">
                        <xsl:value-of select="$ofile"/>
                    </file>
                </xsl:when>
                <xsl:when test="$repo = 'inu' or $repo = 'inu_missing'">
                    <xsl:variable name="ead" select="document($fn)"/>
                    <xsl:variable name="eadid" select="normalize-space($ead/ead/eadheader/eadid)"/>
                    <file url="{concat('http://webapp1.dlib.indiana.edu/findingaids/view?doc.view=entire_text&amp;docId=', $eadid)}">
                        <xsl:value-of select="$ofile"/>
                    </file>
                </xsl:when>
                <xsl:when test="$repo = 'lds' or $repo = 'lds_missing'">
                    <!-- I tested 2 records from lds using exptr. One worked and one is 404. Deemed unreliable. -->
                    <!-- <xsl:variable name="ead" select="document($fn)"/> -->
                    <!-- <xsl:variable name="extptr" select="$ead/ead/eadheader/filedesc/publicationstmt/address/addressline/extptr[matches(@xlink:href, 'eadview\.lds\.org')]/@xlink:href"/> -->
                    <!-- <file url="{replace($extptr, ' ', '%20')}"> -->
                    <!--     <xsl:copy-of select="$stuff"/> -->
                    <!-- </file> -->

                    <file url="missing:">
                        <xsl:value-of select="$ofile"/>
                    </file>
                </xsl:when>
                <xsl:when test="$repo = 'lc' or $repo = 'lc_missing'">
                    <xsl:variable name="ead" select="document($fn)"/>
                    <xsl:variable name="eadid" select="normalize-space($ead/ead/eadheader/eadid)"/>
                    <file url="{$eadid}">
                        <xsl:value-of select="$ofile"/>
                    </file>
                </xsl:when>
                <xsl:when test="$repo = 'meas' or $repo = 'meas_missing'">
                    <file url="missing:">
                        <xsl:value-of select="$ofile"/>
                    </file>
                </xsl:when>
                <xsl:when test="$repo = 'mhs' or $repo = 'mhs_missing'">
                    <xsl:variable name="basename" select="replace($fn, '^.*/(.*?.xml)$', '$1')"/>
                    <file url="{concat('http://www.mnhs.org/library/findaids/', $basename)}">
                        <xsl:value-of select="$ofile"/>
                    </file>

                    <!-- <xsl:variable name="ead" select="document($fn)"/> -->
                    <!-- Unclear why I ever thought that the eadid was consistent for use in the url. -->
                    <!-- <xsl:variable name="eadid" select="replace(normalize-space($ead/ead/eadheader/eadid), '\.xml$', '')"/> -->
                    <!-- <file url="{concat('http://www.mnhs.org/library/findaids/', $eadid, '.xml')}"> -->
                    <!--     <xsl:value-of select="$ofile"/> -->
                    <!-- </file> -->
                </xsl:when>
                <xsl:when test="$repo = 'mit' or $repo = 'mit_missing'">
                    <!-- 
                         Use eadid@url, but change research/collections- to research/collections/collections- as necessary.
                    -->
                    <xsl:variable name="ead" select="document($fn)"/>
                    <xsl:variable name="url" select="replace(normalize-space($ead/ead/eadheader/eadid/@url), '(research/)(collections\-)', '$1collections/$2')"/>
                    <file url="{$url}">
                        <xsl:value-of select="$ofile"/>
                    </file>
                </xsl:when>
                <xsl:when test="$repo = 'ncsu' or $repo = 'ncsu_missing'">
                    <!--
                        NCSU has some missing http:// on urls, as well as wrong and inconsistent host
                        names. Just replace everything up to the first / with the http:// protocol and
                        www.lib.ncsu.edu hostname.
                        
                        <file url="http://www.ncsu.edu/findingaids/mc00261">findingAids/ncsu/mc00261.xml</file>
                        <file url="www.lib.ncsu.edu/findingaids/ua002_001_007">findingAids/ncsu/ua002_001_007.xml</file>
                        <file url="www.lib.ncsu.edu/findingaids/mc00459">findingAids/ncsu/mc00459.xml</file>
                        <file url="www.lib.ncsu.edu/findingaids/mc00471">findingAids/ncsu/mc00471.xml</file>
                        <file url="http//:www.lib.ncsu.edu/findingaids/mc00473">findingAids/ncsu/mc00473.xml</file>
                        <file url="www.lib.ncsu.edu/findingaids/mc00197">findingAids/ncsu/mc00197.xml</file>
                        <file url="http://www.lib.ncsu/findingaids/ua022_035/">findingAids/ncsu/ua022_035.xml</file>
                    -->
                    <xsl:variable name="ead" select="document($fn)"/>
                    <xsl:variable name="url" select="replace(
                                                     normalize-space($ead/ead/eadheader/eadid/@url),
                                                     '^http://.*?/', 'http://www.lib.ncsu.edu/')"/>
                    
                    <file url="{$url}">
                        <xsl:value-of select="$ofile"/>
                    </file>
                </xsl:when>
                <xsl:when test="$repo = 'nlm' or $repo = 'nlm_missing'">
                    <xsl:variable name="ead" select="document($fn)"/>
                    <xsl:variable name="eadid" select="normalize-space($ead/ead/eadheader/eadid)"/>
                    <file url="{concat('http://oculus.nlm.nih.gov/', $eadid)}">
                        <xsl:value-of select="$ofile"/>
                    </file>
                </xsl:when>
                <xsl:when test="$repo = 'nmaia' or $repo = 'nmaia_missing'">
                    <xsl:variable name="ead" select="document($fn)"/>
                    <xsl:variable name="eadid" select="normalize-space($ead/ead/eadheader/eadid)"/>
                    <file url="{concat('http://nmai.si.edu/sites/1/files/archivecenter/', $eadid, '.html')}">
                        <xsl:value-of select="$ofile"/>
                    </file>
                </xsl:when>

                <xsl:when test="$repo = 'nwda' or $repo = 'nwda_missing'">
                    <xsl:variable name="ead" select="document($fn)"/>
                    <xsl:variable name="url" select="$ead/ead/eadheader/eadid/@url"/>
                    <file url="{$url}">
                        <xsl:value-of select="$ofile"/>
                    </file>
                </xsl:when>

                <xsl:when test="$repo = 'nwu' or $repo = 'nwu_missing'">
                    <xsl:variable name="ead" select="document($fn)"/>
                    <xsl:variable name="identifier" select="$ead/ead/eadheader/eadid/@identifier"/>
                    <file url="{concat('http://findingaids.library.northwestern.edu/catalog/', $identifier)}">
                        <xsl:value-of select="$ofile"/>
                    </file>
                </xsl:when>
                <xsl:when test="$repo = 'nypl' or $repo = 'nypl_missing'">
                    <xsl:variable name="ead" select="document($fn)"/>
                    <xsl:variable name="url" select="replace($ead/ead/eadheader/eadid/@url, '.xml$', '')"/>
                    <file url="{$url}">
                        <xsl:value-of select="$ofile"/>
                    </file>
                </xsl:when>
                <xsl:when test="$repo = 'nysa' or $repo = 'nysa_missing'">
                    <xsl:variable name="ead" select="document($fn)"/>
                    <!--
                       Note: unitid (not the more common eadid) 
                    -->
                    <xsl:variable name="unitid" select="normalize-space($ead/ead/archdesc/did/unitid)"/>
                    <file url="{concat('http://iarchives.nysed.gov/xtf/view?docId=', $unitid, '.xml')}">
                        <xsl:value-of select="$ofile"/>
                    </file>
                </xsl:when>
                <xsl:when test="$repo = 'nyu' or $repo = 'nyu_missing'">
                    <!--
                        Collections: nyhs, bhs, fales, archives, tamwag, rism, poly.
                    -->
                    <xsl:variable name="coll" select="replace($fn, '.*findingAids/nyu.*?/(.*?)/.*', '$1')"/>
                    <xsl:variable name="ead" select="document($fn)"/>
                    <xsl:variable name="eadid" select="normalize-space($ead/ead/eadheader/eadid)"/>
                    <file url="{concat('http://dlib.nyu.edu/findingaids/html/', $coll, '/', $eadid, '/', $eadid, '.html')}">
                        <xsl:value-of select="$ofile"/>
                    </file>
                </xsl:when>
                <xsl:when test="$repo = 'oac' or $repo = 'oac_missing'">
                    <xsl:variable name="ead" select="document($fn)"/>
                    <xsl:variable name="identifier" select="$ead/ead/eadheader/eadid/@identifier"/>
                    <file url="{concat('http://www.oac.cdlib.org/', $identifier)}">
                        <xsl:value-of select="$ofile"/>
                    </file>
                </xsl:when>
                <xsl:when test="$repo = 'ohlink' or $repo = 'ohlink_missing'">
                    <!--
                        Using eadid results in 144 missing URLs
                    -->
                    <!-- <xsl:variable name="ead" select="document($fn)"/> -->
                    <!-- <xsl:variable name="eadid" select="normalize-space($ead/ead/eadheader/eadid)"/> -->

                    <!-- 
                         Simply use the strict base name. Easier, more reliable (I hope).
                    -->
                    <file url="{concat('http://rave.ohiolink.edu/archives/ead/', $strict_base)}">
                        <xsl:value-of select="$ofile"/>
                    </file>
                </xsl:when>
                <xsl:when test="$repo = 'pacscl' or $repo = 'pacscl_missing'">
                    <xsl:variable name="ead" select="document($fn)"/>
                    <!-- dirname is like coll in some other repositories -->
                    <xsl:variable name="dirname" select="upper-case(replace($fn, '.*findingAids/pacscl/(.*?)/.*', '$1'))"/>
                    <xsl:variable name="eadid" select="replace($ead/ead/eadheader/eadid, '[^A-Za-z0-9]+', '')"/>
                    <xsl:variable name="mac" select="replace($ead/ead/eadheader/eadid/@mainagencycode, '[^A-Za-z0-9]+', '')"/>
                    <xsl:variable name="unitid" select="replace($ead/ead/archdesc/did/unitid, '[^A-Za-z0-9]+', '')"/>
                    <file url="{concat('http://dla.library.upenn.edu/dla/pacscl/ead.html?id=PACSCL_', $dirname, '_', $eadid, $mac, $unitid)}">
                        <xsl:value-of select="$ofile"/>
                    </file>
                </xsl:when>
                <xsl:when test="$repo = 'pu' or $repo = 'pu_missing'">
                    <xsl:variable name="ead" select="document($fn)"/>
                    <xsl:variable name="url" select="$ead/ead/eadheader/eadid/@url"/>
                    <file url="{$url}">
                        <xsl:value-of select="$ofile"/>
                    </file>
                </xsl:when>
                <xsl:when test="$repo = 'riamco' or $repo = 'riamco_missing'">
                    <xsl:variable name="ead" select="document($fn)"/>
                    <xsl:variable name="eadid" select="normalize-space($ead/ead/eadheader/eadid)"/>
                    <file url="{concat('http://library.brown.edu/riamco/render.php?eadid=', $eadid, '&amp;view=title')}">
                        <xsl:value-of select="$ofile"/>
                    </file>
                </xsl:when>
                <xsl:when test="$repo = 'rmoa' or $repo = 'rmoa_missing'">
                    <file url="{concat('http://rmoa.unm.edu/docviewer.php?docId=', $base)}">
                        <xsl:value-of select="$ofile"/>
                    </file>
                </xsl:when>
                <xsl:when test="$repo = 'rutu' or $repo = 'rutu_missing'">
                    <xsl:variable name="coll" select="replace($fn, '.*findingAids/rutu/(.*?)/.*', '$1')"/>
                    <xsl:variable name="ead" select="document($fn)"/>
                    <xsl:variable name="eadid" select="normalize-space($ead/ead/eadheader/eadid)"/>
                    <!--
                        Since the finding aid link is for scholars, I suppose the frameset is better.
                        
                        # Frameset. Note the f suffix.
                        http://www2.scc.rutgers.edu/ead/manuscripts/nyfaif.html
                        
                        # Actual page. Note the b suffix.
                        http://www2.scc.rutgers.edu/ead/manuscripts/nyfaib.html
                    -->
                    <file url="{concat('http://www2.scc.rutgers.edu/ead/', $coll, '/', $eadid, 'f.html')}">
                        <xsl:value-of select="$ofile"/>
                    </file>
                </xsl:when>
                <xsl:when test="$repo = 'sia' or $repo = 'sia_missing'">
                    <xsl:variable name="url" select="$sia/container/row[@file=$base]/@url"/>
                    <file url="{$url}">
                        <xsl:value-of select="$ofile"/>
                    </file>
                </xsl:when>
                <xsl:when test="$repo = 'syru' or $repo = 'syru_missing'">
                    <xsl:variable name="ead" select="document($fn)"/>
                    <xsl:variable name="eadid" select="normalize-space($ead/ead/eadheader/eadid)"/>
                    <xsl:variable name="letter" select="substring($eadid, 1,1)"/>
                    <file url="{concat('http://library.syr.edu/digital/guides/', $letter, '/', $eadid, '.htm')}">
                        <xsl:value-of select="$ofile"/>
                    </file>
                </xsl:when>
                <xsl:when test="$repo = 'taro' or $repo = 'taro_missing'">
                    <!-- file path suffix, lacking a better name for it -->
                    <xsl:variable name="fp_suffix" select="replace($fn, '.*/taro/(.*?)/.*?$', '$1')"/>

                    <xsl:variable name="basename" select="replace($fn, '.*/(.*).xml$', '$1')"/>

                    <!-- subdirectory, or if empty repeat the basename -->
                    <xsl:variable name="subd">
                        <xsl:choose>
                            <xsl:when test="matches($fn, '.*/taro/.+?/.+/.+.xml$')">
                                <xsl:value-of select="replace($fn, '.*/taro/.*?/(.*/).*.xml$', '$1')"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="concat($basename, '/')"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:variable>
                    <file url="{concat('http://www.lib.utexas.edu/taro/', $fp_suffix, '/', $subd, $basename, '-P.html')}">
                        <xsl:value-of select="$ofile"/>
                    </file>
                </xsl:when>
                <xsl:when test="$repo = 'ual' or $repo = 'ual_missing'">
                    <!--
                        jan 8 2015 eadid seems unreliable. Some are missing. Some have extension ".ead.xml"
                        which causes the URLs to fail. Rever to using the file name base.
                    -->
                    <!-- <xsl:variable name="ead" select="document($fn)"/> -->
                    <!-- <xsl:variable name="eadid" select="normalize-space($ead/ead/eadheader/eadid)"/> -->
                    <xsl:variable name="basename" select="replace($fn, '.*/(.*).ead.xml$', '$1')"/>
                    <file url="{concat('http://acumen.lib.ua.edu/', $basename)}">
                        <xsl:value-of select="$ofile"/>
                    </file>
                </xsl:when>
                <xsl:when test="$repo = 'uchic' or $repo = 'uchic_missing'">
                    <xsl:variable name="ead" select="document($fn)"/>
                    <xsl:variable name="eadid" select="normalize-space($ead/ead/eadheader/eadid)"/>
                    <!--
                        Add suffix to get xml output "&xml". No suffix or "&html" gives html.
                    -->
                    <file url="{concat('http://www.lib.uchicago.edu/e/scrc/findingaids/view.php?eadid=', $eadid)}">
                        <xsl:value-of select="$ofile"/>
                    </file>
                </xsl:when>
                <xsl:when test="$repo = 'uct' or $repo = 'uct_missing'">
                    <xsl:variable name="ead" select="document($fn)"/>
                    <xsl:variable name="url" select="$ead/ead/eadheader/eadid/@url"/>
                    <file url="{$url}">
                        <xsl:value-of select="$ofile"/>
                    </file>
                </xsl:when>
                <xsl:when test="$repo = 'ude' or $repo = 'ude_missing'">
                    <xsl:variable name="ead" select="document($fn)"/>
                    <xsl:variable name="eadid" select="replace(normalize-space($ead/ead/eadheader/eadid), '(.*)\.xml', '$1')"/>
                    <!--
                        # xml, use findaids/xml and .xml
                        http://www.lib.udel.edu/ud/spec/findaids/xml/mss0093_0001.xml
                        
                        # html, use findaids/html and .html
                        http://www.lib.udel.edu/ud/spec/findaids/html/mss0093_0001.html
                    -->
                    <file url="{concat('http://www.lib.udel.edu/ud/spec/findaids/html/', $eadid, '.html')}">
                        <xsl:value-of select="$ofile"/>
                    </file>
                </xsl:when>
                <xsl:when test="$repo = 'afl-ufl' or $repo = 'afl-ufl_missing'">
                    <xsl:variable name="ead" select="document($fn)"/>
                    <xsl:variable name="eadid" select="normalize-space($ead/ead/eadheader/eadid)"/>
                    <xsl:variable name="url"
                                  select="$ufl/Table/Row[Cell[3]/Data = $eadid]/Cell[4]/Data"/>
                    <file url="{$url}">
                        <xsl:value-of select="$ofile"/>
                    </file>
                </xsl:when>
                <xsl:when test="$repo = 'uil' or $repo = 'uil_missing'">
                    <xsl:variable name="ead" select="document($fn)"/>
                    <xsl:variable name="aicid" select="replace($ead/ead/eadheader/eadid/@identifier, '.*:(.*)', '$1')"/>
                    <file url="{concat('http://archives.library.illinois.edu/archon/?p=collections/controlcard&amp;id=', $aicid)}">
                        <xsl:value-of select="$ofile"/>
                    </file>
                </xsl:when>
                <xsl:when test="$repo = 'uks' or $repo = 'uks_missing'">
                    <xsl:variable name="ead" select="document($fn)"/>
                    <xsl:variable name="url" select="$ead/ead/eadheader/eadid/@url"/>
                    <file url="{$url}">
                        <xsl:value-of select="$ofile"/>
                    </file>
                </xsl:when>
                <xsl:when test="$repo = 'umd' or $repo = 'umd_missing'">
                    <!--
                        xml version is concat('http://digital.lib.umd.edu/oclc/', $base)
                    -->
                    <file url="{concat('http://digital.lib.umd.edu/archivesum/actions.DisplayEADDoc.do?source=', $base, '&amp;style=ead')}">
                        <xsl:value-of select="$ofile"/>
                    </file>
                </xsl:when>
                <xsl:when test="$repo = 'umi' or $repo = 'umi_missing'">
                    <!--
                        name-value look up
                    -->
                    <xsl:variable name="nv">
                        <name value="http://quod.lib.umich.edu/b/bhlead/">bentley</name>
                        <name value="http://quod.lib.umich.edu/c/clementsmss/">clementsmss</name>
                    </xsl:variable>
                    <xsl:variable name="coll" select="replace($fn, '.*findingAids/umi/(.*?)/.*', '$1')"/>
                    <xsl:variable name="ead" select="document($fn)"/>
                    <xsl:variable name="eadid" select="normalize-space($ead/ead/eadheader/eadid)"/>
                    <!--
                        value where name=$coll
                    -->
                    <file url="{concat($nv/name[text()=$coll]/@value, $eadid, '?rgn=main;view=text')}">
                        <xsl:value-of select="$ofile"/>
                    </file>
                </xsl:when>
                <xsl:when test="$repo = 'umn' or $repo = 'umn_missing'">
                    <xsl:variable name="ead" select="document($fn)"/>
                    <!--
                        Using eadid is broken for 174 urls, most are obvious typo or format issues. The
                        filename appears to be more reliable.
                    -->
                    <!-- <xsl:variable name="eadid" select="normalize-space($ead/ead/eadheader/eadid)"/> -->
                    <!-- <file url="{concat('http://special.lib.umn.edu/findaid/xml/', $eadid, '.xml')}"> -->

                    <file url="{concat('http://special.lib.umn.edu/findaid/xml/', $base)}">
                        <xsl:value-of select="$ofile"/>
                    </file>
                </xsl:when>
                <xsl:when test="$repo = 'unc' or $repo = 'unc_missing'">
                    <xsl:variable name="url" select="$unc/container/row[@file=$base]/@url"/>
                    <file url="{$url}">
                        <xsl:value-of select="$ofile"/>
                    </file>
                </xsl:when>
                <xsl:when test="$repo = 'unl' or $repo = 'unl_missing'">
                    <!--
                        Renamed from "une". New file name (base) is used verbatim as part of the URL. 
                    -->
                    <xsl:variable name="new_name">
                        <xsl:value-of select="replace($base, '\.xml$', '.html')"/>
                    </xsl:variable>
                    <file url="{concat('http://archivespec.unl.edu/findingaids/', $new_name)}">
                        <xsl:value-of select="$ofile"/>
                    </file>
                </xsl:when>
                <xsl:when test="$repo = 'utsa' or $repo = 'utsa_missing'">
                    <!--
                        Getting the numerical part of the $base file name seems easier and at least as
                        reliable as parsing out the same digits from the eadid.
                    -->
                    <xsl:variable name="fileid" select="replace($base, '.*_(\d+).xml', '$1')"/>
                    <file url="{concat('http://archives.utah.gov/research/inventories/', $fileid, '.html')}">
                        <xsl:value-of select="$ofile"/>
                    </file>
                </xsl:when>
                <xsl:when test="$repo = 'utsu' or $repo = 'utsu_missing'">
                    <xsl:variable name="ead" select="document($fn)"/>
                    <xsl:variable name="url" select="$ead/ead/eadheader/eadid/@url"/>
                    <file url="{$url}">
                        <xsl:value-of select="$ofile"/>
                    </file>
                </xsl:when>
                <xsl:when test="$repo = 'uut' or $repo = 'uut_missing'">
                    <xsl:variable name="ead" select="document($fn)"/>
                    <xsl:variable name="identifier" select="$ead/ead/eadheader/eadid/@identifier"/>
                    <file url="{concat('http://nwda.orbiscascade.org/ark:/', $identifier)}">
                        <xsl:value-of select="$ofile"/>
                    </file>
                </xsl:when>
                <xsl:when test="$repo = 'vah' or $repo = 'vah_missing'">
                    <xsl:variable name="prefix" select="lower-case(replace($base, '^(.*?)\d+.xml', '$1'))"/>
                    <xsl:variable name="dirname" select="$vah/list/inst[@prefix=$prefix]/@dirname"/>
                    <!-- <xsl:variable name="ead" select="document($fn)"/> -->
                    <!-- <xsl:variable name="identifier" select="$ead/ead/eadheader/eadid/@identifier"/> -->
                    <file url="{concat('http://ead.lib.virginia.edu/vivaxtf/view?docId=', $dirname, '/', $base)}">
                        <xsl:value-of select="$ofile"/>
                    </file>
                </xsl:when>
                <xsl:when test="$repo = 'yale' or $repo = 'yale_missing'">
                    <!-- 
                         Normally yale uses the eadid/@url, but some of those are missing. The filename
                         without the extension seems to be an exact match for the ead id, so try
                         it. find_empty_elements.pl will log any missing URLs.
                    -->
                    <xsl:variable name="ead" select="document($fn)"/>
                    <xsl:variable name="url" select="$ead/ead/eadheader/eadid/@url"/>
                    <xsl:choose>
                        <xsl:when test="$ead/ead/eadheader/eadid/@url != ''">
                            <file url="{$url}">
                                <xsl:value-of select="$ofile"/>
                            </file>
                        </xsl:when>
                        <xsl:otherwise>
                            <file url="{concat('http://hdl.handle.net/10079/fa/', replace($base, '\.xml$', ''))}">
                                <xsl:value-of select="$ofile"/>
                            </file>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message>
                        <xsl:text>Error code not found: </xsl:text>
                        <xsl:value-of select="concat($repo, ' fn: ', $fn)"/>
                    </xsl:message>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
    </xsl:template>

    <xsl:template name="tpt_url">

    </xsl:template>

</xsl:stylesheet>
