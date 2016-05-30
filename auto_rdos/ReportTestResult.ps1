Param(
    [Parameter(Mandatory=$True)]
    $xml,
    [Parameter(Mandatory=$True)]
    $testName,
    [Parameter(Mandatory=$True)]
    $distro,
    [Parameter(Mandatory=$True)]
    $vmSize,
    [Parameter(Mandatory=$True)]
    $testResultFoldLisa,
	[Parameter(Mandatory=$True)]
    $testResultFoldRdos,
    [switch] $KernelPanic
)

function CallXsltEx(
    [string] $xml,
    [string] $xsl,
    [string] $output
){
    <#
    .Synopsis
        Perform Xslt Transform with EnableScript execution
    .Description
        Use parameters and template to generate the output xml file.
    .Parameter xml
        The path to xml parameters file
    .Parameter xsl
        The path to the template
    .Parameter output
        The path to the output file
    #>
    $xslt = New-Object System.Xml.Xsl.XslCompiledTransform
    $xsltSetting = New-Object System.Xml.Xsl.XsltSettings
    $xsltSetting.EnableScript = $True
    $xslt.Load($xsl,$xsltSetting,$null)
    $xslt.Transform($xml,$output)
}

if(-not $xml -or $xml -isnot [XML])
{
    LogMsg 0 "Error: collecting log file received a NULL or bad xml parameter"
    return
}

if(-not $testName -or -not $distro -or -not $vmSize -or -not $testResultFoldLisa -or -not $testResultFoldRdos)
{
    LogMsg 0 "Error: not enough parameter for script report result"
    return
}

LogMsg 9 "Info: collecting log files"

$testResultLogFile = Join-Path -Path $testResultFoldLisa -ChildPath ".\ica.log"

if(-not  (Test-Path $testResultLogFile))
{
    LogMsg 0 "Can't find ica.log. unable to check test result of each test case"
}

#########################################################################
# determine status of each test
#########################################################################
$testCasesCag = @(
@{
    name = "successCases"
    result = "Success"
    patterns = @("Test (\w+)\s+: Success$")
}
@{
    name = "failedCases"
    result = "Failed"
    patterns = @("Test (\w+)\s+: Failed$")
}
@{
    name = "abortedCases"
    result = "Aborted"
    patterns = @("Test (\w+)\s+: Aborted$"
        "^    time out starting test (\w+)$"
        "^    Unsuccessful boot for test (\w+)$"
    )
}
)

$cases = @{}
$totalCaseNum = 0

foreach ($cag in $testCasesCag)
{
    $cag.cases = @()
    foreach ($pattern in $cag.patterns)
    {
        $matched = Select-String -Path $testResultLogFile -Pattern $pattern -AllMatches |% {$_.Matches.Groups[1].Value}
        $cag.cases += $matched
    }
    $cag.cases |% {$cases[$_] = @{status = $cag.result} }
    $totalCaseNum += $cag.cases.Count
}

$testUpdatePattern = "^(.*) : Info : .* currentTest updated to (.*) $"
$testUpdates = Select-String -path $testResultLogFile -Pattern $testUpdatePattern -AllMatches |% {
    $groups = $_.Matches.Groups
    @{time = $groups[1].Value; case = $groups[2].Value}
}
if ($testUpdates[-1].case -ne "done")
{
    LogMsg 5 "Warning: test update last one expect done, got: $($testUpdates[-1].case)"
}
for ($i = 0; $i -lt $testUpdates.Count - 1; $i++)
{
    $case = $cases[$testUpdates[$i].case]
    if (! $case)
    {
        $case = $cases[$testUpdates[$i].case] = @{}
    }
    $case.startTime = $testUpdates[$i].time
    $case.endTime = $testUpdates[$i + 1].time
}

if($KernelPanic)
{
    $testStatus = "Kernel Panic"
    LogMsg 0 "test status: Kernel Panic"
}
else
{
    $testStatusCount = ""
    foreach ($cag in $testCasesCag)
    {
        if($cag.cases.Count -eq $totalCaseNum)
        {
            $testStatus = $cag.result
        }
        $testStatusCount += " $($cag.cases.Count) / $totalCaseNum $($cag.result)"
    }
	if( -not $testStatus )
	{
		$testStatus = "Multiple Results"
	}
    LogMsg 5 "test status : $testStatus. $testStatusCount"
}

#get start time for log file
$regexPatternTime = "(?<=LISA test run on\s+).*\b"
$startTime = $(Select-String -path $testResultLogFile -Pattern $regexPatternTime -AllMatches |% {$_.Matches} |% {$_.Value})

#end time set to current time
$endTime = [DateTime]::Now

#########################################################################
# create xml file for report result
#########################################################################

[xml]$resultXml = @"
<results>
    <result>
        <testName>$testName</testName>
        <distro>$distro</distro>
        <vmSize>$vmSize</vmSize>
        <status result="$($testStatus)"></status>
        <startTime>$startTime</startTime>
        <endTime>$endTime</endTime>
    </result>
