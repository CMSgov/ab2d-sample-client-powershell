# Welcome to the AB2D PowerShell Sample Repo 

Our API Clients are open source. This repo contains *sample* PowerShell script which demonstrate how to pull data from the AB2D API Production environment.

This may be a great starting point for your engineering or development teams however it is important to note that the AB2D team does **not** regularly maintain the sample clients. Additionally, a best-effort was made to ensure the clients are secure but they have **not** undergone comprehensive formal security testing. Each user/organization is responsible for conducting their own review and testing prior to implementation

Use of these clients in the sandbox environment, can allow for testing, and if a mistake is made no PII/PHI is compromised. The sandbox environment is publicly available and all of the data in it is synthetic (**not** real)

## Production Use Disclaimer:

These clients are provided as examples, but they are fully functioning (with some modifications) in the production environment. Feel free to use them as a reference. When used in production (even for testing purposes), these clients have the ability to download PII/PHI information. You should therefore ensure the environment in which these scripts are run is secured in a way to allow for storage of PII/PHI. Additionally, when used in the production environment the scripts will require use of your production credentials. As such, please ensure that your credentials are handled in a secure manner and not printed to logs or the terminal. Ensuring the privacy of data is the responsibility of each user and/or organization.


## AB2D PowerShell Instructions

Sample scripts running a full export from starting a job to downloading results

Files Created by Scripts:

1. status_url.txt -- url to check the status of a newly created job
1. completed_job_response.json -- response from status_url when a job has completed successfully.
1. *.ndjson -- eob claims data downloaded after an export completes

Assumptions:

1. Assumes all scripts use the same directory
1. Assumes all scripts use the same base64 encoded AUTH token saved to a file

## Overview

Scripts:

1. create-job.ps1 - create a job and save the url where the status of the job can be checked
1. monitor-job.ps1 - monitor a job until it completes or fails. If it completes, save the list of files to download.
1. download-results.ps1 - download the results of a job to the current directory

These scripts must be run in order to complete a download.

## Since

If you only want claims data updated or filed after a certain date specify the `$SINCE` parameter. 
The expected format is yyyy-MM-dd'T'HH:mm:ss.SSSXXX+/-ZZ:ZZ which follows ISO datetime standards.

The earliest date that since works for is February 13th, 2020. Specifically: `2020-02-13T00:00:00.000-05:00`

Examples:
1. March 1, 2020 at 3 PM EST -> `2020-03-01T15:00:00.000-05:00`
2. May 31, 2020 at 4 AM PST `2020-05-31T04:00:00-08:00`

Example in powershell:

   ```ShellSession
   $SINCE=2020-03-01T15:00:00.000-05:00
   ```

## Step by Step Guide

1. Note the following

   - these directions assume that you are on a Windows machine with PowerShell

   - sandbox is publicly available

   - production is only accessible if you machine has been whitelisted to use it

1. Open PowerShell as an administrator

   1. Select the Windows icon (likely in the bottom left of the screen)

   1. Type the following in the search text box

      ```
      powershell
      ```

   1. Right click on **Windows PowerShell**

   1. Select **Run as administrator**

   1. If the "User Account Conntrol" window appears, select **Yes**

1. Allow PowerShell to run scripts that are not digitally signed

   ```ShellSession
   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
   ```
   
1. Create a download directory where you will be saving the AB2D data

   *Be sure to change the date to today's date.*
   
   *Example:*

   ```ShellSession
   mkdir $home\documents\2020-10-22
   ```

1. Change to the download directory

   *Be sure to change the date to today's date.*
   
   *Example:*

   ```ShellSession
   cd $home\documents\2020-10-22
   ```

1. Note that under each of the following steps, you do the following:

   - copy all lines to the clipboard

   - paste all lines into PowerShell

   - press Enter on the keyboard
   
1. Create the Base64 credentials and save them to the AUTH_FILE

   **Skip if you have already created a Base64 credentials file**

   *Sandbox (working example):*
    
   ```ShellSession
   $BASE64_ENCODED_ID_PASSWORD='MG9hMnQwbHNyZFp3NXVXUngyOTc6SEhkdVdHNkxvZ0l2RElRdVdncDNabG85T1lNVmFsVHRINU9CY3VIdw=='
   Set-Content -Path "{credentials-file}" $BASE64_ENCODED_ID_PASSWORD
   ```
    
   *Production (replace {variable} with your settings):*
    
   ```ShellSession
   $BASE64_ENCODED_ID_PASSWORD='{Base64-encoded id:password}'
   Set-Content -Path "{credentials-file}" $BASE64_ENCODED_ID_PASSWORD
   ```
   
1. Check the base 64 credentials for correctness

   **Skip if you know the Base64 credentials file is accurate**

   ```ShellSession
   $BASE64_ENCODED_ID_PASSWORD = Get-Content "{credentials-file}"
   [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($BASE64_ENCODED_ID_PASSWORD))
   ```

    You should see your id:password just as in the previous step. If you do not then the encoding was not successful.

1. Set target environment variables for target environment and FHIR version. FHIR STU3 (the default) is `v1`. 
   FHIR R4 (coming soon), will be `v2`.

   *Sandbox FHIR STU3 (working example, for FHIR R4, replace v1 with v2 in `AB2D_API_URL`):*

   ```ShellSession
   $AUTH_FILE="{credentials-file}"
   $AUTHENTICATION_URL='https://test.idp.idm.cms.gov/oauth2/aus2r7y3gdaFMKBol297/v1/token'
   $AB2D_API_URL='https://sandbox.ab2d.cms.gov/api/v1'
   
   # If you only want claims data updated or filed after a specific date use the $SINCE parameter
   $SINCE=2020-02-13T00:00:00.000-05:00
   ```

   *Production FHIR STU3 (replace {variable} with your settings, for FHIR R4, replace v1 with v2 in `AB2D_API_URL`):*

   ```ShellSession
   $AUTH_FILE="{your-credentials-file}"
   $AUTHENTICATION_URL='https://idm.cms.gov/oauth2/aus2ytanytjdaF9cr297/v1/token'
   $AB2D_API_URL='https://api.ab2d.cms.gov/api/v1'
   
   # If you only want claims data updated or filed after a specific date use the $SINCE parameter
   $SINCE=2020-02-13T00:00:00.000-05:00
   ```
   
1. Create an export job

   ```ShellSession
   .\create-job.ps1
   ```
   
1. Monitor the status of the export job

   ```ShellSession
   .\monitor-job.ps1
   ```

1. Download file(s)

    **This script will not overwrite existing files so please move previous downloads before running this script**

   ```ShellSession
   .\download-results.ps1
   ```

1. Open your downloaded file(s) in an editor to view the data

   *Sandbox example of the downloaded file:*

   ```
   $home\documents\2020-10-22\Z0000_0001.ndjson
   ```
