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
    </global>
    <xsl:copy-of select="testSuites" />
    <xsl:copy-of select="testCases" />
    <VMs>
        <vm>
            <xsl:copy-of select="hvServer" />
            <xsl:copy-of select="vmName" />
            <os>Linux</os>
            <ipv4></ipv4>
            <xsl:copy-of select="sshKey" />
            <xsl:copy-of select="vm/suite" />
        </vm>
    </VMs>
</config>
</xsl:template>

</xsl:stylesheet>

