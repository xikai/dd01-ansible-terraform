### Creating Codedeploy

resource "aws_codedeploy_app" "cd_app_conf" {
  name = "${var.cd_app_name}"
}
