######################
# download-results.ps1
######################

if (-NOT (TEST-PATH -PATH $AUTH_FILE))
{
  Write-Host 'Auth credentials file does not exist or this program does not have permission to access it'
  exit
}

$JOB_RESULTS = Get-Content -Path 'complete_job_response.json'

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

# Get number of files, first file index, and last file index

$NUMBER_OF_FILES = ($JOB_RESULTS | ConvertFrom-Json).output.Count
$FIRST_FILE_INDEX = 0
$LAST_FILE_INDEX = ($JOB_RESULTS | ConvertFrom-Json).output.Count - 1
Write-Host "There are $NUMBER_OF_FILES file(s) with index(es) ranging from $FIRST_FILE_INDEX to $LAST_FILE_INDEX."
Write-Host ''

# Download file(s) incrementing the file index after each file is downloaded until the last file index is reached
[System.GC]::Collect()

$FILE_INDEX = 0
while ($FILE_INDEX -ne ($LAST_FILE_INDEX + 1)) {
  # Refresh bearer token
  $BEARER_TOKEN = Get-Bearer-Token
  $FILE_URL = ($JOB_RESULTS | ConvertFrom-Json).output[$FILE_INDEX].url
  $FILE = $FILE_URL.split("/")[9]

  if (TEST-PATH -PATH $FILE)
  {
    Write-Host "WARNING: $FILE already exists will not download. Run script again once file is moved to download."
  } else
  {
    Write-Host '---------------------------------------------------------------------------------------------------------------------'
    Write-Host "File URL: $($FILE_URL)"
    Write-Host "Downloading $($FILE)..."
    Write-Host '---------------------------------------------------------------------------------------------------------------------'
    Write-Host ''

    # Note: Setting 'Accept-Encoding: gzip' will download file in gzip format and Powershell will automatically decode (to NDJSON)
    $headers = @{
      "Authorization" = "Bearer $BEARER_TOKEN"
      "Accept" = "application/fhir+ndjson"
      "Accept-Encoding" = "gzip"
    }

    try {
      Invoke-WebRequest -Uri "$FILE_URL" -Headers $headers -Method Get -OutFile "$FILE"
    } catch [System.Net.WebException] {
      Write-Host "  Status Code: $($_.Exception.Response.StatusCode.value__)"
      Write-Host "  Status Description: $($_.Exception.Response.StatusDescription)"
      Write-Host "  Message: $($_.Exception.Message)"
    }
  }

  [System.GC]::Collect()
  $FILE_INDEX++
}
