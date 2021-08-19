import RegistryFTContract from Project.RegistryFTContract
import RegistryService from Project.RegistryService

// This transaction allows any Tenant to receive a Tenant Resource from
// RegistryFTContract. It saves the resource to account storage.
//
// Note that this can only be called by someone who has already registered
// with the RegistryService and received an AuthFT.

transaction() {

  prepare(signer: AuthAccount) {
    // save the Tenant resource to the account if it doesn't already exist
    if signer.borrow<&RegistryFTContract.Tenant>(from: RegistryFTContract.TenantStoragePath) == nil {
      // borrow a reference to the AuthFT in account storage
      let authFTRef = signer.borrow<&RegistryService.AuthFT>(from: RegistryService.AuthStoragePath)
                        ?? panic("Could not borrow the AuthFT")
      
      // save the new Tenant resource from RegistryFTContract to account storage
      signer.save(<-RegistryFTContract.instance(authFT: authFTRef), to: RegistryFTContract.TenantStoragePath)

      // link Tenant{ITenant} resource to public
      signer.link<&RegistryFTContract.Tenant{RegistryFTContract.ITenant}>(RegistryFTContract.TenantPublicPath, target: RegistryFTContract.TenantStoragePath)
      // link Tenant{ITenantAdmin} resource to private, as only the owner can mint / burn tokens.
      signer.link<&RegistryFTContract.Tenant{RegistryFTContract.ITenantAdmin}>(RegistryFTContract.TenantPrivatePath, target: RegistryFTContract.TenantStoragePath)
    }
  }

  execute {
    log("Registered a new Tenant for RegistryFTContract.")
  }
}
