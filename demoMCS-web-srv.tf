resource "openstack_compute_keypair_v2" "web_test_key_kajken" {
  name       = "web_test_key_kajken"
  public_key = file("id_rsa.pub")
}

resource "openstack_compute_secgroup_v2" "http_icpm_allow" {
  name        = "http_icpm_allow"
  description = "Allow SSH and HTTP and ICMP"
  rule {
    from_port   = 80
    to_port     = 80
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }
  rule {
    from_port   = -1
    to_port     = -1
    ip_protocol = "icmp"
    cidr        = "0.0.0.0/0"
  }
}

resource "openstack_networking_network_v2" "web_test_network" {
  name           = "web_test_network"
  admin_state_up = "true"
}

resource "openstack_networking_subnet_v2" "web_test-sbnt" {
  name       = "web_test-subnet"
  network_id = openstack_networking_network_v2.web_test_network.id
  cidr       = "10.154.1.0/24"
  ip_version = 4
  dns_nameservers = [
    "8.8.8.8",
  "1.1.1.1"]
}
resource "openstack_networking_router_v2" "web_test-router" {
  name           = "web_test-router"
  admin_state_up = "true"
  ## ID находим с помощь #openstack network show -c id ext-net
  external_network_id = "298117ae-3fa4-4109-9e08-8be5602be5a2"
}
resource "openstack_networking_router_interface_v2" "terraform" {
  router_id = openstack_networking_router_v2.web_test-router.id
  subnet_id = openstack_networking_subnet_v2.web_test-sbnt.id
}
resource "openstack_compute_floatingip_v2" "vm_floating_ip" {
  pool = "ext-net"
}

resource "openstack_compute_instance_v2" "web_test_vm" {
  name       = "web_test_vm"
  image_name = "CentOS-7.7-202003"
  //  id образа #openstack image show -c id CentOS-7.7-202003
  image_id = "4525415d-df00-4f32-a434-b8469953fe3e"

  flavor_name       = "Basic-1-1-10"
  availability_zone = "DP1"
  key_pair          = openstack_compute_keypair_v2.web_test_key_kajken.name
  security_groups = [
  "${openstack_compute_secgroup_v2.http_icpm_allow.name}"]
  network {
    uuid = openstack_networking_network_v2.web_test_network.id
  }

  user_data = file("web.sh")
  block_device {
    //#openstack image show -c id CentOS-7.7-202003
    uuid                  = "4525415d-df00-4f32-a434-b8469953fe3e"
    source_type           = "image"
    volume_size           = 10
    boot_index            = 0
    destination_type      = "volume"
    delete_on_termination = true
  }
}
resource "openstack_compute_floatingip_associate_v2" "set_floating_ip" {
  floating_ip = openstack_compute_floatingip_v2.vm_floating_ip.address
  instance_id = openstack_compute_instance_v2.web_test_vm.id
}
