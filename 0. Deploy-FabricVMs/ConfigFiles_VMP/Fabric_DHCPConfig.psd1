#DHCP Config
@(
    @{
        DHCPServers = @(
            @{
                Name = "faDC01"
            },
            @{
                Name = "faDC02"
            }
        )
    },
    @{
        Scopes = @(
            @{
                Name            = "Fabric Management - VLAN200"
                StartRange      = "172.25.1.200"
                EndRange        = "172.25.1.240"
                SubnetMask      = "255.255.255.0"
                DefaultGW       = "172.25.1.1"
                DNSServers      = @("172.25.1.10", "172.25.1.11")
                DNSDomain       = "fabric.vinmonopolet.no"
                FailoverReplica = $true
            },
            @{
                Name            = "Hyper-V Management - VLAN 1003"
                StartRange      = "172.25.3.170"
                EndRange        = "172.25.3.230"
                SubnetMask      = "255.255.255.0"
                DefaultGW       = "172.25.3.1"
                DNSServers      = @("172.25.1.10", "172.25.1.11")
                DNSDomain       = "fabric.vinmonopolet.no"
                FailoverReplica = $true
            }
        )
    }
)