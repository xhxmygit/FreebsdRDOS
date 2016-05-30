Param(
  [Parameter(Mandatory=$True)]
  [string] $xmlFilename,
  [int]    $dbgLevel = 0,
  [int]    $lisaDbgLevel = 5,
  [string] $logDir
)

# change current directory for .net
[environment]::CurrentDirectory = pwd

. .\utilFunctions.ps1
# prepare the log dirs for the test log files
MakeDirs

function CallXslt(
    [string] $xml,
    [string] $xsl,
    [string] $output
)
{
    <#
    .Synopsis
        Prepare the xml input file for lisa.
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
    $xslt.Load($xsl)
    $xslt.Transform($xml, $output)
}

function GetVmSize($global, $name)
{
    # find the vm size in xml config file
    $find = @(@($global.vmSizes.vmSize) |? {$_.sizeName -eq $name})

    # make sure only find one size with the name
    if($find.Count -ne 1)
    {
        LogMsg 0 "Error VM Size: $name"
        return $null
    }
    $find[0]
}

function VMClean([string] $computerName, [string] $vmName)
{
    <#
    .Synopsis
        Delete the vms with the name on the remote server.
    .Description
        Clean the remote server before create the new vm.
    .Parameter computerName
        Remote host server name
    .Parameter vmName
        The vm name to be clean up
    #>
    Get-VM -ComputerName $computerName |? { $_.Name -eq $vmName } |% {
        if($_.State -eq "Running")
        {
            # must stop first before remove
            LogMsg 5 "Stoping VM $vmName on $computerName"
            Stop-VM $_ -Force
        }
        LogMsg 5 "Removing VM $vmName on $computerName"
        Remove-VM $_ -Force
    }
}

function CallVhdNew(
    [string] $vmName,
    $hvServer,
    [string] $baseVhd,
    $xStore,
    $testMode,
    $vhdMode
)
{
    if ($testMode -match "X" -and (!$xStore -or !$xStore.url -or !$xStore.accountName -or !$xStore.container -or !$xStore.accessKey))
    {
        LogMsg 0 "Error: missing the xStore configuration"
        return $false
    }
    $hostname = $hvServer.hostname
    $netVmadminRoot = GetNetPath $hvServer.vmadminRoot

    # put the vhdnew.cmd onto the remote server
    NetUseCopy $hvServer vhdnew.cmd \\$hostname\$netVmadminRoot\
    
    # the arguments passed to vhdnew.cmd
    $arguments = '{0} "{1}" "{2}" {3} {4} {5} {6} {7} {8}' -f
        $hostname,
        $vmName,
        $baseVhd,
        $testMode,
        $xStore.url,
        $xStore.accountName,
        $xStore.container,
        $xStore.accessKey,
        $vhdMode

    # run vhdnew.cmd on remote server
    $sts = .\remote_call.ps1 $hvServer "$($hvServer.vmadminRoot)\vhdnew.cmd $arguments > $($hvServer.vmadminRoot)\vhdnew.log"

    # collect the vhdnew.log on the remote server
    $log = Join-Path $testDir $vmName-vhdnew.log
    NetUseCopy $hvServer \\$hostname\$netVmadminRoot\vhdnew.log $log
    
    # check the log file to detect error
    $text = Get-Content $log
    if (!$sts -or $text -match '^Failed.*0x[0-9A-F]{8}$')
    {
        LogMsg 0 "Error: VhdNew failed, please check the log at $log"
        return $false
    }
    return $true
}


