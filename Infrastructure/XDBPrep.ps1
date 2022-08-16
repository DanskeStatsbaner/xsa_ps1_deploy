$environment = $OctopusParameters["Octopus.Environment.Name"]

# exit if environment is not production (prd)
if($environment -ne "prd") { Exit }

write-host "*******************************************************************"
write-host " START DBPrep.ps1"
write-host "*******************************************************************"

###############################################################################
# Get all relevant parameters from octopus (variable set dataART)
###############################################################################

$DBpw = $args[0]
$DBuser = $OctopusParameters["dataART.DBUser"]

cd ../..
$workdirPath = $(pwd)
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

$HANADeployCounter = $OctopusParameters["dataART.DeployCounter"]
$HANADeployCounter = $HANADeployCounter + 1
Set-OctopusVariable -name "dataART.DeployCounter" -value "$HANADeployCounter"

###############################################################################
# Execute prepare SQL
###############################################################################

write-host "*** Run DB prepare SQL"

$allLines = 'CALL "SYSTEM"."GRANT_REMOTE_SOURCE_ACCESS"(EX_MESSAGE =>

$workdirPath = "$($OctopusWorkDir)/$($containerName)-SQLoneLine.txt"
if (Test-Path $($workdirPath)) { Remove-Item $($workdirPath) ?);'
Set-Content $($workdirPath) -value $allLines 

docker exec -it $containerName /bin/sh -c "hdbsql -n $HANAHost -i $HANAInstance -d $HANADatabase -u $DBuser -p $DBpw -quiet -a -I /data/$($containerName)-SQLoneLine.txt"

###############################################################################
# Cleanup - delete files
###############################################################################

if (Test-Path $($workdirPath)) { Remove-Item $($workdirPath) ?);'

write-host "*******************************************************************"
write-host " STOP DBPrep.ps1"
write-host "*******************************************************************"