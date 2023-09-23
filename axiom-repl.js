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