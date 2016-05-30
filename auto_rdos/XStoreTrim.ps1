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
    LogMsg 0 "Error: XStoreTrim test should have 1 hvServer"
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

# the new data disk vhd path for vm
$newDataVhdName = "$vmName-data$vhdExt"

$testMode = "XX"
$xStore = $global.XStore
$sts = CallVhdNew $vmName $hvServer $baseVhdFullPath $xStore $testMode $test.vhdMode
if(! $sts[-1])
{
    return $null
}

$vmSize = GetVmSize $global $test.vmSize
if(! $vmSize)
{
    return $null
}
$vhds = [System.IO.Path]::Combine($hvServer.vmVhdRoot, $newOsVhdName) `
    + " " + [System.IO.Path]::Combine($hvServer.vmVhdRoot, $newDataVhdName)

# create the vm
$sts = CallVmNew $vmName $vmSize $hvServer $distro $vhds
if(! $sts[-1])
{
    return $null
}

$utilFunctions = Resolve-Path ".\utilFunctions.ps1"

$paramsFile = Join-Path $testDir xStoreParams.ps1
LogMsg 5 "Writing xStore params file: $paramsFile"

@"
`$hvServer = @{
hostname = '$($hvServer.hostname)'
username = '$($hvServer.username)'
password = '$($hvServer.password)'
vmadminRoot = '$($hvServer.vmadminRoot)'
}
`$xStore = @{
url = '$($xStore.url)'
accountName = '$($xStore.accountName)'
container = '$($xStore.container)'
accessKey = '$($xStore.accessKey)'
}
"@ | Out-File $paramsFile

# prepare the xml parameters
[xml]$xml = @"
<config>
    <logfileRootDir>$lisaResultFold</logfileRootDir>
    <hvServer>$hostname</hvServer>
    <vmName>$vmName</vmName>
    <sshKey>$($distro.sshKey)</sshKey>
    <lisaRootDir>$($global.lisaRootDir)</lisaRootDir>
    <timeout>$($test.timeout)</timeout>
    <autoRdosRoot>$(pwd)</autoRdosRoot>
    <xStoreParams>$paramsFile</xStoreParams>
</config>
"@

$mimicArpServer = $xml.ImportNode($global.mimicArpServer, $true)
$xml.config.AppendChild($mimicArpServer) | Out-Null

$testParams = $xml.ImportNode($test.testParams, $true)
$xml.config.AppendChild($testParams) | Out-Null

$xml
