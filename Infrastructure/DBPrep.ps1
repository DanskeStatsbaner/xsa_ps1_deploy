$environment = $OctopusParameters["Octopus.Environment.Name"]

# exit if environment is not production (prd)
if($environment -ne "prd") { Exit }

write-host "*******************************************************************"
write-host " START DBPrep.ps1"
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
# Execute prepare SQL
###############################################################################

write-host "*** Run DB prepare SQL"

$allLines = 'CALL "SYSTEM"."GRANT_REMOTE_SOURCE_ACCESS"(EX_MESSAGE => ?);'

if (Test-Path c:\Octopus\Work\$($projectName)-SQLoutput.txt) { Remove-Item c:\Octopus\Work\$($projectName)-SQLoutput.txt }
if (Test-Path c:\Octopus\Work\$($projectName)-SQLoneLine.txt) { Remove-Item c:\Octopus\Work\$($projectName)-SQLoneLine.txt }
Set-Content c:\Octopus\Work\$($projectName)-SQLoneLine.txt -value $allLines 

docker exec -it $containerName /bin/sh -c "hdbsql -n $HANAHost -i $HANAInstance -d $HANADatabase -u $DBuser -p $DBpw -quiet -a -I /data/$($projectName)-SQLoneLine.txt -O /data/$($projectName)-SQLoutput.txt"

###############################################################################
# Cleanup - delete files
###############################################################################

if (Test-Path c:\octopus\work\$($projectName)-SQLoneLine.txt) { Remove-Item c:\octopus\work\$($projectName)-SQLoutput.txt }
if (Test-Path c:\octopus\work\$($projectName)-SQLoneLine.txt) { Remove-Item c:\octopus\work\$($projectName)-SQLoneLine.txt }

write-host "*******************************************************************"
write-host " STOP DBPrep.ps1"
write-host "*******************************************************************"