sql_cluster_s2d
================
Creates the SQL Server cluster including automation to install the WSFC & SQL Server.


# Resources
This module creates the following:

- 3 EC2 instances with userdata bootstrapping for joining the Active Directory domain 
    & kicking off the SSM automation jobs.
- A security group for the instances.
- A role, policy, and instance profile for the instances.
- EBS volumes attached to the instances. Used primarily for Storage Spaces Direct (S2D) pools.
- SSM Automation documents for installing and basic configuration of Windows Server Failover Cluster (WSFC) and SQL Server. The SSM automation documents mainly run PowerShell & PowerShell DSC scripts.
- An SNS topic to send SSM automation step failures to. Note that subscriptions must be added to the SNS topic for the alerts to to 'go anywhere'.
- An S3 bucket for storing the PS scripts.


# Variables

* **automation_scripts_bucket**: Name of the S3 Bucket used to store the automation scripts
* **ami**: AMI used for the instances
* **instance_type**: Size & type of the EC2 instances.
* **root_vol_size**: size of the root volume of the EC2 instances.
* **key_name**: Key pair used for decrypting the instances' administrator password.
* **svr_name_prefix**: a naming prefix used for the servers.
* **name_format**: Instances' Name tag. This string is formatted with the # of server.
* **hostname_format**: Instances' hostname as well as its 'Hostname' tag. This string is formatted with the # of server.
* **subnet_ids**: List of subnets to deploy the instances into.
* **tags**: AWS tags to apply to resources.
* **join_domain_ssm_document**: SSM document used to join Active Directory domain.
* **ad_admin_user**: Active Directory admin username. 
* **ad_password_secrets_arn**: Secrets Manager ARN that contains the AD admin password.
* **sql_svcacct_creds_secrets_arn"**: Secrets Manager ARN that contains the SQL service account username & password.
* **sql_login_creds_secrets_arn"**: Secrets Manager ARN that contains the SQL login username & password.
* **netbios_domain_name**: The NetBIOS name of the AD domain. E.g.: DEV, QA, etc.
* **domain_dns_name**: The AD's DNS name. E.g.: dev.ad.example.com
* **enc_fi**: The FI name. E.g.: FINSERV, SAMPLE_FI, etc.
* **num_of_secondary_nodes**: How many secondary nodes to create in addition to the primary node. NOTE: see additional info below.
* **default_pool_ebs_vols_size**: Size of the EBS volumes for the Default Pool.
* **fci_pool_ebs_vols_size**: Size of the EBS volumes for the FCI Pool.
* **coreplatform_pool_ebs_vols_size**: Size of the EBS volumes for the CorePlatform Pool.
* **archive_pool_ebs_vols_size**: Size of the EBS volumes for the Archive Pool.
* **backup_pool_ebs_vols_size**: Size of the EBS volumes for the Backup Pool.
* **sql_server_iso_bucket**: The S3 bucket containing the ISO for the SQL Server installer.
* **runtime_tag** Sets the !Runtime tag used by Cloud Custodian.

# Outputs

* **sql_cluster_primary_instance_id**: Instance ID of the primary node.
* **sql_cluster_secondary_instance_ids**: Instance IDs of the secondary nodes.

# Details

At an infrastructure level, Terraform is used to create the various AWS resources listed above. Terraform is also used to upload PowerShell scripts to an S3 bucket. These scripts are referenced in SSM automation documents. 

The SSM automation documents are run on the instances the first time they are instantiated. This is kicked off in the `userdata` script. The SSM automation documents are *not* run automatically after this. The SQL Server cluster is treated with more care than other resources and as such, updates must be carefully applied.

The SSM automation documents consist of a number of ordered steps, most of which execute a PowerShell script. Most of the PowerShell (PS) scripts employ DSC (Desired State Configuration), a subset of PowerShell that performs configuration management, i.e. declarative vs procedural code.

*Note:* When executing the Terraform to initially stand up the cluster, all 3 nodes must be launched simultaneously. There are cluster, S2D and SQL Server installation/configurations that require all 3 ndoes to be present.

