Param(
    [Parameter(Mandatory=$True)]
    $global,
    [Parameter(Mandatory=$True)]
    $hvServers,
    [Parameter(Mandatory=$True)]
    $distro,
    [Parameter(Mandatory=$True)]
    $test
)

if ($hvServers.Count -ne 1)
{
    LogMsg 0 "Error: Feature test should have 1 hvServer"
    return $null
}
$hvServer = $hvServers[0]

$hostname = $hvServer.hostname
$vmName = GetVmName $distro $test

# delete the vm with name vmname on the remote server
VMClean $hostname $vmName

$baseVhd = $distro.baseVhd
$baseVhdFullPath = [System.IO.Path]::Combine($hvServer.vmVhdRoot, $baseVhd)
$vhdExt = [System.IO.Path]::GetExtension($baseVhd)

# the new os disk vhd path for vm
$newOsVhdName = $vmName + $vhdExt

$testMode = "L"

$sts = CallVhdNew $vmName $hvServer $baseVhdFullPath $global.XStore $testMode $test.vhdMode
if(! $sts[-1])
{
    return $null
}

$vmSize = GetVmSize $global $test.vmSize
if(! $vmSize)
{
    return $null
}
$vhd = [System.IO.Path]::Combine($hvServer.vmVhdRoot, $newOsVhdName)

# create the vm
$sts = CallVmNew $vmName $vmSize $hvServer $distro $vhd -snapshot
if(! $sts[-1])
{
    return $null
}

if (!$test.baseXml)
{
    LogMsg 0 "Error: missing baseXml"
    return $null
}

$baseXmlFile = Join-Path $lisaRoot $test.baseXml
LogMsg 5 "Info: base xml file $baseXmlFile"
[xml] $baseXml = Get-Content $baseXmlFile

# prepare the xml parameters
[xml]$xml = @"
<config>
    <logfileRootDir>$lisaResultFold</logfileRootDir>
    <hvServer>$hostname</hvServer>
    <vmName>$vmName</vmName>
    <sshKey>$($distro.sshKey)</sshKey>
    <lisaRootDir>$($global.lisaRootDir)</lisaRootDir>
    <vm>
        <suite>$($baseXml.config.testSuites.suite.suiteName)</suite>
    </vm>
</config>
"@
$mimicArpServer = $xml.ImportNode($global.mimicArpServer, $true)
$xml.config.AppendChild($mimicArpServer) | Out-Null

$testSuites = $xml.ImportNode($baseXml.config.testSuites, $true)
$xml.config.AppendChild($testSuites) | Out-Null

$testCases = $xml.ImportNode($baseXml.config.testCases, $true)
$xml.config.AppendChild($testCases) | Out-Null

if($test.cases)
{
    $suiteNode = $xml.CreateElement("suite")
    $testSuites.appendChild($suiteNode) | Out-Null

    XmlAddTextNode $xml $suiteNode "suiteName" "Customized suite"

    $suiteTestsNode = $xml.CreateElement("suiteTests")
    $suiteNode.AppendChild($suiteTestsNode) | Out-Null

    foreach($case in $test.cases.case)
    {
        XmlAddTextNode $xml $suiteTestsNode "suiteTest" $case
    }
    
    $xml.config.vm.suite = "Customized suite"
}

function GetValue($key)
{
    switch ($key)
    {
        hvServer {$hostname}
    }
}

foreach ($case in $test.customizeTestCases)
{
    $testName = $case.testName
    $testNode = (Select-Xml -xml $xml -XPath "config/testCases/test[testName='$testName']").Node
    foreach ($param in $case.modifyParam)
    {
        $paramNode = $testNode.SelectSingleNode("testparams/param[text()='$($param.oldParam)']")
        $paramNode.RemoveAll()
        if (-not $param.newParam.HasChildNodes)
        {
            $paramNode.InnerText = $param.newParam
        }
        else
        {        
            foreach ($newChild in $param.newParam.ChildNodes)
            {
                if ($newChild -is [System.Xml.XmlText])
                {
                    $paramNode.InnerText += $newChild.InnerText
                }
                if ($newChild -is [System.Xml.XmlElement])
                {
                    if ($newChild.Name -eq "valueOf")
                    {
                        $paramNode.InnerText += GetValue $newChild.key
                    }
                }
            }
        }

    }
}

$xml
