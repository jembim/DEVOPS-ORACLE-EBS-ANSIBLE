provider "opc" {
  user = "${var.user}"
  password = "${var.password}"
  identity_domain = "${var.domain}"
  endpoint = "${var.endpoint}"
}

resource "opc_compute_storage_volume" "volume" {
        size = "${var.boot_storage_size}"
        description = "${var.instance_name} Storage"
        name = "${var.instance_name}_Boot_Storage"
        bootable = true
        image_list = "${var.image_list}"
        image_list_entry = "${var.image_list_entry}"
}

resource "opc_compute_storage_volume" "volume2" {
  size        = "${var.storage_size}"
  description = "${var.instance_name} Storage"
  name        = "${var.instance_name}_Storage"
}

resource "opc_compute_ip_reservation" "reservation" {
  name = "${var.instance_name}_ip"
  parent_pool = "/oracle/public/ippool"
  permanent   = true
  tags        = [ "${var.instance_name}_ip" ]
}

resource "opc_compute_instance" "instance" {
        name = "${var.instance_name}"
        label = "${var.instance_name}"
        image_list = "${var.image_list}"
        shape = "${var.shape}"
        ssh_keys = [ "${var.sshkey}" ]
        networking_info {
                index = 0
                shared_network = true
                nat = ["${opc_compute_ip_reservation.reservation.name}"]
                sec_lists = [ "${var.ssh_seclist}" ]
                sec_lists = [ "${var.http_seclist}" ]
                sec_lists = [ "${var.https_seclist}" ]
                sec_lists = [ "${var.wls_seclist}" ]
        }
        storage {
                index = 1
                volume = "${opc_compute_storage_volume.volume.name}"
        }

        storage {
                index  = 2
                volume = "${opc_compute_storage_volume.volume2.name}"
		    }

        boot_order = [ 1 ]
}