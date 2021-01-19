$environment = $OctopusParameters["Octopus.Environment.Name"]

# exit if environment is Sandbox (sit)
if($environment -eq "sit") { Exit }

write-host "*******************************************************************"
write-host " START predeploy.ps1"
write-host "*******************************************************************"

###############################################################################
# Get all relevant parameters from octopus (variable set dataART)
###############################################################################

$XSAPW = $args[0]

$workdirPath = $pwd.ToString()
$workdirPath = $workdirPath.Substring(2, $workdirPath.IndexOf("\Deployment")-2)

$projectName = $OctopusParameters["Octopus.Project.Name"]
$releaseNumber = $OctopusParameters["Octopus.Release.Number"]
$containerName = $projectName

$XSAurl = $OctopusParameters["dataART.XSAUrl"]
$XSAuser = $OctopusParameters["dataART.XSAUser"]
$XSAspace = $OctopusParameters["dataART.XSASpace"]

$HANAHost = $OctopusParameters["dataART.Host"]
$HANAInstance = $OctopusParameters["dataART.Instance"]
$HANADatabase = $OctopusParameters["dataART.Database"]


###############################################################################
# Get SQL from project
###############################################################################

write-host "*** Get SQL from project"

$workdirPath = $workdirPath.Substring(2, $workdirPath.IndexOf("\Deployment")-2)

$fullPath = "$($workdirPath)\Deployment\PreDeploy\$($environment)\*.txt"

$files = Get-ChildItem -Path c:$($fullPath) | sort $files.FullName

$arrFiles = @();

foreach($file in $files ) 
{
    $fileContent = Get-Content $file.FullName
    $allLines = [string]::join(" ",($fileContent.Split("`n")))
    $allLines = [string]::join(" ",($allLines.Split("`r")))
    $arrFiles += $allLines;
}

$allLines = [string]::join(" ", $arrFiles)

if ($allLines -eq ' ')
{
   write-host "*******************************************************************"
   write-host " STOP predeploy.ps1"
   write-host "*******************************************************************"
   Exit
}

###############################################################################
# Get the XSA servicename for the project from the mta.yaml file
###############################################################################

write-host "*** Get MTA information for $projectName"

if (Test-Path c:\Octopus\Work\$($projectName)-serviceName.txt) { Remove-Item c:\Octopus\Work\$($projectName)-serviceName.txt }

#docker run -v c:\octopus\work:/data artifactory.azure.dsb.dk/docker/xsa_cli_deploy /bin/sh -c "xs login -u $XSAuser -p $XSAPW -a $XSAurl -o orgname -s $XSAspace && xs mta $projectName > /data/$($projectName)-serviceName.txt"
docker exec -it $containerName /bin/sh -c "xs login -u $XSAuser -p $XSAPW -a $XSAurl -o orgname -s $XSAspace && xs mta $projectName > /data/$($projectName)-serviceName.txt"

$File = Get-Content c:\Octopus\Work\$($projectName)-serviceName.txt

foreach ($line in $File)
{
    $Arr = $line -split ' '
    foreach ($cell in $Arr)
    {
        if ($cell -eq 'hdi-shared'){$serviceName = $Arr[0]}
    }
}

###############################################################################
# Create new service key and get credentials
###############################################################################

$serviceKey = $($serviceName) + "-sk"

write-host "*** Setup servicekey $serviceKey"

if (Test-Path c:\Octopus\Work\$($projectName)-serviceKey.txt) { Remove-Item c:\Octopus\Work\$($projectName)-serviceKey.txt }

#docker run -v c:\octopus\work:/data artifactory.azure.dsb.dk/docker/xsa_cli_deploy /bin/sh -c "xs login -u $XSAuser -p $XSAPW -a $XSAurl -o orgname -s $XSAspace && xs delete-service-key $serviceName $serviceKey -f"
docker exec -it $containerName /bin/sh -c "xs login -u $XSAuser -p $XSAPW -a $XSAurl -o orgname -s $XSAspace && xs delete-service-key $serviceName $serviceKey -f"
docker exec -it $containerName /bin/sh -c "xs login -u $XSAuser -p $XSAPW -a $XSAurl -o orgname -s $XSAspace && xs create-service-key $serviceName $serviceKey"
docker exec -it $containerName /bin/sh -c "xs login -u $XSAuser -p $XSAPW -a $XSAurl -o orgname -s $XSAspace && xs service-key $serviceName $serviceKey > /data/$($projectName)-serviceKey.txt"

