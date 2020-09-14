variable "depends" {
  type    = any
  default = null
}

variable "ssh_private_key_path" {}
variable "bastion_ip" {}
variable "count_master" {}
variable "count_compute" {}
variable "operating_system" {}
variable "cluster_name" {}
variable "cluster_basedomain" {}
variable "ocp_storage_nfs_enable" {}
variable "ocp_storage_ocs_enable" {}
variable "ocp_virtualization_enable" {}
variable "bootstrap_ip" {
  type = list
}
variable "master_ips" {
  type = list
}
variable "worker_ips" {
  type = list
}


locals {
  expanded_masters = <<-EOT
    %{ for i in range(length(var.master_ips)) ~} 
    server master-${i} ${element(var.master_ips, i)}:6443 check
    %{ endfor ~}
  EOT
  expanded_mcs = <<-EOT
    %{ for i in range(length(var.master_ips)) ~} 
    server master-${i} ${element(var.master_ips, i)}:22623 check
    %{ endfor ~}
  EOT
  expanded_compute_https = <<-EOT
    %{ for i in range(length(var.worker_ips)) ~}
    server worker-${i} ${element(var.worker_ips, i)}:443 check
    %{ endfor ~}
  EOT
  expanded_compute_http = <<-EOT
    %{ for i in range(length(var.worker_ips)) ~}
    server worker-${i} ${element(var.worker_ips, i)}:80 check
    %{ endfor ~}
  EOT
  expanded_masters_https = <<-EOT
    %{ for i in range(length(var.master_ips)) ~} 
    server master-${i} ${element(var.master_ips, i)}:443 check
    %{ endfor ~}
  EOT
  expanded_masters_http = <<-EOT
    %{ for i in range(length(var.master_ips)) ~} 
    server master-${i} ${element(var.master_ips, i)}:80 check
    %{ endfor ~}
  EOT
  expanded_masters_nfs = <<-EOT
    %{ for i in range(length(var.master_ips)) ~}
/mnt/nfs/ocp  ${element(var.master_ips, i)}(rw,async,no_subtree_check,no_root_squash)
    %{ endfor ~}
  EOT
  expanded_compute_nfs = <<-EOT
    %{ for i in range(length(var.worker_ips)) ~}
/mnt/nfs/ocp  ${element(var.worker_ips, i)}(rw,async,no_subtree_check,no_root_squash)
    %{ endfor ~}
  EOT
  expanded_masters_nfs_store01 = <<-EOT
    %{ for i in range(length(var.master_ips)) ~}
/mnt/nfs/store01  ${element(var.master_ips, i)}(rw,async,no_subtree_check,no_root_squash)
    %{ endfor ~}
  EOT
  expanded_compute_nfs_store01 = <<-EOT
    %{ for i in range(length(var.worker_ips)) ~}
/mnt/nfs/store01  ${element(var.worker_ips, i)}(rw,async,no_subtree_check,no_root_squash)
    %{ endfor ~}
  EOT
  expanded_masters_nfs_store02 = <<-EOT
    %{ for i in range(length(var.master_ips)) ~}
/mnt/nfs/store02  ${element(var.master_ips, i)}(rw,async,no_subtree_check,no_root_squash)
    %{ endfor ~}
  EOT
  expanded_compute_nfs_store02 = <<-EOT
    %{ for i in range(length(var.worker_ips)) ~}
/mnt/nfs/store02  ${element(var.worker_ips, i)}(rw,async,no_subtree_check,no_root_squash)
    %{ endfor ~}
  EOT
  expanded_masters_nfs_store03 = <<-EOT
    %{ for i in range(length(var.master_ips)) ~}
/mnt/nfs/store03  ${element(var.master_ips, i)}(rw,async,no_subtree_check,no_root_squash)
    %{ endfor ~}
  EOT
  expanded_compute_nfs_store03 = <<-EOT
    %{ for i in range(length(var.worker_ips)) ~}
/mnt/nfs/store03  ${element(var.worker_ips, i)}(rw,async,no_subtree_check,no_root_squash)
    %{ endfor ~}
  EOT
  expanded_masters_nfs_store04 = <<-EOT
    %{ for i in range(length(var.master_ips)) ~}
/mnt/nfs/store04  ${element(var.master_ips, i)}(rw,async,no_subtree_check,no_root_squash)
    %{ endfor ~}
  EOT
  expanded_compute_nfs_store04 = <<-EOT
    %{ for i in range(length(var.worker_ips)) ~}
/mnt/nfs/store04  ${element(var.worker_ips, i)}(rw,async,no_subtree_check,no_root_squash)
    %{ endfor ~}
  EOT

  expanded_bootstrap_api    = length(var.bootstrap_ip) >= 1 ? "server bootstrap-0 ${element(var.bootstrap_ip, 0)}:6443 check" : ""
  expanded_bootstrap_mcs    = length(var.bootstrap_ip) >= 1 ? "server bootstrap-0 ${element(var.bootstrap_ip, 0)}:22623 check" : ""

  haproxy_cfg_file      = "/etc/haproxy/haproxy.cfg"
  dhcpd_conf_file        = "/etc/dhcp/dhcpd.conf"
}

