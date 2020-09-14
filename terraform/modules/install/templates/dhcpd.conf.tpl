default-lease-time 600;         # 10 minutes
max-lease-time 7200;            # 2  hours

        subnet 192.168.2.0 netmask 255.255.255.0 {

        option domain-name              "example.local.dc";
        option routers                  192.168.2.1;
        option broadcast-address        192.168.2.255;
        option subnet-mask              255.255.255.0;
        option domain-name-servers      8.8.8.8;
        option domain-search            "example.local.dc";

        pool {
                range 192.168.2.100 192.168.2.254;
                # Static entries
                host server00 { hardware ethernet 52:54:00:2d:ed:11; fixed-address 192.168.2.9; }
                host server01 { hardware ethernet 52:54:00:dc:4d:e6; fixed-address 192.168.2.10; option host-name "server01.example.local.dc";}
                host server02 { hardware ethernet 52:54:00:f6:80:fc; fixed-address 192.168.2.11; option host-name "server02.example.local.dc";}
                host server03 { hardware ethernet 52:54:00:1f:65:19; fixed-address 192.168.2.12; option host-name "server03.example.local.dc";}
                host server04 { hardware ethernet 52:54:00:27:3d:c1; fixed-address 192.168.2.30; option host-name "server04.example.local.dc";}
                host server05 { hardware ethernet 52:54:00:5f:4b:27; fixed-address 192.168.2.31; option host-name "server05.example.local.dc";}
                allow unknown-clients;
                next-server 192.168.2.2;
        if exists user-class and option user-class = "iPXE" {
            filename "http://192.168.2.2:8080/boot.ipxe";
        } else {
            filename "undionly.kpxe";
        }
        }
}