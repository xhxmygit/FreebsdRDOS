param([string] $vmName, [string] $hvServerName, [string] $testParams)

function CallVhdGetAs(
    [string] $vmName,
    $hvServer,
    $xStore,
    $testName
)
{
    $hostname = $hvServer.hostname
    cd $rootDir
    
    $log = Join-Path $testLogDir "${vmName}-${testName}.log"
    $cmd = "setupscripts\vhdgetas.cmd"
    $AllArgs = @($hostname, $vmName, $xStore.url, $xStore.accountName, $xStore.container, $xStore.accessKey)
    echo "cmd: $cmd"
    echo "All args: $AllArgs"
    & $cmd $AllArgs | Out-File $log
    if (!$?)
    {
        echo $Error[0]
        return $false
    }
    
    # check the log file to detect error
    if (!(Test-Path $log))
    {
        echo "Error: VhdGetAs failed, log file at $log is missing"
        return $false
    }
    $text = Get-Content $log
    if ($text -match '^Failed.*0x[0-9A-F]{8}$')
    {
        echo "Error: VhdGetAs failed, please check the log at $log"
        return $false
    }

    return $true
}

#
# Parse the testParams string
#
$params = $testParams.Split(';')
foreach ($p in $params)
{
    if ($p.Trim().Length -eq 0)
    {
        continue
    }

    $temp = $p.Trim().Split('=')
    
    if ($temp.Length -ne 2)
    {
        "Warn : test parameter '$p' is being ignored because it appears to be malformed"
        continue
    }

    switch ($temp[0]) {
        "rootDir" { $rootDir = $temp[1]; break }
        "xStoreParams" { $xStoreParams = $temp[1]; break }
        "TestLogDir" { $testLogDir = $temp[1]; break }
        "TestName" { $testName = $temp[1]; break }
    }
}

. $xStoreParams

return CallVhdGetAs $vmName $hvServer $xStore $testName
