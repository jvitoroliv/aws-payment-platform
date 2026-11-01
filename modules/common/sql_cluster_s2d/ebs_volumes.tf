
# EBS Volumes
# ---------------------------------------------------------------------

# Default Pool in Cluster Storage Spaces Direct (S2D)
resource "aws_ebs_volume" "primary_default_pool_xvdf" {
  availability_zone = "${aws_instance.primary_server.availability_zone}"
  size              = "${var.default_pool_ebs_vols_size}"
  type              = "${var.default_pool_ebs_vols_type}"
  iops              = "${var.default_pool_ebs_vols_iops}"
  encrypted         = "${var.ebs_kms_key_id == "" ? false : true}"
  kms_key_id        = "${var.ebs_kms_key_id}"

  tags = "${merge(map("Name", format("%s-001-%s", var.svr_name_prefix, "DefaultPool-disk1")), var.tags)}"
}

resource "aws_volume_attachment" "primary_default_pool_xvdf_attach" {
  device_name = "xvdf"
  volume_id   = "${aws_ebs_volume.primary_default_pool_xvdf.id}"
  instance_id = "${aws_instance.primary_server.id}"
}

resource "aws_ebs_volume" "primary_default_pool_xvdg" {
  availability_zone = "${aws_instance.primary_server.availability_zone}"
  size              = "${var.default_pool_ebs_vols_size}"
  type              = "${var.default_pool_ebs_vols_type}"
  iops              = "${var.default_pool_ebs_vols_iops}"
  encrypted         = "${var.ebs_kms_key_id == "" ? false : true}"
  kms_key_id        = "${var.ebs_kms_key_id}"

  tags = "${merge(map("Name", format("%s-001-%s", var.svr_name_prefix, "DefaultPool-disk2")), var.tags)}"
}

resource "aws_volume_attachment" "primary_default_pool_xvdg_attach" {
  device_name = "xvdg"
  volume_id   = "${aws_ebs_volume.primary_default_pool_xvdg.id}"
  instance_id = "${aws_instance.primary_server.id}"
}

resource "aws_ebs_volume" "secondary_default_pool_xvdf" {
  count = "${var.num_of_secondary_nodes}"

  availability_zone = "${element(aws_instance.secondary_server.*.availability_zone, count.index)}"
  size              = "${var.default_pool_ebs_vols_size}"
  type              = "${var.default_pool_ebs_vols_type}"
  iops              = "${var.default_pool_ebs_vols_iops}"
  encrypted         = "${var.ebs_kms_key_id == "" ? false : true}"
  kms_key_id        = "${var.ebs_kms_key_id}"

  tags = "${merge(map("Name", format("%s-%03d-%s", var.svr_name_prefix, count.index + 2, "DefaultPool-disk1")), var.tags)}"
}

resource "aws_volume_attachment" "secondary_default_pool_xvdf_attach" {
  count = "${var.num_of_secondary_nodes}"

  device_name = "xvdf"
  volume_id   = "${element(aws_ebs_volume.secondary_default_pool_xvdf.*.id, count.index)}"
  instance_id = "${element(aws_instance.secondary_server.*.id, count.index)}"
}

resource "aws_ebs_volume" "secondary_default_pool_xvdg" {
  count = "${var.num_of_secondary_nodes}"

  availability_zone = "${element(aws_instance.secondary_server.*.availability_zone, count.index)}"
  size              = "${var.default_pool_ebs_vols_size}"
  type              = "${var.default_pool_ebs_vols_type}"
  iops              = "${var.default_pool_ebs_vols_iops}"
  encrypted         = "${var.ebs_kms_key_id == "" ? false : true}"
  kms_key_id        = "${var.ebs_kms_key_id}"

  tags = "${merge(map("Name", format("%s-%03d-%s", var.svr_name_prefix, count.index + 2, "DefaultPool-disk2")), var.tags)}"
}

resource "aws_volume_attachment" "secondary_default_pool_xvdg_attach" {
  count = "${var.num_of_secondary_nodes}"

  device_name = "xvdg"
  volume_id   = "${element(aws_ebs_volume.secondary_default_pool_xvdg.*.id, count.index)}"
  instance_id = "${element(aws_instance.secondary_server.*.id, count.index)}"
}

