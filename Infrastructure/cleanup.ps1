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
$containerName = $projectName

###############################################################################
# Stop and delete containers
###############################################################################

if ($(docker container ls -aq -f name="$containerName").length -gt 0){ docker container stop $($containerName) }
docker container prune -f

###############################################################################
# Delete workfiles
###############################################################################

if (Test-Path c:\Octopus\Work\$($projectName)-SQLoutput.txt) { Remove-Item c:\Octopus\Work\$($projectName)-SQLoutput.txt }
if (Test-Path c:\Octopus\Work\$($projectName)-SQLoneLine.txt) { Remove-Item c:\Octopus\Work\$($projectName)-SQLoneLine.txt }
if (Test-Path c:\Octopus\Work\$($projectName)-serviceName.txt) { Remove-Item c:\Octopus\Work\$($projectName)-serviceName.txt }
if (Test-Path c:\Octopus\Work\$($projectName)-serviceKey.txt) { Remove-Item c:\Octopus\Work\$($projectName)-serviceKey.txt }
if (Test-Path c:\Octopus\Work\dataArt.$($projectName).$($releaseNumber).mtar) { Remove-Item c:\Octopus\Work\dataArt.$($projectName).$($releaseNumber).mtar }

write-host "*******************************************************************"
write-host " STOP cleanup.ps1"
write-host "*******************************************************************"