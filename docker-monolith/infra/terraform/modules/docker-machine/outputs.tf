output "docker-host_external_ip" {
  value = "${google_compute_instance.docker-machine.*.network_interface.0.access_config.0.assigned_nat_ip}"
}

#output "app_balancer_ip" {
#  value = "${google_compute_forwarding_rule.www-rule.ip_address}"
#}

