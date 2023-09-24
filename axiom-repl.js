let tx1 = getTx(blockBuilderTxHash);
let tx1_idx = tx1.txIdx().toCircuitValue();
let tx1_blocknumber = tx1.blockNumber().toCircuitValue();
let tx2 = getTx(bundleSenderTxHash);
let tx2_idx = tx2.txIdx();
let bundleSize = sub(tx2_idx.toCircuitValue(), tx1_idx);
addToCallback(bundleSize);
addToCallback(tx1_idx);
addToCallback(tx1_blocknumber);
addToCallback(senderAddress);


{
    "blockBuilderTxHash": "0x56694dfa0b92f3745a575d94a214610e9eedb8e7d07b3fb972bdbb3057e3664d",
    "senderAddress": "0x2e895C036c6DFb475b514B7B8E7eCC278E03dF47",
    "bundleSenderTxHash": "0x6b1662e729cf0174f6e916b2a5869313935d3178b37b28e1b222ea740e2a37e0"
}
