cifs_instance
=============
Creates a simple instance with CIFS shared directories

# Resources


# Variables

* **dependencies**: List of module dependencies
* **name**: The name of the instance
* **hostname**: The hostname to give the computer object in AD
* **vpc_id**: The ID of the VPC the instance is launched in
* **sg_allowed_cidr**: List of CIDR blocks to allow access from
* **ami**: The AMI to launch the instance with
* **instance_type**: The type of instance to launch as the CIFS instance
* **key_name**: The name of the keypair to use
* **subnet_id**: The ID of the subnet to launch the instance into
* **iam_instance_profile**: The name of the instance profile to assign to the instance
* **instance_root_vol**: The size (in GB) of the root EBS volume
* **instance_additional_vol**: This size (in GB) of the additional EBS volume
* **tags**: a map of k-v pairs to assign as tags to resources
* **ssm_document**: the name of the ssm document to assign for auto-joining the domain
* **shares**: Key-Value pairs of Share Locations to Permissions (i.e. 'Share-Directory' = 'domain\\Domain Users')
* **runtime_tag** (Default: off=(M-F,21);on=(M-F,7);tz=est): Sets the !Runtime tag


# Outputs

* **instance_sg_name**: The name of the created security group
* **instance_id**: The identifier of the created instance
* **depended_on**: Output dependencies
