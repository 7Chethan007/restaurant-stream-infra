variable "project_id" {
  description = "GCP project ID (must already exist, Firebase + Pub/Sub + Compute APIs enabled)"
  type        = string
}

variable "region" {
  description = "GCP region for regional resources"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP zone for the VM"
  type        = string
  default     = "us-central1-a"
}

variable "machine_type" {
  description = "VM size for the single backend+Flink host"
  type        = string
  default     = "e2-small"
}

variable "github_org" {
  description = "GitHub org/user the deploy workflows run under — scopes which repos can assume the CI service accounts via Workload Identity Federation"
  type        = string
  default     = "7Chethan007"
}

variable "backend_port" {
  description = "Port the FastAPI backend (producer + SSE) listens on"
  type        = number
  default     = 8000
}

variable "flink_ui_port" {
  description = "Port the Flink JobManager web UI listens on"
  type        = number
  default     = 8081
}
