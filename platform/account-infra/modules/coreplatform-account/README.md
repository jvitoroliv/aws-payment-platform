coreplatform-account
=================

Encapsulates all resources required for standing up an AWS account for the CoreService project.


# Resources

* Route53 Zone for the managed domain
* Route53 Resolvers for DNS forwarding
* Managed Directory Services
* DB Tools Instance
* AD Tools Instance
* Core Account IAM Roles
* CIFS Instance
* Auto-Join Policies, Profiles, and Docs
* Security Groups and IAM Policies for the associated resources above


# Variables

* **region**: The region to deploy in
* **vpc_id**: The ID of the VPC to deploy in
* **environment**: The environment name (i.e. dev, uat, prod)
* **dns_domain**: The domain name for the Route53 zone
* **key_name**: The keypair to be used when launching instances
* **dbtools_instance_type** (Default: r5a.xlarge): The instance type to use for the DB Tools instance
* **dbtools_runtime_tag** (Default: off=(M-F,21);on=(M-F,7);tz=est): The value to configure for the dbtools instance !Runtme tag 
* **dbtools_volume_size** (Default: 100): The size (in GB) to provision for the DB Tools root volume
* **adtools_instance_type** (Default: r5a.large): The instance type to use for the AD Tools instance
* **adtools_runtime_tag** (Default: off=(M-F,21);on=(M-F,7);tz=est): The value to configure for the adtools instance !Runtme tag 
* **adtools_volume_size** (Default: 100): The size (in GB) to provision for the AD Tools root volume
* **cifs_rdp_allow**: A lisr of CIDR blocks to allow RDP access from to the CIFS instance
* **cifs_root_vol** (Default: 100): The size (in GB) of the CIFS Root volume
* **cifs_additional_vol** (Default: 200): The size (in GB) of the addition EBS volume on the CIFS instance
* **cifs_instance_type** (Default: t3.medium): The instance type to use for the CIFS instance
* **cifs_shares**: A map of directories and permissions to share (see _cifs_instance_ module)
* **cifs_runtime_tag** (Default: off=(M-F,21);on=(M-F,7);tz=est): The value to configure for the CIFS instance !Runtme tag 
* **ad_directory_name**: The name of the ad domain
* **ad_directory_password**: The admin password to set when creating the directory
* **ad_directory_edition** (Default: Standard): The edition of managed directory services to use (Standard or Enterprise)
* **ad_directory_type** (Default: MicrosoftAD): The type of directory service to create
* **tag_billingid** (Default: coreplatform): The value to use for the billing tag
* **tag_compliance** (Default: PCI-CDE): The value to use for the compliance tag
* **tag_dataclass** (Default: Confiidential): The value to use for the dataclass tag
* **tag_drtier** (Default: 3): The value to use for the drtier tag
* **tag_lob** (Default: Payment Processing): The value to use for the lob tag
* **tag_owner** (Default: user@example-company.com): The value to use for the owner tag
* **tag_projectname** (Default: coreplatform): The value to use for the projectname tag


# Outputs

* **ad_access_url**: The AD Access URL
* **ad_dns_ip_addresses**: The IP Addresses for the AD Domain controllers
