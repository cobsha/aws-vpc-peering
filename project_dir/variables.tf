variable "region" {

    default = "us-east-2"
}

variable "cidr" {
  
  type = list
  default = ["172.16.0.0/16", "172.17.0.0/16"]
}

variable "project" { 

  type = list
  default = ["zomato", "uber"]
}

variable "env" {

    default = "prod"
}

variable "aws_id" {

    default = "642071678120"
}

variable "instance_ami" {

    default = "ami-02d1e544b84bf7502"
}

variable "instance_type" {

    default = "t2.micro"
}