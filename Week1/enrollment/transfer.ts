import { getFullnodeUrl, SuiClient } from "@mysten/sui.js/client";
import { Ed25519Keypair } from "@mysten/sui.js/keypairs/ed25519";
import { TransactionBlock } from '@mysten/sui.js/transactions';
import wallet from "./dev-wallet.json"

// Import our dev wallet keypair from the wallet file
const keypair = Ed25519Keypair.fromSecretKey(new Uint8Array(wallet));

// Define our WBA SUI Address
const to = "0xa5b1611d756c1b2723df1b97782cacfd10c8f94df571935db87b7f54ef653d66";
const client = new SuiClient({ url: getFullnodeUrl("testnet") });

(async () => {
    try {
        //create Transaction Block.
        const txb = new TransactionBlock();
        //Split coins
        let [coin] = txb.splitCoins(txb.gas, [1000]);
        //Add a transferObject transaction
        txb.transferObjects([coin, txb.gas], to);
        let txid = await client.signAndExecuteTransactionBlock({ signer: keypair, transactionBlock: txb });
        console.log(`Success! Check our your TX here:
        https://suiexplorer.com/txblock/${txid.digest}?network=testnet`);
    } catch (e) {
        console.error(`Oops, something went wrong: ${e}`)
    }
})();

(async () => {
    try {
        //create Transaction Block.
        const txb = new TransactionBlock();
        //Add a transferObject transaction
        txb.transferObjects([txb.gas], to);
        let txid = await client.signAndExecuteTransactionBlock({ signer: keypair, transactionBlock: txb });
        console.log(`Success! Check our your TX here:
        https://suiexplorer.com/txblock/${txid.digest}?network=testnet`);
    } catch (e) {
        console.error(`Oops, something went wrong: ${e}`)
    }
})();