$environment = $OctopusParameters["Octopus.Environment.Name"]

# exit hvis miljø er Sandbox (sit)
if($environment -eq "sit") { Exit }

write-host "*******************************************************************"
write-host " START postdeploy.ps1"
write-host "*******************************************************************"
$XSAPW = $args[0]

$workdirPath = $(pwd)
$projectName = $OctopusParameters["Octopus.Project.Name"]
$releaseNumber = $OctopusParameters["Octopus.Release.Number"]

$XSAurl = $OctopusParameters["dataART.XSAUrl[$environment]"]
$XSAuser = $OctopusParameters["dataART.XSAUser[$environment]"]
$XSAspace = $OctopusParameters["dataART.XSASpace[$environment]"]

$Host = $OctopusParameters["dataART.Host[$environment]"]
$Instance = $OctopusParameters["dataART.Instance[$environment]"]
$Database = $OctopusParameters["dataART.Database[$environment]"]


#docker run -v c:\octopus\work\dataArt.$projectName.$releaseNumber:/data artifactory.azure.dsb.dk/docker/xsa_cli_deploy /bin/sh -c "cp /data/dataArt.$projectName.$releaseNumber.mtar . && ls -la && xs login -u $XSAuser -p $XSAPW -a $XSAurl -o orgname -s $XSAspace && xs deploy -f dataArt.$projectName.$releaseNumber.mtar"
docker run -v c:\octopus\work\dataArt.$projectName.$releaseNumber:/data artifactory.azure.dsb.dk/docker/xsa_cli_deploy /bin/sh -c "xs login -u $XSAuser -p $XSAPW -a $XSAurl -o orgname -s $XSAspace && xs mta $projectName > $($project)-serviceName.txt"


write-host "*******************************************************************"
write-host " STOP postdeploy.ps1"
write-host "*******************************************************************"