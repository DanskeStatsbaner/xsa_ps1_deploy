$environment = $OctopusParameters["Octopus.Environment.Name"]

# exit hvis miljø er Sandbox (sit)
if($environment -eq "sit") { Exit }

write-host "*******************************************************************"
write-host " START deploy.ps1"
write-host "*******************************************************************"
$XSAPW = $args[0]

$workdirPath = $(pwd)
$projectName = $OctopusParameters["Octopus.Project.Name"]
$releaseNumber = $OctopusParameters["Octopus.Release.Number"]

$XSAurl = $OctopusParameters["dataART.XSAUrl[$environment]"]
$XSAuser = $OctopusParameters["dataART.XSAUser[$environment]"]
$XSAspace = $OctopusParameters["dataART.XSASpace[$environment]"]

# kopier mtar filen (f.eks. dataART.CITest.1.0.0.113.mtar) til et bestemt bibliotek c:\octopus\work

docker cp $workdirPath\dataArt.$projectName.$releaseNumber.mtar xsa_cli_deploy:/root/dataArt.$projectName.$releaseNumber.mtar
docker container diff xsa_cli_deploy
docker cp xsa_cli_deploy:/root/. c:\octopus\work\
# Her sker det: 
# -v = run container og mount det eksterne bibliotek som /data
# /bin/sh -c  = kør shell i container:
#    cp = kopier mtar fra mount til root
#    ls -la = vis hvad der ligger i root
#    login hana
#    deploy hana

docker run -v c:\octopus\work\:/data artifactory.azure.dsb.dk/docker/xsa_cli_deploy /bin/sh -c "cp /data/dataArt.$projectName.$releaseNumber.mtar . && ls -la && xs login -u $XSAuser -p $XSAPW -a $XSAurl -o orgname -s $XSAspace && xs deploy -f dataArt.$projectName.$releaseNumber.mtar"

write-host "*******************************************************************"
write-host " STOP deploy.ps1"
write-host "*******************************************************************"