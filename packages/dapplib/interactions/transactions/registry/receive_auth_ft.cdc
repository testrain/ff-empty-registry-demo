import RegistryService from Project.RegistryService

// Allows a Tenant to register with the RegistryService. It will
// save an AuthFT to account storage. Once an account
// has an AuthFT, they can then get Tenant Resources from any contract
// in the Registry.
//
// Note that this only ever needs to be called once per Tenant

transaction() {

    prepare(signer: AuthAccount) {
        // if this account doesn't already have an AuthFT...
        if signer.borrow<&RegistryService.AuthFT>(from: RegistryService.AuthStoragePath) == nil {
            // save a new AuthFT to account storage
            signer.save(<-RegistryService.register(), to: RegistryService.AuthStoragePath)

            // we only expose the IAuthFT interface so all this does is allow us to read
            // the balance inside the AuthFT reference
            signer.link<&RegistryService.AuthFT{RegistryService.IAuthFT}>(RegistryService.AuthPublicPath, target: RegistryService.AuthStoragePath)
        }
    }

    execute {

    }
}