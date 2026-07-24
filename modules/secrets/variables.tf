variable "name_prefix" {
  description = "Prefix for secret names"
  type        = string
}

variable "kms_key_arn" {
  description = "CMK ARN used to encrypt the secret"
  type        = string
}

variable "password_length" {
  description = "Length of the generated password"
  type        = number
  default     = 32
}

variable "recovery_window_in_days" {
  description = "Recovery window when deleting the secret (0-30)"
  type        = number
  default     = 30
}

variable "tags" {
  description = "Tags to apply"
  type        = map(string)
  default     = {}
}