#########################################################################
# FCI Pool
resource "aws_ebs_volume" "primary_fci_pool_xvdh" {
  availability_zone = "${aws_instance.primary_server.availability_zone}"
  size              = "${var.fci_pool_ebs_vols_size}"
  type              = "${var.fci_pool_ebs_vols_type}"
  iops              = "${var.fci_pool_ebs_vols_iops}"
  encrypted         = "${var.ebs_kms_key_id == "" ? false : true}"
  kms_key_id        = "${var.ebs_kms_key_id}"

  tags = "${merge(map("Name", format("%s-001-%s", var.svr_name_prefix, "FCIPool-disk1")), var.tags)}"
}

resource "aws_volume_attachment" "primary_fci_pool_xvdh_attach" {
  device_name = "xvdh"
  volume_id   = "${aws_ebs_volume.primary_fci_pool_xvdh.id}"
  instance_id = "${aws_instance.primary_server.id}"
}

resource "aws_ebs_volume" "primary_fci_pool_xvdi" {
  availability_zone = "${aws_instance.primary_server.availability_zone}"
  size              = "${var.fci_pool_ebs_vols_size}"
  type              = "${var.fci_pool_ebs_vols_type}"
  iops              = "${var.fci_pool_ebs_vols_iops}"
  encrypted         = "${var.ebs_kms_key_id == "" ? false : true}"
  kms_key_id        = "${var.ebs_kms_key_id}"

  tags = "${merge(map("Name", format("%s-001-%s", var.svr_name_prefix, "FCIPool-disk2")), var.tags)}"
}

resource "aws_volume_attachment" "primary_fci_pool_xvdi_attach" {
  device_name = "xvdi"
  volume_id   = "${aws_ebs_volume.primary_fci_pool_xvdi.id}"
  instance_id = "${aws_instance.primary_server.id}"
}

resource "aws_ebs_volume" "secondary_fci_pool_xvdh" {
  count = "${var.num_of_secondary_nodes}"

  availability_zone = "${element(aws_instance.secondary_server.*.availability_zone, count.index)}"
  size              = "${var.fci_pool_ebs_vols_size}"
  type              = "${var.fci_pool_ebs_vols_type}"
  iops              = "${var.fci_pool_ebs_vols_iops}"
  encrypted         = "${var.ebs_kms_key_id == "" ? false : true}"
  kms_key_id        = "${var.ebs_kms_key_id}"

  tags = "${merge(map("Name", format("%s-%03d-%s", var.svr_name_prefix, count.index + 2, "FCIPool-disk1")), var.tags)}"
}

resource "aws_volume_attachment" "secondary_fci_pool_xvdh_attach" {
  count = "${var.num_of_secondary_nodes}"

  device_name = "xvdh"
  volume_id   = "${element(aws_ebs_volume.secondary_fci_pool_xvdh.*.id, count.index)}"
  instance_id = "${element(aws_instance.secondary_server.*.id, count.index)}"
}

resource "aws_ebs_volume" "secondary_fci_pool_xvdi" {
  count = "${var.num_of_secondary_nodes}"

  availability_zone = "${element(aws_instance.secondary_server.*.availability_zone, count.index)}"
  size              = "${var.fci_pool_ebs_vols_size}"
  type              = "${var.fci_pool_ebs_vols_type}"
  iops              = "${var.fci_pool_ebs_vols_iops}"
  encrypted         = "${var.ebs_kms_key_id == "" ? false : true}"
  kms_key_id        = "${var.ebs_kms_key_id}"

  tags = "${merge(map("Name", format("%s-%03d-%s", var.svr_name_prefix, count.index + 2, "FCIPool-disk2")), var.tags)}"
}

resource "aws_volume_attachment" "secondary_fci_pool_xvdi_attach" {
  count = "${var.num_of_secondary_nodes}"

  device_name = "xvdi"
  volume_id   = "${element(aws_ebs_volume.secondary_fci_pool_xvdi.*.id, count.index)}"
  instance_id = "${element(aws_instance.secondary_server.*.id, count.index)}"
}


#########################################################################
# CorePlatform Pool
resource "aws_ebs_volume" "primary_coreplatform_pool_xvdj" {
  availability_zone = "${aws_instance.primary_server.availability_zone}"
  size              = "${var.coreplatform_pool_ebs_vols_size}"
  type              = "${var.coreplatform_pool_ebs_vols_type}"
  iops              = "${var.coreplatform_pool_ebs_vols_iops}"
  encrypted         = "${var.ebs_kms_key_id == "" ? false : true}"
  kms_key_id        = "${var.ebs_kms_key_id}"

  tags = "${merge(map("Name", format("%s-001-%s", var.svr_name_prefix, "CorePlatformPool-disk1")), var.tags)}"
}