data "template_file" "haproxy_lb" {
    depends_on = [ var.depends ]
    template   = file("${path.module}/templates/haproxy.cfg.tpl")

  vars = {
    expanded_masters       = local.expanded_masters
    expanded_compute_http  = tonumber(var.count_compute) >= 1 ? local.expanded_compute_http : local.expanded_masters_http
    expanded_compute_https = tonumber(var.count_compute) >= 1 ? local.expanded_compute_https : local.expanded_masters_https
    expanded_mcs           = local.expanded_mcs
    expanded_bootstrap_api = local.expanded_bootstrap_api
    expanded_bootstrap_mcs = local.expanded_bootstrap_mcs
  }
}

data "template_file" "dhcpd_conf" {
    depends_on = [ var.depends ]
    template   = file("${path.module}/templates/dhcpd.conf.tpl")
}

resource "null_resource" "reconfig_lb" {

  depends_on = [ var.depends ]

  provisioner "file" {

    connection {
      private_key = file(var.ssh_private_key_path)
      host        = var.bastion_ip
    }

    content       = data.template_file.haproxy_lb.rendered
    destination   = local.haproxy_cfg_file
  }

  provisioner "remote-exec" {

    connection {
      private_key = file(var.ssh_private_key_path)
      host        = var.bastion_ip
    }

    inline = [
      "systemctl restart haproxy"
    ]
  }

}

resource "null_resource" "reconfig_dhcpd" {

  depends_on = [ var.depends ]

  provisioner "file" {

    connection {
      private_key = file(var.ssh_private_key_path)
      host        = var.bastion_ip
    }

    content       = data.template_file.dhcpd_conf.rendered
    destination   = local.dhcpd_conf_file
  }
}

