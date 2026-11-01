ecs_cluster
===========

Creates an ECS Cluster to launch services into

> **Note**: This is designed to be used in conjunction with the `ecs_service` module, where the `ecs_service` module utilize resources created within this module.


# Resources
The following resources are created:

* ECS Cluster
* AWS Launch Configuration and Autoscaling Group for Cluster Resources
* Application Load Balancer
* Application Load Balancer Listener
* IAM Profile & Role
* Security Group for the Load Balancer (Configurable ingress)
* Security Group for the Cluster Instances (Only allows traffic from the Load Balancer)
* Cloudwatch Log Group for Cluster Logs
* Autoscaling Notifications (Optional)
* Cloudwatch Alarms (Configurable, Optional)
* Autoscaling Policies, if Alarms are Created



# Variables
The following of variables are used:

* **name**: The name of the cluster
* **vpc_id**: The ID of the VPC to launch into
* **ssm_document**: The SSM Document name to use for auto-domain join
* **key_name**: The keypair to use
* **image_id**: The AMI ID to use
* **instance_type**: The instance type to launch
* **ebs_optimized**: EBS optimized instances? (true|false)
* **volume_size**: Size of the root ebs volume
* **default_cooldown**: Minimum time between scaling events
* **lb_ingress_cidr**: List of CIDR blocks to allow ingress to the load balancer
* **subnet_ids**: List of subnets to launch cluster instances into
* **lb_internal** (Default: true): Create an internal load balancer? (true|false)
* **lb_listener_port** (Default: 80): The listener port for the default listener
* **lb_listener_proto** (Default: http): The default listener protocol (http|https)
* **lb_certificate_arn** (Optional): Specify the certificate ARN, if using HTTPS protocol
* **scale_in_adjustment** (Default: 1): The number of instances to scale-in by per scale-in event
* **scale_out_adjustment** (Default: 1): The number of instances to scale-out by per scale-out event
* **autoscale_notification_ng_topic_arn** (Optional): Provide an SNS Topic ARN if you wish to recieve failed cluster event notifications
* **autoscale_notificatiion_ok_topic_arn** (Optional): Provide an SNS Topic ARN if you wish to receive success cluster event notificiatoins
* **log_retention** (Default: 30): Number of days to keep logs
* **autoscale_cooldown** (Default: 300): Minimun time between scaling events
* **runtime_tag** (Default: off=(M-F,21);on=(M-F,7);tz=est): Value to configure the !RuntimeASG tag with 
* **tags**: Map of k-v pairs to tag resources with
* **asg_tags**: List of maps used for tagging Autoscaling group resources



# Outputs
The following values are output: 

* **cluster_id**: The ID of the created ECS Cluster
* **cluster_sg_id**: The ID of the created ECS Cluster Security Group
* **lb_id**: The ID of the created ALB
* **lb_listener_id**: The ID of the default listener for the ALB
* **lb_sg_id**: The ID of the created ALB Security Group
