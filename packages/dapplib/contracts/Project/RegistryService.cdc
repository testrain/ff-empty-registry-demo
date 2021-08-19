pub contract RegistryService {
    pub var totalSupply: UFix64

    pub resource interface IAuthFT {
        pub var balance: UFix64
    }
    // AuthFT
    // The AuthFT exists so an owner of a DappContract
    // can "register" with this RegistryService contract in order
    // to use contracts that exist within the Registry.
    //
    // This will only need to be acquired one time.
    // Ex. A new account comes to the Registry, gets this AuthFT,
    // and can now interact and retrieve Tenants from whatever
    // Registry contracts they want. They will never have to get another
    // AuthFT.
    //
    pub resource AuthFT: IAuthFT {
        pub var balance: UFix64

        init(balance: UFix64) {
            self.balance = balance

            RegistryService.totalSupply = RegistryService.totalSupply + self.balance
        }
    }

    // register
    // register gets called by someone who has never registered with 
    // RegistryService before.
    //
    // It returns a AuthFT.
    //
    pub fun register(): @AuthFT {        
        return <- create AuthFT(balance: 0.0)
    }

    // Named Paths
    //
    pub let AuthStoragePath: StoragePath

    init() {
        self.totalSupply = 0.0

        self.AuthStoragePath = /storage/RegistryServiceAuthFT
    }
} 
