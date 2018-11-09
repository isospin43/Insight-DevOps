resource "null_resource" "delete_old_keys" {
  provisioner "local-exec" {
    command = "rm -f keys/*.pub"
  }

  provisioner "local-exec" {
    command = "rm -f keys/*.pem"
  }
}

module "cdn-us-east-1" {
  source = "cdn"
  region = "us-east-1"
}

module "cdn-us-west-2" {
  source = "cdn"
  region = "us-west-2"
}

/*
resource "tls_private_key" "sheepsheadbay" {algorithm = "RSA", rsa_bits  = 4096}
resource "aws_key_pair" "sheepsheadbay_generated_key" {
  key_name   = "SV-sheepsheadbay-keypair"
  public_key = "${tls_private_key.sheepsheadbay.public_key_openssh}"
}
resource "aws_instance" "server" {
#  count                  = "${length(data.aws_availability_zones.available.names) * var.servers_per_az}"
#  instance_type          = "${var.instance_type}"
#  ami                    = "${data.aws_ami.default.id}"
#  subnet_id              = "${element(aws_subnet.public.*.id, count.index)}"
#  ipv6_address_count     = "1"
#  vpc_security_group_ids = ["${aws_security_group.default.id}", "${aws_vpc.main.default_security_group_id}"]

  key_name = "${aws_key_pair.sheepsheadbay_generated_key.key_name}"
  provisioner "local-exec" { command = "echo \"${chomp(tls_private_key.sheepsheadbay_generated_key.public_key_openssh)}\" > keys/${aws_key_pair.sheepsheadbay_generated_key.key_name}.pub" }
  provisioner "local-exec" { command = "echo \"${chomp(tls_private_key.sheepsheadbay_generated_key.private_key_pem)}\" > keys/${aws_key_pair.sheepsheadbay_generated_key.key_name}.pem" }
  provisioner "local-exec" { command = "chmod 0400 keys/${aws_key_pair.sheepsheadbay_generated_key.key_name}.pem" }

  #tags = { Name = "cdn-server-${element(data.aws_availability_zones.available.names, count.index)}-${count.index}" }
}
*/
