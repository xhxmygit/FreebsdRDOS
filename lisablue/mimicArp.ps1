#####################################################################
#
# MimicArpPrepare()
#
#####################################################################
function MimicArpPrepare([xml] $xmlData)
{
    $config = $xmlData.config.global.mimicArpServer
    if(-not $config)
    {
        LogMsg 5 "Warning: Mimic ARP server not configured."
        return
    }
    $hostname = $config.hostname
    $username = $config.username
    $sshKey = $config.sshKey
    if(-not $hostname -or -not $username -or -not $sshKey)
    {
        LogMsg 5 "Error: Mimic ARP server not correctly configured."
        return
    }
    
    #
    # The first time we SSH into a VM, SSH will prompt to accept the server key.
    # Send a "no-op command to the VM and assume this is the first SSH connection,
    # so pipe a 'y' respone into plink
    #
    
    LogMsg 9 "INFO : Call: echo y | bin\plink -i ssh\$sshKey $username@$hostname exit"
    echo y | bin\plink -i ssh\${sshKey} $username@${hostname} exit
}


#####################################################################
#
# MimicArpClean()
#
#####################################################################
function MimicArpClean([xml] $xmlData, [string] $macAddress)
{
    <#
    .Synopsis
        Clean the mac address on mimic arp server.
    .Description
        Use SSH to clean the mac/ip pair on mimic arp server.
    .Parameter vm
        The XML object representing the VM to copy from.
    .Parameter macAddress
        The mac address pass to the mimic arp server to clean.
   #>

    $macAddress = $macAddress.ToLower()
    MimicArpLog $xmlData "Clr $macAddress"
    $command = "rm -f ~/mimic-arp/$macAddress"

    return MimicArpSendCommand $xmlData $command
}


#####################################################################
#
# MimicArpLog()
#
#####################################################################
function MimicArpLog([xml] $xmlData, [string] $message)
{
    #escape dollar before date to run date commend on mimic arp server
    $command = "echo `$(date) : $message >> ~/mimic-arp/log"

    return MimicArpSendCommand $xmlData $command
}


#####################################################################
#
# MimicArpSendCommand()
#
#####################################################################
function MimicArpSendCommand([xml] $xmlData, [string] $command)
{
    $retVal = $False

    $vmName = "Mimic ARP Server"
    $config = $xmlData.config.global.mimicArpServer
    $hostname = $config.hostname
    $username = $config.username
    $sshKey = $config.sshKey
    if(-not $hostname -or -not $username -or -not $sshKey)
    {
        LogMsg 9 "Error: Mimic ARP server not configured."
        return $retVal
    }

    $process = Start-Process bin\plink -ArgumentList "-i ssh\${sshKey} $username@${hostname} ${command}" -PassThru -NoNewWindow -redirectStandardOutput lisaOut.tmp -redirectStandardError lisaErr.tmp
    $commandTimeout = 30
    while(!$process.hasExited)
    {
        LogMsg 8 "Waiting 1 second to check the process status for Command = '$command'."
        sleep 1
        $commandTimeout -= 1
        if ($commandTimeout -le 0)
        {
            LogMsg 3 "Killing process for Command = '$command'."
            $process.Kill()
            LogMsg 0 "Error: Send command to $vmName timed out for Command = '$command'"
        }
    }

    if ($commandTimeout -gt 0)
    {
        $retVal = $True
        LogMsg 2 "Success: Successfully sent command to $vmName. Command = '$command'"
    }
    
    del lisaOut.tmp -ErrorAction "SilentlyContinue"
    del lisaErr.tmp -ErrorAction "SilentlyContinue"

    return $retVal
}


#####################################################################
#
# MimicArpGet()
#
#####################################################################
function MimicArpGet([xml] $xmlData, [string] $macAddress)
{
    <#
    .Synopsis
        Get ip address by mac address from mimic arp server
    .Description
        Use SSH to get ip address by mac address from mimic arp server
    .Parameter macAddress
        The mac address pass to the mimic arp server to get.
    #>

    $retVal = $null

    $vmName = "Mimic Arp Server"
    $config = $xmlData.config.global.mimicArpServer
    $hostname = $config.hostname
    $username = $config.username
    $sshKey = $config.sshKey
    if(-not $hostname -or -not $username -or -not $sshKey)
    {
        LogMsg 9 "Error: Mimic ARP server not configured."
        return $retVal
    }
    
    $macAddress = $macAddress.ToLower()
    $remoteFile = "/$username/mimic-arp/$macAddress"

    LogMsg 9 "INFO: Try MimicArpGet $username@${hostname}:${remoteFile} $macAddress"
    
    $process = Start-Process bin\pscp -ArgumentList "-i ssh\${sshKey} $username@${hostname}:${remoteFile} $macAddress" -PassThru -NoNewWindow -Wait -redirectStandardOutput lisaOut.tmp -redirectStandardError lisaErr.tmp
    if ($process.ExitCode -eq 0)
    {
        $retVal = Get-Content $macAddress
        del $macAddress
        LogMsg 2 "Success: $vmName successfully copy '${remoteFile}' to '$macAddress'."
        MimicArpLog $xmlData "Get $macAddress -\> $retVal" | Out-Null
    }

    del lisaOut.tmp -ErrorAction "SilentlyContinue"
    del lisaErr.tmp -ErrorAction "SilentlyContinue"

    return $retVal
}