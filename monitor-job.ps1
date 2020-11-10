###################################
# monitor-job.ps1
###################################

if (-NOT (TEST-PATH -PATH $AUTH_FILE))
{
  Write-Host 'Auth credentials file does not exist or this program does not have permission to access it'
  exit
}

# Pull URL returned by AB2D which can be used to grab the status of the job
$STATUS_URL = Get-Content 'status_url.txt'

Write-Host '---------------------------------------------------------------------------------------------------------------------'
Write-Host 'The AB2D API status URL that is used to check the status of the job'
Write-Host '---------------------------------------------------------------------------------------------------------------------'
Write-Host $STATUS_URL
Write-Host ''

$AUTH = Get-Content $AUTH_FILE
$AUTH = $AUTH.Trim()

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Get-Bearer-Token {
  $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
  $headers.Add("Authorization", "Basic $AUTH")
  $headers.Add("Accept", "application/json")
  $headers.Add("Content-Type", "application/x-www-form-urlencoded")
  $response = Invoke-RestMethod "$OKTA_URI_WITH_PARAMS" -Method "POST" -Headers $headers -Body $body
  Write-Host '---------------------------------------------------------------------------------------------------------------------'
  Write-Host 'The latest bearer token used to authenticate with the AB2D API (expires in 1 hour)'
  Write-Host '---------------------------------------------------------------------------------------------------------------------'
  Write-Host $response.access_token
  Write-Host ''
  return $response.access_token
}

# Set API variables for retrieving bearer token
$OKTA_URI_WITH_PARAMS = "$AUTHENTICATION_URL`?grant_type=client_credentials&scope=clientCreds"

# Get initial bearer token
$BEARER_TOKEN = Get-Bearer-Token


# Check job status until you get a status of 200

$JOB_COMPLETE = 0
$COUNTER = 0
$SLEEP_TIME_IN_SECONDS = 60
$TOTAL_PROCESSING_TIME = 0
$REFRESH_TOKEN_FACTOR_IN_SECONDS = 1800

while ($response.StatusCode -ne "200") {
  $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
  $headers.Add("Accept", "application/json")
  $headers.Add("Authorization", "Bearer $BEARER_TOKEN")
  $response = Invoke-WebRequest "$STATUS_URL" -Method 'GET' -Headers $headers -Body $body

  if ($response.StatusCode -ne "200") {
    Write-Host '---------------------------------------------------------------------------------------------------------------------'
    Write-Host "Current status code: $($response.StatusCode)"

    if ($TOTAL_PROCESSING_TIME -ne 0) {
      Write-Host "Job process time (in seconds): $($TOTAL_PROCESSING_TIME)"
    } else {
      Write-Host "Starting job monitoring..."
    }
    Write-Host '---------------------------------------------------------------------------------------------------------------------'
    Write-Host ''

  } else {
    Write-Host '---------------------------------------------------------------------------------------------------------------------'
    Write-Host 'Export job complete'
    Write-Host '---------------------------------------------------------------------------------------------------------------------'
    Write-Host ''

    $JOB_COMPLETE = 1
    Set-Content -Path 'complete_job_response.json' $response
  }

  if ($JOB_COMPLETE -eq 0) {
    Start-Sleep -Seconds $SLEEP_TIME_IN_SECONDS
    $COUNTER++
    $TOTAL_PROCESSING_TIME += $SLEEP_TIME_IN_SECONDS

    if (($TOTAL_PROCESSING_TIME % $REFRESH_TOKEN_FACTOR_IN_SECONDS) -eq 0) {
      # Refresh bearer token
      $BEARER_TOKEN = Get-Bearer-Token
    }
  }
}
