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

$baseVHD = $distro.baseVHD
$vhdExt = [System.IO.Path]::GetExtension($baseVHD)
$vmSize = GetVmSize $global $test.vmSize

function PrepareVM(
    [Parameter(Mandatory=$True)]
    [string] $type,
    [Parameter(Mandatory=$True)]
    [string] $vmName,
    [Parameter(Mandatory=$True)]
    $hvServer
)
{
    VMClean $hvServer.hostname $vmName
    
    ################## create VHD file ########################
    $baseVhdFullPath = [System.IO.Path]::Combine($hvServer.vmVhdRoot, $baseVHD)
    $newOsVhdName = $vmName + $vhdExt

    #test propose native VHDs
    $testMode = "X"
    LogMsg 9 "creating VHD file for ${type}: $newOsVhdName in $($hvServer.hostname)"
    $rst = CallVhdNew $vmName $hvServer $baseVhdFullPath $global.xStore $testMode $test.vhdMode
    if(-not $rst[-1])
    {
        LogMsg 0 "Error: Failed to create VHD: $newOsVhdName"
        return $false
    }
    
    ########################## create vm for server ##########################
    LogMsg 9 "Creating VM for ${type}: $vmName in $($hvServer.hostname)"
    $newOsVhdFull = [System.IO.Path]::Combine($hvServer.vmVhdRoot, $newOsVhdName)
    $rst = CallVmNew $vmName $vmSize $hvServer $distro $newOsVhdFull
    if(-not $rst[-1])
    {
        LogMsg 0 "Error: Failed to create VM: $vmName"
        return $false
    }
    return $true
}

###########################################################################################
# create server VM
###########################################################################################

$hvServerServer = $hvServers[0]
#assign hvServers to server and client respectively
if($test.testMode.StartsWith("INTRA-")) {
    if ($hvServers.Count -ne 1)
    {
        LogMsg 0 "Error: INTRA mode should have 1 hvServer"
        return $null
    }
    $hvServerClient = $hvServers[0]
} else {
    if ($hvServers.Count -ne 2)
    {
        LogMsg 0 "Error: INTER mode should have 2 hvServers"
        return $null
    }
    $hvServerClient = $hvServers[1]
}

$vmNamePrefix = $distro.distroName + "." + $test.testName + "." + $test.testMode
$vmNameServer = $vmNamePrefix + ".Server"

$sts = PrepareVM "server" $vmNameServer $hvServerServer
if(-not $sts)
{
    return $null
}

###########################################################################################
#create client VM
###########################################################################################

$mac = $(get-vm -ComputerName $hvServerServer.hostname -name $vmNameServer  | select -ExpandProperty networkadapters |% {$_.macaddress} )
$badMac = "000000000000"
if ($mac -eq $badMac)
{
    LogMsg 0 "Error: the mac address of $vmNameServer on $($hvServerServer.hostname) is $badMac"
    return $null
}
$mac = $mac.tolower()
LogMsg 5 "mac address of $vmNameServer : $mac"

$vmNameClient =  $vmNamePrefix + ".Client"
$sts = PrepareVM "client" $vmNameClient $hvServerClient
if(-not $sts)
{
    return $null
}

$IperfParam = 'IPERF_PARAMS="' + " -c $mac"
if ($test.iperfThreads) 
{
    $IperfParam += " -P $($test.iperfThreads)"
}
if ($test.iperfSeconds) 
{
    $IperfParam += " -t $($test.iperfSeconds)"
}
if ($test.testMode.EndsWith("-UDP")) 
{
    $IperfParam += " -u"
}
$IperfParam += '"'

###########################################################################################
#create configure file for test
###########################################################################################
[xml]$xmlConfig = @"
<config>
    <logfileRootDir>$lisaResultFold</logfileRootDir>
    <lisaRootDir>$($global.lisaRootDir)</lisaRootDir>
    <timeout>$($test.timeout)</timeout>
    <VMs>
        <vm>
            <role>NonSUT</role>
            <hvServer>$($hvServerServer.hostname)</hvServer>
            <vmName>$vmNameServer</vmName>
            <os>Linux</os>
            <ipv4></ipv4>
            <sshKey>$($distro.sshKey)</sshKey>
        </vm>
        <vm>
            <role>SUT</role>
            <hvServer>$($hvServerClient.hostname)</hvServer>
            <vmName>$vmNameClient</vmName>
            <os>Linux</os>
            <ipv4></ipv4>
            <sshKey>$($distro.sshKey)</sshKey>
            <suite>Network</suite>
        </vm>
    </VMs>
    <testParams>
        <param>$IperfParam</param>
        <param>ARP_SERVER=$($global.mimicArpServer.hostname)</param>
        <param>USER=$($global.mimicArpServer.username)</param>
    </testParams>
</config>
"@

#append mimicArpServer node in config file
$mimicArpServer = $xmlConfig.ImportNode($global.mimicArpServer, $true)
$xmlConfig.config.AppendChild($mimicArpServer) | Out-Null

#copy the testParams in config xml
$testParams = $xmlConfig.ImportNode($test.testParams, $true)
@($testParams.ChildNodes) |% { $xmlConfig.config.testParams.AppendChild($_) | Out-Null }

###########################################################################################
# create configure node of VMs
###########################################################################################

$xmlConfig