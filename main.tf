
data "terraform_remote_state" "site" {
  backend = "s3"
  config {
    bucket = "${var.terraform_bucket}"
    key = "${var.site_module_state_path}"
    region = "eu-west-1"
  }
}
data "template_file" "project-app_cloudconfig" {
  template = "${file("${path.module}/templates/project-app.cloudinit")}"
  vars {
    chef-resources_key = "${var.chef-resources_key}"
  }
}

resource "aws_launch_configuration" "project-app_lc" {
  user_data = "${data.template_file.project-app_cloudconfig.rendered}"
   lifecycle {  # This is necessary to make terraform launch configurations work with autoscaling groups
    create_before_destroy = true
  }
  security_groups = [/*???*/"${aws_security_group.project-app.id}"]
  name_prefix = "${var.cluster_name}_lc"
  enable_monitoring = false

  //???
  image_id = "${var.ami}"
  instance_type = "${var.instance_type}"
  key_name = "${data.terraform_remote_state.site.admin_key_name}"
  
}

//???
resource "aws_autoscaling_group" "project-app_asg" {
  name = "${var.cluster_name}_asg"
  launch_configuration = "${aws_launch_configuration.project-app_lc.name}"
  max_size = "${var.project-app_cluster_size_max}"
  min_size = "${var.project-app_cluster_size_min}"
  desired_capacity = "${var.project-app_cluster_size_min}"
  vpc_zone_identifier = [ "${data.terraform_remote_state.site.public_subnets}" ]

  load_balancers = [ "${aws_elb.project-app.name}" ]

  tag {
    key = "Name"
    value = "${var.cluster_name}"
    propagate_at_launch = true
  }

  tag {
    key = "Team"
    value = "Cloudschool"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}


// ???
resource "aws_security_group" "project-app_lb" {
  
  name = "${var.cluster_name}-lb"
  description = "${var.cluster_name}-lb"
  vpc_id = "${data.terraform_remote_state.site.vpc_id}"

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "project-app" {
  
  lifecycle {  # This is necessary to make terraform launch configurations work with autoscaling groups
    create_before_destroy = true
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  // ???
  name = "${var.cluster_name}"
  description = "${var.cluster_name}"
  vpc_id = "${data.terraform_remote_state.site.vpc_id}"

  ingress {
    from_port = 5000
    to_port = 5000
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
   # security_groups = [ "${aws_security_group.project-app_lb.id}" ]
  }
  
}

//???
resource "aws_elb" "project-app" {
  name = "${var.cluster_name}-lb"

  subnets = [ "${data.terraform_remote_state.site.public_subnets}" ]
  security_groups = [ "${aws_security_group.project-app_lb.id}" ]

  listener {
    // ???
    instance_port = 5000
    instance_protocol = "HTTP"
    lb_port = 8080
    lb_protocol = "HTTP"
  }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 10
    timeout = 5
    target = "TCP:5000"
    interval = 10
  }

}


resource "aws_security_group" "rds-mysql-db" {
    ingress {
    from_port = 3306
    to_port = 3306
    protocol = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# resource "aws_db_instance" "rds-mysql-db" {
#   multi_az = false
#   db_subnet_group_name = "${data.terraform_remote_state.site.public_subnets[0]}"
#   apply_immediately = true
#    // ???
#   identifier = "project-app-db"
#   engine = "mysql"
#   engine_version = "5.7.25"
#   instance_class = "db.t2.micro"
#   name = "flightsAlarm"
#   password = "zohar12345"
#   username = "admin"
#   storage_type = "standard"
#   allocated_storage = "20"
#   availability_zone = "us-east-1c"
#   vpc_security_group_ids = [ "${aws_security_group.rds-mysql-db.id}" ]
  
# }

# //???
# resource "aws_s3_bucket" "project-app-deploy_bucket" {
#   bucket = "project-app-deploy"
# }