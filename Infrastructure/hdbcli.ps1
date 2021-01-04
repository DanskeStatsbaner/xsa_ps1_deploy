$environment = $OctopusParameters["Octopus.Environment.Name"]

# exit hvis miljø er Sandbox (sit)
if($environment -eq "sit") { Exit }

write-host "*******************************************************************"
write-host " START hdbcli.ps1"
write-host "*******************************************************************"
$XSAPW = $args[0]

$workdirPath = $(pwd)
$projectName = $OctopusParameters["Octopus.Project.Name"]
$releaseNumber = $OctopusParameters["Octopus.Release.Number"]

$XSAurl = $OctopusParameters["dataART.XSAUrl[$environment]"]
$XSAuser = $OctopusParameters["dataART.XSAUser[$environment]"]
$XSAspace = $OctopusParameters["dataART.XSASpace[$environment]"]

# kopier mtar filen (f.eks. dataART.CITest.1.0.0.113.mtar) til et bestemt bibliotek c:\octopus\work

#docker cp $workdirPath\FIL_DER_SKAL_KØRES xsa_hdbcli:/root/FIL_DER_SKAL_KØRES
docker container diff xsa_hdbcli
docker cp xsa_hdbcli:/root/. c:\octopus\work

# Her sker det: 
# -v = run container og mount det eksterne bibliotek som /data
# /bin/sh -c  = kør shell i container:
#    cp = kopier mtar fra mount til root
#    ls -la = vis hvad der ligger i root
#    login hana
#    deploy hana

#docker run -v c:\octopus\work:/data artifactory.azure.dsb.dk/docker/xsa_hdbcli /bin/sh -c "cp /data/FIL_DER_SKAL_KØRES . && ls -la && xs login -u $XSAuser -p $XSAPW -a $XSAurl -o orgname -s $XSAspace && xs deploy -f dataArt.$projectName.$releaseNumber.mtar"

write-host "*******************************************************************"
write-host " STOP hdbcli.ps1"
write-host "*******************************************************************"