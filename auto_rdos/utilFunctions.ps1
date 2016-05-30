function MakeDir($dir)
{
    if (!(Test-Path $dir))
    {
        mkdir $dir | Out-Null
    }
}

function MakeDirs()
{
	$testStartTime = date
    # testDir is the root log dir for this run
    if ($logDir)
    {
        $script:testDir = $logDir
    }
    else
    {
        $rootDir = ".\TestResults"
        MakeDir $rootDir
        
        $fname = [System.IO.Path]::GetFileNameWithoutExtension($xmlFilename)
        $testRunDir = $fname + "-" + $testStartTime.ToString("yyyyMMdd-HHmmss")

        $script:testDir = Join-Path -Path $rootDir -ChildPath $testRunDir
    }
    MakeDir $testDir
    
    $script:logFile = Join-Path -Path $testDir -ChildPath "auto_rdos.log"
        
    LogMsg 0 "Info : Driver machine: $env:COMPUTERNAME"
    LogMsg 0 "Info : Log file: $logFile"
    LogMsg 0 "Info : Using XML file: $xmlFilename"
    cp $xmlFilename $testDir

    # Because we will change current location to call lisa, use absolute path
    $script:logFile = Resolve-Path $logFile
}

########################################################################
#
# LogMsg()
#
########################################################################
function LogMsg([int]$level, [string]$msg, [string]$color = "Magenta")
{
    <#
    .Synopsis
        Write a message to the log file and the console.
    .Description
        Add a time stamp and write the message to the test log.  In
        addition, write the message to the console.  Color code the
        text based on the level of the message.
    .Parameter level
        Debug level of the message
    .Parameter msg
        The message to be logged
    .Example
        LogMsg 3 "This is a test"
    #>

    if ($level -le $dbgLevel)
    {
        $now = date -Format "MM/dd/yyyy HH:mm:ss : "
        ($now + $msg) | Out-File -Encoding ascii -Append -FilePath $logFile
        
        if ( $msg.StartsWith("Error"))
        {
            $color = "Red"
        }
        elseif ($msg.StartsWith("Warn"))
        {
            $color = "Yellow"
        }
        
        Write-Host -ForegroundColor $color "$msg"
    }
}

function GetVmName($distro, $test)
{
    $distro.distroName + "." + $test.testName
}

function GetNetPath([string] $path)
{
    $path.Replace(':', '$')
}

function NetUseCopy($hvServer, [string] $from, [string] $to)
{
    $hostname = $hvServer.hostname
    $username = $hvServer.username
    $password = $hvServer.password

    net use * /del /yes
    net use \\$hostname /user:$username $password | Out-Null
    LogMsg 5 "Copying from $from to $to"
    copy $from $to
}

function XmlAddTextNode(
    [xml] $xml,
    [System.Xml.XmlNode] $appendTo,
    [string] $node,
    [string] $text
)
{
    $textElement = $xml.CreateElement($node)
    $textElement.innerText = $text
    $appendTo.AppendChild($textElement) | Out-Null
}
