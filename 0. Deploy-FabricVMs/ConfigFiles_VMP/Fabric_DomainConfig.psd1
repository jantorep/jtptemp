#Domain Config
@(
    @{
        CommonVMConfig = @(
            @{
                localAdminPassword = "Passw0rd"
                domainadminPassword = "Passw0rd"
                SourceVHD          = "D:\Scripts\Create-MasterVHD\VHD\WS2019_DC_GUI_2004.vhdx"
                VMRootPath         = "D:\VMs"
                VMSwitch           = "Standalone Switch"
                FabricVlan         = "200"
            }
        )
    },
    @{
        DomainControllers = @(
            @{
                Name      = "faDC01"
                IPAddress = "172.25.1.10"
                Subnet    = "24"
                Gateway   = "172.25.1.1"
            },
            @{
                Name      = "faDC02"
                IPAddress = "172.25.1.11"
                Subnet    = "24"
                Gateway   = "172.25.1.1"
            }
        )
    },
    @{
        DomainConfig = @(
            @{
                DomainName                    = "fabric.vinmonopolet.no"
                DomainNetbiosName             = "Fabric"
                SafeModeAdministratorPassword = "4X13nJRWJ0LZFbVfsa4rMTh3b1HDxGR8"
                RootDN                        = "DC=fabric,DC=vinmonopolet,DC=no"
                DefaultComputerOU             = "OU=Servers,OU=FABRIC"
                DefaultUserOU                 = "OU=Accounts,OU=FABRIC"
                OUs                           = @(
                    "OU=FABRIC",
                    "OU=Servers,OU=FABRIC",
                    "OU=HyperV,OU=Servers,OU=FABRIC",
                    "OU=Accounts,OU=FABRIC",
                    "OU=AdminAccounts,OU=Accounts,OU=FABRIC",
                    "OU=ServiceAccounts,OU=Accounts,OU=FABRIC",
                    "OU=xClarity,OU=ServiceAccounts,OU=Accounts,OU=FABRIC",
                    "OU=Users,OU=Accounts,OU=FABRIC",
                    "OU=Groups,OU=FABRIC",
                    "OU=LocalAdminGroups,OU=Groups,OU=FABRIC",
                    "OU=ServerGroups,OU=Groups,OU=FABRIC",
                    "OU=AdminGroups,OU=Groups,OU=FABRIC",
                    "OU=UserRoles,OU=Groups,OU=FABRIC"
                )
                Users                         = @(
                    @{
                        Name                  = "a-fa-SPIRVFR" 
                        AccountPassword       = "Passw0rd!"
                        Path                  = "OU=AdminAccounts,OU=Accounts,OU=FABRIC"
                        Description           = "EXTERNAL - Vidar Friid/Spirhed"
                        PasswordNeverExpires  = $false
                        ChangePasswordAtLogon = $true
                        CannotChangePassword  = $false
                        Enabled               = $true
                    },
                    @{
                        Name                  = "a-fa-SPIRGJTP" 
                        AccountPassword       = "Passw0rd!"
                        Path                  = "OU=AdminAccounts,OU=Accounts,OU=FABRIC"
                        Description           = "EXTERNAL - Jan-Tore Pedersen/Spirhed"
                        PasswordNeverExpires  = $false
                        ChangePasswordAtLogon = $true
                        CannotChangePassword  = $false
                        Enabled               = $true
                    },
                    @{
                        Name                  = "a-fa-PIB" 
                        AccountPassword       = "Passw0rd!"
                        Path                  = "OU=AdminAccounts,OU=Accounts,OU=FABRIC"
                        Description           = "EXTERNAL - Per-Ivar Bratbakken/Vinmonopolet"
                        PasswordNeverExpires  = $false
                        ChangePasswordAtLogon = $true
                        CannotChangePassword  = $false
                        Enabled               = $true
                    }
                )
                Groups                        = @(
                    @{
                        Name          = "WU_EveryMonday_03"
                        Path          = "OU=ServerGroups,OU=Groups,OU=FABRIC"
                        Description   = "Windows Update enforced every Monday at 03:00"
                        GroupCategory = "Security"
                        GroupScope    = "DomainLocal"
                        Members       = @()
                    },
                    @{
                        Name          = "WU_EveryWednesday_03"
                        Path          = "OU=ServerGroups,OU=Groups,OU=FABRIC"
                        Description   = "Windows Update enforced every Wednesday at 03:00"
                        GroupCategory = "Security"
                        GroupScope    = "DomainLocal"
                        Members       = @()
                    },
                    @{
                        Name          = "UR-FabricAdmin" 
                        Path          = "OU=UserRoles,OU=Groups,OU=FABRIC"
                        Description   = "User Role for fabric admins security group"
                        GroupCategory = "Security"
                        GroupScope    = "DomainLocal"
                        Members       = @("a-fa-SPIRVFR","a-fa-SPIRGJTP","a-fa-PIB")
                    },
                    @{
                        Name          = "UR-IaasTenant" 
                        Path          = "OU=UserRoles,OU=Groups,OU=FABRIC"
                        Description   = "User Role for fabric admins security group"
                        GroupCategory = "Security"
                        GroupScope    = "DomainLocal"
                        Members       = @()
                    },
                    @{
                        Name          = "ServerAdmins"
                        Path          = "OU=AdminGroups,OU=Groups,OU=FABRIC"
                        Description   = "Local admin on all servers"
                        GroupCategory = "Security"
                        GroupScope    = "DomainLocal"
                        Members       = @("UR-FabricAdmin")
                    },
                    @{
                        Name          = "Hyper-VAdmins"
                        Path          = "OU=AdminGroups,OU=Groups,OU=FABRIC"
                        Description   = "Local admin on all Hyper-V Servers"
                        GroupCategory = "Security"
                        GroupScope    = "DomainLocal"
                        Members       = @("UR-FabricAdmin")
                    },
                    @{
                        Name          = "LXCAAdmins" 
                        Path          = "OU=AdminGroups,OU=Groups,OU=FABRIC"
                        Description   = "Lenovo xClarity Administrators Admin group"
                        GroupCategory = "Security"
                        GroupScope    = "DomainLocal"
                        Members       = @("UR-FabricAdmin")
                    },
                    @{
                        Name          = "LAPSAdmins" 
                        Path          = "OU=AdminGroups,OU=Groups,OU=FABRIC"
                        Description   = "Can read LAPS Password"
                        GroupCategory = "Security"
                        GroupScope    = "DomainLocal"
                        Members       = @("UR-FabricAdmin")
                    }
                )
            }
        )
    }
)