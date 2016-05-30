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
            <suiteName>XStoreTrim</suiteName>
            <suiteTests>
                <suiteTest>auto_rdos_XStoreTrim_XFS_setup</suiteTest>
                <suiteTest>GetActivepagesBeforeTest_XFS</suiteTest>
                <suiteTest>auto_rdos_XStoreTrim_XFS</suiteTest>
                <suiteTest>GetActivepagesAfterTest_XFS</suiteTest>
                <suiteTest>CompareActivePageTest_XFS</suiteTest>
                <suiteTest>auto_rdos_XStoreTrim_BTRFS_setup</suiteTest>
                <suiteTest>GetActivepagesBeforeTest_BTRFS</suiteTest>
                <suiteTest>auto_rdos_XStoreTrim_BTRFS</suiteTest>
                <suiteTest>GetActivepagesAfterTest_BTRFS</suiteTest>
                <suiteTest>CompareActivePageTest_BTRFS</suiteTest>
                <suiteTest>auto_rdos_XStoreTrim_EXT4_setup</suiteTest>
                <suiteTest>GetActivepagesBeforeTest_EXT4</suiteTest>
                <suiteTest>auto_rdos_XStoreTrim_EXT4</suiteTest>
                <suiteTest>GetActivepagesAfterTest_EXT4</suiteTest>
                <suiteTest>CompareActivePageTest_EXT4</suiteTest>
            </suiteTests>
        </suite>
    </testSuites>

    <testCases>
        <test> 
            <testName>auto_rdos_XStoreTrim_BTRFS_setup</testName> 
            <testScript>auto_rdos_XStoreTrim_setup.sh</testScript>
            <files>remote-scripts/ica/auto_rdos_XStoreTrim_setup.sh</files>
            <testParams>
                <param>trimParam=BTRFS</param>
            </testParams>
            <onError>Abort</onError>
            <noReboot>True</noReboot>
        </test>
        <test> 
            <testName>auto_rdos_XStoreTrim_XFS_setup</testName> 
            <testScript>auto_rdos_XStoreTrim_setup.sh</testScript>
            <files>remote-scripts/ica/auto_rdos_XStoreTrim_setup.sh</files>
            <testParams>
                <param>trimParam=XFS</param>
            </testParams>
            <onError>Abort</onError>
            <noReboot>True</noReboot>
        </test>
        <test> 
            <testName>auto_rdos_XStoreTrim_EXT4_setup</testName> 
            <testScript>auto_rdos_XStoreTrim_setup.sh</testScript>
            <files>remote-scripts/ica/auto_rdos_XStoreTrim_setup.sh</files>
            <testParams>
                <param>trimParam=EXT4</param>
            </testParams>
            <onError>Abort</onError>
            <noReboot>True</noReboot>
        </test>
        <test>
            <testName>GetActivepagesBeforeTest_BTRFS</testName> 
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
            <testName>auto_rdos_XStoreTrim_BTRFS</testName> 
            <testScript>auto_rdos_XStoreTrim.sh</testScript>
            <files>remote-scripts/ica/auto_rdos_XStoreTrim.sh</files>
            <xsl:copy-of select="timeout" />
            <testParams>
                <xsl:for-each select="testParams/param">
                    <xsl:copy-of select="." />
                </xsl:for-each>
            </testParams>
            <onError>Continue</onError>
            <noReboot>True</noReboot>
        </test>
        <test>
            <testName>GetActivepagesAfterTest_BTRFS</testName> 
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
            <testName>CompareActivePageTest_BTRFS</testName> 
            <testScript>setupscripts\CompareActivePageTest.ps1</testScript>
            <testParams>
                <param>trimParam=BTRFS</param>
            </testParams>
            <timeout>600</timeout>
            <onError>Abort</onError>
            <noReboot>False</noReboot>
        </test>
        <test>
            <testName>GetActivepagesBeforeTest_XFS</testName> 
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
            <testName>auto_rdos_XStoreTrim_XFS</testName> 
            <testScript>auto_rdos_XStoreTrim.sh</testScript>
            <files>remote-scripts/ica/auto_rdos_XStoreTrim.sh</files>
            <xsl:copy-of select="timeout" />
            <testParams>
                <xsl:for-each select="testParams/param">
                    <xsl:copy-of select="." />
                </xsl:for-each>
            </testParams>
            <onError>Continue</onError>
            <noReboot>True</noReboot>
        </test>
        <test>
            <testName>GetActivepagesAfterTest_XFS</testName> 
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
            <testName>CompareActivePageTest_XFS</testName> 
            <testScript>setupscripts\CompareActivePageTest.ps1</testScript>
            <testParams>
                <param>trimParam=XFS</param>
            </testParams>
            <timeout>600</timeout>
            <onError>Abort</onError>
            <noReboot>False</noReboot>
        </test>
        <test>
            <testName>GetActivepagesBeforeTest_EXT4</testName> 
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
            <testName>auto_rdos_XStoreTrim_EXT4</testName> 
            <testScript>auto_rdos_XStoreTrim.sh</testScript>
            <files>remote-scripts/ica/auto_rdos_XStoreTrim.sh</files>
            <xsl:copy-of select="timeout" />
            <testParams>
                <xsl:for-each select="testParams/param">
                    <xsl:copy-of select="." />
                </xsl:for-each>
            </testParams>
            <onError>Continue</onError>
            <noReboot>True</noReboot>
        </test>
        <test>
            <testName>GetActivepagesAfterTest_EXT4</testName> 
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
            <testName>CompareActivePageTest_EXT4</testName> 
            <testScript>setupscripts\CompareActivePageTest.ps1</testScript>
            <testParams>
                <param>trimParam=EXT4</param>
            </testParams>
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
            <suite>XStoreTrim</suite>
        </vm>
    </VMs>

</config>
</xsl:template>

</xsl:stylesheet>

