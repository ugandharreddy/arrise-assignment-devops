variable "region" {
  description = "AWS region for the development environment."
  type        = string
  default     = "us-east-1"
}

variable "instances" {
  description = "Development EC2 instance definitions."
  type = list(object({
    name             = string
    ami              = string
    instance_type    = string
    key_name         = string
    root_volume_type = string
    root_volume_size = number
    iops             = optional(number)
    environment      = string
    owner            = string
    tags             = optional(map(string), {})
  }))
}

variable "protected_instance_name" {
  description = "Name of the instance that should be protected from accidental destruction."
  type        = string
  default     = "app-03"
}
