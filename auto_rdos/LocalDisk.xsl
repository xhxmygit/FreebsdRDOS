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
            <suiteName>LocalDisk</suiteName>
            <suiteTests>
                <suiteTest>auto_rdos_LocalDisk</suiteTest>
            </suiteTests>
        </suite>
    </testSuites>

    <testCases>
         <test> 
            <testName>auto_rdos_LocalDisk</testName> 
            <testScript>auto_rdos_LocalDisk.sh</testScript>
            <files>remote-scripts/ica/auto_rdos_LocalDisk.sh</files>
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
        </test>
    </testCases>

    <VMs>
        <vm>
            <xsl:copy-of select="hvServer" />
            <xsl:copy-of select="vmName" />
            <os>Linux</os>
            <ipv4></ipv4>
            <xsl:copy-of select="sshKey" />
            <suite>LocalDisk</suite>
        </vm>
    </VMs>

</config>
</xsl:template>

</xsl:stylesheet>

