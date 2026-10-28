variable "account_mode" {
  description = "Which account resources to deploy: a for account A, b for account B."
  type        = string
  validation {
    condition     = contains(["a", "b"], var.account_mode)
    error_message = "account_mode must be either 'a' or 'b'."
  }
}

variable "account_id_a" {
  description = "Account A ID."
  type        = string
}

variable "account_id_b" {
  description = "Account B ID."
  type        = string
}

variable "role_a_name" {
  description = "Name for roleA in Account A."
  type        = string
  default     = "roleA"
}

variable "role_b_name" {
  description = "Name for roleB in Account A."
  type        = string
  default     = "roleB"
}

variable "role_c_name" {
  description = "Name for roleC in Account B."
  type        = string
  default     = "roleC"
}

variable "bucket_name" {
  description = "Name of the S3 bucket exposed through Account B access."
  type        = string
}

variable "group1_members" {
  description = "Users who belong to group1 in Account A."
  type        = list(string)
  default     = []
}

variable "group2_members" {
  description = "Users who belong to group2 in Account A."
  type        = list(string)
  default     = []
}

variable "role_a_trusted_account" {
  description = "Account used as the trust principal for roleA."
  type        = string
  default     = "000000000000"
}

variable "role_b_trusted_account" {
  description = "Account used as the trust principal for roleB."
  type        = string
  default     = "000000000000"
}
