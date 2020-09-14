output "lb_ip" {
    value = packet_device.lb.access_public_ipv4
}

output "ocp_vlan" {
    value = packet_vlan.ocp.vxlan
}