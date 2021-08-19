import RegistryFTContract from Registry.RegistryFTContract
import FungibleToken from Flow.FungibleToken

transaction {
    prepare(signer: AuthAccount) {
        if signer.borrow<&RegistryFTContract.Vault>(from: RegistryFTContract.VaultStoragePath) == nil {
            signer.save(<-RegistryFTContract.createEmptyVault(), to: RegistryFTContract.VaultStoragePath);

            // link balance interface to public
            signer.link<&RegistryFTContract.Vault{FungibleToken.Balance}>(
                RegistryFTContract.BalancePublicPath,
                target: RegistryFTContract.VaultStoragePath
            );
            // link receiver interface to public
            signer.link<&RegistryFTContract.Vault{FungibleToken.Receiver}>(
                RegistryFTContract.ReceiverPublicPath,
                target: RegistryFTContract.VaultStoragePath
            );
        }
    }
}