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

$HANAHost = $OctopusParameters["dataART.Host[$environment]"]
$HANAInstance = $OctopusParameters["dataART.Instance[$environment]"]
$HANADatabase = $OctopusParameters["dataART.Database[$environment]"]

docker run -v c:\octopus\work:/data artifactory.azure.dsb.dk/docker/xsa_cli_deploy /bin/sh -c "xs login -u $XSAuser -p $XSAPW -a $XSAurl -o orgname -s $XSAspace && xs mta $projectName > /data/$($project)-serviceName.txt"

$File = Get-Content c:\octopus\work\$($project)-serviceName.txt

Write-Host "File: $File"

foreach ($line in $File)
{
    $Arr = $line -split ' '
    foreach ($cell in $Arr)
    {
        if ($cell -eq 'hdi-shared'){$serviceName = $Arr[0]}
    }
}

$serviceKey = $($serviceName) + "-sk"

Write-Host "Service key: $serviceKey"

write-host "*******************************************************************"
write-host " STOP postdeploy.ps1"
write-host "*******************************************************************"