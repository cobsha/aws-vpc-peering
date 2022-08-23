variable "region" { }

variable "vpc_cidr" { }

variable "project" { }

variable "env" { }

variable "zone" {
  
  type = list
  default = ["a", "b", "c"]
}