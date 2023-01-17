# Disable progress bars created by Invoke-RestMethod which internally uses Write-Progress)
$progressPreference = 'silentlyContinue'

$url = 'http://130.25.14.49:8085/'
$apiUrl = $url + 'rest/api/latest/'
$project = 'AD-BA'
$queueUrl = ("{0}queue/{5}" -f $apiUrl, $project)

$username='one'
$password='password'

# Build basic auth values
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $username, $password)))

# Queue the build
$result = Invoke-RestMethod -Method Post -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)} $queueUrl
$buildUrl = $url + "browse/" + $result.restQueuedBuild.buildResultKey
Write-Host ("Build number {0} queued successfully, see {1}" -f $result.restQueuedBuild.buildNumber, $buildUrl)

# Poll the build status until complete or timeout
$time = 0
$refreshInterval = 5
$timeout = 120
$prevStatus = ""

while(1){
	$status = Invoke-RestMethod $result.restQueuedBuild.link.href
	if($status.result.lifeCycleState -eq 'Finished'){
		break;
	}
	
	if($status.result.lifeCycleState -ne $prevStatus){
		Write-Host ("Build is {0}" -f $status.result.lifeCycleState)
		$prevStatus = $status.result.lifeCycleState
	}
	
	if($time -ge $timeout)
	{
		Write-Host "Timeout exceeded..." -foregroundcolor "red"
		break;
	}
	
	Start-Sleep -s $refreshInterval
	$time += $refreshInterval
}

$fgcol = 'red'
if($status.result.state -eq 'Successful'){
	$fgcol='green'
}
Write-Host ("Build is {0}, outcome is {1}" -f $status.result.lifeCycleState, $status.result.state) -foregroundcolor $fgcol
Write-Host ("See {0} for details" -f $buildUrl) -foregroundcolor $fgcol

# Re-enable progress bars
$progressPreference = 'Continue'