resource "aws_volume_attachment" "primary_coreplatform_pool_xvdj_attach" {
  device_name = "xvdj"
  volume_id   = "${aws_ebs_volume.primary_coreplatform_pool_xvdj.id}"
  instance_id = "${aws_instance.primary_server.id}"
}

resource "aws_ebs_volume" "primary_coreplatform_pool_xvdk" {
  availability_zone = "${aws_instance.primary_server.availability_zone}"
  size              = "${var.coreplatform_pool_ebs_vols_size}"
  type              = "${var.coreplatform_pool_ebs_vols_type}"
  iops              = "${var.coreplatform_pool_ebs_vols_iops}"
  encrypted         = "${var.ebs_kms_key_id == "" ? false : true}"
  kms_key_id        = "${var.ebs_kms_key_id}"

  tags = "${merge(map("Name", format("%s-001-%s", var.svr_name_prefix, "CorePlatformPool-disk2")), var.tags)}"
}

resource "aws_volume_attachment" "primary_coreplatform_pool_xvdk_attach" {
  device_name = "xvdk"
  volume_id   = "${aws_ebs_volume.primary_coreplatform_pool_xvdk.id}"
  instance_id = "${aws_instance.primary_server.id}"
}

resource "aws_ebs_volume" "secondary_coreplatform_pool_xvdj" {
  count = "${var.num_of_secondary_nodes}"

  availability_zone = "${element(aws_instance.secondary_server.*.availability_zone, count.index)}"
  size              = "${var.coreplatform_pool_ebs_vols_size}"
  type              = "${var.coreplatform_pool_ebs_vols_type}"
  iops              = "${var.coreplatform_pool_ebs_vols_iops}"
  encrypted         = "${var.ebs_kms_key_id == "" ? false : true}"
  kms_key_id        = "${var.ebs_kms_key_id}"

  tags = "${merge(map("Name", format("%s-%03d-%s", var.svr_name_prefix, count.index + 2, "CorePlatformPool-disk1")), var.tags)}"
}

resource "aws_volume_attachment" "secondary_coreplatform_pool_xvdj_attach" {
  count = "${var.num_of_secondary_nodes}"

  device_name = "xvdj"
  volume_id   = "${element(aws_ebs_volume.secondary_coreplatform_pool_xvdj.*.id, count.index)}"
  instance_id = "${element(aws_instance.secondary_server.*.id, count.index)}"
}

resource "aws_ebs_volume" "secondary_coreplatform_pool_xvdk" {
  count = "${var.num_of_secondary_nodes}"

  availability_zone = "${element(aws_instance.secondary_server.*.availability_zone, count.index)}"
  size              = "${var.coreplatform_pool_ebs_vols_size}"
  type              = "${var.coreplatform_pool_ebs_vols_type}"
  iops              = "${var.coreplatform_pool_ebs_vols_iops}"
  encrypted         = "${var.ebs_kms_key_id == "" ? false : true}"
  kms_key_id        = "${var.ebs_kms_key_id}"

  tags = "${merge(map("Name", format("%s-%03d-%s", var.svr_name_prefix, count.index + 2, "CorePlatformPool-disk2")), var.tags)}"
}

resource "aws_volume_attachment" "secondary_coreplatform_pool_xvdk_attach" {
  count = "${var.num_of_secondary_nodes}"

  device_name = "xvdk"
  volume_id   = "${element(aws_ebs_volume.secondary_coreplatform_pool_xvdk.*.id, count.index)}"
  instance_id = "${element(aws_instance.secondary_server.*.id, count.index)}"
}


#########################################################################
# Archive Pool
resource "aws_ebs_volume" "primary_archive_pool_xvdl" {
  availability_zone = "${aws_instance.primary_server.availability_zone}"
  size              = "${var.archive_pool_ebs_vols_size}"
  type              = "${var.archive_pool_ebs_vols_type}"
  iops              = "${var.archive_pool_ebs_vols_iops}"
  encrypted         = "${var.ebs_kms_key_id == "" ? false : true}"
  kms_key_id        = "${var.ebs_kms_key_id}"

  tags = "${merge(map("Name", format("%s-001-%s", var.svr_name_prefix, "ArchivePool-disk1")), var.tags)}"
}

resource "aws_volume_attachment" "primary_archive_pool_xvdl_attach" {
  device_name = "xvdl"
  volume_id   = "${aws_ebs_volume.primary_archive_pool_xvdl.id}"
  instance_id = "${aws_instance.primary_server.id}"
}

