import FungibleToken from Flow.FungibleToken
import RegistryFTContract from Registry.RegistryFTContract

pub fun main(account: Address): UFix64 {
    let vaultRef = getAccount(account).getCapability(RegistryFTContract.BalancePublicPath)
        .borrow<&RegistryFTContract.Vault{FungibleToken.Balance}>()
        ?? panic("Could not borrow Balance reference to the Vault")

    return vaultRef.balance
}