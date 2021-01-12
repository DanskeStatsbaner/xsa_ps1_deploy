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

$XSAurl = $OctopusParameters["dataART.XSAUrl"]
$XSAuser = $OctopusParameters["dataART.XSAUser"]
$XSAspace = $OctopusParameters["dataART.XSASpace"]

$HANAHost = $OctopusParameters["dataART.Host"]
$HANAInstance = $OctopusParameters["dataART.Instance"]
$HANADatabase = $OctopusParameters["dataART.Database"]

write-host "*** Get MTA information for $projectName"

docker run -v c:\octopus\work:/data artifactory.azure.dsb.dk/docker/xsa_cli_deploy /bin/sh -c "xs login -u $XSAuser -p $XSAPW -a $XSAurl -o orgname -s $XSAspace && xs mta $projectName > /data/$($projectName)-serviceName.txt"

$File = Get-Content c:\octopus\work\$($projectName)-serviceName.txt

foreach ($line in $File)
{
    $Arr = $line -split ' '
    foreach ($cell in $Arr)
    {
        if ($cell -eq 'hdi-shared'){$serviceName = $Arr[0]}
    }
}

$serviceKey = $($serviceName) + "-sk"

write-host "*** Setup servicekey $serviceKey"

docker run -v c:\octopus\work:/data artifactory.azure.dsb.dk/docker/xsa_cli_deploy /bin/sh -c "xs login -u $XSAuser -p $XSAPW -a $XSAurl -o orgname -s $XSAspace && xs create-service-key $serviceName $serviceKey && xs service-key $serviceName $serviceKey > /data/$($projectName)-serviceKey.txt"

$File = Get-Content c:\octopus\work\$($projectName)-serviceKey.txt

foreach ($line in $File)
{
    $Arr = $line -split ' '
    foreach ($cell in $Arr)
    {
        if ($cell -eq '"user"')
        {
            $userArr = $Arr[4] -split '"'
        }
        if ($cell -eq '"password"')
        {
            $passwordArr = $Arr[4] -split '"'
        }
    }
}


$DBuser = $userArr[1]
$DBpw = $passwordArr[1]

$File = Get-Content c:\octopus\work\testSQL.txt

$allLines = [string]::join(" ",($File.Split("`n")))
$allLines = [string]::join(" ",($allLines.Split("`r")))

Set-Content -Path c:\octopus\work\testSQLoneLine.txt -Value $allLines

write-host "*** Run post-deployment SQL"

docker run -v c:\octopus\work:/data artifactory.azure.dsb.dk/docker/xsa_cli_deploy /bin/sh -c "hdbsql -n $HANAHost -i $HANAInstance -d $HANADatabase -u $DBuser -p $DBpw -quiet -a -I /data/testSQLoneLine.txt -o /data/testSQLoutput.txt"

write-host "*** Cleanup - delete servicekey"

docker run -v c:\octopus\work:/data artifactory.azure.dsb.dk/docker/xsa_cli_deploy /bin/sh -c "xs login -u $XSAuser -p $XSAPW -a $XSAurl -o orgname -s $XSAspace && xs delete-service-key $serviceName $serviceKey -f"

write-host "*******************************************************************"
write-host " STOP postdeploy.ps1"
write-host "*******************************************************************"