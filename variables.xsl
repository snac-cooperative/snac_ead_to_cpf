<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
    xmlns:ead="urn:isbn:1-931666-22-9"
    xmlns:functx="http://www.functx.com"
    xmlns:snac="http://socialarchive.iath.virginia.edu/"
    xmlns:xlink="http://www.w3.org/1999/xlink"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    exclude-result-prefixes="#all"
    version="2.0">
    <!-- 
         Note @force added to support QA files reverting to ussing pStart and pEnd which has been overridden
         during development. Eventually we need a command line param for all the normal EAD files.
         
         The CPF localType values are in av.xml since they are shared variables with the earlier CPF
         extraction in ../eac_project. (MARC, British Library, SIA archives format, SIA Field Books, etc.)
    -->
    
    <xsl:variable name="cr" select="'&#x0A;'"/>
    
    <xsl:variable name="this_year" select="year-from-date(current-date())"/>

    <xsl:variable name="start" as="xs:integer">
        <xsl:choose>
            <xsl:when test="snac:list/@force = '1'">
                <xsl:value-of select="snac:list/@pStart"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="1"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <xsl:variable name="stop" as="xs:integer">
        <xsl:choose>
            <xsl:when test="snac:list/@force = '1'">
                <xsl:value-of select="snac:list/@pEnd"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="20"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>

    <xsl:variable name="sourceID">
        <xsl:value-of select="snac:list/@sourceCode"/>
    </xsl:variable>

    <xsl:variable name="aposLiteral">'</xsl:variable>
    <xsl:variable name="quoteLiteral">"</xsl:variable>

    <xsl:variable name="quoteEscape">&quot;</xsl:variable>
    <xsl:variable name="aposEscape">&apos;</xsl:variable>

    <xsl:variable name="sourceList">
        <!--
            Finding aid URLs added Mar 26 2014 as comments. 
            Updated jan 15 2014 via email
            
            No files:
            anfra - Archives nationales (France)
            
            Awaiting complete/updated data:
            ahub - ArchivesHub (UK)
            lds - Church of Latter Day Saints Archives (No algorithm, incorrect url in <extptr>)
            
            
            No finding aids online:
            howard - Howard University (No finding aids found)
            
            
            URLs cannot be created from current records:
            fsga - Freer Sackler Gallery Archives, Smithsonian Institution (Can't associate eadid or any ead data with URL id values.)
            meas - Maine Archives Search (Some URLs have dot (.) some have space (%20), pattern is unclear.)
            nyu - New York University (106 bad/broken out of 3668 total records. See nyu section in variables.xsl for details.)
            sia - Smithsonian Institution Archives (We have no way to convert eadid to sirsi_arc values)
            unc - University of North Carolina, Chapel Hill (Can't build urls with ead data, confirmed, see notes)
            une - University of Nebraska (Can't associate eadid with finding aid url file name)
            
            
            Superceded:
            ufl - University of Florida (Now part of alf)
        -->
        <source>
            <sourceCode>aao</sourceCode>
            <sourceName>Arizona Archives Online</sourceName>
            <!--
                /data/source/findingAids/aao/uoa_university_of_az/UAMS469.xml

                <eadid encodinganalog="852"> PUBLIC "-//University of Arizona Library Special
                Collections//text(US::AzU::Theatre Progams collection)//en"
                "UAMS469.xml"</eadid>
                
                <unitid label="Collection Number:" encodinganalog="099" repositorycode="AzU" countrycode="us">MS 469</unitid>
                
                http://www.azarchivesonline.org/xtf/view?docId=ead/uoa/UAMS469.xml&doc.view=toc&brand=default&toc.id=0
                
                # Works. Human readable (inspite of the .xml extension)
                http://www.azarchivesonline.org/xtf/view?docId=ead/uoa/UAMS469.xml
                
                /data/source/findingAids/aao/phm_postal_history_museum/PHF_MS_COLL_2010.26.xml
                
                <eadid countrycode="US" encodinganalog="identifier" mainagencycode="US-AzTuPHF"
                publicid="-//Postal History Foundation::Peggy J. Slusser Memorial Philatelic Library//TEXT
                (US::US-AzTuPHF::PHF_MS COLL 2010.26::Arizona Territorial Correspondence
                Collection)//EN">PHF_MS_COLL_2010.26.xml</eadid>
                
                http://www.azarchivesonline.org/xtf/view?docId=ead/phm/PHF_MS_COLL_2010.26.xml

                > grep fn: logs/aao.log | perl -ne '$_ =~ m/aao\/(.*?)\//; print "$1\n"' | sort -u
                asl_az_state_library
                asm_az_state_museum
                asu_az_state_university
                ccp_center_for_creative_photography
                hm_heard_museum
                lo_lowell_observatory
                mna_museum_of_northern_az
                nau_northern_az_university
                phm_postal_history_museum
                sh_sharlot_hall
                uoa_university_of_az
                
                > find /data/source/findingAids/aao/ -type d
                /data/source/findingAids/aao/
                /data/source/findingAids/aao/ccp_center_for_creative_photography
                /data/source/findingAids/aao/nau_northern_az_university
                /data/source/findingAids/aao/asu_az_state_university
                /data/source/findingAids/aao/asm_az_state_museum
                /data/source/findingAids/aao/asl_az_state_library
                /data/source/findingAids/aao/uoa_university_of_az
                /data/source/findingAids/aao/mna_museum_of_northern_az
                /data/source/findingAids/aao/lo_lowell_observatory
                /data/source/findingAids/aao/hm_heard_museum
                /data/source/findingAids/aao/sh_sharlot_hall
                /data/source/findingAids/aao/phm_postal_history_museum
            -->
            <url></url>
            <identifier>concat('UA', normalize-space(ead/archdesc/did/unitid), '.xml')</identifier>
        </source>
        <source>
            <sourceCode>aar</sourceCode>
            <sourceName>Archives of American Art (Smithsonian Institution)</sourceName>
            <!--
                /data/source/findingAids/aar/moorbens.xml
                
                <eadid mainagencycode="DSI-AAA" countrycode="us"
                url="http://www.aaa.si.edu/collections/findingaids/xml/moorbens.xml">moorbens</eadid>
                
                # Works. Redirects to human readable link below. Discovered this by editing the pdf link
                http://www.aaa.si.edu/collections/findingaids/moorbens.xml

                # Page redirects to 404 or if /collections to a human readable collections browsing page.
                http://www.aaa.si.edu/collections/findingaids/xml/moorbens.xml
                
                # The actual finding aid. Yes, it has "/more" on the end
                http://www.aaa.si.edu/collections/benson-bond-moore-papers-6095/more
                
                # pdf
                http://www.aaa.si.edu/collections/findingaids/moorbens.pdf
            -->
            <url/>
            <identifier/>
        </source>
        <source>
            <sourceCode>afl</sourceCode>
            <sourceName>Archives Florida</sourceName>
            <!-- 
                 See afl-ufl (below where ufl used to be) for the ufl data. 
                 
                 /data/source/findingAids/afl/11180_M1982_10.xml
                 
                 <eadid mainagencycode="FWA" countrycode="us" url="http://fusionmx.lib.uwf.edu/archon/ead.php?id=18">M1982-10SC</eadid>
                 
                 <titleproper>Howard, James William, Diary</titleproper>
                 
                 # Works, redirects to finding aid, human readable
                 http://digitool.fcla.edu/webclient/DeliveryManager?pid=11180&custom_att_2=direct
                 
                 # no, error
                 http://digitool.fcla.edu/R/?func=search-advanced-go&find_code1=PID&request1=11180
                 
                 # no
                 http://digitool.fcla.edu/R/?func=search-advanced-go&find_code1=WID&request1=11180
                 
                 # no
                 http://digitool.fcla.edu/R/?func=search-advanced-go&find_code1=PAA&request1=11180
                 
                 # No.
                 http://digitool.fcla.edu/R/?func=search-advanced-go&find_code1=WID&request1=M1982_10
                 
                 # no.
                 http://digitool.fcla.edu/R/?func=search-advanced-go&find_code1=WID&request1=M1982_10.xml
                 
                 # result with single record
                 http://digitool.fcla.edu/R/?func=search-advanced-go&find_code1=WID&request1=M1982%2010.xml
                 
                 # returns search with single record
                 http://digitool.fcla.edu/R/?func=search-advanced-go&find_code1=WID&request1=M1982%2010
                 
                 # returns a web page with a single finding aid result
                 http://digitool.fcla.edu/R/?func=search-advanced-go&find_code1=WID&request1=M1982-10
                 
                 http://digitool.fcla.edu/R/LTIYXDEHY9A55NAN94R3VIQAHTXEDPM199PYEKJ72NV2BT77GL-00140
                 
                 http://digitool.fcla.edu/view/action/singleViewer.do?dvs=1396619909143~578&locale=en_US&VIEWER_URL=/view/action/singleViewer.do?&DELIVERY_RULE_ID=7&search_terms=m1982%2010sc&adjacency=N&application=DIGITOOL-3&frameId=1&usePid1=true&usePid2=true
                 
                 # This seems to work:
                 http://143.88.66.76/archon/index.php?p=collections/controlcard&id=18
                 
                 # 404
                 http://fusionmx.lib.uwf.edu/archon/ead.php?id=18
                 
                 /data/source/findingAids/afl/165407_FTaSU1977012j.xml
                 
                 <eadid countrycode="US" mainagencycode="FTaSU" publicid="-//Florida State
                 University::Strozier Library::Special Collections//TEXT (US::FTaSU::MSS 1977-012j::Autograph
                 letter signed from Charlotte, Countess of Leicester, October 23, 1794)//TEXT//EN">MSS
                 1977-012j.xml</eadid>
                 
                 # works, redirects to finding aid, human readable
                 http://digitool.fcla.edu/webclient/DeliveryManager?pid=165407&custom_att_2=direct
                 
                 # no, error. PID is not in list of options for find_code1
                 http://digitool.fcla.edu/R/?func=search-advanced-go&find_code1=PID&request1=165407
                 
                 # works, search with 1 result
                 http://digitool.fcla.edu/R/?func=search-advanced-go&find_code1=WRD&request1=165407
                 
                 # works, search with 1 result
                 http://digitool.fcla.edu/R/?func=search-advanced-go&find_code1=WRD&request1=FTaSU1977012j.xml
                 
                 # works, search result with one finding aid link
                 http://digitool.fcla.edu/R/?func=search-advanced-go&find_code1=WID&request1=FTaSU1977012j.xml
                 
                 # Works, returns a web page with one finding aid link
                 http://digitool.fcla.edu/R/?func=search-advanced-go&find_code1=WTI&request1=Autograph%20letter%20signed%20from%20Charlotte,%20Countess%20of%20Leicester,%20October%2023,%201794
                 
                 # Nope
                 http://digitool.fcla.edu/R/?func=search-advanced-go&find_code1=WID&request1=MSS1977-012
                 
                 # Works
                 http://fsuarchon.fcla.edu/index.php?p=collections/controlcard&id=3887&q=Bryant
                 
                 # works
                 http://fsuarchon.fcla.edu/index.php?p=collections/findingaid&id=3887&q=Bryant&rootcontentid=141809

            -->
            <url/>
            <identifier/>
         </source>

         
         <source>
             <sourceCode>ahub</sourceCode>
             <sourceName>ArchivesHub (UK)</sourceName>
             <!-- 
                  jun 04 2014 Disable ahub until we get a new data set.
                  
                  Old data not working, inconsistent, new, revised data coming soon.
                  
                  Old comments move to code_archive.txt
             -->
             <url/>
             <identifier/>
         </source>
         <source>
             <sourceCode>anfra</sourceCode>
             <sourceName>Archives nationales (France)</sourceName>
             <!-- 
                  No files as of mar 24 2014.
             -->
             <url/>
             <identifier/>
         </source>
        <source>
            <sourceCode>aps</sourceCode>
            <sourceName>American Philosophical Society</sourceName>
            <!--
                /data/source/findingAids/aps/Mss.649.962.Sh6m-ead.xml
                
                <eadid countrycode="US" mainagencycode="US-PPAmP" url="http://www.amphilsoc.org/mole/view?docId=ead/Mss.649.962.Sh6m-ead.xml"/>

                The URL is complete and works, html human readable
            -->
            <url/>
            <identifier/>
        </source>
        <source>
            <sourceCode>bnf</sourceCode>
            <sourceName>Bibliothèque nationale de France / BnF Archives et manuscripts</sourceName>
            <!-- 
                 /data/source/findingAids/bnf/preliminary/Christine_of_Pizan_ms.xml
                 
                 <eadid>FRBNFEAD000050858</eadid>
                 
                 # This has some (most?) of the data, but the online version seems to be more extensive (the online
                 # version has a summary at the top and a "Bibliographie" that we don't have in our ead file.
                 
                 # works, html
                 http://archivesetmanuscrits.bnf.fr/ead.html?id=FRBNFEAD000050858
                 
                 Images of the actual bound manuscript:
                 <dao href="http://gallica.bnf.fr/ark:/12148/btv1b52000943c"/>
                 
                 Images of the actual bound manuscript:
                 <dao actuate="onrequest" href="http://gallica.bnf.fr/ark:/12148/btv1b60007552" title="Accéder au manuscrit numérisé"/>
                 
                 # In this case, the online ead seems to be closer to the EAD we have:
                 /data/source/findingAids/bnf/preliminary/selection_of_letters_Francis_I.xml
                 
                 <eadid>FRBNFEAD000050342</eadid>
                 
                 http://archivesetmanuscrits.bnf.fr/ead.html?id=FRBNFEAD000050342
            -->
            <url/>
            <identifier/>
        </source>
        <source>
            <sourceCode>byu</sourceCode>
            <sourceName>Brigham Young University</sourceName>
            <!--
                /data/source/findingAids/byu/UPB_MSS4085.xml
                
                <eadid countrycode="US" mainagencycode="US-UPB" publicid="-//L. Tom Perry Special
                Collections::20th Century Western &amp; Mormon Manuscripts//TEXT(US::US-UPB::MSS 4085::Uintah
                County Juvenile Court records)//EN" encodinganalog="identifier">UPB_MSS4085</eadid>
                
                # Note the %20 in the URL. HTML, human readable
                http://findingaid.lib.byu.edu/viewItem/MSS%204085
                
                /data/source/findingAids/byu/UPB_MSSSC2175.xml

                <eadid countrycode="US" mainagencycode="US-UPB" publicid="-//L. Tom Perry Special
                Collections::19th Century Western &amp; Mormon Manuscripts//TEXT (US::US-UPB::MSS SC
                2175::Sybren van Dyk diaries)//EN" encodinganalog="identifier">UPB_MSSSC2175</eadid>
                
                # Yikes! Two %20 in the url.
                http://findingaid.lib.byu.edu/viewItem/MSS%20SC%202175
                
                /data/source/findingAids/byu/UPB_UA5399.xml
                
                <eadid countrycode="US" mainagencycode="US-UPB" publicid="-//L. Tom Perry Special
                Collections::University Archives//TEXT(US::US-UPB::UA 5399::Ephraim Hatch photographs of the
                Harold B. Lee Library and the Provo City Library)//EN"
                encodinganalog="identifier">UPB_UA5399</eadid>
                
                # Seems to work to parse out "UA 5399" from eadid@publicid.
                http://findingaid.lib.byu.edu/viewItem/UA%205399
            -->
            <url/>
            <identifier/>
        </source>
        <source>
            <sourceCode>cjh</sourceCode>
            <sourceName>Center for Jewish History</sourceName>
            <!--

