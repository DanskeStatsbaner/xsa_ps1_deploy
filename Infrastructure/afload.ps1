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
$workdirRoot = $workdirPath.Substring(2, $workdirPath.IndexOf("\Deployment")-2)

write-host "WORKDIR: $workdirRoot"

$artifactoryPW = $args[0]
$login = $OctopusParameters["artifactory.login"]
$registry = $OctopusParameters["artifactory.registry"]
$projectName = $OctopusParameters["Octopus.Project.Name"]
$containerName = $projectName

###############################################################################
# Stop and delete containers
###############################################################################

#docker container stop $(docker container ls -aq)
docker container rm $containerName -f
docker container prune -f

###############################################################################
# Login to artifactory, pull and start XSA_CLI_DEPLOY container
###############################################################################

docker login -u $login -p $artifactoryPW   $registry
docker pull artifactory.azure.dsb.dk/docker/xsa_cli_deploy
#docker run -t -d --name xsa_cli_deploy artifactory.azure.dsb.dk/docker/xsa_cli_deploy
docker run -v c:$($workdirRoot):/data -t -d --name $containerName -rm artifactory.azure.dsb.dk/docker/xsa_cli_deploy

write-host "*******************************************************************"
write-host " STOP afload.ps1"
write-host "*******************************************************************"