resource "aws_ebs_volume" "primary_archive_pool_xvdm" {
  availability_zone = "${aws_instance.primary_server.availability_zone}"
  size              = "${var.archive_pool_ebs_vols_size}"
  type              = "${var.archive_pool_ebs_vols_type}"
  iops              = "${var.archive_pool_ebs_vols_iops}"
  encrypted         = "${var.ebs_kms_key_id == "" ? false : true}"
  kms_key_id        = "${var.ebs_kms_key_id}"

  tags = "${merge(map("Name", format("%s-001-%s", var.svr_name_prefix, "ArchivePool-disk2")), var.tags)}"
}

resource "aws_volume_attachment" "primary_archive_pool_xvdm_attach" {
  device_name = "xvdm"
  volume_id   = "${aws_ebs_volume.primary_archive_pool_xvdm.id}"
  instance_id = "${aws_instance.primary_server.id}"
}

resource "aws_ebs_volume" "secondary_archive_pool_xvdl" {
  count = "${var.num_of_secondary_nodes}"

  availability_zone = "${element(aws_instance.secondary_server.*.availability_zone, count.index)}"
  size              = "${var.archive_pool_ebs_vols_size}"
  type              = "${var.archive_pool_ebs_vols_type}"
  iops              = "${var.archive_pool_ebs_vols_iops}"
  encrypted         = "${var.ebs_kms_key_id == "" ? false : true}"
  kms_key_id        = "${var.ebs_kms_key_id}"

  tags = "${merge(map("Name", format("%s-%03d-%s", var.svr_name_prefix, count.index + 2, "ArchivePool-disk1")), var.tags)}"
}

resource "aws_volume_attachment" "secondary_archive_pool_xvdl_attach" {
  count = "${var.num_of_secondary_nodes}"

  device_name = "xvdl"
  volume_id   = "${element(aws_ebs_volume.secondary_archive_pool_xvdl.*.id, count.index)}"
  instance_id = "${element(aws_instance.secondary_server.*.id, count.index)}"
}

resource "aws_ebs_volume" "secondary_archive_pool_xvdm" {
  count = "${var.num_of_secondary_nodes}"

  availability_zone = "${element(aws_instance.secondary_server.*.availability_zone, count.index)}"
  size              = "${var.archive_pool_ebs_vols_size}"
  type              = "${var.archive_pool_ebs_vols_type}"
  iops              = "${var.archive_pool_ebs_vols_iops}"
  encrypted         = "${var.ebs_kms_key_id == "" ? false : true}"
  kms_key_id        = "${var.ebs_kms_key_id}"

  tags = "${merge(map("Name", format("%s-%03d-%s", var.svr_name_prefix, count.index + 2, "ArchivePool-disk2")), var.tags)}"
}

resource "aws_volume_attachment" "secondary_archive_pool_xvdm_attach" {
  count = "${var.num_of_secondary_nodes}"

  device_name = "xvdm"
  volume_id   = "${element(aws_ebs_volume.secondary_archive_pool_xvdm.*.id, count.index)}"
  instance_id = "${element(aws_instance.secondary_server.*.id, count.index)}"
}


#########################################################################
# Backup Pool
resource "aws_ebs_volume" "primary_backup_pool_xvdn" {
  availability_zone = "${aws_instance.primary_server.availability_zone}"
  size              = "${var.backup_pool_ebs_vols_size}"
  type              = "${var.backup_pool_ebs_vols_type}"
  iops              = "${var.backup_pool_ebs_vols_iops}"
  encrypted         = "${var.ebs_kms_key_id == "" ? false : true}"
  kms_key_id        = "${var.ebs_kms_key_id}"

  tags = "${merge(map("Name", format("%s-001-%s", var.svr_name_prefix, "BackupPool-disk1")), var.tags)}"
}

resource "aws_volume_attachment" "primary_backup_pool_xvdn_attach" {
  device_name = "xvdn"
  volume_id   = "${aws_ebs_volume.primary_backup_pool_xvdn.id}"
  instance_id = "${aws_instance.primary_server.id}"
}

resource "aws_ebs_volume" "primary_backup_pool_xvdo" {
  availability_zone = "${aws_instance.primary_server.availability_zone}"
  size              = "${var.backup_pool_ebs_vols_size}"
  type              = "${var.backup_pool_ebs_vols_type}"
  iops              = "${var.backup_pool_ebs_vols_iops}"
  encrypted         = "${var.ebs_kms_key_id == "" ? false : true}"
  kms_key_id        = "${var.ebs_kms_key_id}"

  tags = "${merge(map("Name", format("%s-001-%s", var.svr_name_prefix, "BackupPool-disk2")), var.tags)}"
}