/data/source/findingAidscjh/yum-ead-snac/1078462_BernardBernstein.xml

 <eadid mainagencycode="NyNyCJH" countrycode="us" encodinganalog="856$u" publicid="-//us::nnlbi//TEXT
 us::nnlbi::FILENAME.xml//EN">BernardBernstein</eadid>

Guide to the Papers of Bernard Bernstein

# works, via google. Use the pid from the filename.
http://findingaids.cjh.org/?pID=1078462

# nope
http://findingaids.cjh.org/BernardBernstein.html

                /data/source/findingAids/cjh/yum-ead-snac/92140_RuthAbrams02.xml
                
                <eadid mainagencycode="NyNyCJH">RuthAbrams02</eadid>
                
                # (old) Odd with double // after the domain name.
                http://findingaids.cjh.org//RuthAbrams02.html
                
                # (old) This works (single / after the domain name). human readable
                http://findingaids.cjh.org/RuthAbrams02.html
                
                /data/source/findingAids/cjh/yum-ead-snac/92138_SampsonEngoren.xml
                
                <eadid mainagencycode="NyNyCJH" encodinganalog="856$u" publicid="-//us::nnyu//TEXT us::nnyu::FILENAME.xml//EN" countrycode="us">SampsonEngoren</eadid>
                
                # (old) Seems to work using the eadid value.
                http://findingaids.cjh.org/SampsonEngoren.html
            -->
            <url/>
            <identifier/>
        </source>
        <source>
            <sourceCode>colu</sourceCode>
            <sourceName>Columbia University</sourceName>
            <!--
                /data/source/findingAids/colu/nnc-ua/ldpd_8429267_ead.xml
                
                <eadid countrycode="US" encodinganalog="Identifier" publicid="-//us::nnc-ua//TEXT
                us::nnc-ua::ldpd_8429267_ead//EN" mainagencycode="nnc-ua">ldpd_8429267_ead.xml</eadid>
                
                # Odd that there are URLs with double //. Single / works fine of course., human readable
                http://findingaids.cul.columbia.edu/ead//nnc-ua/ldpd_8429267
                
                # Adding the suffix "_ead.xml" does not work, and it is unclear what that document is.
                # "_ead" also doesn't work. Both urls with a suffix appear to be empty.
                
                # Works fine. 
                http://findingaids.cul.columbia.edu/ead/nnc-ua/ldpd_8429267

                > find /data/source/findingAids/colu/ -type d | less
                /data/source/findingAids/colu/
                /data/source/findingAids/colu/nnc-ua
                /data/source/findingAids/colu/nnc-rb
                /data/source/findingAids/colu/nnc-ea
                /data/source/findingAids/colu/nnc-a
            -->
            <url/>
            <identifier/>
        </source>
        <source>
            <sourceCode>crnlu</sourceCode>
            <sourceName>Cornell University</sourceName>
            <!-- 
                 /data/source/findingAids/crnlu/KCL05619-040.xml
                 
                 <eadid mainagencycode="nic" countrycode="us" publicid="-//Cornell University::Cornell
                 University Library::Kheel Center for Labor-Management Documentation and
                 Archives//TEXT(US::NIC::KCL05619-040::ACWA's Sidney Hillman Foundation
                 Records)//EN">KCL05619-040.xml</eadid>
                 
                 # Works, human readable
                 http://rmc.library.cornell.edu/EAD/xml/dlxs/KCL05619-040.xml
                 
                 # Works, but their server suggests the "xml" url above
                 http://rmc.library.cornell.edu/EAD/xml/dlxs/KCL05619-040
                 
                 # Also works, but probably not the record of reference:
                 http://ebooks.library.cornell.edu/cgi/f/findaid/findaid-idx?c=rmc;cc=rmc;rgn=main;view=text;didno=KCL05619-040.xml
                 
                 /data/source/findingAids/crnlu/RMM04613.xml
                 
                 <eadid mainagencycode="nic" countrycode="us" publicid="-//Cornell University::Cornell
                 University Library::Division of Rare and Manuscript
                 Collections//TEXT(US::NIC::RMM04613::A.J. Liebling collection)//EN">RMM04613.xml</eadid>
                 
                 # Works
                 http://rmc.library.cornell.edu/EAD/xml/dlxs/RMM04613.xml
            -->
            <url/>
            <identifier/>
        </source>
        <source>
            <sourceCode>duke</sourceCode>
            <sourceName>Duke University</sourceName>
            <!-- 

/data/source/findingAids/duke/toolkit-EAD/taylorcharlesforbes.xml

<eadid countrycode="US" mainagencycode="US-NcD" url="http://library.duke.edu/rubenstein/findingaids/taylorcharlesforbes/taylorcharlesforbes/">taylorcharlesforbes</eadid>

# workes, guessed, apparent typo in eadid@url
http://library.duke.edu/rubenstein/findingaids/taylorcharlesforbes/

# no
http://library.duke.edu/rubenstein/findingaids/taylorcharlesforbes/taylorcharlesforbes/


/data/source/findingAids/duke/toolkit-EAD/jarrattpuryearfamily.xml

<eadid countrycode="US" mainagencycode="US-NcD" url="http://library.duke.edu/rubenstein/findingaids/jarrattpuryear/">jarrattpuryear</eadid>

# works, via google, and this: http://184.168.105.185/archivegrid/collection/data/19933762
http://library.duke.edu/rubenstein/findingaids/jarrattpuryearfamily/