$File = Get-Content c:\Octopus\Work\$($projectName)-serviceKey.txt

foreach ($line in $File)
{
    $Arr = $line -split ' '
    foreach ($cell in $Arr)
    {
        if ($cell -eq '"user"'){$userArr = $Arr[4] -split '"'}
        elseif ($cell -eq '"password"'){$passwordArr = $Arr[4] -split '"'}
    }
}

$DBuser = $userArr[1]
$DBpw = $passwordArr[1]

###############################################################################
# Get SQL from project and execute
###############################################################################

write-host "*** Run pre-deployment SQL"

Write-Host "ALL LINES: $allLines" 

if (Test-Path c:\Octopus\Work\$($projectName)-SQLoutput.txt) { Remove-Item c:\Octopus\Work\$($projectName)-SQLoutput.txt }
if (Test-Path c:\Octopus\Work\$($projectName)-SQLoneLine.txt) { Remove-Item c:\Octopus\Work\$($projectName)-SQLoneLine.txt }
Set-Content c:\Octopus\Work\$($projectName)-SQLoneLine.txt -value $allLines 

#docker run -v c:\octopus\work:/data artifactory.azure.dsb.dk/docker/xsa_cli_deploy /bin/sh -c "hdbsql -n $HANAHost -i $HANAInstance -d $HANADatabase -u $DBuser -p $DBpw -quiet -a -I /data/$($projectName)-SQLoneLine.txt -O /data/$($projectName)-SQLoutput.txt"
docker exec -it $containerName /bin/sh -c "hdbsql -n $HANAHost -i $HANAInstance -d $HANADatabase -u $DBuser -p $DBpw -quiet -a -I /data/$($projectName)-SQLoneLine.txt -O /data/$($projectName)-SQLoutput.txt"

###############################################################################
# Analyse SQL result
###############################################################################

$fileContent = Get-Content c:\Octopus\Work\$($projectName)-SQLoutput.txt

$fileContentArr = $fileContent.Split(@("`r`n", "`r", "`n"),[StringSplitOptions]::None)

Write-Host "SQL results:"
Write-Host " "

$resultCode = 0

ForEach($fileLine in $fileContentArr) 
{
    Write-Host $fileLine
    $lineContentArr = $fileLine.Split(" ",[StringSplitOptions]::None)
    $resultCode += $lineContentArr[1]
}

###############################################################################
# Cleanup - delete servicekey and delete files
###############################################################################

write-host "*** Cleanup - delete servicekey"

#docker run -v c:\octopus\work:/data artifactory.azure.dsb.dk/docker/xsa_cli_deploy /bin/sh -c "xs login -u $XSAuser -p $XSAPW -a $XSAurl -o orgname -s $XSAspace && xs delete-service-key $serviceName $serviceKey -f"
docker exec -it $containerName /bin/sh -c "xs login -u $XSAuser -p $XSAPW -a $XSAurl -o orgname -s $XSAspace && xs delete-service-key $serviceName $serviceKey -f"

if (Test-Path c:\Octopus\Work\$($projectName)-serviceName.txt) { Remove-Item c:\Octopus\Work\$($projectName)-serviceName.txt }
if (Test-Path c:\Octopus\Work\$($projectName)-serviceKey.txt) { Remove-Item c:\Octopus\Work\$($projectName)-serviceKey.txt }
if (Test-Path c:\Octopus\Work\$($projectName)-SQLoneLine.txt) { Remove-Item c:\Octopus\Work\$($projectName)-SQLoutput.txt }
if (Test-Path c:\Octopus\Work\$($projectName)-SQLoneLine.txt) { Remove-Item c:\Octopus\Work\$($projectName)-SQLoneLine.txt }

write-host "*******************************************************************"
write-host " STOP predeploy.ps1"
write-host "*******************************************************************"

Exit $resultCode