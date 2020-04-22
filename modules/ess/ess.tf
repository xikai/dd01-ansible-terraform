resource "alicloud_ess_scaling_group" "scaling" {
  scaling_group_name         = "${var.env}-${var.scaling_group_name}-asg"
  min_size                   = "${var.min_size}"
  max_size                   = "${var.max_size}"
  vswitch_ids                = ["${var.vswitch_ids}"]
  loadbalancer_ids           = ["${var.loadbalancer_ids}"]
  db_instance_ids            = ["${var.db_instance_ids}"]
  multi_az_policy            = "${var.multi_az_policy}"
  removal_policies           = ["OldestInstance", "NewestInstance"]
}

resource "alicloud_ess_scaling_configuration" "config" {
  scaling_group_id           = "${alicloud_ess_scaling_group.scaling.id}"
  instance_name              = "${var.env}-${var.instance_name}-asg"
  instance_type              = "${var.instance_type}"
  image_id                   = "${var.image_id}"
  system_disk_size           = "${var.system_disk_size}"
  system_disk_category       = "${var.system_disk_category}"
  key_name                   = "${var.key_name}"
  role_name                  = "${var.role_name}"
  security_group_id          = "${var.security_group_id}"
  active                     = true
  enable                     = true
  internet_max_bandwidth_in  = 10
  internet_max_bandwidth_out = 10
  internet_charge_type       = "PayByTraffic"
  force_delete               = true

  user_data = <<HEREDOC
#!/bin/bash
set -x

#apt-get update -y  >>user_data.log 2>&1
#apt-get install software-properties-common -y >>user_data.log 2>&1
#apt-add-repository --yes --update ppa:ansible/ansible >>user_data.log 2>&1
#apt-get install ansible jq -y >>user_data.log 2>&1
#
#wget http://gosspublic.alicdn.com/ossutil/1.5.2/ossutil64 -P /usr/local/bin/ >>user_data.log
#chmod 755 /usr/local/bin/ossutil64

export HOME="${var.userdata_ENV_HOME}"
export OSS_ANSIBLE="${var.userdata_OSS_ANSIBLE}"
export PROJECTNAME="${var.instance_name}"
export CODE_SERVER="${var.userdata_CODE_SERVER}"

export KEYID=$(curl -s http://100.100.100.200/latest/meta-data/ram/security-credentials/ansible-oss-pull |jq -r .AccessKeyId)
export KEYSECRET=$(curl -s http://100.100.100.200/latest/meta-data/ram/security-credentials/ansible-oss-pull |jq -r .AccessKeySecret)
export STSTOKEN=$(curl -s http://100.100.100.200/latest/meta-data/ram/security-credentials/ansible-oss-pull |jq -r .SecurityToken)
export ENDPOINT="oss-cn-shenzhen.aliyuncs.com"

export HOST_IP=$(ifconfig eth0 |grep "inet" |awk '{print $2}' |tr -d "addr:" |tr -s . -)
hostnamectl --static set-hostname $${PROJECTNAME}-$$HOST_IP

cp_chmod_exec () {
  PLAYBOOK=$$1
  echo $PLAYBOOK >> exec.txt
  ossutil64 -i $$KEYID -k $$KEYSECRET -t $$STSTOKEN -e $$ENDPOINT cp oss://$${OSS_ANSIBLE}/$$PLAYBOOK $${HOME}/$$PLAYBOOK
  chmod 400 $${HOME}/$$PLAYBOOK
  ansible-playbook -v $${HOME}/$$PLAYBOOK
}

mkdir -p $${HOME}/playbooks/common
ossutil64 -i $$KEYID -k $$KEYSECRET -t $$STSTOKEN -e $$ENDPOINT cp -r oss://$${OSS_ANSIBLE}/playbooks/common/public_keys $${HOME}/playbooks/common
ossutil64 -i $$KEYID -k $$KEYSECRET -t $$STSTOKEN -e $$ENDPOINT cp -r oss://$${OSS_ANSIBLE}/playbooks/roles/ $${HOME}/playbooks/roles/

list_playbooks=(${join(" ", var.userdata_VAR_PLAYBOOKS)})
for playbook in $${list_playbooks[@]}
do
	cp_chmod_exec $playbook
done

mkdir /srv/$${PROJECTNAME}
wget http://$${CODE_SERVER}/$${PROJECTNAME}.tgz
tar -xzf $${PROJECTNAME}.tgz -C /srv/$${PROJECTNAME}

HEREDOC
}


#手动伸缩
resource "alicloud_ess_scaling_rule" "rule" { 
  scaling_group_id = "${alicloud_ess_scaling_group.scaling.id}"
  adjustment_type = "${var.adjustment_type}"
  adjustment_value = "${var.adjustment_value}"
  cooldown = 60
}

#在指定时间伸缩扩容
#resource "alicloud_ess_schedule" "run" {
#  scheduled_action = "${alicloud_ess_scaling_rule.rule.ari}"
#  launch_time = "${var.schedule_launch_time}"
#  scheduled_task_name = "tf-run"
#}

#根据监控CPU利用率触发伸缩扩容
#resource "alicloud_ess_scaling_rule" "rule" {
#    scaling_rule_name = "accEssAlarm_basic"
#    scaling_group_id = "${alicloud_ess_scaling_group.scaling.id}"
#    adjustment_type = "${var.adjustment_type}"
#    adjustment_value = "${var.adjustment_value}"
#    cooldown = 60
#}
#
#resource "alicloud_ess_alarm" "alarm" {
#    name = "accEssAlarm_basic"
#    description = "Acc alarm test"
#    alarm_actions = ["${alicloud_ess_scaling_rule.rule.ari}"]
#    scaling_group_id = "${alicloud_ess_scaling_group.scaling.id}"
#    metric_type = "system"
#    metric_name = "CpuUtilization"
#    period = 300
#    statistics = "Average"
#    threshold = 80              #ess己启动实例的平均CPU利用率达到%80时 触发alarm_actions
#    comparison_operator = ">="
#    evaluation_count = 2 
#}

