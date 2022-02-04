output "OpenStack-URL" {
  value = "http://${aws_instance.openstack.public_ip}/"
}

output "Credentials" {
    value = "User: admin/demo - Password: nomoresecret"
}