Where possible, existing established DSC modules were used vs writing custom `Script` resources. At the time of development this module, both the `xFailOverCluster` and `SqlServerDsc` modules were lacking certain features or had bugs that required additional custom code.

The SSM automation logs to CloudWatch Log Groups named after the instances. Generally, most of the logs needed to troubleshoot an issue can be found in these logs. However, sometimes it's necessary to cancel the automation, RDP into the server and review the Event Viewer logs in _Applications and Services Logs/Microsoft/Windows/Desired State Configuration_.

If SSM automation determines that a step has failed, it will branch to the end of the document where there is a step that publishes to an SNS topic. Note that subscriptions must be added to the SNS topic for the alerts to to 'go anywhere'.

Note that some errors & failures in PowerShell may not be non-terminating and not result in the SSM step failing.

SQL Server installation is performed on the primary node with the main _Action_ parameter set to "InstallFailoverCluster". On the secondary nodes, the _Action_ parameter is "AddNode".

[As of Oct 2019] Although there is a variable for # of secondary nodes, it's currently decorative as the PS code is built around there being 3 nodes. Fully variablized PS/DSC code was too complex to introduce into the development prior to all other functionality being completed.

[As of Oct 2019] *Note:* The _SQLServerDSC_ module has a limitation that prevents the _SQLInstall_ step from executing cleanly on the Primary node. It reports a few conditions incorrectly and forces a reboot, which then loops. The similar step on the Secondary nodes works properly. 

## Rebuilding a Cluster

When destroying and rebuilding a cluster (i.e. re-deploying), the following items must be cleaned up (deleted) first:
* Terminate the EC2 instances.
* For good measure, delete the EBS volumes. Use the search term "sql" for each combination of FI+environment, there should be 30 volumes that accompany the instances (as of the time of writing of this doc).
* In Active Directory Users & Computers, delete the computer objects of the instances (e.g. AUE1SqlSvrW003D), the Cluster (e.g. FinservDevCluster), and the SQL Server network name (e.g. FinservDevSQLServer)
* In DNS, delete the entries for those computers/objects as well.
* Optional, but not usually necessary: delete the SSM docs associated with the instances (e.g.: FinservDEVCluster-ssm-*-server-config*)
* Optional, but not usually necessary: delete the ENIs associated with the instances (search for ‘sql’)

In order to catch unexpected errors/omissions early, it's a good idea to follow along with deployments:
* Login to the AWS console, and follow along with: instances, EBS volumes, SSM automation, and CloudWatch logs.
* Once the primary node gets to at least the PrimaryConfig step, you can RDP in and launch the Failover Cluster admin GUI.
* Once the SQL Server steps are done, you should also be able to verify that the various SQL Server tools are installed. You can launch SQL Config Mgr to view services’ status, etc.

## Potential Improvements

* Storage Spaces Direct pools can not be created without at least 3 disks. As configured, each pool has 6 disks (2 on each server). However, if by chance, both secondary nodes are not up and have their disks (EBS volumes) attached, then pool creation will fail. While this is an unlikely event due to the number of steps the primary node needs to run before setting up the pools, ideally, there should be a dependency and/or wait condition.

* Write/devise a workaround the limitation of the _SQLServerDSC_ module where it fails on the primary node.

* [Consider/Decide] Use Chocolatey vs DSC to install SSMS (SQL Server Management Studio). SSMS is currently shipped as an `.exe` which the DSC `Package` resource does not handle very well.

* [Consider] If using SSM automation to install SSMS, then restructure the SQL installation on the secondary nodes to also run the _DownloadSQL_ step and install SQL Server off of the local copy (vs the shared one on the primary node).

* [Idea] Use SSM's `aws:executeAutomation` and `aws:waitForAwsResourceProperty` Actions to create a more ordered flow amongst the various steps and nodes. For example, the `aws:executeAutomation` step could be inserted into the SSM automation of the secondary nodes to execute the primary node's automation, or the `aws:waitForAwsResourceProperty` action could be used in the primary node's automation to wait for the secondary instances to come online. 
   Ref: https://docs.aws.amazon.com/systems-manager/latest/userguide/automation-actions.html
