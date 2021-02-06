//data "aws_ssm_parameter" "linux_latest_ami" {
//  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
//}
//
//resource "aws_instance" "bastion" {
//  ami           = data.aws_ssm_parameter.linux_latest_ami.value
//  instance_type = "t2.micro"
//  key_name      = local.app_name
//
//  subnet_id              = aws_subnet.public.2.id
//  vpc_security_group_ids = [aws_security_group.public.id, aws_security_group.bastion.id]
//
//  tags = {
//    Project = local.app_name
//  }
//}
//
//output "ssh_tunnel_command" {
//  description = "To create an SSH tunnel using this bastion use the following command in commandline"
//  value = "ssh -i <path/to/pem-file.pem> -L <local-port>:<dns-name-to-db-instance>:<db-port> -t centos@${aws_instance.bastion.public_ip}"
//}

resource "aws_security_group" "bastion" {
  name        = "${local.app_name}-bastion-sg"
  description = "${local.app_name} security group for the bastion instance"
  vpc_id      = aws_vpc.main.id
}

resource "aws_security_group_rule" "in_SSH_from_anywhere" {
  security_group_id = aws_security_group.bastion.id
  type        = "ingress"
  protocol    = "tcp"
  from_port   = 22
  to_port     = 22
  cidr_blocks = ["0.0.0.0/0"]  # should narrow down to specific ip addresses if possible
}

resource "aws_security_group_rule" "out_SSH_to_priv_app" {
  security_group_id = aws_security_group.bastion.id
  type        = "egress"
  protocol    = "tcp"
  from_port   = 22
  to_port     = 22
  source_security_group_id = aws_security_group.priv_app.id
}

resource "aws_security_group_rule" "out_SSH_to_priv_data" {
  security_group_id = aws_security_group.bastion.id
  type        = "egress"
  protocol    = "tcp"
  from_port   = 22
  to_port     = 22
  source_security_group_id = aws_security_group.priv_data.id
}

resource "aws_security_group_rule" "out_to_anywhere" {
  security_group_id = aws_security_group.bastion.id
  type        = "egress"
  protocol    = -1
  from_port   = 0
  to_port     = 0
  cidr_blocks = ["0.0.0.0/0"]
}