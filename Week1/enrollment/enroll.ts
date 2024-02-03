import { getFullnodeUrl, SuiClient } from "@mysten/sui.js/client";
import { Ed25519Keypair } from "@mysten/sui.js/keypairs/ed25519";
import { bcs } from "@mysten/sui.js/bcs";
import { TransactionBlock } from '@mysten/sui.js/transactions';
import wallet from "./wba-wallet.json"
import { fromHEX } from "@mysten/bcs";

const keypair = Ed25519Keypair.fromSecretKey(fromHEX(wallet.privateKey));
const client = new SuiClient({ url: getFullnodeUrl("testnet") });

const enrollment_object_id = "0x5927f2574f0a5e2afa574e24bca462269d31cf29bdd2215d908b90b691ea5747";
const cohort = "0xa85910892fca1bedde91ec6a1379bcf71f4106adbe390ccd67fb696c802d99ab";

const txb = new TransactionBlock();
const github = new Uint8Array(Buffer.from("iamknownasfesal"));
let serialized_github = txb.pure(bcs.vector(bcs.u8()).serialize(github), "vector<u8>");

txb.moveCall({
    target: `${enrollment_object_id}::enrollment::enroll`,
    arguments: [txb.object(cohort), serialized_github],
});

(async () => {
    let txid = await client.signAndExecuteTransactionBlock({ signer: keypair, transactionBlock: txb });
    console.log(`Success! Check our your TX here: https://suiexplorer.com/txblock/${txid.digest}?network=testnet`);
})();