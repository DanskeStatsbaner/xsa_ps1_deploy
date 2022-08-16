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
# $workdirPath = $workdirPath.Substring(0, $workdirPath.IndexOf("\Deployment"))

$projectName = $OctopusParameters["Octopus.Project.Name"]
$releaseNumber = $OctopusParameters["Octopus.Release.Number"]
$containerName = "dataArt.$($projectName).$($releaseNumber).$($environment)"

$XSAurl = $OctopusParameters["dataART.XSAUrl"]
$XSAuser = $OctopusParameters["dataART.XSAUser"]
$XSAspace = $OctopusParameters["dataART.XSASpace"]

$OctopusWorkDir = $OctopusParameters["dataART.OctopusWorkDir"]

###############################################################################
# Copy project mtar file to work directory - $($OctopusWorkDir)\
###############################################################################
$fullPath = "$($workdirPath)"
$files = get-childitem "$fullPath" -include *.* -Recurse
foreach($file in $files) 
{
    write-host "sourceDirPath : " $file.FullName
}

$projectNameLower = $projectName.ToLower()
$sourceDirPath = "$($workdirPath)/dataART.$projectNameLower.$releaseNumber.mtar"

write-host "Read from : " $sourceDirPath

$targetDirPath = "$($OctopusWorkDir)/$($containerName).mtar"
if (Test-Path $($targetDirPath)) { Remove-Item $($targetDirPath) }

write-host "Write into : " $targetDirPath

Copy-Item "$($sourceDirPath)" -Destination "$($targetDirPath)" -Force

$fullPath = "$($OctopusWorkDir)"
$files = get-childitem "$fullPath" -include *.* -Recurse
foreach($file in $files) 
{
    write-host "targetdir : " $file.FullName
}

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

docker exec -t $containerName /bin/sh -c "cp /data/$containerName.mtar . && xs login -u $XSAuser -p $XSAPW -a $XSAurl -o orgname -s $XSAspace && xs deploy -f $containerName.mtar > /data/$containerName.log"

# Get the log and put it into the Octopus log
$workdirPath = "$($OctopusWorkDir)/$containerName.log"
$FileContent = Get-Content "$($workdirPath)"

write-host "*******************************************************************"
write-host " Deployment log"
write-host "*******************************************************************"
write-host $FileContent

# Find the log number and create a file with the names of the logs
$Matches = Select-String -InputObject $FileContent -Pattern "xs dmol -i" 
$Start=$Matches.Line.IndexOf("xs dmol -i")
if (-Not $Start.Equals(-1))
{
    $end=$Matches.Line.Substring($Start+12,10).IndexOf("to")
    $logNo=$Matches.Line.Substring($Start+11,$end-1)
}

# Determine if the deploy was as success or a failure
$exitCode = 0
$findErrorStatus = "xs deploy -i " + $logNo + " -a retry"

$Matches = Select-String -InputObject $FileContent -Pattern "$findErrorStatus" 
if ($Matches.LineNumber -gt 0)
{
    $exitCode = 1

    # Download logfiles
    docker exec -it $containerName /bin/sh -c "xs login -u $XSAuser -p $XSAPW -a $XSAurl -o orgname -s $XSAspace && xs dmol -i $logNo"
    $dmolDir = "./mta-op-$logNo"
    docker exec -it $containerName /bin/sh -c "cd $dmolDir . && cat * . "
}

# cleanup

docker exec -t $containerName /bin/sh -c "rm -fv *.log"

$workdirPath = "$($OctopusWorkDir)\$($containerName).txt"
if (Test-Path $($workdirPath)) { Remove-Item $($workdirPath) }


write-host "*******************************************************************"
write-host " STOP deploy.ps1"
write-host "*******************************************************************"

Exit $exitCode