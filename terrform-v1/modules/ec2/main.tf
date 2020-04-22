resource "aws_instance" "this" {
  ami                    = "${var.ec2_ami}"
  instance_type               = "${var.ec2_instance_type}"
  key_name                    = "${var.ec2_key_name}"
  security_groups             = ["${var.ec2_security_groups}"]
  associate_public_ip_address = true
  ebs_optimized               = false
  iam_instance_profile        = "${var.ec2_iam_instance_profile}"
  subnet_id                   = "${var.ec2_subnet}"




  root_block_device = [
    {
      volume_size           = "${var.ec2_volume_size}"
      volume_type           = "${var.ec2_volume_type}"
      delete_on_termination = true
    },
  ]
  tags        = {
    "Name"        = "${var.env}-${var.ec2_name}"
    "Team"     = "${var.ec2_name}"
    "BillingTag" = "${var.env}"
    "Billing"    = "${var.env}"
    "Environment" = "${var.env}"
    "SshUser"    = "${var.ec2_user}"
  }
}
