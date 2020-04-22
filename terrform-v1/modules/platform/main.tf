####Create security group
resource "aws_security_group" "default_dd01_sg" {
  name            = "${var.env}-${var.project_name}"
  description     = "${var.env}-${var.project_name} security rule"
  vpc_id          = "${var.vpc_id}"

  tags            = {
    "Name"        = "${var.env}-${var.project_name}"
    "Environment" = "${var.env}"
  }
}
resource "aws_security_group_rule" "ingress_rule" {
  count             = "${length(var.inbound_rules)}"
  type              = "ingress"
  cidr_blocks       = ["${element(var.inbound_rules[count.index], 0)}"]
  from_port         = "${element(var.inbound_rules[count.index], 1)}"
  to_port           = "${element(var.inbound_rules[count.index], 2)}"
  protocol          = "${element(var.inbound_rules[count.index], 3)}"
  security_group_id = "${aws_security_group.default_dd01_sg.id}"
}
resource "aws_security_group_rule" "ingress_rule2" {
  type              = "ingress"
  from_port         = "0"
  to_port           = "0"
  protocol          = "-1"
  security_group_id = "${aws_security_group.default_dd01_sg.id}"
  self = true
}
resource "aws_security_group_rule" "egress_rule" {
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = "0"
  to_port           = "0"
  protocol          = "-1"
  security_group_id = "${aws_security_group.default_dd01_sg.id}"
}

####Creating ELB
resource "aws_elb" "elb_conf" {
  name            = "${var.env}-${var.elb_name}-elb"
  internal        = false
  subnets         = ["${var.subnets}"]
  security_groups = ["${aws_security_group.default_dd01_sg.id}"]

  access_logs {
    enabled       = "${var.elb_access_logs["enabled"]}"
    bucket        = "${var.elb_access_logs["bucket"]}"
    bucket_prefix = "${var.elb_access_logs["bucket_prefix"]}"
    interval      = 60
  }
  health_check {
    healthy_threshold   = 5
    unhealthy_threshold = 5
    timeout             = 30
    interval            = 60
    target              = "${var.elb_health_check_target}"
  }
  listener {
    lb_port           = 80
    lb_protocol       = "http"
    instance_port     = "80"
    instance_protocol = "http"
  }
  listener {
    lb_port            = 443
    lb_protocol        = "https"
    instance_port      = "80"
    instance_protocol  = "http"
    ssl_certificate_id = "${var.elb_ssl_certificate_id}"
  }
  tags {
    "Name"       = "${var.env}-${var.elb_name}"
    "Billing"    = "${var.env}"
    "Team"       = "${var.billing_team}"
    "Environment" = "${var.env}"
  }
}

