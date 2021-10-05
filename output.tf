output "Public_IP" {
  value = openstack_compute_floatingip_v2.vm_floating_ip.address
}
