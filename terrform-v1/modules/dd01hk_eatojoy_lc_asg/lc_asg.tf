### Creating launch configuration
resource "aws_launch_configuration" "lc_conf" {
  name_prefix                 = "${var.env}-${var.asg_name}-lc"
  image_id                    = "${var.lc_ami}"
  instance_type               = "${var.lc_instance_type}"
  key_name                    = "${var.lc_ec2_key_name}"
  security_groups             = ["${var.lc_security_groups}"]
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
export SERVICE_NAME="${var.asg_name}"
export SERVICE_ENV="${var.env}"

export INSTANCE_ID=$(ec2metadata --instance-id)
export REGION=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | grep region | awk -F\" '{print $4}')
export TAG_VALUE=$(aws ec2 describe-tags --filters "Name=resource-id,Values=$INSTANCE_ID" "Name=key,Values=Name" --region=$REGION --output=text | cut -f5)


# @param $1 name of the script
cp_chmod_exec () { #
  PLAYBOOK=$$1
  echo $PLAYBOOK >> exec.txt
  aws s3 cp s3://$${S3BUCKET_TERRAFORM}/$$PLAYBOOK $${HOME}/dd01hk-terraform/$$PLAYBOOK
  chmod 400 ./$${HOME}/dd01hk-terraform/$$PLAYBOOK
  ansible-playbook -v ./$${HOME}/dd01hk-terraform/$$PLAYBOOK
}

#AWS CLI, Ansible installion

aws s3 cp s3://$${S3BUCKET_TERRAFORM}/playbooks/projects/host_vars/localhost/vars.yml $${HOME}/dd01hk-terraform/playbooks/projects/host_vars/localhost/vars.yml
sops --decrypt --in-place $${HOME}/dd01hk-terraform/playbooks/projects/host_vars/localhost/vars.yml

aws s3 sync s3://$${S3BUCKET_TERRAFORM}/playbooks/projects/roles $${HOME}/dd01hk-terraform/playbooks/projects/roles

aws s3 sync s3://$${S3BUCKET_TERRAFORM}/playbooks/projects/templates $${HOME}/dd01hk-terraform/playbooks/projects/templates
mkdir -p  $${HOME}/dd01hk-terraform/playbooks/common/

ln -s $${HOME}/dd01hk-terraform/playbooks/projects/roles $${HOME}/dd01hk-terraform/playbooks/common/roles

ln -s $${HOME}/dd01hk-terraform/playbooks/projects/host_vars $${HOME}/dd01hk-terraform/playbooks/common/host_vars

aws s3 sync s3://$${S3BUCKET_SSHPUBKEY}/playbook/public_keys $${HOME}/dd01hk-terraform/playbooks/common/public_keys

mkdir /usr/local/openfalcon-agent
aws s3 sync s3://dd01hk-ops-terraform-res/falcon/ /usr/local/openfalcon-agent/

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
  name                      = "${var.env}-${var.asg_name}-asg"
  launch_configuration      = "${aws_launch_configuration.lc_conf.name}"
  min_size                  = "${var.asg_min_size}"
  max_size                  = "${var.asg_max_size}"
  desired_capacity          = "${var.asg_desired_capacity}"
  vpc_zone_identifier       = ["${var.asg_subnets}"]
  load_balancers            = ["${var.elb_name}"]
  target_group_arns         = ["${var.alb_tg_arn}"]  
  health_check_type         = "ELB"
  default_cooldown          = 300
  health_check_grace_period = 300

  tag {
    key                 = "Name"
    value               = "${var.env}-${var.asg_name}-asg"
    propagate_at_launch = true
  }

  tag {
    key                 = "Team"
    value               = "${var.asg_name}"
    propagate_at_launch = true
  }

  tag {
    key                 = "BillingTag"
    value               = "${var.env}"
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
  name                   = "${var.env}-${var.asg_name}-asg-policy"
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
  alarm_name          = "${var.env}-${var.asg_name}-asg"
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



