variable "project_name" {
  type    = string
  default = "handson"
}

variable "environment" {
  type    = string
  default = "staging"
}

variable "vpc_cidr" {
  type    = string
  default = "10.1.0.0/16"
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.1.1.0/24", "10.1.2.0/24"]
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.1.10.0/24", "10.1.20.0/24"]
}

variable "availability_zones" {
  type    = list(string)
  default = ["ap-northeast-1a", "ap-northeast-1c"]
}

variable "ami_id" {
  type    = string
  default = "ami-0d52744d6551d851e"
}

variable "instance_type" {
  type    = string
  default = "t3.small"
}

variable "tags" {
  type    = map(string)
  default = {}
}
