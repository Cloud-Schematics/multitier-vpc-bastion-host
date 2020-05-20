variable "ssh_accesscheck" {
  description = "Flag to request remote-exec validation of SSH access, true/false"
}

variable "ssh_private_key" {
  description = "SSH private key of SSH key pair used for VSIs and Bastion"
}

variable "target_hosts" {
  description = "List of target hosts to be checked"
  default     = []
}

variable "bastion_host" {
  description = "Bastion host to be used"
  default     = ""
}
