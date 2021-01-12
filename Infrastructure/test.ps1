$environment = $OctopusParameters["Octopus.Environment.Name"]

# exit hvis miljø er Sandbox (sit)
if($environment -eq "sit") { Exit }

write-host "*******************************************************************"
write-host " START testdeploy.ps1"
write-host "*******************************************************************"
$XSAPW = $args[0]

$workdirPath = $(pwd)
$projectName = $OctopusParameters["Octopus.Project.Name"]
$releaseNumber = $OctopusParameters["Octopus.Release.Number"]

$XSAurl = $OctopusParameters["dataART.XSAUrl"]
$XSAuser = $OctopusParameters["dataART.XSAUser"]
$XSAspace = $OctopusParameters["dataART.XSASpace"]

write-host "*******************************************************************"
write-host " STOP test.ps1"
write-host "*******************************************************************"