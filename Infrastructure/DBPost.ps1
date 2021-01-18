$environment = $OctopusParameters["Octopus.Environment.Name"]

# exit if environment is not production (prd)
if($environment -ne "prd") { Exit }

write-host "*******************************************************************"
write-host " START DBPost.ps1"
write-host "*******************************************************************"

###############################################################################
# Get all relevant parameters from octopus (variable set dataART)
###############################################################################

$DBpw = $args[0]
$DBuser = $OctopusParameters["dataART.DBUser"]

$workdirPath = $(pwd)
$projectName = $OctopusParameters["Octopus.Project.Name"]
$releaseNumber = $OctopusParameters["Octopus.Release.Number"]

$XSAurl = $OctopusParameters["dataART.XSAUrl"]
$XSAuser = $OctopusParameters["dataART.XSAUser"]
$XSAspace = $OctopusParameters["dataART.XSASpace"]

$HANAHost = $OctopusParameters["dataART.Host"]
$HANAInstance = $OctopusParameters["dataART.Instance"]
$HANADatabase = $OctopusParameters["dataART.Database"]

###############################################################################
# Execute post SQL
###############################################################################

$allLines = 'CALL "SYSTEM"."REVOKE_REMOTE_SOURCE_ACCESS"(EX_MESSAGE => ?);'

if (Test-Path c:\octopus\work\$($projectName)-SQLoutput.txt) { Remove-Item c:\octopus\work\$($projectName)-SQLoutput.txt }
if (Test-Path c:\octopus\work\$($projectName)-SQLoneLine.txt) { Remove-Item c:\octopus\work\$($projectName)-SQLoneLine.txt }
Set-Content c:\octopus\work\$($projectName)-SQLoneLine.txt -value $allLines 

write-host "*** Run DB post SQL"

docker run -v c:\octopus\work:/data artifactory.azure.dsb.dk/docker/xsa_cli_deploy /bin/sh -c "hdbsql -n $HANAHost -i $HANAInstance -d $HANADatabase -u $DBuser -p $DBpw -quiet -a -I /data/$($projectName)-SQLoneLine.txt -o /data/$($projectName)-SQLoutput.txt"

###############################################################################
# Cleanup - delete files
###############################################################################

if (Test-Path c:\octopus\work\$($projectName)-SQLoneLine.txt) { Remove-Item c:\octopus\work\$($projectName)-SQLoutput.txt }
if (Test-Path c:\octopus\work\$($projectName)-SQLoneLine.txt) { Remove-Item c:\octopus\work\$($projectName)-SQLoneLine.txt }

write-host "*******************************************************************"
write-host " STOP DBPost.ps1"
write-host "*******************************************************************"