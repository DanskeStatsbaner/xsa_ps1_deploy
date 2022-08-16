$environment = $OctopusParameters["Octopus.Environment.Name"]

# exit if environment is Sandbox (sit)
if($environment -eq "sit") { Exit }

write-host "*******************************************************************"
write-host " START cleanup.ps1"
write-host "*******************************************************************"

###############################################################################
# Get all relevant parameters from octopus (variable set dataART)
###############################################################################

$projectName = $OctopusParameters["Octopus.Project.Name"]
$projectName = $projectName.ToLower()
$releaseNumber = $OctopusParameters["Octopus.Release.Number"]
$containerName = "dataART.$($projectName).$($releaseNumber).$($environment)"

$OctopusWorkDir = $OctopusParameters["dataART.OctopusWorkDir"]

###############################################################################
# Delete workfiles
###############################################################################

$workdirPath = "$($OctopusWorkDir)/$($containerName)-SQLoneLine.txt"
if (Test-Path $($workdirPath)) { Remove-Item $($workdirPath) }
$workdirPath = "$($OctopusWorkDir)/$($containerName).mtar"
if (Test-Path $($workdirPath)) { Remove-Item $($workdirPath) }

docker exec -t $containerName /bin/sh -c "rm -fv *.txt"

###############################################################################
# Stop and delete containers
###############################################################################

if ($(docker container ls -aq -f name="$containerName").length -gt 0){ docker container stop $($containerName) }
docker container prune -f

write-host "*******************************************************************"
write-host " STOP cleanup.ps1"
write-host "*******************************************************************"