# no
http://library.duke.edu/rubenstein/findingaids/jarrattpuryear/

                 /data/source/findingAids/duke/toolkit-EAD/barnsleygodfrey.xml
                 
                 <eadid countrycode="US" mainagencycode="US-NcD"
                 url="http://library.duke.edu/rubenstein/findingaids/barnsleygodfrey/">barnsleygodfrey</eadid>
                 
                 # Works, human readable
                 http://library.duke.edu/rubenstein/findingaids/barnsleygodfrey/
                 
                 /data/source/findingAids/duke/classic-EADs/uafacman.xml
                 
                 <eadid countrycode="us" mainagencycode="ndd" publicid="-//University Archives//TEXT
                 (US::ndd::Facilities Management Department records, 1990-2006)//EN"
                 url="http://library.duke.edu/rubenstein/findingaids/uafacman/">uafacman</eadid>
                 
                 # Works. Title is very slightly different. 
                 http://library.duke.edu/rubenstein/findingaids/uafacman/

                 > find /data/source/findingAids/duke/ -type d       
                 /data/source/findingAids/duke/
                 /data/source/findingAids/duke/toolkit-EAD
                 /data/source/findingAids/duke/classic-EADs
            -->
            <url/>
            <identifier/>
        </source>
        <source>
            <sourceCode>fivecol</sourceCode>
            <sourceName>Five Colleges</sourceName>
            <!-- 
                 /data/source/findingAids/fivecol/manosca47.xml
                 <eadid publicid="-//us::manosca//TEXT us::manosca::manosca47.xml//EN" countrycode="us" mainagencycode="manosca">manosca47</eadid>
                 # Works
                 http://asteria.fivecolleges.edu/findaids/smitharchives/manosca47.html
                 
                 /data/source/findingAids/fivecol/mshm484.xml
                 <eadid publicid="-//us::mshm//TEXT us::mshm::mshm484.xml//EN" countrycode="us" mainagencycode="mshm">mshm484</eadid>
                 # works
                 http://asteria.fivecolleges.edu/findaids/mountholyoke/mshm484.html
                 
                 /data/source/findingAids/fivecol/ma19.xml
                 <eadid publicid="-//us::ma//TEXT us::ma::ma19.xml//EN" countrycode="us" mainagencycode="ma">ma19</eadid>
                 # works
                 http://asteria.fivecolleges.edu/findaids/amherst/ma19.html
                 
                 /data/source/findingAids/fivecol/mah1.xml
                 <eadid publicid="-//us::mah//TEXT us::mah::mah1.xml//EN" countrycode="us" mainagencycode="mah">mah1</eadid>
                 # works
                 http://asteria.fivecolleges.edu/findaids/hampshire/mah1.html
                 
                 /data/source/findingAids/fivecol/manoscmr16.xml
                 <eadid countrycode="us" mainagencycode="manoscmr" url="http://asteria.fivecolleges.edu/findaids/mortimer/manoscmr16.html">manoscmr16</eadid>
                 # works
                 http://asteria.fivecolleges.edu/findaids/mortimer/manoscmr16.html
                 
                 /data/source/findingAids/fivecol/mnsss450.xml
                 <eadid publicid="-//us::mnsss//TEXT us::mnsss::msss502.xml//EN" countrycode="us" mainagencycode="mnsss">msss502</eadid>
                 # works
                 http://asteria.fivecolleges.edu/findaids/sophiasmith/mnsss450.html
                 
                 /data/source/findingAids/fivecol/msss502.xml
                 <eadid publicid="-//us::mnsss//TEXT us::mnsss::msss502.xml//EN" countrycode="us" mainagencycode="mnsss">msss502</eadid>
                 # works
                 http://asteria.fivecolleges.edu/findaids/sophiasmith/msss502.html
                 
                 /data/source/findingAids/fivecol/mufs060.xml
                 <eadid publicid="-//us::mu//TEXT us::mu::mufs060.xml//EN" countrycode="us" mainagencycode="mu">mufs060</eadid>
                 # works
                 http://asteria.fivecolleges.edu/findaids/umass/mufs060.html
                 
                 /data/source/findingAids/fivecol/mums235.xml
                 <eadid publicid="-//us::mu//TEXT us::mu::mums235.xml//EN" countrycode="us" mainagencycode="mu">mums235</eadid>
                 # works
                 http://asteria.fivecolleges.edu/findaids/umass/mums235.html
                 
                 /data/source/findingAids/fivecol/muph006.xml
                 <eadid publicid="-//us::mu//TEXT us::mu::muph006.xml//EN" countrycode="us" mainagencycode="mu">muph006</eadid>
                 # works
                 http://asteria.fivecolleges.edu/findaids/umass/muph006.html
                 
                 /data/source/findingAids/fivecol/murg3_1_b88.xml
                 <eadid publicid="-//us::mu//TEXT us::mu::murg3_1_b88.xml//EN" countrycode="us" mainagencycode="mu">murg3_1_b88</eadid>
                 # works
                 http://asteria.fivecolleges.edu/findaids/umass/murg3_1_b88.html
                 
                 > grep -Po "fivecol\/.*?\d+" logs/fivecol.log | perl -ne '$_ =~ m/fivecol\/(.*?)\d+/; print "$1\n";' | sort -u     
                 ma
                 mah
                 manosca
                 manoscmr
                 mnsss
                 mshm
                 msss
                 mufs
                 mums
                 muph
                 murg

                 # Index
                 http://asteria.fivecolleges.edu/findaids/hampshire/
                 # Cocoon failure
                 http://asteria.fivecolleges.edu/findaids/hampshire/mah1.xml
            -->
            <url/>
            <identifier/>
        </source>
        <source>
            <sourceCode>fsga</sourceCode>
            <sourceName>Freer Sackler Gallery Archives (Smithsonian Institution)</sourceName>
            <!--
                # Apparently not possible to find the "real" finding aid without looking at the href in the
                # title="Finding Aid" link. Even the siris_bib id links to an incomplete summary of the real finding aid.
                
                # Daniel suggested this:
                https://www.asia.si.edu/research/archivesFindingAids.asp
                
                /data/source/findingAids/fsga/FSA.A1989.xml
                
                <eadid countrycode="US" mainagencycode="US-DSI-FSA"
                url="http://www.asia.si.edu/visitor/archivesFindingAids.htm">FSA.A1989.xml</eadid>

                <titleproper>A Finding Aid to the Dwight William Tryon papers, circa 1872-1930</titleproper>
                
                <notestmt><note><p>This finding aid was created from a MARC collection-level record.<num
                type="siris_bib">279719</num></p></note></notestmt>

                # Incomplete summary, has a link with a different format from the link in the finding aid below.
                http://collections.si.edu/search/results.htm?q=record_ID:siris_arc_279719

                # Print version, incomplete summary
                http://collections.si.edu/search/results.htm?print=yes&q=record_ID:siris_arc_279719

                # Works, but doesn't use any of our EAD data. Found this on the summary page above.
                http://www.asia.si.edu/archives/finding_aids/tryon.htm
                
                # no
                http://www.asia.si.edu/archives/finding_aids/FSA.A1989.xml
                # no
                http://www.asia.si.edu/collections/finding_aids/FSA.A1989.xml
                # no
                http://collections.si.edu/findingaids/FSA.A1989.xml

                # Ditto, plain xml
                http://www.asia.si.edu/archives/finding_aids/tryon.xml
                
                /data/source/findingAids/fsga/FSA.A2001.14.xml
                <eadid countrycode="US" mainagencycode="US-DSI-FSA">FSA.A2001.14.xml</eadid>
                <num type="siris_bib">279715</num>

                # summary only
                http://collections.si.edu/search/results.htm?q=record_ID:siris_arc_279715

                # more complete finding aid, but still not as much info as FSA.A2001.14.xml
                http://siris-archives.si.edu/ipac20/ipac.jsp?&profile=all&source=~!siarchives&uri=full=3100001~!279715~!0#focus

                # 
                http://www.asia.si.edu/archives/finding_aids/bahr.htm
                http://www.asia.si.edu/archives/finding_aids/bahr.xml
            -->
            <url/>
            <identifier/>
        </source>
        <source>
            <sourceCode>harvard</sourceCode>
            <sourceName>Harvard University</sourceName>
            <!--
                /data/source/findingAids/harvard/med00075.xml
                <eadid identifier="000603644">med00075</eadid>

                # Works, human readable, Must change &amp; to & for the real url
                http://oasis.lib.harvard.edu//oasis/deliver/deepLink?_collection=oasis&uniqueId=med00075
            -->
            <url>http://oasis.lib.harvard.edu//oasis/deliver/deepLink?_collection=oasis&amp;uniqueId=</url>
            <identifier>baseFileName</identifier>
        </source>
        <source>
            <sourceCode>howard</sourceCode>
            <sourceName>Howard University</sourceName>
            <!--
                # No finding aids found.
                /data/source/findingAids/howard/Coll._007-ead.xml
                <eadid countrycode="US" mainagencycode="US-DHU-MS"/>
                <unitid>Coll. 007</unitid>
                
                http://www.howard.edu/msrc/manuscripts_processed_listings.html
            -->
            <url/>
            <identifier/>
        </source>
        <source>
            <sourceCode>inu</sourceCode>
            <sourceName>Indiana University</sourceName>
            <!--
                /data/source/findingAids/inu/InU-Ar-VAC0395.xml
                <eadid countrycode="US" encodinganalog="identifier" mainagencycode="InU-Ar" identifier="InU-Ar-VAC0395">InU-Ar-VAC0395</eadid>

                # works, human readable
                http://webapp1.dlib.indiana.edu/findingaids/view?doc.view=entire_text&docId=InU-Ar-VAC0395
                
                /data/source/findingAids/inu/InU-Li-VAA1280.xml
                <eadid encodinganalog="identifier" identifier="InU-Li-VAA1280" countrycode="US" mainagencycode="InU-Li">InU-Li-VAA1280</eadid>

                # works
                http://webapp1.dlib.indiana.edu/findingaids/view?doc.view=entire_text&docId=InU-Li-VAA1280
            -->
            <url/>
            <identifier/>
        </source>
        <source>
            <sourceCode>lds</sourceCode>
            <sourceName>Church of Latter Day Saints Archives</sourceName>
            <!--
                # No clear rule(s) to transform eadid into the URL. Can't predict when to insert a space,
                # where to insert space. Instead use the addressline/extptr with eadview.lsd.org instead.
                # extptr not reliable.

                /data/source/findingAids/lds/MS_15339.xml
                
                <eadid encodinganalog="identifier" countrycode="US" mainagencycode="US-USlC" publicid="-//The Church of Jesus
                Christ of Latter-day Saints::Church History Library//TEXT (US::US-USlC::USlC_MS15339.xml::Armintia Achsa
                Wilson Wilkins Family papers//EN">USlC_MS15339</eadid>
                
                # addressline/extptr
                <extptr xlink:href="https://eadview.lds.org/findingaid/MS 15339"/>

                # Works The actual URL needs " " encoded as %20, human readable
                https://eadview.lds.org/findingaid/MS%2015339
                
                # Note that filenames had spaces changed to "_", but the eadid is unchanged and has a mixture
                # of underscore and spaces with no clear logic.
                
                /data/source/findingAids/lds/M270_K49h_v._1-8_1992.xml
                
                <eadid encodinganalog="identifier" countrycode="US" mainagencycode="US-USlC" publicid="-//The
                Church of Jesus Christ of Latter-day Saints::Church History Library//TEXT
                (US::US-USlC::USlC_M270K49h_v. 1-8 1992.xml::Heber C. Kimball family
                history//EN">USlC_M270K49h_v. 1-8 1992</eadid>
                
                <extptr xlink:href="https://eadview.lds.org/findingaid/M270 K49h v. 1-8 1992"/>
                
                # No.
                https://eadview.lds.org/findingaid/M270 K49h v. 1-8 1992
                
                # No. 
                https://eadview.lds.org/findingaid/M270K49h_v.1-81992
            -->
            <url/>
            <identifier/>
        </source>
        <source>
            <sourceCode>lc</sourceCode>
            <sourceName>Library of Congress</sourceName>
            <!--
                /data/source/findingAids/lc/ms010225.xml
                
                <eadid mainagencycode="US-DLC" countrycode="US" identifier="hdl:loc.mss/eadmss.ms010225"
                encodinganalog="856$u">http://hdl.loc.gov/loc.mss/eadmss.ms010225</eadid>
                
                # works, human readable, redirects to a summary page, this is what they request people bookmark/cite
                http://hdl.loc.gov/loc.mss/eadmss.ms010225
                
                # What they give as the link to the xml version
                http://hdl.loc.gov/loc.mss/eadmss.ms010225.2
            -->
            <url></url>
            <identifier>eadid/@identifier</identifier>
            <!-- substring after hdl: or just use the eadid value (which is simpler) -->
        </source>
        <source>
            <sourceCode>meas</sourceCode>
            <sourceName>Maine Archives Search</sourceName>
            <!-- 
                 # Can't determine if the id in the URL has a dot or space (%20). Any leading zero on the id
                 # number seems to be removed. 

                 /data/source/findingAids/meas/plummeremacon.xml
                 
                 <eadid publicid="MS.0413" countrycode="US" mainagencycode="US-meU">MS.0413</eadid>
                 
                 # Works. found via http://www.library.umaine.edu/speccoll/eadsearch/
                 http://www.library.umaine.edu/speccoll/eadsearch/detail.aspx?pno=0&id=MS.413
                 
                 # Found via a browsing page
                 http://www.library.umaine.edu/speccoll/FindingAids/PlummerE.htm
                 
                 <eadid encodinganalog="852$a" publicid="MS 447" countrycode="US" mainagencycode="US-MeU">Source=DLC System ID= MS 447</eadid>
                 
                 /data/source/findingAids/meas/sanfordf.xml
                 
                 # Works, from the search page
                 http://www.library.umaine.edu/speccoll/eadsearch/detail.aspx?pno=0&id=MS%20447
                 
                 # No.
                 http://www.library.umaine.edu/speccoll/eadsearch/detail.aspx?pno=0&id=MS.447
                 
                 /data/source/findingAids/meas/kellmanpetermacon.xml
                 
                 <eadid publicid="MS.0271" countrycode="US" mainagencycode="US-meU">MS.0271</eadid>
                 
                 # Works, from the search
                 http://www.library.umaine.edu/speccoll/eadsearch/detail.aspx?pno=0&id=MS%20271
                 
                 # No.
                 http://www.library.umaine.edu/speccoll/eadsearch/detail.aspx?pno=0&id=MS.271
            -->
            <url/>
            <identifier/>
        </source>
        <source>
            <sourceCode>mhs</sourceCode>
            <sourceName>Minnesota Historical Society</sourceName>
            <!-- 
                 # Some eadid values have .xml which needs to be trimmed off since we always add a .xml suffix.
                 
                 # Only 10 failures
                 
                 missing file: mhs/00908.xml url: http://www.mnhs.org/library/findaids/00908.xml 
                 missing file: mhs/00378.xml url: http://www.mnhs.org/library/findaids/00378.xml 
                 missing file: mhs/govcdd05.xml url: http://www.mnhs.org/library/findaids/govcdd05.xml 
                 missing file: mhs/00480.xml url: http://www.mnhs.org/library/findaids/00480.xml 
                 missing file: mhs/00790.xml url: http://www.mnhs.org/library/findaids/00790.xml 
                 missing file: mhs/00445.xml url: http://www.mnhs.org/library/findaids/00445.xml 
                 missing file: mhs/00444.xml url: http://www.mnhs.org/library/findaids/00444.xml 
                 missing file: mhs/P400.xml url: http://www.mnhs.org/library/findaids/P400.xml 
                 missing file: mhs/00443.xml url: http://www.mnhs.org/library/findaids/00443.xml 
                 missing file: mhs/00494.xml url: http://www.mnhs.org/library/findaids/00494.xml 
                 
                 /data/source/findingAids/mhs/00908.xml
                 
                 <eadid countrycode="us" mainagencycode="MnHi">00908.xml</eadid>
                 
                 GREAT NORTHERN RAILWAY COMPANY: ADVERTISING AND PUBLICITY DEPARTMENT: An Inventory of Its Lantern Slides at
                 the Minnesota Historical Society
                 
                 # no, but is in a link on their web site, so probably a mistaken 40
                 # linked from here: http://www.mnhs.org/library/findaids/index-WhatsNew-June2011.htm
                 http://www.mnhs.org/library/findaids/00908.xml

                 /data/source/findingAids/mhs/P2513.xml
                 
                 <eadid countrycode="us" mainagencycode="MnHi">Fraternal organizationsp2513</eadid>
                 
                 UNION VETERANS' UNION. JOHN A. LOGAN REGIMENT, NO. 2: An Inventory of Its Records at the
                 Minnesota Historical Society
                 
                 # works, via google.
                 http://www.mnhs.org/library/findaids/P2513.xml
                 
                 # no
                 http://www.mnhs.org/library/findaids/Fraternalorganizationsp2513.xml
                 
                 # no
                 http://www.mnhs.org/library/findaids/Fraternal%20organizationsp2513.xml

                 # no
                 http://www.mnhs.org/library/findaids/Fraternal organizationsp2513.xml
                 
                 /data/source/findingAids/mhs/lb00055.xml
                 
                 <eadid countrycode="us" mainagencycode="MnHi"> <?replace_text {fileName, or delete if there
                 is no file name}?> </eadid>
                 
                 Norman County, Minnesota : An Inventory of Telephone Directories at the Minnesota Historical
                 Society
                 
                 # works, find by guessing
                 http://www.mnhs.org/library/findaids/lb00055.xml

                 # no
                 http://www.mnhs.org/library/findaids/.xml
                 
                 /data/source/findingAids/mhs/SAM184.xml
                 
                 <eadid countrycode="us" mainagencycode="MnHi">SAM184,xml</eadid>
                 
                 # works, found by guessing
                 http://www.mnhs.org/library/findaids/SAM184.xml

                 # No
                 http://www.mnhs.org/library/findaids/SAM184,xml.xml

                 /data/source/findingAids/mhs/gr00027.xml
                 <eadid countrycode="us" mainagencycode="MnHi">gr00027</eadid>

                 # works, human readable
                 http://www.mnhs.org/library/findaids/gr00027.xml
            -->
            <url/>
            <identifier/>
        </source>
        <source>
            <sourceCode>mit</sourceCode>
            <sourceName>Massachusetts Institute of Technology</sourceName>
            <!--
                /data/source/findingAids/mit/AC.0072-ead.xml
                
                # Apparently missing "/collections" in the middle of the URL.
                
                <eadid countrycode="US" mainagencycode="US-mcm"
                url="http://libraries.mit.edu/archives/research/collections-ac/ac72.html">AC 72</eadid>

                # This works. human readable, eadid@url is wrong, but can be modified to work
                http://libraries.mit.edu/archives/research/collections/collections-ac/ac72.html
                
                /data/source/findingAids/mit/MC.0572-ead.xml
                
                <eadid countrycode="US" mainagencycode="US-mcm"
                url="http://libraries.mit.edu/archives/research/collections/collections-mc/mc572.html">MC
                572</eadid>
                
                # Works. This is eadid@url unmodified, so clearly some records have @url correct
                http://libraries.mit.edu/archives/research/collections/collections-mc/mc572.html
                
                # Works. Odd that ac205 is a directory and not an html file name.
                http://libraries.mit.edu/archives/research/collections/collections-ac/ac205/
                
                # There are two files with lowercase ac or mc. Both have missing finding aids.
                > grep fn: logs/mit.log| grep -Pv "mit\/MC|mit\/AC" | less
                fn: /data/source/findingAids/mit/ac.0048-ead.xml
                fn: /data/source/findingAids/mit/mc.0670-ead.xml
                
                # Missing. Unclear why.
                /data/source/findingAids/mit/ac.0048-ead.xml
                # 404
                http://libraries.mit.edu/archives/research/collections/collections-ac/ac48.html
                
                # Missing 404, even after fixing the URL to by adding "/collections"
                /data/source/findingAids/mit/mc.0670-ead.xml
                <eadid countrycode="US" mainagencycode="US-mcm" url="http://libraries.mit.edu/archives/research/collections-mc/mc670.html">MC 670</eadid>
                # 404
                http://libraries.mit.edu/archives/research/collections/collections-mc/mc670.html
            -->
            <url/>
            <identifier/>
        </source>
        <source>
            <sourceCode>ncsu</sourceCode>
            <sourceName>North Carolina State University</sourceName>
            <!--
                # ncsu does not respond to wget \-\-spider unclear why.

                /data/source/findingAids/ncsu/ua023_020.xml
                <eadid url="http://www.lib.ncsu.edu/findingaids/ua023_020">ua023_020</eadid>

                # Works. Human readable.
                http://www.lib.ncsu.edu/findingaids/ua023_020

                # Works. Full xml
                http://www.lib.ncsu.edu/findingaids/ua023_020.xml                

            -->
            <url/>
            <identifier/>
        </source>
        <source>
            <sourceCode>nlm</sourceCode>
            <sourceName>National Library of Medicine</sourceName>
            <!--
                /data/source/findingAids/nlm/sydenham.xml
                
                <eadid publicid="PUBLIC &quot;-//National Library of Medicine::History of Medicine
                Division//TEXT&#10; (US::DNLM::MS C 243::Sydenham Hospital Records)//EN&quot; &quot;sydenham"

                countrycode="us" mainagencycode="DNLM">sydenham</eadid>

                # Works, human readable
                http://oculus.nlm.nih.gov/sydenham

                # redirects to
                http://oculus.nlm.nih.gov/cgi/f/findaid/findaid-idx?c=nlmfindaid;idno=sydenham

                # Works, full text, didno is required
                http://oculus.nlm.nih.gov/cgi/f/findaid/findaid-idx?c=nlmfindaid;view=text;didno=sydenham
                
                /data/source/findingAids/nlm/101549021.xml
                
                <eadid publicid="-//National Library of Medicine::History of Medicine Division::Archives and
                Modern Manuscripts Collection//TEXT//EN" countrycode="us"
                mainagencycode="DNLM">101549021</eadid>
                
                # Works, human readable
                http://oculus.nlm.nih.gov/101549021

                # Works, full text
                http://oculus.nlm.nih.gov/cgi/f/findaid/findaid-idx?c=nlmfindaid;cc=nlmfindaid;view=text;rgn=main;didno=101549021
            -->
            <url/>
            <identifier/>
        </source>
        <source>
            <sourceCode>nmaia</sourceCode>
            <sourceName>National Museum of the American Indian Archives (Smithsonian Institution)</sourceName>
            <!-- 
                 /data/source/findingAids/nmaia/NMAI.AC.024.xml

                 <eadid countrycode="US" mainagencycode="US-MdSuSIAI">AC024_kaplan</eadid>
                 
                 # Works. Seems odd to only have a pdf.
                 http://nmai.si.edu/sites/1/files/archivecenter/AC024_kaplan.pdf
                 
                 # Works. html
                 http://nmai.si.edu/sites/1/files/archivecenter/AC024_kaplan.html

                 # The "finding aid" link here goes to the same pdf.
                 http://siris-archives.si.edu/ipac20/ipac.jsp?session=1E9U6941W0493.58133&profile=all&uri=full=3100001~!282696~!1&ri=1&aspect=Browse&menu=search&source=~!siarchives&ipp=20&spp=20&staffonly=&term=Oaxaca+(Mexico+:+State)&index=PSUBJ&uindex=&aspect=Browse&menu=search&ri=1
            -->
            <url/>
            <identifier/>
        </source>
        <source>
            <sourceCode>nwda</sourceCode>
            <sourceName>Northwest Digital Archives</sourceName>
            <!-- 
                 /data/source/findingAids/nwda/lewis_and_clark_college/OLPb056WHI.xml
                 
                 <eadid countrycode="us" encodinganalog="identifier"
                 url="http://nwda.orbiscascade.org/ark:/80444/xv57653" mainagencycode="OrPL"
                 identifier="80444/xv57653">OLPb056WHI.xml</eadid>
                 
                 # Works. human readable, The directory name ends in a colon because it is an ark, not a directory name.
                 http://nwda.orbiscascade.org/ark:/80444/xv57653

                 # Works, redirects to orbiscascade.org
                 http://nwda-db.wsulibs.wsu.edu/findaid/ark:/80444/xv57653
            -->
            <url>http://nwda-db.wsulibs.wsu.edu/findaid/ark:/</url>
            <identifier>eadid/@identifier</identifier>
        </source>
        <source>
            <sourceCode>nwu</sourceCode>
            <sourceName>Northwestern University</sourceName>
            <!--
                /data/source/findingAids/nwu/inu:inu-ead-nua-archon-876.xml
                
                <eadid countrycode="US" encodinganalog="856$u" identifier="inu-ead-nua-archon-876" mainagencycode="US-US-IEN">11/3/11/12</eadid>
                
                # works, human readable
                http://findingaids.library.northwestern.edu/catalog/inu-ead-nua-archon-876
                
                # example
                http://findingaids.library.northwestern.edu/catalog/inu-ead-nua-archon-1525
            -->
            <url/>
            <identifier/>
        </source>
        <source>
            <sourceCode>nypl</sourceCode>
            <sourceName>New York Public Library</sourceName>
            <!-- 
                 /data/source/findingAids/nypl/brg22240.xml

                 <eadid countrycode="US" mainagencycode="US-NN" url="http://archives.nypl.org/brg/22240.xml">brg22240.xml</eadid>
                 
                 # works, human readable, html
                 http://archives.nypl.org/brg/22240
                 
                 # works, html
                 http://archives.nypl.org/brg/22240.html


                 # works, xml
                 http://archives.nypl.org/brg/22240.xml
            -->
            <url/>
            <identifier/>
        </source>
        <source>
            <sourceCode>nysa</sourceCode>
            <sourceName>New York State Archives</sourceName>
            <!--
                /data/source/findingAids/nysa/13681.xml
                <eadid countrycode="US" mainagencycode="N-Ar" url="www.archives.nysed.gov/aindex.shtml" encodinganalog="856$u">426</eadid>
                archdesc/did/<unitid>13681</unitid>

                # works, human readable, html
                http://iarchives.nysed.gov/xtf/view?docId=13681.xml
            -->
            <url>http://iarchives.nysed.gov/xtf/view?docId=</url>
            <identifier>fileName</identifier>
        </source>
        <source>
            <sourceCode>nyu</sourceCode>
            <sourceName>New York University</sourceName>
            <!--
                # There is only 1 phr record, and the finding aid does not appear online.
                /data/source/findingAids/nyu/phr/phr.xml
                <eadid countrycode="us" mainagencycode="NNU" identifier="[Call #]">phr</eadid>
                <addressline>Elmer Holmes Bobst Library<lb/>
                
                # Not missing, but bad
                xlf /data/source/findingAids/nyu/fales/amfam.xml
                # no, based on the eadid
                http://dlib.nyu.edu/findingaids/html/fales/amfam/amfam.html
                # Works. Found via nyu search engine
                http://dlib.nyu.edu/findingaids/html/fales/amfamily/
                
                
                # Missing, but is in the nyu search engine
                xlf /data/source/findingAids/nyu/nyhs/Imperial.xml
                <eadid countrycode="us" mainagencycode="yourcodehere" identifier="youridentifierhere">imperial</eadid>
                http://dlib.nyu.edu/findingaids/html/nyhs/imperial/imperial.html
                # 404, linked from nyu's own search engine
                http://dlib.nyu.edu/findingaids/html/nyhs/imperial

                # Bad. Nothing found for phr perhaps due to the identifier being "[Call #]"
                http://dlib.nyu.edu/findingaids/html/phr/phr/phr.html
                
                /data/source/findingAids/nyu/poly/bugliarello_chancellor.xml
                <eadid countrycode="US">bugliarello_chancellor</eadid>

                # Works, human readable, html
                http://dlib.nyu.edu/findingaids/html/poly/bugliarello_chancellor/bugliarello_chancellor.html

                # search results
                http://dlib.nyu.edu/findingaids/search/?q=RG.7&collectionId=poly&start=0
                
                /data/source/findingAids/nyu/nyhs/thompson.xml
                <eadid countrycode="US" mainagencycode="US-NHi">thompson</eadid>

                # works
                http://dlib.nyu.edu/findingaids/html/nyhs/thompson/thompson.html
                
                
                /data/source/findingAids/nyu/tamwag/aia_002.xml
                <eadid countrycode="US" mainagencycode="US-NNU-TL" url="http://dlib.nyu.edu/findingaids/html/tamwag/aia_002">aia_002</eadid>
                # works
                http://dlib.nyu.edu/findingaids/html/tamwag/aia_002/aia_002.html
                

/data/source/findingAids/nyu/nyhs/archtest.xml

                # Not all sub directories tested.
                
                > grep -Po "fn:.*?nyu\/.*?\/" logs/nyu.log  | sort | uniq -c
                193 fn: /data/source/findingAids/nyu/archives/
                1423 fn: /data/source/findingAids/nyu/bhs/
                250 fn: /data/source/findingAids/nyu/fales/
                346 fn: /data/source/findingAids/nyu/nyhs/
                1 fn: /data/source/findingAids/nyu/phr/
                13 fn: /data/source/findingAids/nyu/poly/
                16 fn: /data/source/findingAids/nyu/rism/
                1322 fn: /data/source/findingAids/nyu/tamwag/
                
                > find /data/source/findingAids/nyu/ -type d | sort -u
                /data/source/findingAids/nyu/
                /data/source/findingAids/nyu/archives
                /data/source/findingAids/nyu/bhs
                /data/source/findingAids/nyu/fales
                /data/source/findingAids/nyu/nyhs
                /data/source/findingAids/nyu/phr
                /data/source/findingAids/nyu/poly
                /data/source/findingAids/nyu/rism
                /data/source/findingAids/nyu/tamwag
            -->
            <url/>
            <identifier/>
        </source>
        <source>
            <sourceCode>oac</sourceCode>
            <sourceName>Online Archive of California</sourceName>
            <!--
                /data/source/findingAids/oac/ccoro/citruslabels.xml
                
                <eadid xmlns:cdlpath="http://www.cdlib.org/path/" countrycode="us" mainagencycode="CCoro"
                identifier="ark:/13030/kt3c60249v"
                cdlpath:parent="ark:/13030/kt0k4017ds">citruslabels.xml</eadid>
                
                # works, human readable, redirects to URL below
                http://www.oac.cdlib.org/ark:/13030/kt3c60249v/
                
                # redirected to from above
                http://www.oac.cdlib.org/findaid/ark:/13030/kt3c60249v/
                http://www.oac.cdlib.org/findaid/ark:/13030/kt3c60249v/entire_text/
            -->
            <url>http://www.oac.cdlib.org/findaid/</url>
            <identifier>eadid/@identifier</identifier>
        </source>
        <source>
            <sourceCode>ohlink</sourceCode>
            <sourceName>EAD FACTORY (OhioLink)</sourceName>
            <!--
                /data/source/findingAids/ohlink/OhCiUAR0188.xml
                <eadid mainagencycode="OhCiUAR" url="http://ohiolink.edu/EAD/oha.irk.html" countrycode="us">OhCiUAR0188</eadid>
                
                # Works, human readable, persistent link, from web page below
                http://rave.ohiolink.edu/archives/ead/OhCiUAR0188
                
                # Works, found via google.
                http://ead.ohiolink.edu/xtf-ead/view?docId=ead/OhCiUAR0188.xml
                http://ead.ohiolink.edu/xtf-ead/view?docId=ead/OhCiUAR0188.xml;query=;brand=default
            -->
            <url/>
            <identifier/>
        </source>
        <source>
            <sourceCode>pacscl</sourceCode>
            <sourceName>Philadelphia Area Consortium of Special Collections Libraries</sourceName>
            <!--
                /data/source/findingAids/pacscl/cca/CCA_Hatfield_FINAL-EAD.xml 

                <eadid/>
                <unitid>CCA.RG.3250.010</unitid>
   
                # dirname upper-case CCA
                # eadid 
                # mac 
                # unitid CCARG3250010
                # ? dirname eadid mainagencycode num or filename
                # Works, human readable
                http://dla.library.upenn.edu/dla/pacscl/ead.html?id=PACSCL_CCA_CCARG3250010

                # Permanent
                http://hdl.library.upenn.edu/1017/d/pacscl/CCA_CCARG3250010

                # Perm redirects here:
                http://dla.library.upenn.edu/dla/pacscl/detail.html?id=PACSCL_CCA_CCARG3250010

                # From the pacscl search engine:
                http://dla.library.upenn.edu/dla/pacscl/ead.html?q=CCA.RG.3250.010&id=PACSCL_CCA_CCARG3250010&
                
                /data/source/findingAids/pacscl/bmc/BMC.2010-01-ead.xml

                <eadid countrycode="US" mainagencycode="US-PBm"/>
                <unitid>BMC.2010-01</unitid>

                # We need to use the mainagencycode if it exists
                http://dla.library.upenn.edu/dla/pacscl/ead.html?id=PACSCL_BMC_USPBmBMC201001
                
                /data/source/findingAids/pacscl/cchs/CCHS_Thomas_Nursery.xml
                
                <eadid/>
                <unitid>CCHS.MS.Coll.189</unitid>
                
                
                /data/source/findingAids/pacscl/upenn_biddle/PU-L.ALI.04.003-ead.xml
                
                <eadid countrycode="US" mainagencycode="US-PU-L"
                url="http://dla.library.upenn.edu/dla/ead/detail.html?id=EAD_upenn_biddle_USPULPULALI04003">W:\pennlaw\bll\archives\findingaids\PU-L.ALI.04.003-ead.xml
                </eadid>
                <unitid>PU-L.ALI.04.003</unitid>
                
                # dirname upper-case
                # eadid WpennlawbllarchivesfindingaidsPULALI04003eadxml
                # mac USPUL
                # unitid PULALI04003
                # ? dirname eadid mainagencycode num or filename
                # Works!
                http://dla.library.upenn.edu/dla/pacscl/ead.html?id=PACSCL_UPENN_BIDDLE_WpennlawbllarchivesfindingaidsPULALI04003eadxmlUSPULPULALI04003

                # Works. Interesting internal string: "Wpennlawbllarchivesfindingaids".
                http://dla.library.upenn.edu/dla/ead/detail.html?id=EAD_upenn_biddle_WpennlawbllarchivesfindingaidsPULALI04003eadxmlUSPULPULALI04003

                # 404 (from eadid@url)
                http://dla.library.upenn.edu/dla/ead/detail.html?id=EAD_upenn_biddle_USPULPULALI04003
                
                /data/source/findingAids/pacscl/upenn_cajs/ARC_MS_26.xml

                <eadid countrycode="US" mainagencycode="US-US-US-PUCJS">PU-CJS ARC MS 26</eadid>
                <unitid>ARC.MS.26</unitid>                

                # works dirname eadid mainagencycode num or filename
                http://dla.library.upenn.edu/dla/pacscl/ead.html?id=PACSCL_UPENN_CAJS_PUCJSARCMS26USUSUSPUCJSARCMS26
                
                /data/source/findingAids/pacscl/du/UR.04.010-ead.xml
                
                <eadid countrycode="US" mainagencycode="US-DXU">ur04010</eadid>
                <unitid>UR.04.010</unitid>

                # Search UR.04.010 returns no records
                # Google finds this working URL:
                http://dla.library.upenn.edu/dla/pacscl/ead.html?id=PACSCL_DU_ur04010USDXUUR04010
                
                /data/source/findingAids/pacscl/du/MC.00.002-ead.xml

                <eadid countrycode="US" mainagencycode="US-DXU">mc00002</eadid>
                <unitid>MC.00.002</unitid>

                # Works
                http://dla.library.upenn.edu/dla/pacscl/ead.html?id=PACSCL_DU_mc00002USDXUMC00002
                
                # Check all repositories. 
                
                > grep -Po "fn:.*?pacscl\/.*?\/" logs/pacscl.log | sort | uniq -c 
                19 fn: /data/source/findingAids/pacscl/ansp/
                52 fn: /data/source/findingAids/pacscl/bmc/
                1 fn: /data/source/findingAids/pacscl/cca/
                8 fn: /data/source/findingAids/pacscl/cchs/
                28 fn: /data/source/findingAids/pacscl/cpp/
                71 fn: /data/source/findingAids/pacscl/du/
                28 fn: /data/source/findingAids/pacscl/ducom/
                54 fn: /data/source/findingAids/pacscl/flp/
                41 fn: /data/source/findingAids/pacscl/gsp/
                74 fn: /data/source/findingAids/pacscl/haverford/
                618 fn: /data/source/findingAids/pacscl/hsp/
                22 fn: /data/source/findingAids/pacscl/ism/
                14 fn: /data/source/findingAids/pacscl/lcp/
                2 fn: /data/source/findingAids/pacscl/ltsp/
                1 fn: /data/source/findingAids/pacscl/nara/
                4 fn: /data/source/findingAids/pacscl/pca/
                8 fn: /data/source/findingAids/pacscl/pennhort/
                6 fn: /data/source/findingAids/pacscl/pma/
                10 fn: /data/source/findingAids/pacscl/rml/
                15 fn: /data/source/findingAids/pacscl/tuscrc/
                7 fn: /data/source/findingAids/pacscl/udel/
                2 fn: /data/source/findingAids/pacscl/ul/
                119 fn: /data/source/findingAids/pacscl/upenn_biddle/
                6 fn: /data/source/findingAids/pacscl/upenn_cajs/
                48 fn: /data/source/findingAids/pacscl/upenn_museum/
                82 fn: /data/source/findingAids/pacscl/upenn_rbml/
                10 fn: /data/source/findingAids/pacscl/wfis/
             -->
            <url/>
            <identifier/>
        </source>
        <source>
            <sourceCode>pu</sourceCode>
            <sourceName>Princeton University</sourceName>
            <!--
                /data/source/findingAids/pu/mudd_publicpolicy/MC001.03.EAD.xml
                
                <eadid countrycode="US" encodinganalog="dc:identifier" mainagencycode="US-NjP"
                url="http://arks.princeton.edu/ark:/88435/p8418n298"
                urn="ark:/88435/p8418n298">MC001.03</eadid>

                # Works, human readable summary with a link to entire finding aid
                http://arks.princeton.edu/ark:/88435/p8418n298

                # Works, entire finding aid on one page
                http://findingaids.princeton.edu/collections/MC001.03?view=onepage
                
                /data/source/findingAids/pu/eng/ENG021.EAD.xml

                # works, value-of eadid@url
                http://arks.princeton.edu/ark:/88435/wm117p067
            -->
            <url/>
            <identifier/>
        </source>
        <source>
            <sourceCode>riamco</sourceCode>
            <sourceName>Rhode Island Archival &amp; Manuscript Collections Online</sourceName>
            <!-- 
                 /data/source/findingAids/riamco/US-RPB-ms2007.032.xml
                 <eadid countrycode="US" mainagencycode="US-RPB" identifier="ms2007.032.xml">US-RPB-ms2007.032</eadid>

                 # Their site search returns &view=title URLs. There doesn't appears to be a view=all option.
                 # No docs for the php scripts and CGI interface. There is a pdf option (see below).
                 http://library.brown.edu/riamco/render.php?eadid=US-RPB-ms2007.032&view=title
                 
                 /data/source/findingAids/riamco/US-RNN-ms17.xml
                 <eadid identifier="ms17.xml" mainagencycode="US-RNN" countrycode="US">US-RNN-ms17</eadid>
                 
                 # works, human readable, but is a summary page with links to each section
                 http://library.brown.edu/riamco/render.php?eadid=US-RNN-ms17&view=title

                 # pdf, appears to be created on the fly and delivered as a pop-up which is unfortunate
                 # since anyone with an ounce of security awareness has pop-ups blocked.
                 http://library.brown.edu/riamco/mkpdf.php?eadd=US-RNN-ms17

                 # pdf redirects here:
                 http://library.brown.edu/riamco/xml2pdffiles/US-RNN-ms17.pdf
            -->
            <url/>
            <identifier/>
        </source>
        <source>
            <sourceCode>rmoa</sourceCode>
            <sourceName>Rocky Mountain Online Archive</sourceName>
            <!--
                /data/source/findingAids/rmoa/nmsmac418-s.xml
                <eadid publicid="-////TEXT(US::NmSm::AC 418-s)//EN" countrycode="us" mainagencycode="NmSm" encodinganalog="Identifier"/>

                # works, human readable
                http://rmoa.unm.edu/docviewer.php?docId=nmsmac418-s.xml
                http://rmoa.unm.edu/printerfriendly.php?docId=nmsmac418-s.xml
                
                /data/source/findingAids/rmoa/nmumss817bc.xml
                # works
                http://rmoa.unm.edu/docviewer.php?docId=nmumss817bc.xml
            -->
            <url/>
            <identifier/>
        </source>
        <source>
            <sourceCode>rutu</sourceCode>
            <sourceName>Rutgers University</sourceName>
            <!--

/data/source/findingAids/rutu/manuscripts/nyfai.xml

<eadid encodinganalog="852" publicid="nyfai" countrycode="us" mainagencycode="njr">nyfai</eadid>

Inventory to the Records of the New York Feminist Art Institute

# Works, via google
http://www2.scc.rutgers.edu/ead/manuscripts/nyfaif.html

# no
http://www2.scc.rutgers.edu/ead/manuscripts/nyfai.html

                /data/source/findingAids/rutu/manuscripts/nyfai.xml
                <eadid encodinganalog="852" publicid="nyfai" countrycode="us" mainagencycode="njr">nyfai</eadid>

                # Frameset, human readable, 
                http://www2.scc.rutgers.edu/ead/manuscripts/nyfaif.html

                # Actual page. Note the b suffix.
                http://www2.scc.rutgers.edu/ead/manuscripts/nyfaib.html
                
                /data/source/findingAids/rutu/ijs/barron.xml
                <eadid encodinganalog="852" publicid="barron" countrycode="us" mainagencycode="njr">barron</eadid>

                # The actual URL, note the "b" suffix:
                http://www2.scc.rutgers.edu/ead/ijs/barronb.html

                # The browseable URL, loads a frameset containing barronb.html. Maybe f for frames?
                http://www2.scc.rutgers.edu/ead/ijs/barronf.html
                
                /data/source/findingAids/rutu/oralHist/diamond.xml
                <eadid encodinganalog="852" publicid="diamond" countrycode="us" mainagencycode="njr">diamond</eadid>
                # works
                http://www2.scc.rutgers.edu/ead/oralHist/diamondb.html
                
                > find /data/source/findingAids/rutu/ -type d
                /data/source/findingAids/rutu/
                /data/source/findingAids/rutu/manuscripts
                /data/source/findingAids/rutu/ijs
                /data/source/findingAids/rutu/uarchives
                /data/source/findingAids/rutu/foster
                /data/source/findingAids/rutu/oralHist
            -->
            <url/>
            <identifier/>
        </source>
        <source>
            <sourceCode>sia</sourceCode>
            <sourceName>Smithsonian Institution Archives</sourceName>
            <!--
                # Need to convert old eadid values to new siris_arc values.

                /data/source/findingAids/sia/FARU7184.xml

                <eadid mainagencycode="DSI-AI" countrycode="us"
                identifier="http://siarchives.si.edu/findingaids/FARU7184.xml" encodinganalog="856$u">
                http://siarchives.si.edu/findingaids/FARU7184.xml</eadid>

                # 404
                http://siarchives.si.edu/findingaids/FARU7184.xml

                # Summary plus human readable version of the finding aid RU007184
                http://siarchives.si.edu/collections/siris_arc_217341

                # search results with a link to the finding aid, but link is 404
                http://collections.si.edu/search/results.htm?fq=data_source%3A%22Field+Book+Registry%22&q=RU007184&fq=online_media_type:%22Finding+aids%22

                # 404, link from search results above.
                http://siarchives.si.edu/findingaids/faru7184.htm
                
                # Working Example
                http://siarchives.si.edu/collections/siris_arc_217072
            -->
            <url/>
            <identifier/>
        </source>
        <source>
            <sourceCode>syru</sourceCode>
            <sourceName>Syracuse University</sourceName>
            <!--
                /data/source/findingAids/syru/queen_vic.xml
                <eadid countrycode="US" mainagencycode="NSyU" identifier="queen_vic">queen_vic</eadid>

                # works, human readable
                http://library.syr.edu/digital/guides/q/queen_vic.htm
                http://library.syr.edu/digital/guides/print/queen_vic_prt.htm
                
                /data/source/findingAids/syru/council_europe.xml
                # works
                http://library.syr.edu/digital/guides/c/council_europe.htm
            -->
            <url/>
            <identifier/>
        </source>
        <source>
            <sourceCode>taro</sourceCode>
            <sourceName>Texas Archival Resources Online</sourceName>
            <!--
                # Some urls can be made to work, but have extra text that is different for each subdir. Check that
                # subdirs are consistent. This needs more work. There are 40 subdirs (not counting taro itself), making the problem non-trivial.
                
                > find /data/source/findingAids/taro -type d | grep -Pv "\d+" | wc -l
                41
                
                /data/source/findingAids/taro/ojac/00009.xml
                
                <eadid mainagencycode="TxAlyOJA" countrycode="us">urn:taro:ojac.00009</eadid>
                
                <unitid encodinganalog="099" label="Identification:" countrycode="us" repositorycode="TxAlyOJA">AR.2005.008; AR.2005.010</unitid>
                
                # Works, xml
                http://www.lib.utexas.edu/taro/ojac/00009.xml
                
                # works, human readable, html 
                http://www.lib.utexas.edu/taro/ojac/00009/ojac-00009.html
                
                # works, "print" version, html, human readable
                http://www.lib.utexas.edu/taro/ojac/00009/00009-P.html

                /data/source/findingAids/taro/ttusw/00109.xml
                
                <eadid countrycode="us" mainagencycode="TxLT-SW" encodinganalog="852">urn:taro:ttu.sw.00109</eadid>
                
                # works, print, human readable, html
                http://www.lib.utexas.edu/taro/ttusw/00109/00109-P.html
                
                # Daniel xml example
                http://www.lib.utexas.edu/taro/ttusw/00109.xml
                
                # daniel html example
                http://www.lib.utexas.edu/taro/ttusw/00109/tsw-00109.html
                
                /data/source/findingAids/taro/uthrc/00194/00194p1.xml
                
                # works, human readable, html
                http://www.lib.utexas.edu/taro/uthrc/00194/00194p1-P.html

                # Works
                http://www.lib.utexas.edu/taro/uthrc/00194/00194p1.xml

                # Works, found via search
                http://www.lib.utexas.edu/taro/uthrc/00194/hrc-00194p1.html

                /data/source/findingAids/taro/tturb/00174.xml

                <eadid countrycode="us" mainagencycode="TxLT-SW" encodinganalog="852">urn:taro:ttu.rb.00174</eadid>
                http://swco.ttu.edu
                
                # works, print, html, human readable
                http://www.lib.utexas.edu/taro/tturb/00174/00174-P.html

                # works, use tturb from file directory
                http://www.lib.utexas.edu/taro/tturb/00174.xml
                
                /data/source/findingAids/taro/tturb/00268/00268p1.xml
                
                <eadid countrycode="us" mainagencycode="TxLT-SW" encodinganalog="852">urn:taro:ttu.rb.00268p1</eadid>
                
                # works, must use numerical subdir when it exists
                http://www.lib.utexas.edu/taro/tturb/00268/00268p1.xml

                /data/source/findingAids/taro/dalpub/08003.xml

                <eadid mainagencycode="dalpub" countrycode="us">urn:taro:dalpub.08003</eadid>
                
                # works, print, human readable, html
                http://www.lib.utexas.edu/taro/dalpub/08003/08003-P.html

                # works, getting "dalpub" from "dalpub" does not work like other records
                http://www.lib.utexas.edu/taro/dalpub/08003.xml

                /data/source/findingAids/taro/utlac/00035/00035p1.xml
                
                <eadid countrycode="us" mainagencycode="TxU-LA" encodinganalog="852$a"
                url="www.lib.utexas.edu/taro/utlac/00035/lac-00035p1.html">urn:taro:utexas.blac.00035.00035p1</eadid>

                # works, "utlac" from filename subdir
                http://www.lib.utexas.edu/taro/utlac/00035/00035p1.xml
                
                /data/source/findingAids/taro/utaaa/00094.xml
                
                <eadid countrycode="us" mainagencycode="TxU" encodinganalog="852$a">urn:taro:utexas.aaa.00094</eadid>

                # Works, get utaaa from filename subdir
                http://www.lib.utexas.edu/taro/utaaa/00094.xml
            -->
            <url/>
            <identifier/>
        </source>
        <source>
            <sourceCode>ual</sourceCode>
            <sourceName>University of Alabama</sourceName>
            <!--
                /data/source/findingAids/ual/u0003_0003242.ead.xml
                <eadid countrycode="US" mainagencycode="US-US-ALM">u0003_0003242</eadid>
                <titleproper>Guide to the Letter from Mack to Mary Louise Brashaw
                <num>MSS.3242</num>

                # works, human readable, html
                http://acumen.lib.ua.edu/u0003_0003242.ead.xml
                http://acumen.lib.ua.edu/content/u0003/0003242/Metadata/
                http://acumen.lib.ua.edu/content/u0003/0003242/Metadata/u0003_0003242.ead.xml
                
                /data/source/findingAids/ual/u0003_0002668.ead.xml                

                # works
                http://acumen.lib.ua.edu/u0003_0002668.ead.xml
            -->
            <url/>
            <identifier/>
        </source>
        <source>
            <sourceCode>uchic</sourceCode>
            <sourceName>University of Chicago</sourceName>
            <!--
                /data/source/findingAids/uchic/ICU.SPCL.STARRMEX.xml
                <eadid>ICU.SPCL.STARRMEX</eadid>
                
                # works, human readable, html
                http://www.lib.uchicago.edu/e/scrc/findingaids/view.php?eadid=ICU.SPCL.STARRMEX&html

                # works
                http://www.lib.uchicago.edu/e/scrc/findingaids/view.php?eadid=ICU.SPCL.STARRMEX&xml

                # Also html
                http://www.lib.uchicago.edu/e/scrc/findingaids/view.php?eadid=ICU.SPCL.STARRMEX
            -->
            <url/>
            <identifier/>
        </source>
        <source>
            <sourceCode>uct</sourceCode>
            <sourceName>University of Connecticut</sourceName>
            <!--

/data/source/findingAids/uct/MSS19980082.xml

<eadid countrycode="US" mainagencycode="US-UCW" url="http://doddcenter.uconn.edu/asc/findaids/">MSS19980082</eadid>

University of Connecticut, Institutue of Cooperative Marketing Records 1998.0082

# works via google, Where does "icm" come from?
http://doddcenter.uconn.edu/asc/findaids/icm/MSS19980082.html

# no
http://doddcenter.uconn.edu/asc/findaids/MSS19980082.html

# no
http://doddcenter.uconn.edu/asc/findaids/
cmd: wget \-\-spider "http://doddcenter.uconn.edu/asc/findaids/"

/data/source/findingAids/uct/MSS19840024.xml

# no
http://doddcenter.uconn.edu/asc/findaids/IAMAW7000/MSS19840024.html
cmd: wget \-\-spider "http://doddcenter.uconn.edu/asc/findaids/IAMAW7000/MSS19840024.html"

/data/source/findingAids/uct/MSS20090030.xml
url:
cmd: wget \-\-spider ""

/data/source/findingAids/uct/MSS19980300.xml
url:
cmd: wget \-\-spider ""


/data/source/findingAids/uct/MSS19990066.xml
url:
cmd: wget \-\-spider ""

/data/source/findingAids/uct/MSS19980205.xml
url:
cmd: wget \-\-spider ""

/data/source/findingAids/uct/MSS19860010.xml
url:  
cmd: wget \-\-spider ""

/data/source/findingAids/uct/MSS19980222.xml
url:
cmd: wget \-\-spider ""


                /data/source/findingAids/uct/MSS19970101.xml
                
                <eadid countrycode="US" mainagencycode="US-UCW"
                url="http://doddcenter.uconn.edu/asc/findaids/CT_Soldiers/MSS19970101.html">MSS19970101</eadid>

                # works, human readable, html 
                http://doddcenter.uconn.edu/asc/findaids/CT_Soldiers/MSS19970101.html
                
                # works, xml
                http://doddcenter.uconn.edu/asc/findaids/CT_Soldiers/MSS19970101.xml
            -->
            <url/>
            <identifier/>
        </source>
        <source>
            <sourceCode>ude</sourceCode>
            <sourceName>University of Delaware</sourceName>
            <!--

# Interesting index.htm
http://www.lib.udel.edu/ud/spec/findaids/bazelon/index.htm

/data/source/findingAids/ude/minimal_ead/mss0272.xml

<eadid countrycode="us" mainagencycode="deu" identifier="mss0272.xml">mss0272.xml</eadid>

Finding aid for W. D. Snodgrass correspondence with Daniela Gioseffi

# works, via google and the browsing page http://www.lib.udel.edu/ud/spec/findaids/index.htm
http://www.lib.udel.edu/ud/spec/findaids/snodgios.htm

# no
http://www.lib.udel.edu/ud/spec/findaids/html/mss0272.html

# no
http://www.lib.udel.edu/ud/spec/findaids/xml/mss0272.xml


                /data/source/findingAids/ude/minimal_ead/mss0272.xml
                
                /data/source/findingAids/ude/full_ead/mss0099_0576.xml

                <eadid countrycode="us" mainagencycode="deu" identifier="mss0099_0576.xml">mss0099_0576.xml</eadid>
                
                # works, human readable, html
                http://www.lib.udel.edu/ud/spec/findaids/html/mss0099_0576.html
                
                # works, xml
                http://www.lib.udel.edu/ud/spec/findaids/xml/mss0099_0576.xml
                
                # examples manuscripts, collections.
                http://www.lib.udel.edu/ud/spec/findaids/xml/mss0093_0001.xml
                http://www.lib.udel.edu/ud/spec/findaids/html/mss0093_0001.html
                http://www.lib.udel.edu/ud/spec/findaids/colish.htm
            -->
            <url/>
            <identifier/>
        </source>
        <!--
            ufl is part of afl but still separate. Renamed to afl-ufl
        -->
        <source>
            <sourceCode>afl-ufl</sourceCode>
            <sourceName>University of Florida</sourceName>
            <!-- 
                 # Requires ufl_e2u.xml to decode, urls are human readable html
                 
                 /data/source/findingAids/afl-ufl/ufms272.xml
                 
                 <eadid url="http://web.uflib.ufl.edu/spec/browseu_ms.htm" countrycode="US"
                 mainagencycode="US-FU" publicid="-//us::FU//TEXT us::FU::ufms272.xml//EN">ufms272</eadid>
            -->
            <url/>
            <identifier/>
            </source>
        <source>
            <sourceCode>uil</sourceCode>
            <sourceName>University of Illinois</sourceName>
            <!--
                /data/source/findingAids/uil/vice_chancellor_for_administrative_affairs_issuanc_995.xml
                <eadid encodinganalog="856$u" mainagencycode="US-IU-Ar" countrycode="US" identifier="ArchonInternalCollectionID:995">24/1/806</eadid>

                # html
                http://archives.library.illinois.edu/archon/?p=collections/controlcard&id=995

                # printer
                http://archives.library.illinois.edu/archon/?p=collections/controlcard&id=995&templateset=print&disabletheme=1
            -->
            <url/>
            <identifier/>
        </source>
        <source>
            <sourceCode>uks</sourceCode>
            <sourceName>University of Kansas</sourceName>
            <!--
                /data/source/findingAids/uks/ksrl.sc.holyromanempire.xml
                <eadid encodinganalog="Identifier" url="http://hdl.handle.net/10407/2047781585" identifier="10407/2047781585">ksrl.sc.holyromanempire</eadid>

                # works, human readable, html, eadid@url also citation from the html finding aid
                http://hdl.handle.net/10407/2047781585

                # redirects to
                http://etext.ku.edu/view?docId=ksrlead/ksrl.sc.holyromanempire.xml

                # printer
                http://etext.ku.edu/view?docId=ksrlead/ksrl.sc.holyromanempire.xml&doc.view=print;chunk.id=
            -->
            <url/>
            <identifier/>
        </source>
        <source>
            <sourceCode>umd</sourceCode>
            <sourceName>University of Maryland</sourceName>
            <!--
                /data/source/findingAids/umd/MdU.ead.univarch.0181.xml
                <eadid countrycode="iso3611-1" mainagencycode="MdU">MdU.ead.univarch.0181</eadid>

                # works
                http://digital.lib.umd.edu/oclc/MdU.ead.univarch.0181.xml
                
                # works, human readable overview
                http://digital.lib.umd.edu/archivesum/actions.DisplayEADDoc.do?source=MdU.ead.univarch.0181.xml&style=ead
            -->
            <url/>
            <identifier/>
        </source>
        <source>
            <sourceCode>umi</sourceCode>
            <sourceName>University of Michigan Bentley Library &amp; Special Collections</sourceName>
            <!--
                # Note the comment in the eadid. Seems legal, but looks weird.
                /data/source/findingAids/umi/bentley/titush.xml
                
                <eadid publicid="us//::miu-h//TXT us::miu-h::titush.xml//EN" countrycode="us"
                mainagencycode="MiU-H" encodinganalog="Identifier">umich-bhl-86254</eadid>

                # overview
                http://quod.lib.umich.edu/b/bhlead/umich-bhl-86254?subview=standard;view=reslist

                # entire page
                http://quod.lib.umich.edu/b/bhlead/umich-bhl-86254?rgn=main;view=text
                
                /data/source/findingAids/umi/clementsmss/maxim_final.xml
                
                <eadid countrycode="us" mainagencycode="MiU-C" publicid="us//::miu-c//TXT
                us::miu-c::maxim_final.xml//EN" encodinganalog="Identifier"> umich-wcl-M-1687max<!\-\- Don't
                forget to change filename.xml in the publicid attribute\-\-></eadid>

                # Works
                http://quod.lib.umich.edu/c/clementsmss/umich-wcl-M-1687max?rgn=main;view=text

                > find /data/source/findingAids/umi -type d          
                /data/source/findingAids/umi
                /data/source/findingAids/umi/bentley
                /data/source/findingAids/umi/clementsmss
            -->
            <url></url>
            <identifier>eadid</identifier>
        </source>
        <source>
            <sourceCode>umn</sourceCode>
            <sourceName>University of Minnesota</sourceName>
            <!--
                /data/source/findingAids/umn/ihrcknowledge.xml
                
                <eadid countrycode="us" mainagencycode="MnU" publicid="-//University of Minnesota, Twin
                Cities::Immigration History Research Center//TEXT (us::MnU::ihrcknowledge:: Ukrainian
                Knowledge Society of New York City Records, 1908-1948.)//EN">ihrcknowledge</eadid>
                
                <unitid encodinganalog="099" countrycode="mnu" repositorycode="MnU" label="Collection ID: ">UKR</unitid>
                
                # works, xml
                http://special.lib.umn.edu/findaid/xml/ihrcknowledge.xml
            -->
            <url/>
            <identifier/>
        </source>
        <source>
            <sourceCode>unc</sourceCode>
            <sourceName>University of North Carolina, Chapel Hill</sourceName>
            <!--
                # No way to construct a URL from the eadid.

                /data/source/findingAids/unc/03227.xml
                
                <eadid countrycode="us" mainagencycode="ncu" publicid="-// University of North Carolina at Chapel
                Hill::Southern Historical Collection//TEXT (US::NCU::OFC$::Mebane Family Papers, (3227))//EN">03227</eadid>
                
                # Works, discovered via search engine
                http://www2.lib.unc.edu/mss/inv/m/Mebane_Family.html
                
                # Uses the eadid (collection id), but redirects to a login page
                http://www.lib.unc.edu/api/ead/index.html?collID=03227
                
                http://www.lib.unc.edu/api/ead/index.html?collID=03227
                
                # Has call number 3227, has link to finding aid, Mebane_Family.html, but can't associate eadid.
                http://search.lib.unc.edu/search?R=UNCb2426898
                
                /data/source/findingAids/unc/04517.xml

                <eadid publicid="PUBLIC &quot; -//Manuscripts Department, Library of the University of North
                Carolina at Chapel Hill//Text(US::NCU::OFC$::A. R. Ammons Papers (#4517))//EN&quot; &quot;
                04517.xml&quot; " countrycode="us" mainagencycode="ncu">04517</eadid>
                
                # example, 04517
                http://www2.lib.unc.edu/mss/inv/a/Ammons,A.R.html
            -->
            <url/>
            <identifier/>
        </source>
        <source>
            <sourceCode>une</sourceCode>
            <sourceName>University of Nebraska</sourceName>
            <!-- 
                 # Cannot associate our file name with a URL. Filenames appear to have been randomly
                 # munged. Never did find sandoz-ms80-reelMS0031-unl.xml. No relation between eadid@identifier
                 # and ead URL.
                 
                 /data/source/findingAids/une/pejsa-cz-ms273-unl.xml
                 
                 <eadid countrycode="us" mainagencycode="NbU" identifier="b40857955c">b40857955c</eadid>
                 
                 http://archivespec.unl.edu/findingaids/MS273-pejsa-cz-unl.html
                 
                 /data/source/findingAids/une/boucher-rg05-12-03-unl.xml
                 
                 <eadid countrycode="us" mainagencycode="NbU" identifier="b39378378.3">b39378378.3</eadid>
                 
                 # Works, discovered via google
                 http://archivespec.unl.edu/findingaids/RG05-12-03-boucher-unl.html

                 # no
                 http://archivespec.unl.edu/findingaids/12-03-boucher-rg05-unl.html

                 # no
                 http://archivespec.unl.edu/findingaids/rg05-boucher-12-03-unl.html
                 http://archivespec.unl.edu/findingaids/RG05-boucher-12-03-unl.html
                 
                 
                 /data/source/findingAids/une/sandoz-ms80-reelMS0031-unl.xml
                 
                 # ok, but not our finding aid, appears to be for a larger collection, includes several reels.
                 http://archivespec.unl.edu/findingaids/MS080-sandoz-unl.html
                 
                 # no
                 http://archivespec.unl.edu/findingaids/MS80-reelMS0031-sandoz-unl.html
                 
                 # no
                 http://archivespec.unl.edu/findingaids/MS80-REELMS0031-sandoz-unl.html
            -->
            <url/>
            <identifier/>
        </source>
        <source>
            <sourceCode>utsa</sourceCode>
            <sourceName>Utah State Archives</sourceName>
            <!--
                /data/source/findingAids/utsa/U-Ar_1312.xml
                
                <eadid countrycode="US" mainagencycode="US-U-Ar" publicid="-//State of Utah::Utah State
                Archives and Records Service//TEXT (US::U-Ar::U-Ar_1312.xml::Minutes)//EN"
                encodinganalog="identifier">U-Ar_1312</eadid>
                
                # works, human readable, html
                http://archives.utah.gov/research/inventories/1312.html
                
                # What google found:
                http://archives.state.ut.us/cgi-bin/eadseriesget.cgi?WEBINPUT_BIBLGRPC_KEY=1312

                # example
                http://archives.utah.gov/research/inventories/83953.html
            -->
            <url/>
            <identifier/>
        </source>
        <source>
            <sourceCode>utsu</sourceCode>
            <sourceName>Utah State University</sourceName>
            <!--
                /data/source/findingAids/utsu/ULA_mss270.xml
                
                <eadid countrycode="US" encodinganalog="identifier" identifier="80444/xv74929"
                url="http://uda-db.orbiscascade.org/findaid/ark:/80444/xv74929" mainagencycode="US-ULA" publicid="-//Utah
                State University::Special Collections and Archives//TEXT (US::US-ULA::USU_ULA_COLLMSS270::John M. Cannon
                papers)//EN">ULA_USU_ COLL MSS 270</eadid>
                
                # works, human readable, html, eadid@url redirects to:
                http://nwda.orbiscascade.org/ark:/80444/xv74929
                
                # The original eadid@url
                http://uda-db.orbiscascade.org/findaid/ark:/80444/xv74929
            -->
            <url/>
            <identifier/>
        </source>
        <source>
            <sourceCode>uut</sourceCode>
            <sourceName>University of Utah</sourceName>
            <!-- 
                 /data/source/findingAids/uut/UU_Acc0506.xml
                 
                 <eadid countrycode="US" mainagencycode="US-UUML"
                 publicid="-//:://TEXT(US::UUML::UU_Acc0506.xml::University of Utah Associate Vice President
                 for Academic Affairs records)//EN" identifier="80444/xv10833"
                 encodinganalog="identifier">UU_Acc0506</eadid>
                 
                 # works, human readable, html
                 http://nwda.orbiscascade.org/ark:/80444/xv10833
            -->
            <url/>
            <identifier/>
        </source>
        <source>
            <sourceCode>vah</sourceCode>
            <sourceName>Virginia Heritage</sourceName>
            <!--
                # Requires vah_e2u.xml aka ead-inst.xml from Steven Majewski sdm7g@virginia.edu

                # Each collection (see grep below) has a different location, none of which can be determined from the ead
                
                /data/source/findingAids/vah/viwc00450.xml
                
                <eadid countrycode="US" mainagencycode="US-ViWC">PUBLIC "-//Colonial Williamsburg
                Foundation::John D. Rockefeller, Jr. Library//TEXT (US::ViWC::viwc00450:: Requisition,
                1861 July 9)//EN" "viwc00450.xml" </eadid>
                
                <address xmlns="urn:isbn:1-931666-22-9" xmlns:xlink="http://www.w3.org/1999/xlink"
                xml:base="http://ead.lib.virginia.edu/vivaead/add_con/cw_address.xi.xml">
                
                # Unclear how to turn US-ViCW into "cw" except by parsing address@xml:base. Worldcat regsitry is VCW or OCLC-VCW.
                
                # works, xml
                http://ead.lib.virginia.edu/vivaead/published/cw/viwc00450.xml

                # works, human readable
                http://ead.lib.virginia.edu/vivaxtf/view?docId=cw/viwc00450.xml
                
                # citation
                http://ead.lib.virginia.edu/vivaxtf/view?docId=cw/viwc00450.xml
                
                /data/source/findingAids/vah/viu00455.xml
                
                <eadid publicid="PUBLIC &amp;#34;-//University of Virginia::Library::Special Collections
                Dept.//TEXT (US::ViU::00455::Silas Weir Mitchell Collection)//EN&amp;#34;
                &amp;#34;ViU00455.sgm&amp;#34;" countrycode="US" mainagencycode="US-ViU">PUBLIC "-//University
                of Virginia::Library::Special Collections Dept.//TEXT (US::ViU::00455::Silas Weir Mitchell
                Collection)//EN" "ViU00455.sgm"</eadid>
                
                # found via google, actual xml
                http://ead.lib.virginia.edu/vivaead/published/uva-sc/viu00455.xml
                
                # works, human readable, found via ead.lib.virginia.edu "uva-sc" found in address/@xml:base 
                http://ead.lib.virginia.edu/vivaxtf/view?docId=uva-sc/viu00455.xml

                /data/source/findingAids/vah/vipets00040.xml
                
                <eadid publicid="PUBLIC &amp;#34;-//Virginia State University::Johnston Memorial
                Library::Special Collections and Archives//TEXT (US::ViPetS::vipets00040::Thomas Patterson
                Papers)//EN&amp;#34; &amp;#34;vipets00040.xml&amp;#34;" countrycode="US"
                mainagencycode="US-ViPets">PUBLIC "-//Virginia State University::Johnston Memorial
                Library::Special Collections and Archives//TEXT (US::ViPetS::vipets00040::Thomas Patterson
                Papers)//EN" "vipets00040.xml"</eadid>
                
                <address xmlns="urn:isbn:1-931666-22-9" xmlns:xlink="http://www.w3.org/1999/xlink"
                xml:base="http://ead.lib.virginia.edu/vivaead/add_con/vsu_address.xi.xml">
                
                # Works, human readable
                http://ead.lib.virginia.edu/vivaxtf/view?docId=vsu/vipets00040.xml
                
                # Works, xml
                http://ead.lib.virginia.edu/vivaead/published/vsu/vipets00040.xml

                > grep fn: logs/vah.log | perl -ne '$_ =~ m/vah\/(.*?)\d+/; print "$1\n"' | sort -u
                Mundy_
                vaallhs
                vi
                viasr
                viblbv
                vifarl
                vifgm
                vifrem
                vih
                vihart
                viho
                vil
                viletbl
                vilogh
                viltbl
                vilxv
                vilxw
                vilxwl
                vino
                vipets
                vircu
                vircuh
                viro
                virvu
                viu
                viuh
                viul
                viur
                viw
                viwc
                viwyc
            -->
            <url>http://ead.lib.virginia.edu/vivaead/published/</url>
            <identifier/>
        </source>
        <source>
            <sourceCode>yale</sourceCode>
            <sourceName>Yale University</sourceName>
            <!--
                /data/source/findingAids/yale/mssa.ru.0724.xml
                
                <eadid countrycode="US" mainagencycode="US-CtY" publicid="-//Yale University::Manuscripts and
                Archives//TEXT (US::CtY::::[Controller, Yale University, records])//EN"
                url="http://hdl.handle.net/10079/fa/mssa.ru.0724">mssa.ru.0724</eadid>
                
                # eadid@url human readable, html
                http://hdl.handle.net/10079/fa/mssa.ru.0724

                # redirects to
                http://drs.library.yale.edu/HLTransformer/HLTransServlet?stylename=yul.ead2002.xhtml.xsl&pid=mssa:ru.0724&clear-stylesheet-cache=yes

                # full html
                http://drs.library.yale.edu/HLTransformer/HLTransServlet?stylename=yul.ead2002.xhtml.xsl&pid=mssa:ru.0724&query=&clear-stylesheet-cache=yes&hlon=yes&big=&adv=&filter=&hitPageStart=&sortFields=&view=all
                
                /data/source/findingAids/yale/ycba.mss.0009.xml
                
                <eadid countrycode="US" mainagencycode="US-CtY-BA" publicid="-//Yale University::Yale Center
                for British Art//TEXT (US::CtY-BA::::[Drawings for the London Stage Collection])//EN"
                url="http://hdl.handle.net/10079/fa/ycba.mss.0009">ycba.mss.0009</eadid>
                
                # eadid@url
                http://hdl.handle.net/10079/fa/ycba.mss.0009

                # redirects to
                http://drs.library.yale.edu/HLTransformer/HLTransServlet?stylename=yul.ead2002.xhtml.xsl&pid=ycba:mss.0009&clear-stylesheet-cache=yes

                # full html
                http://drs.library.yale.edu/HLTransformer/HLTransServlet?stylename=yul.ead2002.xhtml.xsl&pid=ycba:mss.0009&query=&clear-stylesheet-cache=yes&hlon=yes&big=&adv=&filter=&hitPageStart=&sortFields=&view=all
                
                /data/source/findingAids/yale/beinecke.poley.xml

                # eadid@url
                http://hdl.handle.net/10079/fa/beinecke.poley

                # redirects to:
                http://drs.library.yale.edu/HLTransformer/HLTransServlet?stylename=yul.ead2002.xhtml.xsl&pid=beinecke:poley&clear-stylesheet-cache=yes
                
                > grep fn: logs/yale.log | perl -ne '$_ =~ m/yale\/(.*?)\./; print "$1\n"' | sort -u
                arts
                beinecke
                divinity
                med
                mssa
                music
                vrc
                ycba
            -->
            <url/>
            <identifier/>
        </source>

    </xsl:variable>

    <xsl:variable name="langCodeList">
        <xsl:copy-of select="document('iso639-2.new.xml')"/>
    </xsl:variable>

    <xsl:variable name="relatorList">
        <xsl:for-each select="document('relatorList.xml')/relatorList/relator">
            <xsl:copy-of select="."/>
        </xsl:for-each>
    </xsl:variable>

</xsl:stylesheet>
