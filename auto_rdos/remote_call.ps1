Param(
    [Parameter(Mandatory=$True)]
    $hvServer,
    [Parameter(Mandatory=$True)]
    [string]$cmd
)

$computerName = $hvServer.hostname
LogMsg 5 "Connecting to $computerName" -color Cyan

# prepare the credential for Get-WmiObject
$secPassword = ConvertTo-SecureString $hvServer.password -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($hvServer.username, $secPassword)

# prepare the username and password for ManagementClass
$options = New-Object System.Management.ConnectionOptions
$options.UserName = $hvServer.username
$options.Password = $hvServer.password
$options.EnablePrivileges = $true

$scope = New-Object System.Management.ManagementScope
$scope.Path = "\\$computerName\root\cimv2"
$scope.Options = $options

$path = New-Object System.Management.ManagementPath
$path.ClassName = "Win32_Process"

$wmi = New-Object System.Management.ManagementClass($scope, $path, $null)
# fail out if the object didn't get created
if (! $wmi)
{
    LogMsg 0 "Failed connect to $computerName." -color Red
    return $false
}

LogMsg 5 "Running $cmd" -color Cyan
$remote = $wmi.Create($cmd)
if ($remote.ReturnValue -ne 0)
{
    LogMsg 0 "Failed to launch $cmd on $computerName. ReturnValue is $($remote.ReturnValue)" -color Red
    return $false
}

$id = $remote.ProcessId
LogMsg 5 "Successfully launched $cmd on $computerName with a process Id of $id" -color Green

# now wait until the remote process to finish
while(Get-WmiObject Win32_Process -ComputerName $computerName -Credential $credential -Filter "ProcessId=$id")
{
    sleep 2
}

LogMsg 5 "Successfully finished $cmd on $computerName"
return $true

