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
    LogMsg 0 "Error: XStoreReboot test should have 1 hvServer"
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

$testMode = "X"

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
$sts = CallVmNew $vmName $vmSize $hvServer $distro $vhd
if(! $sts[-1])
{
    return $null
}

# prepare the xml parameters
[xml]$xml = @"
<config>
    <logfileRootDir>$lisaResultFold</logfileRootDir>
    <hvServer>$hostname</hvServer>
    <vmName>$vmName</vmName>
    <sshKey>$($distro.sshKey)</sshKey>
    <lisaRootDir>$($global.lisaRootDir)</lisaRootDir>
    <timeout>$($test.timeout)</timeout>
</config>
"@
$mimicArpServer = $xml.ImportNode($global.mimicArpServer, $true)
$xml.config.AppendChild($mimicArpServer) | Out-Null

$testParams = $xml.ImportNode($test.testParams, $true)
$xml.config.AppendChild($testParams) | Out-Null

$xml
