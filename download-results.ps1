######################
# download-results.ps1
######################

if (-NOT (TEST-PATH -PATH $AUTH_FILE))
{
  Write-Host 'Auth credentials file does not exist or this program does not have permission to access it'
  exit
}

$JOB_RESULTS = Get-Content -Path 'complete_job_response.json' | select -Last 1

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

# Set API variables

$OKTA_URI_WITH_PARAMS = "$AUTHENTICATION_URL`?grant_type=client_credentials&scope=clientCreds"

# Get number of files, first file index, and last file index

$NUMBER_OF_FILES = ($JOB_RESULTS | ConvertFrom-Json).output.Count
$FIRST_FILE_INDEX = 0
$LAST_FILE_INDEX = ($JOB_RESULTS | ConvertFrom-Json).output.Count - 1
Write-Host "There are $NUMBER_OF_FILES file(s) with index(es) ranging from $FIRST_FILE_INDEX to $LAST_FILE_INDEX."
Write-Host ''

# Download file(s) incrementing the file index after each file is downloaded until the last file index is reached

$FILE_INDEX = 0
while ($FILE_INDEX -ne ($LAST_FILE_INDEX + 1)) {
  # Refresh bearer token
  $BEARER_TOKEN = Get-Bearer-Token
  $FILE_URL = ($JOB_RESULTS | ConvertFrom-Json).output[$FILE_INDEX].url
  $FILE = $FILE_URL.split("/")[9]

  if (TEST-PATH -PATH $FILE)
  {
    Write-Host "$FILE already exists will not override"
  } else
  {
    Write-Host '---------------------------------------------------------------------------------------------------------------------'
    Write-Host "File URL: $($FILE_URL)"
    Write-Host "Downloading $($FILE)..."
    Write-Host '---------------------------------------------------------------------------------------------------------------------'
    Write-Host ''

    $client = New-Object System.Net.WebClient
    $client.headers["Authorization"] = "Bearer $BEARER_TOKEN"
    $client.headers["Accept"] = "application/fhir+ndjson"

    try {
      Add-Content -Path $FILE -Value $client.DownloadString("$FILE_URL")
    } catch [System.Net.WebException] {
      $result = $_.Exception.Response
      Write-Host $result
      Write-Host ''
    }
  }
  $FILE_INDEX++
}
