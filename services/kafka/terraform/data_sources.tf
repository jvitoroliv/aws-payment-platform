#Predefined Project Information
data "aiven_project" "finserv-project" {
  project = "corp-eventing-${var.aiven_project}"
}

#Predefined Service Information
data "aiven_kafka" "kafka_service_ue1" {
  project = data.aiven_project.finserv-project.project
  service_name = "corp-kafka-${var.aiven_project}-pci-ue1"
}

data "aiven_kafka" "kafka_service_uw2" {
  project = data.aiven_project.finserv-project.project
  service_name = "corp-kafka-${var.aiven_project}-pci-uw2"
}

data "aiven_kafka_mirrormaker" "mm2_service_ue1" {
  project = data.aiven_project.finserv-project.project
  service_name = "finserv-mm2-${var.aiven_project}-pci-ue1"
}

data "aiven_kafka_mirrormaker" "mm2_service_uw2" {
  project = data.aiven_project.finserv-project.project
  service_name = "finserv-mm2-${var.aiven_project}-pci-uw2"
}

data "aws_secretsmanager_secret_version" "aiven_api_token" {
  secret_id = "${var.environment}-aiven-api-token"
}
