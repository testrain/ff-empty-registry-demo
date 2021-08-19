import FungibleToken from Flow.FungibleToken
import RegistryInterface from Project.RegistryInterface
import RegistryService from Project.RegistryService

pub contract RegistryFTContract: RegistryInterface, FungibleToken {

    // Maps an address (of the customer/DappContract) to the amount
    // of tenants they have for a specific RegistryContract.
    access(contract) var clientTenants: {Address: UInt64}
   

    pub resource interface ITenant {
        pub var totalSupply: UFix64
    }

    pub resource interface ITenantAdmin {
        pub fun adminRef(): &Administrator
        access(contract) fun updateTotalSupply(deltaAmount: Fix64)
    }

    // Tenant
    //
    // Requirement that all conforming multitenant smart contracts have
    // to define a resource called Tenant to store all data and things
    // that would normally be saved to account storage in the contract's
    // init() function
    //  
    pub resource Tenant: ITenant, ITenantAdmin {
        /// Total supply of FT this tenant holds
        pub var totalSupply: UFix64

        access(self) let admin: @Administrator

        access(contract) fun updateTotalSupply(deltaAmount: Fix64) {
            if (deltaAmount >= 0.0) {
                self.totalSupply = self.totalSupply + UFix64(deltaAmount)
            } else {
                self.totalSupply = self.totalSupply - UFix64(deltaAmount)
            }
        }

        pub fun adminRef(): &Administrator {
            return &self.admin as &Administrator
        }

        init() {
          self.totalSupply = 0.0
          self.admin <- create Administrator()
        }

        destroy() {
            destroy self.admin
        }
    }

    // instance
    // instance returns an Tenant resource.
    //
    pub fun instance(authFT: &RegistryService.AuthFT): @Tenant {
        let clientTenant = authFT.owner!.address
        if let count = self.clientTenants[clientTenant] {
            self.clientTenants[clientTenant] = self.clientTenants[clientTenant]! + (1 as UInt64)
        } else {
            self.clientTenants[clientTenant] = (1 as UInt64)
        }

        return <-create Tenant()
    }

    // getTenants
    // getTenants returns clientTenants.
    //
    pub fun getTenants(): {Address: UInt64} {
        return self.clientTenants
    }

    // Named Paths
    //
    pub let TenantStoragePath: StoragePath
    pub let TenantPublicPath: PublicPath
    pub let TenantPrivatePath: PrivatePath

    pub let VaultStoragePath: StoragePath
    pub let BalancePublicPath: PublicPath
    pub let ReceiverPublicPath: PublicPath


    /// Total supply of FTTokens in existence
    pub var totalSupply: UFix64

    /// TokensInitialized
    ///
    /// The event that is emitted when the contract is created
    pub event TokensInitialized(initialSupply: UFix64)

    /// TokensWithdrawn
    ///
    /// The event that is emitted when tokens are withdrawn from a Vault
    pub event TokensWithdrawn(amount: UFix64, from: Address?)

    /// TokensDeposited
    ///
    /// The event that is emitted when tokens are deposited to a Vault
    pub event TokensDeposited(amount: UFix64, to: Address?)

    /// TokensMinted
    ///
    /// The event that is emitted when new tokens are minted
    pub event TokensMinted(amount: UFix64)

    /// TokensBurned
    ///
    /// The event that is emitted when tokens are destroyed
    pub event TokensBurned(amount: UFix64)

    /// MinterCreated
    ///
    /// The event that is emitted when a new minter resource is created
    pub event MinterCreated(allowedAmount: UFix64)

    /// BurnerCreated
    ///
    /// The event that is emitted when a new burner resource is created
    pub event BurnerCreated()

    /// Vault
    ///
    /// Each user stores an instance of only the Vault in their storage
    /// The functions in the Vault and governed by the pre and post conditions
    /// in FungibleToken when they are called.
    /// The checks happen at runtime whenever a function is called.
    ///
    /// Resources can only be created in the context of the contract that they
    /// are defined in, so there is no way for a malicious user to create Vaults
    /// out of thin air. A special Minter resource needs to be defined to mint
    /// new tokens.
    ///
    pub resource Vault: FungibleToken.Provider, FungibleToken.Receiver, FungibleToken.Balance {

        /// The total balance of this vault
        pub var balance: UFix64

        // initialize the balance at resource creation time
        init(balance: UFix64) {
            self.balance = balance
        }

        /// withdraw
        ///
        /// Function that takes an amount as an argument
        /// and withdraws that amount from the Vault.
        ///
        /// It creates a new temporary Vault that is used to hold
        /// the money that is being transferred. It returns the newly
        /// created Vault to the context that called so it can be deposited
        /// elsewhere.
        ///
        pub fun withdraw(amount: UFix64): @FungibleToken.Vault {
            self.balance = self.balance - amount
            emit TokensWithdrawn(amount: amount, from: self.owner?.address)
            return <-create Vault(balance: amount)
        }

        /// deposit
        ///
        /// Function that takes a Vault object as an argument and adds
        /// its balance to the balance of the owners Vault.
        ///
        /// It is allowed to destroy the sent Vault because the Vault
        /// was a temporary holder of the tokens. The Vault's balance has
        /// been consumed and therefore can be destroyed.
        ///
        pub fun deposit(from: @FungibleToken.Vault) {
            let vault <- from as! @RegistryFTContract.Vault
            self.balance = self.balance + vault.balance
            emit TokensDeposited(amount: vault.balance, to: self.owner?.address)
            vault.balance = 0.0
            destroy vault
        }

        destroy() {
            RegistryFTContract.totalSupply = RegistryFTContract.totalSupply - self.balance
        }
    }

    /// createEmptyVault
    ///
    /// Function that creates a new Vault with a balance of zero
    /// and returns it to the calling context. A user must call this function
    /// and store the returned Vault in their storage in order to allow their
    /// account to be able to receive deposits of this token type.
    ///
    pub fun createEmptyVault(): @Vault {
        return <-create Vault(balance: 0.0)
    }

    pub resource Administrator {

        /// createNewMinter
        ///
        /// Function that creates and returns a new minter resource
        ///
        pub fun createNewMinter(allowedAmount: UFix64): @Minter {
            emit MinterCreated(allowedAmount: allowedAmount)
            return <-create Minter(allowedAmount: allowedAmount)
        }

        /// createNewBurner
        ///
        /// Function that creates and returns a new burner resource
        ///
        pub fun createNewBurner(): @Burner {
            emit BurnerCreated()
            return <-create Burner()
        }
    }

    /// Minter
    ///
    /// Resource object that token admin accounts can hold to mint new tokens.
    ///
    pub resource Minter {

        /// The amount of tokens that the minter is allowed to mint
        pub var allowedAmount: UFix64

        /// mintTokens
        ///
        /// Function that mints new tokens, adds them to the total supply,
        /// and returns them to the calling context.
        ///
        pub fun mintTokens(tenant: &Tenant{ITenantAdmin}, amount: UFix64): @RegistryFTContract.Vault {
            pre {
                amount > 0.0: "Amount minted must be greater than zero"
                amount <= self.allowedAmount: "Amount minted must be less than the allowed amount"
            }
            tenant.updateTotalSupply(deltaAmount: Fix64(amount))
            RegistryFTContract.totalSupply = RegistryFTContract.totalSupply + amount
            self.allowedAmount = self.allowedAmount - amount
            emit TokensMinted(amount: amount)
            return <-create Vault(balance: amount)
        }

        init(allowedAmount: UFix64) {
            self.allowedAmount = allowedAmount
        }
    }

    /// Burner
    ///
    /// Resource object that token admin accounts can hold to burn tokens.
    ///
    pub resource Burner {

        /// burnTokens
        ///
        /// Function that destroys a Vault instance, effectively burning the tokens.
        ///
        /// Note: the burned tokens are automatically subtracted from the
        /// total supply in the Vault destructor.
        ///
        pub fun burnTokens(tenant: &Tenant{ITenantAdmin}, from: @FungibleToken.Vault) {
            let vault <- from as! @RegistryFTContract.Vault
            let amount = vault.balance
            destroy vault
            tenant.updateTotalSupply(deltaAmount: -Fix64(amount))
            emit TokensBurned(amount: amount)
        }
    }

    init() {
        self.totalSupply = 0.0

        // Initialize clientTenants
        self.clientTenants = {}

        // Set Named paths
        self.TenantStoragePath = /storage/RegistryFTContractTenant
        self.TenantPublicPath = /public/RegistryFTContractTenant
        self.TenantPrivatePath = /private/RegistryFTContractTenant

        self.VaultStoragePath = /storage/RegistryContractFTVault
        self.BalancePublicPath = /public/RegistryContractFTBalance
        self.ReceiverPublicPath = /public/RegistryContractFTReceiver

        emit TokensInitialized(initialSupply: self.totalSupply)
    }
}