variable "vpc-cidr" {
  default = "10.0.0.0/16"
  description = "VPC CIDR Block"
  type = string
}

variable "pulic-subnet-1-cidr" {
  default = "10.0.0.0/24"
  description = "public subnet 1 CIDR Block"
  type = string
}

variable "pulic-subnet-2-cidr" {
  default = "10.0.1.0/24"
  description = "public subnet 2 CIDR Block"
  type = string
}

variable "private-subnet-1-cidr" {
  default = "10.0.2.0/24"
  description = "private subnet 1 CIDR Block"
  type = string
}

variable "private-subnet-2-cidr" {
  default = "10.0.3.0/24"
  description = "private subnet 2 CIDR Block"
  type = string
}

variable "private-subnet-3-cidr" {
  default = "10.0.4.0/24"
  description = "private subnet 3 CIDR Block"
  type = string
}

variable "private-subnet-4-cidr" {
  default = "10.0.5.0/24"
  description = "private subnet 4 CIDR Block"
  type = string
}

