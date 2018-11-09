variable "region" {}

variable "servers_per_az" {
  default = 1
}

variable "instance_type" {
  default = "t2.nano"
}

variable "r53_zone_id" {
  default = "Z31FS5VZVUSMT6"
}

# Will be prepended to the name associated r53_zone_id
variable "r53_domain_name" {
  default = "cdn"
}

variable "server_port" {
  default = "80"
}

#"${data.aws_ami.ubuntu_consul_agent}"
data "aws_ami" "default" {
  most_recent = true
  owners = ["self"]

  filter {
    name   = "name"
    values = ["steve-west-public-*","steve-east-public-*"]
  }
}
