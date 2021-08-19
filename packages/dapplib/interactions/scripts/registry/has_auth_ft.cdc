import RegistryService from Project.RegistryService

// Checks to see if an account has an AuthFT

pub fun main(tenant: Address): Bool {
    let hasAuthFT = getAccount(tenant).getCapability(RegistryService.AuthPublicPath)
                        .borrow<&RegistryService.AuthFT{RegistryService.IAuthFT}>()

    if hasAuthFT == nil {
        return false
    } else {
        return true
    }
}