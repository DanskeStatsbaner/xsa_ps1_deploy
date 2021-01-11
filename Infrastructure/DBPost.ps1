$environment = $OctopusParameters["Octopus.Environment.Name"]

# exit hvis miljø er forskellig fra Produktion (prd)
if($environment -ne "prd") { Exit }

write-host "*******************************************************************"
write-host " START DBPrep.ps1"
write-host "*******************************************************************"

$DBpw = $args[0]
$DBuser = $OctopusParameters["dataART.DBUser[$environment]"]

$workdirPath = $(pwd)
$projectName = $OctopusParameters["Octopus.Project.Name"]
$releaseNumber = $OctopusParameters["Octopus.Release.Number"]

$XSAurl = $OctopusParameters["dataART.XSAUrl[$environment]"]
$XSAuser = $OctopusParameters["dataART.XSAUser[$environment]"]
$XSAspace = $OctopusParameters["dataART.XSASpace[$environment]"]

$HANAHost = $OctopusParameters["dataART.Host[$environment]"]
$HANAInstance = $OctopusParameters["dataART.Instance[$environment]"]
$HANADatabase = $OctopusParameters["dataART.Database[$environment]"]

$allLines = 'CALL "SYSTEM"."REVOKE_REMOTE_SOURCE_ACCESS"(EX_MESSAGE => ?);'

Set-Content -Path c:\octopus\work\testSQLoneLine.txt -Value $allLines

write-host "*** Run DB prepare SQL"

docker run -v c:\octopus\work:/data artifactory.azure.dsb.dk/docker/xsa_cli_deploy /bin/sh -c "hdbsql -n $HANAHost -i $HANAInstance -d $HANADatabase -u $DBuser -p $DBpw -quiet -a -I /data/testSQLoneLine.txt -o /data/testSQLoutput.txt"

write-host "*******************************************************************"
write-host " STOP DBPrep.ps1"
write-host "*******************************************************************"