coreplatform-fsx
=================

Encapsulates all resources required for standing up the FSx file system for an environment.

# Post FSx Deployment

The following steps need to be completed manually after the FSx has been created:

* This Terraform script automatically adds an alias to the coreplatformxxx.ue1.finservglobal.example.com Route 53 private hosted zone to represent the FSx for this environment, where xxx is the environment = dev, qa. This alias will be called "shrd-files" and will point to a placeholder IP address 1.2.3.4. Find the FSx IP address in the AWS console and update this alias to point to the real FSx IP address. Using the IP address here is a workaround, see the long-term solution below.

* Remote desktop in to an CorePlatform EC2 instance using your secure\x account and run the filesystem.ps1 found in the FI repository to create the file system for each FI. Run as "filesystem.ps1 FINSERV dev" and "filesystem.ps1 Finservcorp dev".

* From this same EC2 instance, enter the UNC path: \\shrd-files.coreplatformdev.ue1.finservglobal.example.com\share and apply the following groups with full control permission. Add PERM-D-FSx-CorePlatform_xxx_FINSERV group to shares\FINSERV folder where xxx is the environment = Dev, QA. Add PERM-D-FSx-CorePlatform_xxx_FINSERVcorp group to shares\Finservcorp folder. Add both groups to shares\FTP folder.

## Long-Term FSx/Route 53 Plan

* Request the End User Computing (EUC) or Infoblox group manually add the FSx to the secure.finservglobal.example.com Active Directory DNS. The FSx is successfully added to the AD but is not included in the DNS (no explanation for this at this time). This will need to be done each time the FSx is created.

* Implement a proper subdomain of the secure.finservglobal.example.com, i.e., cpdev.secure.finservglobal.example.com as mentioned in PBI 32532. This will need to be done for every CorePlatform AWS environment. Once this has been implemented, this Terraform script can be updated to write the FSx DNS name into the Route 53 private hosted zone alias shrd-files instead of an IP address.