function CallVmNew(
    [string] $vmName,
    $vmSize,
    $hvServer,
    $distro,
    [string] $vhds,
    [switch] $snapshot
)
{
    if (!$hvServer -or !$hvServer.switchName -or !$hvServer.vmRoot -or !$hvServer.vmVhdRoot -or !$hvServer.vmSnapshotRoot)
    {
        LogMsg 0 "Error: missing the hvServer configuration"
        return $false
    }
    
    $hostname = $hvServer.hostname
    $netVmadminRoot = GetNetPath $hvServer.vmadminRoot

    # put the vmnew.cmd onto the remote server
    NetUseCopy $hvServer vmnew.cmd \\$hostname\$netVmadminRoot\
    
    # the arguments passed to vmnew.cmd
    $arguments = '"{0}" {1} {2} "{3}" "{4}" "{5}" "{6}" {7}' -f
        $vmName,
        $vmSize.cpus,
        $vmSize.memory,
        $hvServer.switchName,
        $hvServer.vmRoot,
        $hvServer.vmVhdRoot,
        $hvServer.vmSnapshotRoot,
        $vhds

    # run vmnew.cmd on remote server
    $sts = .\remote_call.ps1 $hvServer "$($hvServer.vmadminRoot)\vmnew.cmd $arguments > $($hvServer.vmadminRoot)\vmnew.log"

    # collect the vmnew.log on the remote server
    $log = Join-Path $testDir $vmName-vmnew.log
    NetUseCopy $hvServer \\$hostname\$netVmadminRoot\vmnew.log $log
    
    # check the log file to detect error
    $text = Get-Content $log
    if (!$sts -or $text -match '^ERROR:')
    {
        LogMsg 0 "Error: VmNew failed, please check the log at $log"
        return $false
    }
    $comPort = $distro.comPort
    if ($comPort)
    {
        LogMsg 0 "Info: VM $vmName on $hostname use com port $comPort"
        Set-VMComPort -ComputerName $hostname -VMName $vmName -Number 1 -Path $null
        Set-VMComPort -ComputerName $hostname -VMName $vmName -Number $comPort -Path "\\.\pipe\$vmName"
    }
    if ($snapshot)
    {
        $snapshotName = "ICABase"
        LogMsg 0 "Info: Creating a snapshot $snapshotName for VM $vmName on $hostname"
        Checkpoint-VM -ComputerName $hostname -VMName $vmName -SnapshotName $snapshotName
    }
    return $true
}

function RunTest($global, $hvServer, $distro, $test)
{
    
    $username = $hvServer.username
    $password = $hvServer.password
}

