$environment = $OctopusParameters["Octopus.Environment.Name"]

# exit hvis miljø er Sandbox (sit)
if($environment -eq "sit") { Exit }

$login = $OctopusParameters["artifactory.login"]
$registry = $OctopusParameters["artifactory.registry"]
$artifactoryPW = $args[0]

# stop alle kørende containers
docker container stop $(docker container ls -aq)
# slet alle containers
docker container prune -f

# login artifactory
docker login -u $login -p $artifactoryPW   $registry


# hent vores SAP software container
docker pull artifactory.azure.dsb.dk/docker/xsa_hdbcli
docker run -t -d --name xsa_hdbcli artifactory.azure.dsb.dk/docker/xsa_hdbcli