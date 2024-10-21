###################################
# create-job.ps1
###################################

if (-NOT (TEST-PATH -PATH $AUTH_FILE))
{
    Write-Host 'Auth credentials file does not exist or this program does not have permission to access it'
    exit
}

if ($AB2D_API_URL -like "*/v1" -And $UNTIL)
{
    Write-Host 'The _until parameter is only available with version 2 (FHIR R4) of the API'
    exit
}

$AUTH = Get-Content $AUTH_FILE
$AUTH = $AUTH.Trim()

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Get-Bearer-Token {
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Authorization", "Basic $AUTH")
    $headers.Add("Accept", "application/json")
    $headers.Add("Content-Type", "application/x-www-form-urlencoded")
    $response = Invoke-RestMethod "$OKTA_URI_WITH_PARAMS" -Method "POST" -Headers $headers -Body $body
    if ($response.access_token) {
        Write-Host 'Received access token that was not null'
    }
    return $response.access_token
}

# Set API variables
$OKTA_URI_WITH_PARAMS = "$AUTHENTICATION_URL`?grant_type=client_credentials&scope=clientCreds"
$EXPORT_URL = "$AB2D_API_URL/fhir/Patient/`$export`?_outputFormat=application%2Ffhir%2Bndjson&_type=ExplanationOfBenefit"

if ($SINCE)
{
    $SINCE = $SINCE -replace ":", "%3A"
    $EXPORT_URL = $EXPORT_URL + "&_since=" + $SINCE
}
if ($UNTIL)
{
    $UNTIL = $UNTIL -replace ":", "%3A"
    $EXPORT_URL = $EXPORT_URL + "&_until=" + $UNTIL
}

Write-Host '---------------------------------------------------------------------------------------------------------------------'
Write-Host 'The OKTA URI used for getting bearer token'
Write-Host '---------------------------------------------------------------------------------------------------------------------'
Write-Host $OKTA_URI_WITH_PARAMS
Write-Host ''
Write-Host '---------------------------------------------------------------------------------------------------------------------'
Write-Host 'The AB2D API endpoint for starting an export job'
Write-Host '---------------------------------------------------------------------------------------------------------------------'
Write-Host $EXPORT_URL
Write-Host ''

# Get initial bearer token

$BEARER_TOKEN = Get-Bearer-Token

# Create an export job

$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Accept", "application/json")
$headers.Add("Prefer", "respond-async")
$headers.Add("Authorization", "Bearer $BEARER_TOKEN")
$response = Invoke-WebRequest "$EXPORT_URL" -Method 'GET' -Headers $headers -Body $body
$STATUS_URL = $response.Headers['Content-Location']

if ($STATUS_URL)
{
    Write-Host "Starting a job succeeded"
    Write-Host "Saving the status url to use for monitoring $STATUS_URL"
    Set-Content -Path 'status_url.txt' $STATUS_URL
} else {
    Write-Host 'Starting a job failed'
}

