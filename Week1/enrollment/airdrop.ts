import { Ed25519Keypair } from "@mysten/sui.js/keypairs/ed25519";
import { getFaucetHost, requestSuiFromFaucetV0 } from "@mysten/sui.js/faucet";
import { fromHEX } from "@mysten/bcs";

import wallet from "./wba-wallet.json"

// We're going to import our keypair from the wallet file
const keypair = Ed25519Keypair.fromSecretKey(fromHEX(wallet.privateKey));

(async () => {
    try {
        let res = await requestSuiFromFaucetV0({
            host: getFaucetHost("testnet"),
            recipient: keypair.toSuiAddress(),
        });
        console.log(`Success! Check our your TX here:
          https://suiscan.xyz/testnet/object/${res.transferredGasObjects[0].id}`);
    } catch (e) {
        console.error(`Oops, something went wrong: ${e}`)
    }
})();