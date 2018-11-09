terraform { required_version = ">= 0.10.3" }

provider "aws" { region = "${var.region}" }

data "aws_availability_zones" "available" { state = "available" }

data "aws_route53_zone" "default" { zone_id = "${var.r53_zone_id}" }

resource "aws_vpc" "main" {
  cidr_block                       = "192.168.0.0/16"
  assign_generated_ipv6_cidr_block = "true"
  enable_dns_support               = "true"
  enable_dns_hostnames             = "true"

  tags { Name = "cdn-${var.region}" }
}

resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.main.id}"

  tags = { Name = "cdn-${var.region}-igw" }
}

resource "aws_subnet" "public" {
  count                           = "${length(data.aws_availability_zones.available.names)}"
  vpc_id                          = "${aws_vpc.main.id}"
  cidr_block                      = "${cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)}"
  ipv6_cidr_block                 = "${cidrsubnet(aws_vpc.main.ipv6_cidr_block, 8, count.index)}"
  map_public_ip_on_launch         = true
  assign_ipv6_address_on_creation = true
  availability_zone               = "${element(data.aws_availability_zones.available.names, count.index)}"

  tags = { Name = "cdn-${element(data.aws_availability_zones.available.names, count.index)}-public" }
}

resource "aws_route_table" "public" {
  count  = "${length(data.aws_availability_zones.available.names)}"
  vpc_id = "${aws_vpc.main.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.default.id}"
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = "${aws_internet_gateway.default.id}"
  }
}

resource "aws_route_table_association" "public" {
  count          = "${length(data.aws_availability_zones.available.names)}"
  subnet_id      = "${element(aws_subnet.public.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.public.*.id, count.index)}"
}

resource "aws_security_group" "default" {
    vpc_id = "${aws_vpc.main.id}"

    ingress { from_port = "${var.server_port}", to_port = "${var.server_port}", protocol = "tcp", cidr_blocks  = ["0.0.0.0/0"]}
    egress { from_port = "${var.server_port}", to_port = "${var.server_port}", protocol = "tcp", cidr_blocks  = ["0.0.0.0/0"]}
    ingress {from_port = 22, to_port = 22, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"]}
    egress {from_port = 22, to_port = 22, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"]}
    egress {from_port = 0, to_port = 0, protocol = "-1", cidr_blocks = ["0.0.0.0/0"]}
    ingress { from_port = -1, to_port = -1, protocol = "icmpv6", ipv6_cidr_blocks = ["::/0"]}
    ingress {from_port = -1, to_port = -1, protocol = "icmp", cidr_blocks = ["0.0.0.0/0"]}
}

resource "aws_security_group" "elb_sg" {
  vpc_id = "${aws_vpc.main.id}"
  ingress {from_port = 80, to_port = 80, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"]}
  egress {from_port = 0, to_port = 0, protocol = "-1", cidr_blocks = ["0.0.0.0/0"]}
}

resource "tls_private_key" "this_project" {algorithm = "RSA", rsa_bits  = 4096}
resource "aws_key_pair" "project_generated_key" {
  key_name   = "SV-insight-keypair-${var.region}"
  public_key = "${tls_private_key.this_project.public_key_openssh}"
}


resource "aws_instance" "server" {
  count                  = "${length(data.aws_availability_zones.available.names) * var.servers_per_az}"
  instance_type          = "${var.instance_type}"
  ami                    = "${data.aws_ami.default.id}"
  subnet_id              = "${element(aws_subnet.public.*.id, count.index)}"
  ipv6_address_count     = "1"
  vpc_security_group_ids = ["${aws_security_group.default.id}", "${aws_vpc.main.default_security_group_id}"]

  key_name = "${aws_key_pair.project_generated_key.key_name}"
  provisioner "local-exec" { command = "rm  -f keys/${aws_key_pair.project_generated_key.key_name}.pub" }
  provisioner "local-exec" { command = "rm  -f keys/${aws_key_pair.project_generated_key.key_name}.pem" }
  provisioner "local-exec" { command = "echo \"${chomp(tls_private_key.this_project.public_key_openssh)}\" > keys/${aws_key_pair.project_generated_key.key_name}.pub" }
  provisioner "local-exec" { command = "echo \"${chomp(tls_private_key.this_project.private_key_pem)}\" > keys/${aws_key_pair.project_generated_key.key_name}.pem" }
  provisioner "local-exec" { command = "chmod 0400 keys/${aws_key_pair.project_generated_key.key_name}.pem" }

  tags = { Name = "cdn-server-${element(data.aws_availability_zones.available.names, count.index)}-${count.index}" }
}

# 1st change - added aws_elb below
resource "aws_elb" "elbmain" {
  name               = "global-elb"
  subnets = ["${element(aws_subnet.public.*.id, count.index)}"]
  security_groups = ["${aws_security_group.elb_sg.id}"]
  #subnets = "${element(aws_subnet.public.*.id, count.index)}"
  #availability_zones = ["us-east-1","us-west-1"] #,"us-west-2"]
  #availability_zones = "${element(data.aws_availability_zones.available.names, count.index)}"
  listener {
    lb_port           = 80
    lb_protocol       = "http"
    instance_port     = "${var.server_port}"
    instance_protocol = "http"
  }

  health_check {
  healthy_threshold   = 2
  unhealthy_threshold = 2
  timeout             = 3
  target              = "HTTP:80/"
  interval            = 30
}
  #instances = ["${aws_instance.server.id}"]
  #cross_zone_load_balancing = true
  instances = ["${aws_instance.server.*.id}"]

}

# 2nd change - added aws_elb below
#  resource "aws_elb_attachment" "service1-elb1" {
#          elb      = "${aws_elb.elbmain.id}"
#          instance = "${element(aws_instance.server.*.id, count.index)}"
          ##instance = "${element(aws_instance.server.*.id, count.index)}"
#       }



resource "aws_route53_record" "cdnv4" {
  zone_id        = "${data.aws_route53_zone.default.zone_id}"
  name           = "${format("%s.%s", var.r53_domain_name, data.aws_route53_zone.default.name)}"
  type           = "A"
  ttl            = "60"
  records        = ["${aws_instance.server.*.public_ip}"]
  set_identifier = "cdn-${var.region}-v4"

  latency_routing_policy {
    region = "${var.region}"
  }
}
