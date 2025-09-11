
variable "ResourcePrefix" {
  description = "Prefix to be used for naming resources"
  type        = string
}

variable "log_bucket_name" {
  description = "Name of the logging bucket"
  type        = string
}

variable "log_bucket_versioning_status" {
  description = "Versioning status for the replication destination bucket"
  type        = string
}

