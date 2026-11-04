###################################
# create-job.ps1
###################################

# Validate AB2D API version: v1 (FHIR STU3), v2 (FHIR R4) or v3 (FHIR R4)
if ($AB2D_API_URL -notmatch '/v[123]$')
{
    Write-Host "AB2D_API_URL must end with /v1, /v2 or /v3 (current: $AB2D_API_URL)"
    exit
}

if (-NOT (TEST-PATH -PATH $AUTH_FILE))
{
    Write-Host 'Auth credentials file does not exist or this program does not have permission to access it'
    exit
}

if ($AB2D_API_URL -like "*/v1" -And $UNTIL)
{
    Write-Host 'The _until parameter is only available with version 2 and version 3 (FHIR R4) of the API'
    exit
}

if ($SERVICE_DATE -And $AB2D_API_URL -notlike "*/v3")
{
    Write-Host 'The $SERVICE_DATE parameter is only available with version 3 of the API'
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
if ($SERVICE_DATE)
{
    # service-date is passed to the API as a URL encoded _typeFilter subquery on ExplanationOfBenefit
    # gt2026-01-01,lt2026-02-01 -> ExplanationOfBenefit?service-date=gt2026-01-01&service-date=lt2026-02-01
    $SERVICE_DATE_PARAMS = ($SERVICE_DATE -split "," | ForEach-Object { "service-date%3D" + $_.Trim() }) -join "%26"
    $EXPORT_URL = $EXPORT_URL + "&_typeFilter=ExplanationOfBenefit%3F" + $SERVICE_DATE_PARAMS
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