#
# monitoring test. end testing if detect kernel panic
# end testing if detect kernel panic
#
function TestMonitor($procId, [string[]] $kernelLogFileArray)
{
    if(-not $procId) 
    {
        LogMsg 0 "ERROR : illegle process id of lisa"
        return 10
    }

    $preLineNum = 0
    while($true) 
    {
        Get-Process -id $procId -ErrorAction "SilentlyContinue" | Out-Null
        if($?)
        { 
            foreach($kernelLogFile in $kernelLogFileArray)
            {
                $kernelLogContent = Get-Content $kernelLogFile
                $lineNum = $($kernelLogContent | Measure-Object -line |% {$_.lines})
                LogMsg 11 "line number of current kernel log : $($kernelLogFile) is $($lineNum)"

                #detect if kernel panic occur
                $latestLineNum = $lineNum - $preLineNum
                $result = $($kernelLogContent | Select-Object -Last $latestLineNum |`
                            Select-String "kernal\s+panic" -AllMatches)
                if($result) 
                {
                    LogMsg 0 "ERROR : kernel panic detect. stopping test..."
                    Stop-Process -id $procId -Force -ErrorAction "SilentlyContinue"
                    return 100
                }

            }
            Start-Sleep 60
        }
        else 
        {
            LogMsg 0 "lisa complete running. exit..."
            return 0
        }
    }
    return 0
}

function RunIcaSerial()
{
    #$pclass = [wmiclass]'root\cimv2:Win32_Process'
    #$kernelCmd = "bin\icaserial READ \\$hostname\pipe\$vmName | tee $absoluteTestDir\$vmName-icaserial.txt"
    #LogMsg 0 "Starting $kernelCmd"
    #$kernelId = $pclass.Create("powershell `"$kernelCmd`"", $lisaRoot, $null).ProcessId
    #LogMsg 5 "Get icaserial process id: $kernelId"
    
    $script:kernelIdArray = @()
    $script:kernelLogFileArray = @()
    foreach($vm in $resultConfigXml.config.VMs.vm)
    {
        $vmName = $vm.vmName
        $hostname = $vm.hvServer

        $kernelLogFileName = "$absoluteTestDir\$vmName-icaserial.log"
        $script:kernelLogFileArray += $kernelLogFileName
        LogMsg 0 "get kernel log from \\$hostname\pipe\$vmName and stored in $kernelLogFileName"
        $KernelProc = Start-Process -FilePath "$lisaRoot\bin\icaserial.exe" "READ","\\$hostname\pipe\$vmName" -PassThru -WorkingDirectory "$lisaRoot\bin" -RedirectStandardOutput "$kernelLogFileName"
        $kernelId = $kernelProc.Id

        $script:kernelIdArray += $kernelProc.Id
        LogMsg 5 "Get icaserial process id: $kernelId"
    }
}

[xml]$xml = Get-Content $xmlFilename
$config = $xml.config

# support multiple hvServers
$hvServers = @($config.hvServers.hvServer)

$lisaRoot = $config.global.lisaRootDir
        
foreach($distro in $config.distros.distro)
{
    $distroName = $distro.distroName
    if (!$distroName)
    {
        LogMsg 0 "Error: distro name in config xml is empty"
        return
    }
    foreach($test in $config.tests.test)
    {
        $testName = $test.testName
        if (!$testName)
        {
            LogMsg 0 "Error: test name in config xml is empty"
            return
        }
        [string]$script = $test.testScript
        $logMsgText = "Running test $script "
        foreach($hvServer in $hvServers)
        {
            $hostname = $hvServer.hostname
            $logMsgText += "hvServer=$hostname "
        }
        $logMsgText += "distro=$distroName test=$testName"
        LogMsg 0 $logMsgText

        $absoluteTestDir = Resolve-Path $testDir
        $lisaResultFold = Join-Path -Path $absoluteTestDir -ChildPath "LisaResult"
        
		# calling the test script, getting the xml parameters
		$lisaXml = & $script $config.global $hvServers $distro $test
		if(! $lisaXml)
		{
			LogMsg 0 "Error: Run test script failed"
			continue
		}
			
		$vmName = GetVmName $distro $test
			
		# save the xml parameters to file
		$lisaArgsFile = Join-Path $testDir "${vmName}_args.xml"
		$lisaXml.Save($lisaArgsFile)

		# getting the lisa input xml file
		$lisaXmlFile = Join-Path $testDir "$vmName.xml"
		CallXslt $lisaArgsFile $test.testTemplate $lisaXmlFile
		$resultConfigXml = [xml](get-content $lisaXmlFile)

        # running ica serial
        RunIcaSerial

        LogMsg 0 "log file : $($logFile)"
		# calling lisa
		$absoluteLisaXmlFile = Resolve-Path $lisaXmlFile
		$lisaParam = "run `"$absoluteLisaXmlFile`" -dbgLevel $lisaDbgLevel"
		#$lisaParam = "run $absoluteLisaXmlFile -dbgLevel $lisaDbgLevel"

		LogMsg 0 "Calling Lisa.ps1 $lisaParam"
		$KernelProcLisa = Start-Process powershell "-File Lisa.ps1 $lisaParam"  -PassThru -WorkingDirectory $lisaRoot
        $KernelIdLisa = $($KernelProcLisa.Id)

        #
        # monitor testing 
        # return value of 100 indicates kernel panic
        #
        LogMsg 0 "Monitoring test : process id of lisa: $KernelIdLisa"
        $monitorResult = TestMonitor $KernelIdLisa $kernelLogFileArray
		
		#create report XML
		$vmSize = $test.vmSize
        
        #find newest fold as the result fold and ica.log is in there
        $tempFold = $(dir $lisaResultFold | Sort-Object -Property LastWriteTime -Descending |`
                        Select-Object -First 1 |% {$_.Name})
        $testResultFold = Join-Path -Path $lisaResultFold -ChildPath $tempFold
        
        $reportResultScript = ".\ReportTestResult.ps1"
        if($monitorResult -eq 100)
        {
            LogMsg 0 $("run $reportResultScript [Xml] $testName "`
                    + "$distroName $vmSize $testResultFold $absoluteTestDir -KernelPanic")
            $resultXml = & $reportResultScript $resultConfigXml $testName `
                    $distroName $vmSize $testResultFold $absoluteTestDir -KernelPanic
        }
        else 
        {
            LogMsg 0 $("run $reportResultScript [Xml] $testName "`
                    + "$distroName $vmSize $testResultFold $absoluteTestDir")
            $resultXml = & $reportResultScript $resultConfigXml $testName `
                    $distroName $vmSize $testResultFold $absoluteTestDir
        }      
		# stop the ica serial
        foreach($kernelId in $kernelIdArray)
        {
            taskkill /PID $kernelId /T /F
		}
    }
}
