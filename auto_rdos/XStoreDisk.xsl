<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:output method="xml" indent="yes"/>
<xsl:template match="/config">
<config>
    <global>
        <xsl:copy-of select="logfileRootDir" />
        <defaultSnapshot>ICABase</defaultSnapshot>
        <email>
            <recipients>
                <to>t-cwang@microsoft.com</to>
            </recipients>
            <sender>t-cwang@microsoft.com</sender>
            <subject>LISA FTM Test Run for LIS3.5 on WS2012</subject>
            <smtpServer>smtphost.redmond.corp.microsoft.com</smtpServer>
        </email>
        <xsl:copy-of select="mimicArpServer" />
        <!-- Optional testParams go here -->
    </global>

    <testSuites>
        <suite>
            <suiteName>XStoreDisk</suiteName>
            <suiteTests>
                <suiteTest>auto_rdos_XStoreDisk_setup</suiteTest>
                <suiteTest>GetActivepagesBeforeTest</suiteTest>
                <suiteTest>auto_rdos_XStoreDisk</suiteTest>
                <suiteTest>GetActivepagesAfterTest</suiteTest>
                <suiteTest>CompareActivePageTest</suiteTest>
            </suiteTests>
        </suite>
    </testSuites>

    <testCases>
         <test> 
            <testName>auto_rdos_XStoreDisk_setup</testName> 
            <testScript>auto_rdos_XStoreDisk_setup.sh</testScript>
            <files>remote-scripts/ica/auto_rdos_XStoreDisk_setup.sh</files>
            <onError>Abort</onError>
            <noReboot>True</noReboot>
        </test>
        <test>
            <testName>GetActivepagesBeforeTest</testName> 
            <testScript>setupscripts\GetActivePages.ps1</testScript>
            <testParams>
                <param>xStoreParams=<xsl:value-of select="xStoreParams" /></param>
                <xsl:for-each select="testParams/param">
                    <xsl:copy-of select="." />
                </xsl:for-each>
            </testParams> 
            <timeout>600</timeout>
            <onError>Abort</onError>
            <noReboot>True</noReboot>
        </test>
        <test> 
            <testName>auto_rdos_XStoreDisk</testName> 
            <testScript>auto_rdos_XStoreDisk.sh</testScript>
            <files>remote-scripts/ica/auto_rdos_XStoreDisk.sh</files>
            <xsl:copy-of select="timeout" />
            <testParams>
                <xsl:for-each select="testParams/param">
                    <xsl:copy-of select="." />
                </xsl:for-each>
            </testParams> 
            <uploadFiles>
                <file>IOZoneLog.log</file>
            </uploadFiles>
            <onError>Continue</onError>
            <noReboot>True</noReboot>
        </test>
        <test>
            <testName>GetActivepagesAfterTest</testName> 
            <testScript>setupscripts\GetActivePages.ps1</testScript>
            <testParams>
                <param>xStoreParams=<xsl:value-of select="xStoreParams" /></param>
                <xsl:for-each select="testParams/param">
                    <xsl:copy-of select="." />
                </xsl:for-each>
            </testParams> 
            <timeout>600</timeout>
            <onError>Abort</onError>
            <noReboot>True</noReboot>
        </test>
        <test>
            <testName>CompareActivePageTest</testName> 
            <testScript>setupscripts\CompareActivePageTest.ps1</testScript>
            <timeout>600</timeout>
            <onError>Abort</onError>
            <noReboot>True</noReboot>
        </test>
    </testCases>

    <VMs>
        <vm>
            <xsl:copy-of select="hvServer" />
            <xsl:copy-of select="vmName" />
            <os>Linux</os>
            <ipv4></ipv4>
            <xsl:copy-of select="sshKey" />
            <suite>XStoreDisk</suite>
        </vm>
    </VMs>

</config>
</xsl:template>

</xsl:stylesheet>

