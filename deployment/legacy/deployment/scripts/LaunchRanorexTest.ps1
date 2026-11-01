$Submitter = "TFS"
$RanorexURL = "http://localhost:9000/Submit/"

write-host "Launching Ranorex test for $env:envshortname - $env:fi -- $env:Release_ReleaseName"

try {
	$page = (new-object net.webclient).DownloadString("${RanorexURL}?Environment=${env:envshortname}&Customer=${env:fi}&TestName=HighLevel&Submitter=${Submitter}&ReleaseNumber=${env:Release_ReleaseName}")
}
catch {
    $errmsg = $_.Exception.Message
    write-warning "Error Launching Ranorex test: $errmsg"
    exit 0
}
