<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:msxsl="urn:schemas-microsoft-com:xslt" exclude-result-prefixes="msxsl" xmlns:cs="urn:cs" version="1.0">
<xsl:output method="xml" indent="yes"/>
<msxsl:script language="C#" implements-prefix="cs">
	<![CDATA[
		public string TimePeriod(string dtStr1, string dtStr2)
		{
			if (String.IsNullOrEmpty(dtStr1) || String.IsNullOrEmpty(dtStr2))
			{
				return "-1";
			}
			DateTime dt1 = Convert.ToDateTime(dtStr1);
			DateTime dt2 = Convert.ToDateTime(dtStr2);
			TimeSpan diff = dt2-dt1;
			return diff.TotalSeconds.ToString();
		}
	]]>
</msxsl:script>
	<xsl:template match="/">
	<xsl:for-each select="results/result">
		<testsuite name="{testName} - {distro}" tests = "{status/successCases + status/failedCases + status/abortedCases}" failures="{status/failedCases}" skipped="{status/abortedCases}" hostname="{../VMs/vm/hvServer}.{../VMs/vm/vmName}" starttime="{startTime}" endtime="{endTime}" time="{cs:TimePeriod(startTime, endTime)}">
			<xsl:apply-templates select="cases"/>
		</testsuite>
	</xsl:for-each>
	</xsl:template>

	<xsl:template match="cases">
	<xsl:for-each select="case">
		<testcase name="{caseName}" time="{cs:TimePeriod(startTime, endTime)}" isoname="xxx.iso" classname="{../../testName}.{caseName}">
			<xsl:if test="status = 'Failed'">
				<error type="Failed">
				<xsl:for-each select="LogFiles/logFile">
					<Log file="{.}"/>
				</xsl:for-each>
				</error>
			</xsl:if>
			<xsl:if test="status = 'Aborted'">
				<error type="Aborted">
				<xsl:for-each select="LogFiles/logFile">
					<Log file="{.}"/>
				</xsl:for-each>
				</error>
			</xsl:if>
			<xsl:if test="status = 'Not Sure'">
				<skipped/>
			</xsl:if>
			<xsl:if test="status = 'Success'">
				<xsl:copy-of select="LogFiles"/>
			</xsl:if>
		</testcase>
	</xsl:for-each>
	</xsl:template>
</xsl:stylesheet>

