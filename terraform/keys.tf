# This is used to generate SSH key pairs so that you can SSH into your ec2 resources

resource "tls_private_key" "rsa_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "key_pair" {
  key_name   = local.app_name
  public_key = tls_private_key.rsa_key.public_key_openssh
}

output "pem_key" {
  description = "Copy and paste this PEM key to a directory of your choosing"
  value = tls_private_key.rsa_key.private_key_pem
}


//# method of automatically saving PEM file to path of your choosing (not recommended)
//resource "local_file" "my_key_file" {
//  content  = tls_private_key.rsa_key.private_key_pem
//  filename = local.key_file
//
//  provisioner "local-exec" {
//    command = local.is_windows ? local.powershell : local.bash
//  }
//
//  provisioner "local-exec" {
//    command = local.is_windows ? local.powershell_ssh : local.bash_ssh
//  }
//}
//
//locals {
//  is_windows = substr(pathexpand("~"), 0, 1) == "/" ? false : true
//  key_file   = pathexpand("~/.ssh/vpc-reference-architecture.pem")
//}
//
//locals {
//  bash           = "chmod 400 ${local.key_file}"
//  bash_ssh       = "eval `ssh-agent` ; ssh-add -k ${local.key_file}"
//  powershell     = "icacls ${local.key_file} /inheritancelevel:r /grant:r johndoe:R"
//  powershell_ssh = "ssh-agent ; ssh-add -k ~/.ssh/vpc-reference-architecture.pem"
//}