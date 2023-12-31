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

$projectName = $OctopusParameters["Octopus.Project.Name"]
$projectName = $projectName.ToLower()
$releaseNumber = $OctopusParameters["Octopus.Release.Number"]
$containerName = "dataART.$($projectName).$($releaseNumber).$($environment)"

$XSAurl = $OctopusParameters["dataART.XSAUrl"]
$XSAuser = $OctopusParameters["dataART.XSAUser"]
$XSAspace = $OctopusParameters["dataART.XSASpace"]

$HANAHost = $OctopusParameters["dataART.Host"]
$HANAInstance = $OctopusParameters["dataART.Instance"]
$HANADatabase = $OctopusParameters["dataART.Database"]

$OctopusWorkDir = $OctopusParameters["dataART.OctopusWorkDir"]

###############################################################################
# Get SQL from project
###############################################################################

write-host "*** Get SQL from project"

cd ../..
$workdirPath = $pwd.ToString()

$fullPath = "$($workdirPath)/Deployment/PreDeploy/$($environment)/*.txt"
if (Test-Path $($fullPath)) {}
else
{
   write-host "*******************************************************************"
   write-host " STOP predeploy.ps1 - no pre-deploy SQL defined"
   write-host "*******************************************************************"
   Exit
}

$fullPath = "$($workdirPath)/Deployment/PreDeploy/$($environment)"
$files = get-childitem "$fullPath" -include *.txt -Recurse
sort $files.FullName 

$arrFiles = @();

foreach($file in $files) 
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
   write-host " STOP predeploy.ps1 - no pre-deploy SQL defined"
   write-host "*******************************************************************"
   Exit
}

###############################################################################
# Get the XSA servicename for the project from the mta.yaml file
###############################################################################

write-host "*** Get MTA information for $projectName"

docker exec -t $containerName /bin/sh -c "rm -fv /data/$($containerName)*.txt"

docker exec -t $containerName /bin/sh -c "xs login -u $XSAuser -p $XSAPW -a $XSAurl -o orgname -s $XSAspace && xs mta $projectName > /data/$($containerName)-serviceName.txt"

$workdirPath = "$($OctopusWorkDir)/$($containerName)-serviceName.txt"
$File = Get-Content $($workdirPath)

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

docker exec -t $containerName /bin/sh -c "xs login -u $XSAuser -p $XSAPW -a $XSAurl -o orgname -s $XSAspace && xs delete-service-key $serviceName $serviceKey -f && xs create-service-key $serviceName $serviceKey && xs service-key $serviceName $serviceKey > /data/$($containerName)-serviceKey.txt"

$workdirPath = "$($OctopusWorkDir)/$($containerName)-serviceKey.txt"
$File = Get-Content $($workdirPath)

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

if ($DBuser -eq ' ')
{
   write-host "*******************************************************************"
   write-host " STOP predeploy.ps1 - no HDI service key found"
   write-host "*******************************************************************"
   Exit
}

###############################################################################
# Get SQL from project and execute
###############################################################################

write-host "*** Run pre-deployment SQL"

docker exec -t $containerName /bin/sh -c "rm -fv /data/$($containerName)*.txt"

$workdirPath = "$($OctopusWorkDir)/$($containerName)-SQLoneLine.txt"
if (Test-Path $($workdirPath)) { Remove-Item $($workdirPath) }
Set-Content $($workdirPath) -value $allLines 

docker exec -t $containerName /bin/sh -c "hdbsql -n $HANAHost -i $HANAInstance -d $HANADatabase -u $DBuser -p $DBpw -quiet -a -I /data/$($containerName)-SQLoneLine.txt -O /data/$($containerName)-SQLoutput.txt"

###############################################################################
# Analyse SQL result
###############################################################################

$workdirPath = "$($OctopusWorkDir)/$($containerName)-SQLoutput.txt"
$fileContent = Get-Content $($workdirPath)

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

docker exec -t $containerName /bin/sh -c "xs login -u $XSAuser -p $XSAPW -a $XSAurl -o orgname -s $XSAspace && xs delete-service-key $serviceName $serviceKey -f"

$workdirPath = "$($OctopusWorkDir)/$($containerName)-SQLoneLine.txt"
if (Test-Path $($workdirPath)) { Remove-Item $($workdirPath) }

docker exec -t $containerName /bin/sh -c "rm -fv /data/$($containerName)*.txt"

write-host "*******************************************************************"
write-host " STOP predeploy.ps1"
write-host "*******************************************************************"

Exit $resultCode