import FungibleToken from Flow.FungibleToken
import RegistryFTContract from Registry.RegistryFTContract

pub fun main(deployedAddr: Address): UFix64 {
    let tenantRef = getAccount(deployedAddr)
        .getCapability(RegistryFTContract.TenantPublicPath)
        .borrow<&RegistryFTContract.Tenant{RegistryFTContract.ITenant}>()
        ?? panic("cannot borrow reference to ITenant");

    return tenantRef.totalSupply
}