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
$workdirPath = $workdirPath.Substring(0, $workdirPath.IndexOf("\Deployment"))

$projectName = $OctopusParameters["Octopus.Project.Name"]
$releaseNumber = $OctopusParameters["Octopus.Release.Number"]
$containerName = "dataArt.$($projectName).$($releaseNumber).$($environment)"

$XSAurl = $OctopusParameters["dataART.XSAUrl"]
$XSAuser = $OctopusParameters["dataART.XSAUser"]
$XSAspace = $OctopusParameters["dataART.XSASpace"]

###############################################################################
# Copy project mtar file to work directory - c:\octopus\work\
###############################################################################

if (Test-Path c:\Octopus\Work\$($containerName).mtar) { Remove-Item c:\Octopus\Work\$($containerName).mtar }
Copy-Item "$workdirPath\dataArt.$projectName.$releaseNumber.mtar" -Destination "C:\octopus\work\$containerName.mtar" -Force

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

docker exec -it $containerName /bin/sh -c "cp /data/$containerName.mtar . && xs login -u $XSAuser -p $XSAPW -a $XSAurl -o orgname -s $XSAspace && xs deploy -f $containerName.mtar>C:\octopus\work\$containerName.log"
$FileContent = Get-Content "C:\octopus\work\$containerName.log"
$Matches = Select-String -InputObject $FileContent -Pattern "xs dmol -i" 
$Start=$Matches.Line.IndexOf("xs dmol -i")
if (-Not $Start.Equals(-1))
{
echo $Start
$Lognr=$Matches.Line.Substring($Start+11,6)
echo $Lognr
}
else
{echo "Deploy OK"}
write-host "*******************************************************************"
write-host " STOP deploy.ps1"
write-host "*******************************************************************"