resource "aws_volume_attachment" "primary_backup_pool_xvdo_attach" {
  device_name = "xvdo"
  volume_id   = "${aws_ebs_volume.primary_backup_pool_xvdo.id}"
  instance_id = "${aws_instance.primary_server.id}"
}

resource "aws_ebs_volume" "secondary_backup_pool_xvdn" {
  count = "${var.num_of_secondary_nodes}"

  availability_zone = "${element(aws_instance.secondary_server.*.availability_zone, count.index)}"
  size              = "${var.backup_pool_ebs_vols_size}"
  type              = "${var.backup_pool_ebs_vols_type}"
  iops              = "${var.backup_pool_ebs_vols_iops}"
  encrypted         = "${var.ebs_kms_key_id == "" ? false : true}"
  kms_key_id        = "${var.ebs_kms_key_id}"

  tags = "${merge(map("Name", format("%s-%03d-%s", var.svr_name_prefix, count.index + 2, "BackupPool-disk1")), var.tags)}"
}

resource "aws_volume_attachment" "secondary_backup_pool_xvdn_attach" {
  count = "${var.num_of_secondary_nodes}"

  device_name = "xvdn"
  volume_id   = "${element(aws_ebs_volume.secondary_backup_pool_xvdn.*.id, count.index)}"
  instance_id = "${element(aws_instance.secondary_server.*.id, count.index)}"
}

resource "aws_ebs_volume" "secondary_backup_pool_xvdo" {
  count = "${var.num_of_secondary_nodes}"

  availability_zone = "${element(aws_instance.secondary_server.*.availability_zone, count.index)}"
  size              = "${var.backup_pool_ebs_vols_size}"
  type              = "${var.backup_pool_ebs_vols_type}"
  iops              = "${var.backup_pool_ebs_vols_iops}"
  encrypted         = "${var.ebs_kms_key_id == "" ? false : true}"
  kms_key_id        = "${var.ebs_kms_key_id}"

  tags = "${merge(map("Name", format("%s-%03d-%s", var.svr_name_prefix, count.index + 2, "BackupPool-disk2")), var.tags)}"
}

resource "aws_volume_attachment" "secondary_backup_pool_xvdo_attach" {
  count = "${var.num_of_secondary_nodes}"

  device_name = "xvdo"
  volume_id   = "${element(aws_ebs_volume.secondary_backup_pool_xvdo.*.id, count.index)}"
  instance_id = "${element(aws_instance.secondary_server.*.id, count.index)}"
}

# Create locals to build the variable lists that are passed thru the SSM doc to powershell
locals {
  default_pool_volumes = "'${join(",",  concat(list(aws_ebs_volume.primary_default_pool_xvdf.id,aws_ebs_volume.primary_default_pool_xvdg.id),aws_ebs_volume.secondary_default_pool_xvdf.*.id,aws_ebs_volume.secondary_default_pool_xvdg.*.id))}'"
  fci_pool_volumes = "'${join(",",  concat(list(aws_ebs_volume.primary_fci_pool_xvdh.id,aws_ebs_volume.primary_fci_pool_xvdi.id),aws_ebs_volume.secondary_fci_pool_xvdh.*.id,aws_ebs_volume.secondary_fci_pool_xvdi.*.id))}'"
  coreplatform_pool_volumes = "'${join(",",  concat(list(aws_ebs_volume.primary_coreplatform_pool_xvdj.id,aws_ebs_volume.primary_coreplatform_pool_xvdk.id),aws_ebs_volume.secondary_coreplatform_pool_xvdj.*.id,aws_ebs_volume.secondary_coreplatform_pool_xvdk.*.id))}'"
  archive_pool_volumes = "'${join(",",  concat(list(aws_ebs_volume.primary_archive_pool_xvdl.id,aws_ebs_volume.primary_archive_pool_xvdm.id),aws_ebs_volume.secondary_archive_pool_xvdl.*.id,aws_ebs_volume.secondary_archive_pool_xvdm.*.id))}'"
  backup_pool_volumes = "'${join(",",  concat(list(aws_ebs_volume.primary_backup_pool_xvdn.id,aws_ebs_volume.primary_backup_pool_xvdo.id),aws_ebs_volume.secondary_backup_pool_xvdn.*.id,aws_ebs_volume.secondary_backup_pool_xvdo.*.id))}'"
}
