$environment = $OctopusParameters["Octopus.Environment.Name"]

# exit if environment is Sandbox (sit)
if($environment -eq "sit") { Exit }

write-host "*******************************************************************"
write-host " START deploy.ps1"
write-host "*******************************************************************"

###############################################################################
# Get all relevant parameters from octopus (variable set dataART)
###############################################################################

$XSAPW = $args[0]

$workdirPath = $pwd.ToString()
$projectName = $OctopusParameters["Octopus.Project.Name"]
$releaseNumber = $OctopusParameters["Octopus.Release.Number"]
$containerName = $projectName

$XSAurl = $OctopusParameters["dataART.XSAUrl"]
$XSAuser = $OctopusParameters["dataART.XSAUser"]
$XSAspace = $OctopusParameters["dataART.XSASpace"]

###############################################################################
# Copy project mtar file to work directory - c:\octopus\work\
###############################################################################

Copy-Item "$workdirPath\dataArt.$projectName.$releaseNumber.mtar" -Destination "C:\octopus\work" -Force
#docker cp $workdirPath\dataArt.$projectName.$releaseNumber.mtar xsa_cli_deploy:/root/dataArt.$projectName.$releaseNumber.mtar
#docker container diff xsa_cli_deploy
#docker cp xsa_cli_deploy:/root/. c:\octopus\work\

###############################################################################
# Deploy:
#
# Docker exec explain: 
# /bin/sh -c  = run shell within container:
#    cp = copy mtar from mount to container root
#    login hana
#    deploy hana
#
###############################################################################

#docker run -v c:\octopus\work\:/data artifactory.azure.dsb.dk/docker/xsa_cli_deploy /bin/sh -c "cp /data/dataArt.$projectName.$releaseNumber.mtar . && ls -la && xs login -u $XSAuser -p $XSAPW -a $XSAurl -o orgname -s $XSAspace && xs deploy -f dataArt.$projectName.$releaseNumber.mtar"
docker exec -it $containerName /bin/sh -c "cp /data/dataArt.$projectName.$releaseNumber.mtar . && xs login -u $XSAuser -p $XSAPW -a $XSAurl -o orgname -s $XSAspace && xs deploy -f dataArt.$projectName.$releaseNumber.mtar"

write-host "*******************************************************************"
write-host " STOP deploy.ps1"
write-host "*******************************************************************"