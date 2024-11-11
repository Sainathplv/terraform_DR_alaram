variable "primary_region" {
  default = "us-east-1"
}

variable "secondary_region" {
  default = "us-west-2"
}

variable "primary_vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "secondary_vpc_cidr" {
  default = "10.1.0.0/16"
}

variable "primary_subnet_1_cidr" {
  default = "10.0.1.0/24"
}

variable "primary_subnet_2_cidr" {
  default = "10.0.2.0/24"
}

variable "secondary_subnet_1_cidr" {
  default = "10.1.1.0/24"
}

variable "secondary_subnet_2_cidr" {
  default = "10.1.2.0/24"
}

variable "email_notification" {
  default = "sainathreddypalavala7@gmail.com"
}