####Create auto scaling
### Creating launch configuration
resource "aws_launch_configuration" "lc_conf" {
  name_prefix                 = "${var.env}-${var.project_name}-lc"
  image_id                    = "${var.lc_ami}"
  instance_type               = "${var.lc_instance_type}"
  key_name                    = "${var.lc_ec2_key_name}"
  security_groups             = ["${aws_security_group.default_dd01_sg.id}"]
  associate_public_ip_address = true
  ebs_optimized               = false
  iam_instance_profile        = "${var.lc_iam_instance_profile}"


  user_data = <<HEREDOC
#!/bin/bash
set -x
export HOME="${var.lc_userdata_ENV_HOME}"
export SETUP_ENV="${var.lc_userdata_ENV_SETUP_ENV}"
export S3BUCKET_ENV="${var.lc_userdata_ENV_S3BUCKET_ENV}"
export S3BUCKET_TERRAFORM="${var.lc_userdata_ENV_S3BUCKET_TERRAFORM}"
export S3BUCKET_SSHPUBKEY="${var.lc_userdata_ENV_S3BUCKET_SSHPUBKEY}"
export SERVICE_NAME="${var.env}-${var.project_name}"


# @param $1 name of the script
cp_chmod_exec () { #
  PLAYBOOK=$$1
  echo $PLAYBOOK >> exec.txt
  aws s3 cp s3://$${S3BUCKET_TERRAFORM}/$$PLAYBOOK $${HOME}/dd01-terraform/$$PLAYBOOK
  chmod 400 ./$${HOME}/dd01-terraform/$$PLAYBOOK
  ansible-playbook -v ./$${HOME}/dd01-terraform/$$PLAYBOOK
}

#AWS CLI, Ansible installion

aws s3 cp s3://$${S3BUCKET_TERRAFORM}/playbooks/projects/host_vars/localhost/vars.yml $${HOME}/dd01-terraform/playbooks/projects/host_vars/localhost/vars.yml
sops --decrypt --in-place $${HOME}/dd01-terraform/playbooks/projects/host_vars/localhost/vars.yml

aws s3 sync s3://$${S3BUCKET_TERRAFORM}/playbooks/projects/roles $${HOME}/dd01-terraform/playbooks/projects/roles

aws s3 sync s3://$${S3BUCKET_TERRAFORM}/playbooks/projects/templates $${HOME}/dd01-terraform/playbooks/projects/templates
mkdir -p  $${HOME}/dd01-terraform/playbooks/common/

ln -s $${HOME}/dd01-terraform/playbooks/projects/roles $${HOME}/dd01-terraform/playbooks/common/roles

ln -s $${HOME}/dd01-terraform/playbooks/projects/host_vars $${HOME}/dd01-terraform/playbooks/common/host_vars

aws s3 sync s3://$${S3BUCKET_SSHPUBKEY}/playbook/public_keys $${HOME}/dd01-terraform/playbooks/common/public_keys

list_playbooks=(${join(" ", var.lc_userdata_VAR_PLAYBOOKS)})
for playbook in $${list_playbooks[@]}
do
	cp_chmod_exec $playbook
done
HEREDOC

  root_block_device = [
    {
      volume_size           = "${var.asg_volume_size}"
      volume_type           = "${var.asg_volume_type}"
      delete_on_termination = true
    },
  ]

  lifecycle {
    create_before_destroy = true
  }
}

### Creating autoscaling group
resource "aws_autoscaling_group" "asg_conf" {
  name                      = "${var.env}-${var.project_name}-asg"
  launch_configuration      = "${aws_launch_configuration.lc_conf.name}"
  min_size                  = "${var.asg_min_size}"
  max_size                  = "${var.asg_max_size}"
  desired_capacity          = "${var.asg_desired_capacity}"
  vpc_zone_identifier       = ["${var.subnets}"]
  load_balancers            = ["${var.env}-${var.elb_name}-elb"]
  health_check_type         = "ELB"
  default_cooldown          = 300
  health_check_grace_period = 300

  tag {
    key                 = "Name"
    value               = "${var.env}-${var.project_name}-asg"
    propagate_at_launch = true
  }

  tag {
    key                 = "Team"
    value               = "${var.billing_team}"
    propagate_at_launch = true
  }

  tag {
    key                 = "SshUser"
    value               = "${var.lc_ami_user}"
    propagate_at_launch = true
  }

  tag {
    key                 = "Billing"
    value               = "${var.env}"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = "${var.env}"
    propagate_at_launch = true
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_policy" "asg_policy" {
  name                   = "${var.env}-${var.project_name}-asg-policy"
  policy_type            = "TargetTrackingScaling"  #使用目标跟踪扩展策略
  autoscaling_group_name = "${aws_autoscaling_group.asg_conf.name}"
  estimated_instance_warmup = "60"
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"  #指标类型为CPU平均利用率
    }

  target_value = "${var.asp_target_value}"     #当cpu利用率在百分之多少时触发策略
  }
}

resource aws_cloudwatch_metric_alarm "panic_time" {
  alarm_name          = "${var.env}-${var.project_name}-asg"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"   #将数据与指定阈值进行比较的周期数
  metric_name         = "HTTPCode_Backend_5XX"   #指标
  namespace           = "AWS/ELB"  #警报关联度量标准的命名空间
  period              = "60"    #时间秒
  statistic           = "Average"  #统计数据
  threshold           = "1"

  dimensions {
    LoadBalancerName = "${var.elb_name}"
  }
  alarm_description = "This metric monitors elb backend http 5xx"
  alarm_actions     = ["${var.cloudwatch_sns}"]  
}