resource "null_resource" "check_port" {
  depends_on = [ var.depends ]

  provisioner "remote-exec" {
    
    connection {
      private_key = file(var.ssh_private_key_path)
      host        = var.bastion_ip
    }

    inline = [<<EOT
      i=0;
      while [[ $(curl -k -s -o /dev/null -w ''%%{http_code}'' https://${length(var.bootstrap_ip) >= 1 ? "${element(var.bootstrap_ip, 0)}" : "${var.bastion_ip}"}:6443) != '403' ]]; do 
      ((i++));
      echo "Waiting for TCP6443 on bootstrap/API (Retrying $i of 1200)";
      sleep 2;
      if [[ $i -ge 1200 ]]; then 
      echo "Timeout exceed"; exit 1; 
      fi
      done
    EOT
    ]
  }

}


resource "null_resource" "ocp_installer_wait_for_bootstrap" {

  depends_on = [ null_resource.check_port ]

  provisioner "remote-exec" {

    connection {
      private_key = file(var.ssh_private_key_path)
      host        = var.bastion_ip
    }

    inline = [<<EOT
      while [ ! -f /root/ocp4upi/artifacts/install/auth/kubeconfig ]; do sleep 2; done; 
      /root/ocp4upi/artifacts/openshift-install --dir /root/ocp4upi/artifacts/install wait-for bootstrap-complete;
    EOT
    ]
  }
}

data "template_file" "nfs_exports" {
    template = <<-EOT
    ${local.expanded_masters_nfs}
    ${local.expanded_compute_nfs}
    ${local.expanded_masters_nfs_store01}
    ${local.expanded_compute_nfs_store01}
    ${local.expanded_masters_nfs_store02}
    ${local.expanded_compute_nfs_store02}
    ${local.expanded_masters_nfs_store03}
    ${local.expanded_compute_nfs_store03}
    ${local.expanded_masters_nfs_store04}
    ${local.expanded_compute_nfs_store04}
    EOT
}

resource "null_resource" "reconfig_nfs_exports" {

  depends_on = [var.depends]

  provisioner "file" {

    connection {
      private_key = file(var.ssh_private_key_path)
      host        = var.bastion_ip
    }

    content       = data.template_file.nfs_exports.rendered
    destination = "/etc/exports"
  }

  provisioner "remote-exec" {

    connection {
      private_key = file(var.ssh_private_key_path)
      host        = var.bastion_ip
    }

    inline = [
      "systemctl restart nfs-server",
      "exportfs -s"
    ]
  }

}

resource "null_resource" "ocp_bootstrap_cleanup" {
  depends_on = [null_resource.ocp_installer_wait_for_bootstrap]
  provisioner "remote-exec" {

    connection {
      private_key = file(var.ssh_private_key_path)
      host        = var.bastion_ip
    }

    inline = [
      "sed -i '/${element(var.bootstrap_ip, 0)}/d' ${local.haproxy_cfg_file}",
      "systemctl restart haproxy"
    ]
  }
}

resource "null_resource" "ocp_installer_wait_for_completion" {

  depends_on = [null_resource.ocp_installer_wait_for_bootstrap, null_resource.ocp_bootstrap_cleanup ]

  provisioner "remote-exec" {
   
    connection {
      private_key = file(var.ssh_private_key_path)
      host        = var.bastion_ip
    }

    inline = [<<EOT
      while [ ! -f /root/ocp4upi/artifacts/install/auth/kubeconfig ]; do sleep 2; done;
      /root/ocp4upi/artifacts/openshift-install --dir /root/ocp4upi/artifacts/install wait-for install-complete;
      mkdir -p ~/.kube || true;
      cp /root/ocp4upi/artifacts/install/auth/kubeconfig ~/.kube/config || true;
    EOT
    ]
  }
}

resource "null_resource" "ocp_approve_pending_csrs" {

  depends_on = [ null_resource.ocp_installer_wait_for_bootstrap, null_resource.ocp_bootstrap_cleanup ]

  provisioner "file" {

    connection {
      private_key = file(var.ssh_private_key_path)
      host        = var.bastion_ip
    }

    source       = "${path.module}/templates/ocp-approve-pending-csrs.sh"
    destination  = "/root/ocp4upi/artifacts/ocp-approve-pending-csrs.sh"
  }

  provisioner "remote-exec" {

    connection {
      private_key = file(var.ssh_private_key_path)
      host        = var.bastion_ip
    }
    inline        = [
      "chmod +x /root/ocp4upi/artifacts/ocp-approve-pending-csrs.sh",
      "/root/ocp4upi/artifacts/ocp-approve-pending-csrs.sh"
    ]
  
  }
}

resource "null_resource" "ocp_nfs_provisioner" {

  depends_on = [ null_resource.ocp_installer_wait_for_completion ]
  count      = var.ocp_storage_nfs_enable == true ? 1 : 0

  provisioner "file" {

    connection {
      private_key = file(var.ssh_private_key_path)
      host        = var.bastion_ip
    }

    source       = "${path.module}/templates/nfs-provisioner.sh"
    destination  = "/root/ocp4upi/artifacts/nfs-provisioner.sh"
  }

  provisioner "remote-exec" {
    
    connection {
      private_key = file(var.ssh_private_key_path)
      host        = var.bastion_ip
    }
    inline        = [
      "chmod +x /root/ocp4upi/artifacts/nfs-provisioner.sh",
      "/root/ocp4upi/artifacts/nfs-provisioner.sh /root/ocp4upi ${var.bastion_ip}"
    ]
  
  }
}

resource "null_resource" "ocp_internal_net" {

  depends_on = [ null_resource.ocp_nfs_provisioner ]

  provisioner "file" {

    connection {
      private_key = file(var.ssh_private_key_path)
      host        = var.bastion_ip
    }

    source       = "${path.module}/templates/internal-net.sh"
    destination  = "/root/ocp4upi/artifacts/internal-net.sh"
  }

  provisioner "remote-exec" {
    
    connection {
      private_key = file(var.ssh_private_key_path)
      host        = var.bastion_ip
    }
    inline        = [
      "chmod +x /root/ocp4upi/artifacts/internal-net.sh",
      "/root/ocp4upi/artifacts/internal-net.sh"
    ]
  
  }
}

output "finished" {
    depends_on = [null_resource.ocp_installer_wait_for_bootstrap, null_resource.ocp_bootstrap_cleanup, null_resource.ocp_installer_wait_for_completion, null_resource.ocp_internal_net ]
    value      = "OpenShift install wait and cleanup finished"
}

