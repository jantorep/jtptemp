#Domain Config
@(
    @{
        VMs                         = @(
            @{
                Name                  = "faDHCP01" 
                IP                    = "172.25.1.12"
                SysPrepVHDPath        = "D:\Scripts\Create-MasterVHD\VHD\WS2019_DC_Core_2004.vhdx"
                StartMemory = 2GB
                MinMemory = 2GB
                MaxMemory = 8GB
                JoinDomain = $false
            },
            @{
                Name                  = "faDHCP02" 
                IP                    = "172.25.1.13"
                SysPrepVHDPath        = "D:\Scripts\Create-MasterVHD\VHD\WS2019_DC_Core_2004.vhdx"
                StartMemory = 2GB
                MinMemory = 2GB
                MaxMemory = 8GB
                JoinDomain = $true
            },
            @{
                Name                  = "faWSUS01" 
                IP                    = "172.25.1.14"
                SysPrepVHDPath        = "D:\Scripts\Create-MasterVHD\VHD\WS2019_DC_GUI_2004.vhdx"
                StartMemory = 2GB
                MinMemory = 2GB
                MaxMemory = 8GB
                JoinDomain = $true
            },
            @{
                Name                  = "faRootCA01" 
                IP                    = "172.25.1.15"
                SysPrepVHDPath        = "D:\Scripts\Create-MasterVHD\VHD\WS2019_DC_GUI_2004.vhdx"
                StartMemory = 2GB
                MinMemory = 2GB
                MaxMemory = 8GB
                JoinDomain = $false     
            },
            @{
                Name                  = "faSUBCA01" 
                IP                    = "172.25.1.16"
                SysPrepVHDPath        = "D:\Scripts\Create-MasterVHD\VHD\WS2019_DC_GUI_2004.vhdx"
                StartMemory = 2GB
                MinMemory = 2GB
                MaxMemory = 8GB
                JoinDomain = $true     
            },
            @{
                Name                  = "faRDS01" 
                IP                    = "10.30.1.18"
                SysPrepVHDPath        = "D:\Scripts\Create-MasterVHD\VHD\WS2019_DC_GUI_2004.vhdx"
                StartMemory = 4GB
                MinMemory = 4GB
                MaxMemory = 16GB
                JoinDomain = $true
            },
            @{
                Name                  = "faRDS02" 
                IP                    = "10.30.1.19"
                SysPrepVHDPath        = "D:\Scripts\Create-MasterVHD\VHD\WS2019_DC_GUI_2004.vhdx"
                StartMemory = 4GB
                MinMemory = 4GB
                MaxMemory = 16GB
                JoinDomain = $true
            },
            @{
                Name                  = "faPKIWEB01" 
                IP                    = "172.25.1.17"
                SysPrepVHDPath        = "D:\Scripts\Create-MasterVHD\VHD\WS2019_DC_GUI_2004.vhdx"
                StartMemory = 2GB
                MinMemory = 2GB
                MaxMemory = 8GB
                JoinDomain = $true
            },
            @{
                Name                  = "faVMM01a" 
                IP                    = "172.25.1.30"
                SysPrepVHDPath        = "D:\Scripts\Create-MasterVHD\VHD\WS2019_DC_GUI_2004.vhdx"
                StartMemory = 6GB
                MinMemory = 6GB
                MaxMemory = 10GB
                JoinDomain = $true
            },
            @{
                Name                  = "faVMM01b" 
                IP                    = "172.25.1.31"
                SysPrepVHDPath        = "D:\Scripts\Create-MasterVHD\VHD\WS2019_DC_GUI_2004.vhdx"
                StartMemory = 6GB
                MinMemory = 6GB
                MaxMemory = 10GB
                JoinDomain = $true
            },
            @{
                Name                  = "faVMMSQL01a" 
                IP                    = "172.25.1.34"
                SysPrepVHDPath        = "D:\Scripts\Create-MasterVHD\VHD\WS2019_DC_GUI_2004.vhdx"
                StartMemory = 12GB
                MinMemory = 12GB
                MaxMemory = 12GB
                JoinDomain = $true
            },
            @{
                Name                  = "faVMMSQL01b" 
                IP                    = "172.25.1.35"
                SysPrepVHDPath        = "D:\Scripts\Create-MasterVHD\VHD\WS2019_DC_GUI_2004.vhdx"
                StartMemory = 12GB
                MinMemory = 12GB
                MaxMemory = 12GB
                JoinDomain = $true
            },
            @{
                Name                  = "faFILE01" 
                IP                    = "172.25.1.20"
                SysPrepVHDPath        = "D:\Scripts\Create-MasterVHD\VHD\WS2019_DC_GUI_2004.vhdx"
                StartMemory = 2GB
                MinMemory = 2GB
                MaxMemory = 8GB
                JoinDomain = $true
            },
            @{
                Name                  = "faSCOM01" 
                IP                    = "172.25.1.38"
                SysPrepVHDPath        = "D:\Scripts\Create-MasterVHD\VHD\WS2019_DC_GUI_2004.vhdx"
                StartMemory = 6GB
                MinMemory = 6GB
                MaxMemory = 10GB
                JoinDomain = $true
            },
            @{
                Name                  = "faSCOM02" 
                IP                    = "172.25.1.39"
                SysPrepVHDPath        = "D:\Scripts\Create-MasterVHD\VHD\WS2019_DC_GUI_2004.vhdx"
                StartMemory = 6GB
                MinMemory = 6GB
                MaxMemory = 10GB
                JoinDomain = $true
            },
            @{
                Name                  = "faSCOMRep01" 
                IP                    = "172.25.1.40"
                SysPrepVHDPath        = "D:\Scripts\Create-MasterVHD\VHD\WS2019_DC_GUI_2004.vhdx"
                StartMemory = 6GB
                MinMemory = 6GB
                MaxMemory = 10GB
                JoinDomain = $true
            },
            @{
                Name                  = "faSCOMSQL01a" 
                IP                    = "172.25.1.41"
                SysPrepVHDPath        = "D:\Scripts\Create-MasterVHD\VHD\WS2019_DC_GUI_2004.vhdx"
                StartMemory = 6GB
                MinMemory = 6GB
                MaxMemory = 10GB
                JoinDomain = $true
            },
            @{
                Name                  = "faSCOMSQL01b" 
                IP                    = "172.25.1.42"
                SysPrepVHDPath        = "D:\Scripts\Create-MasterVHD\VHD\WS2019_DC_GUI_2004.vhdx"
                StartMemory = 6GB
                MinMemory = 6GB
                MaxMemory = 10GB
                JoinDomain = $true
            }
        )
    }
)