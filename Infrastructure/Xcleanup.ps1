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
$releaseNumber = $OctopusParameters["Octopus.Release.Number"]
$containerName = "dataArt.$($projectName).$($releaseNumber).$($environment)"

$OctopusWorkDir = $OctopusParameters["dataART.OctopusWorkDir"]

###############################################################################
# Stop and delete containers
###############################################################################

if ($(docker container ls -aq -f name="$containerName").length -gt 0){ docker container stop $($containerName) }
docker container prune -f

###############################################################################
# Delete workfiles
###############################################################################

if (Test-Path $OctopusWorkDir\$($containerName)-SQLoutput.txt) { Remove-Item $OctopusWorkDir\$($containerName)-SQLoutput.txt }
if (Test-Path $OctopusWorkDir\$($containerName)-SQLoneLine.txt) { Remove-Item $OctopusWorkDir\$($containerName)-SQLoneLine.txt }
if (Test-Path $OctopusWorkDir\$($containerName)-serviceName.txt) { Remove-Item $OctopusWorkDir\$($containerName)-serviceName.txt }
if (Test-Path $OctopusWorkDir\$($containerName)-serviceKey.txt) { Remove-Item $OctopusWorkDir\$($containerName)-serviceKey.txt }
if (Test-Path $OctopusWorkDir\$($containerName).mtar) { Remove-Item $OctopusWorkDir\$($containerName).mtar }

write-host "*******************************************************************"
write-host " STOP cleanup.ps1"
write-host "*******************************************************************"