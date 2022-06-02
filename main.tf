variable "region" {
    default = "ca-central-1"
}
/* variable "public_key_file" {
  type        = string
  description = "Filename of the public key of a key pair on your local machine. This key pair will allow to connect to the nodes of the cluster with SSH."
  default     = "~/.ssh/id_rsa.pub"
} */

variable "vpc_cidr_block" {
    type        = string
    description = ""
    default     = "10.0.0.0/16"
}

variable "public_subnet_1_cidr" {
    type        = string
    description = ""
    default     = "10.0.1.0/24"
}
variable "public_subnet_2_cidr" {
    type        = string
    description = ""
    default     = "10.0.2.0/24"
}
variable "private_subnet_1_cidr" {
    type        = string
    description = ""
    default     = "10.0.3.0/24"
}
variable "private_subnet_2_cidr" {
    type        = string
    description = ""
    default     = "10.0.4.0/24"
}
variable "eip_association_address" {
    type        = string
    description = ""
    default     = "10.0.5.0/24"
}
/* variable "ec2_keypair" {
    type        = string
    description = ""
    default     = "paire.pem"
} */
variable "ec2_instance_type" {
  type        = string
  description = "EC2 instance type for the master node (must have at least 2 CPUs)."
  default     = "t3.medium"
}

variable "allowed_ssh_cidr_blocks" {
    type        = list(string)
    description = ""
    default     = ["24.226.138.237/32"]
}

variable "ec2_instance_min_size" {
  description = "The minimum number of the EC2 instances"
  default     = 1
}

variable "ec2_instance_max_size" {
  description = "The maximum number of the EC2 instances"
  default     = 3
}

variable "web_server_port" {
  description = "The TCP port the server will use for HTTP requests"
  default     = 8080
}
