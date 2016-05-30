param([string] $vmName, [string] $hvServerName, [string] $testParams)

<#
    Extract AP Usage from log file
#>
function ParseLog($log)
{
    $text = Get-Content $log
    if ($text -match '^Failed.*0x[0-9A-F]{8}$')
    {
        "Error: VhdGetAs failed, please check the log at $log"
        return $null
    }
	else
	{
		$line = $text -match 'Active blob size = '
		$regex = [regex]'(\d+)'
		$APValue = $regex.match($line).Value
		return $APValue
	}
}

#
# Parse the testParams string
#
$trimParam = ""
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
        "TestLogDir" { $testLogDir = $temp[1]; break }
        "trimParam" { $trimParam = $temp[1]; break }
    }
}

if ($trimParam -eq "")
{
    $logBefore = Join-Path $testLogDir $vmName-GetActivepagesBeforeTest.log
    $logAfter = Join-Path $testLogDir $vmName-GetActivepagesAfterTest.log
}
else
{
    $logBefore = Join-Path $testLogDir $vmName-GetActivepagesBeforeTest_$trimParam.log
    $logAfter = Join-Path $testLogDir $vmName-GetActivepagesAfterTest_$trimParam.log
}

if(!(Test-Path $logBefore))
{
    "Error: Can't find file: $logBefore"
    return $false
}

if(!(Test-Path $logAfter))
{
    "Error: Can't find file: $logAfter"
    return $false
}

$APBefore = ParseLog $logBefore
if (!$APBefore[-1])
{
    return $APBefore
}

$APAfter = ParseLog $logAfter
if (!$APAfter[-1])
{
    return $APAfter
}

"Info: APBefore is $APBefore"
"Info: APAfter is $APAfter"
$APBeforeValue = [Int]::Parse($APBefore)
$APAfterValue = [Int]::Parse($APAfter)

return $APBeforeValue * 0.95 -le $APAfterValue -and $APAfterValue -le $APBeforeValue * 1.05