</results>
"@

#########################################################################
# status of test
#########################################################################
foreach ($cag in $testCasesCag)
{
    XmlAddTextNode $resultXml $resultXml.results.result.status $cag.name $cag.cases.Count
}

#########################################################################
# create nodes for each test cases
#########################################################################
$casesNode = $resultXml.CreateElement("cases")
$resultXml.results.result.AppendChild($casesNode) | Out-Null

function FindLog([string] $log, [switch] $optional)
{
    $log = Join-Path -path $testResultFoldLisa -ChildPath $log
    if(Test-Path $log)
    {
        $script:logFileArray += $log
        LogMsg 9 "Info: find log of $($vm.vmName): $log"
    }
    elseif (!$optional)
    {
        LogMsg 5 "Warn: can't find log file: $log"
    }
}

#all test that in configure file
$curTestSuite = $(Select-Xml -Xml $xml -XPath "config/VMs/vm/suite" |% {$_.Node.'#text'})
$testCasesUT = Select-Xml -xml $xml -XPath "config/testSuites/suite[suiteName='$curTestSuite']/suiteTests" |% {$_.Node.suiteTest}

foreach ($case in $testCasesUT)
{

	#get test info from configure file
	$test = $($xml.config.testCases.test |? {$_.testName -eq $case})
	
    $caseNode = $resultXml.CreateElement("case")
    $caseName = $test.testName
    XmlAddTextNode $resultXml $caseNode "caseName" $caseName

    ######################## status of test ###########################
    $status = "Not Sure"
    if ($cases[$caseName].status)
    {
        $status = $cases[$caseName].status
    }

    LogMsg 9 "status of case: $caseName : $status"
    XmlAddTextNode $resultXml $caseNode "status" $status

    if ($cases[$caseName].startTime)
    {
        XmlAddTextNode $resultXml $caseNode "startTime" $cases[$caseName].startTime
    }
    if ($cases[$caseName].endTime)
    {
        XmlAddTextNode $resultXml $caseNode "endTime" $cases[$caseName].endTime
    }

    ################# create log node certain test cases ##############
    $logFileArray = @()

    foreach ($vm in $xml.config.VMs.vm)
    {
        #test log
        $testLog = "$($vm.vmName)_${caseName}_.log"
        if ($test.testScript.EndsWith(".ps1"))
        {
            $testLog = "$($vm.vmName)_${caseName}_ps.log"
        }
        FindLog $testLog
 
        #summary log
        FindLog "$($vm.vmName)__${caseName}_summary.log" -optional

        #customized logs of each test
        foreach ($file in $test.uploadFiles.file)
        {
            FindLog "$($vm.vmName)_${caseName}_${file}"
        }
    }

    #append child node of log file
    $logFilesNode = $resultXml.CreateElement("LogFiles")
    foreach($logFileText in $logFileArray) 
    {
        XmlAddTextNode $resultXml $logFilesNode "logFile" $logFileText
    }
    $caseNode.AppendChild($logFilesNode) | Out-Null

    ########### complete create a case node  add it to cases node #######

    $casesNode.AppendChild($caseNode) | Out-Null
}

#########################################################################
# create info of related VMs
#########################################################################
$VMs = $resultXml.importNode($xml.config.VMs, $true)
$resultXml.DocumentElement.AppendChild($VMs) | Out-Null

foreach ($vm in $xml.config.VMs.vm)
{
    $kernelLog = $resultXml.CreateElement("kernelLog")
    $kernelLogFile = "$($vm.vmName)-icaserial.log"
    $kernelLogFile = Join-Path -Path $testResultFoldRdos -ChildPath $kernelLogFile
    if(test-path $kernelLogFile)
    {
        LogMsg 9 "find kernel log of $($vm.vmName): $($kernelLogFile)"
        $kernelLogText = $resultXml.CreateTextNode($kernelLogFile)
        $kernelLog.AppendChild($kernelLogText) | Out-Null

        $selectedXmlNode = $(Select-Xml -xml $resultXml -XPath "results/VMs/vm" |% {$_.Node} |? {$_.vmName -eq $vm.vmName})
        $selectedXmlNode.AppendChild($kernelLog) | Out-Null
    }
    else
    {
        LogMsg 0 "Error: kernel log file of VM: $($vm.vmName) don't exist"
    }
}

$resultXmlFile = Join-Path -Path $testDir -ChildPath "testResult.xml"
$resultXml.Save($resultXmlFile)
LogMsg 0 "Creating test result report : $($resultXmlFile)"

#Junit Format Result 

$junitTemplate = Resolve-Path .\ToJUnitResult.xsl
$junitXmlResultFile = Join-Path -Path $testDir -ChildPath "TestReport.xml"
& CallXsltEx $resultXmlFile $junitTemplate.Path $junitXmlResultFile
LogMsg 0 "Convert to JUnit test result report : $($junitXmlResultFile)"

$resultXml