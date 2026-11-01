# Auth Header for dispatch request
$headers = @{
  Authorization = "Bearer ${env:MappedGithubPat}"
}

# Body Request for dispatch request
$ref = "${env:Build_SourceBranch}" -replace "refs/heads/", ""
$body = @{
  "ref" = $ref
  "inputs" = @{
    "envShortname" = "${env:EnvShortname}"
    "releaseSha" = "${env:Build_SourceVersion}"
  }
} | ConvertTo-Json

# Get a list of workflows to get the workflow id for the dispatch request
$uri = "https://api.github.com/repos/example-org/CoreService/actions/workflows"
$response = Invoke-RestMethod -Method 'Get' -Headers $headers -Uri $uri

foreach($workflow in $response.workflows) {
  if($workflow.name -eq "release-tag") {
    $id = $workflow.id
  }
}

$uriDispatch = "https://api.github.com/repos/example-org/CoreService/actions/workflows/$id/dispatches"
$response = Invoke-RestMethod -Method 'Post' -Headers $headers -Body $body -Uri $uriDispatch
