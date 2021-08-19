import RegistryFTContract from Registry.RegistryFTContract
import FungibleToken from Flow.FungibleToken

transaction(recipient: Address, amount: UFix64) {
    let tenantAdminRef: &RegistryFTContract.Tenant{RegistryFTContract.ITenantAdmin}
    let receiverRef: &RegistryFTContract.Vault{FungibleToken.Receiver}

    prepare(signer: AuthAccount) {
        self.tenantAdminRef = signer
            .getCapability(RegistryFTContract.TenantPrivatePath)
            .borrow<&RegistryFTContract.Tenant{RegistryFTContract.ITenantAdmin}>()
            ?? panic("could not get tenant reference as ITenantAdmin")
        self.receiverRef = getAccount(recipient)
            .getCapability(RegistryFTContract.ReceiverPublicPath)
            .borrow<&RegistryFTContract.Vault{FungibleToken.Receiver}>()
            ?? panic("could not get receiver reference to the FungibleToken.Receiver")
    }

    execute {
        let minter <- self.tenantAdminRef.adminRef().createNewMinter(allowedAmount: amount)
        let mintedVault <- minter.mintTokens(tenant: self.tenantAdminRef, amount: amount)
        self.receiverRef.deposit(from: <-mintedVault)
        destroy minter
    }
}