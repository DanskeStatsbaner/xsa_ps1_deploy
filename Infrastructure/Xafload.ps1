$environment = $OctopusParameters["Octopus.Environment.Name"]

# exit if environment is Sandbox (sit)
if($environment -eq "sit") { Exit }

write-host "*******************************************************************"
write-host " START afload.ps1"
write-host "*******************************************************************"

###############################################################################
# Get all relevant parameters from octopus (variable set dataART)
###############################################################################

$workdirPath = $pwd.ToString()

$artifactoryPW = $args[0]
$login = $OctopusParameters["artifactory.login"]
$registry = $OctopusParameters["artifactory.registry"]
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
# Login to artifactory, pull and start XSA_CLI_DEPLOY container
###############################################################################

docker login -u $login -p $artifactoryPW   $registry
docker pull artifactory.azure.dsb.dk/docker/xsa_cli_deploy
docker run -v $OctopusWorkDir:/data --name $containerName --rm -t -d artifactory.azure.dsb.dk/docker/xsa_cli_deploy

write-host "*******************************************************************"
write-host " STOP afload.ps1"
write-host "*******************************************************************"