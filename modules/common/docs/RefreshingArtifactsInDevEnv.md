# How to Refresh CorePlatform Artifacts in the Dev Env

## Introduction
The ec2_asg userdata.ps1 has a method for refreshing the CorePlatform artifacts on an existing AMI when the EC2 instance is being launched. This technique can be used to save time by not having to run the CorePlatform build and AMI pipelines to deploy new code.

This method has only been configured for the ec2_asg instances and then only for the Windows service server in the Terraform scripts. If you need to use this method for a different server type, use the Windows service server as an example. Note, the winsvc_policy_document has the permissions needed for the EC2 instance to retrieve files from S3.

## The Typical Deployment Method
The normal way of getting code out to the dev env using the ADO build pipelines:

- From the ADO "Package" folder, run the "CoreService Build - MJ" pipeline.
- Then from the "CoreService AWS" folder, run the "CoreService Build - MJ - AWS phase" piepline.
- If you are building the Major branch, the AMI builds will automatically run for the IIS servers and the Windows Service server. If you are building a private branch you will need to run these manually.
- When all AMIs are complete, you can run the "Full-Stop Deploy CoreService - Major to AWS-DEV" release. If you don't need the Database Update to run, skip this step and simply run the appropriate Terraform pipeline to deploy the instance you're working on.

## The Optimized Deployment Method
This method skips the lengthy pipeline runs, AMI builds, and release process and instead allows you to deploy to a launching EC2 instance directly from an CorePlatform artifact zip file that has been uploaded to S3.

Build CorePlatform on your laptop to simulate the "CoreService Build - MJ" pipeline. From C:\Devel\CoreService folder, run this in PowerShell:

```
$msBuildPath = .\FindMSBuild.ps1
& "${msBuildPath}MSBUILD.exe" .\MJ_DeleteWorkFolder.proj
& "${msBuildPath}MSBUILD.exe" .\CreateVersionFile.proj
& "${msBuildPath}MSBUILD.exe" .\MJ_BuildTransforms.proj
& "${msBuildPath}MSBUILD.exe" .\MJ_BuildCorePlatform.proj
& "${msBuildPath}MSBUILD.exe" .\MJ_BuildDataUpdate.proj
```

This will generate CorePlatform artifact files in the following folders:

- C:\Devel\CoreService\Work\Debug\DataArtifacts - for the db update
- C:\Devel\CoreService\Work\Debug\EncArtifacts - the CorePlatform binaries
- C:\Devel\CoreService\Work\Debug\Artifacts - miscellaneous binaries

The EC2 instance you're working on will have a subset of these zip files stored in the C:\temp folder and deployed to the C:\CoreService folder.

Upload the entire zip file for the server you're working on to the S3 bucket "coreplatform-artifacts-dev" in the EC2Launch folder. For example, I was working on the Windows Service server so I uploaded "CoreService.WinServices.21.2.2-MS-4896520190619.00401.zip" to S3. This upload could take 5 minutes. This step is unnecesary if the artifacts on the EC2 instance are already up-to-date, i.e., no major changes are needed from your private branch.

Note: the original file name had "QA" after the version number but I replaced that with my private branch label "MS-48965". This naming convention is important to segregate developer's code.

You can upload multiple files to this bucket and they will be unzipped to your EC2 Instance in alphabetical order by the S3 object name. For example, I wanted to debug the startup.ps1 script so I created another zip file named "CoreService.WinServices.21.2.2-MS-4896520190619.00402-update1.zip" containing just the startup.ps1 file. When the EC2 instance launces it will unzip this file after the first one, in effect patching the server.

To deploy these artifacts from the S3 bucket, from the ADO "enc-infra-devops" folder run the "coreplatform-fi-infrastructure-FINSERV_DEV" pipeline specifying your private build in the branch variable.

Terminate the running EC2 instance and wait until the ASG launches a new instance. Watch the CloudWatch log group UserData for your instance's computer name and confirm in the log that the instance has successfully loaded your artifacts from S3.

When you are done, delete the files from S3.


