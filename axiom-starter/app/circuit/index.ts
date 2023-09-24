import { Halo2Lib, Halo2Data } from "@axiom-crypto/halo2-js";
import { CircuitInputs } from "./constants";

export const circuit = async (
  halo2Lib: Halo2Lib,
  halo2Data: Halo2Data,
  { blockBuilderTxHash, senderAddress, bundleSenderTxHash }: CircuitInputs
) => {
  const {
    constant,
    add,
    sub,
    and,
    or,
    assertEqual,
    checkLessThan,
    addToCallback,
    log,
  } = halo2Lib;
  const {
    getAccount,
    getReceipt,
    getStorage,
    getTx,
    getHeader,
    getSolidityMapping,
    circuit
  } = halo2Data;
  // example Axiom REPL circuit to prove the first block an account transacted
  // get the previous block number
  // const prevBlock = sub(claimedBlockNumber, constant(1));

  //get the account at the previous block
  // const accountPrevBlock = getAccount(prevBlock, address);

  // // get the account nonce at the previous block and assert that it is 0
  // const prevNonce = accountPrevBlock.nonce().toCircuitValue();
  // assertEqual(prevNonce, constant(0))

  // // get the account nonce at the claimed block number
  // const account = getAccount(claimedBlockNumber, address);
  // const currNonce = account.nonce().toCircuitValue();

  // //checks that currNonce > 0 at the claimed block
  // checkLessThan(constant(0), currNonce)

  // // add the address and blockNumber to the callback, for it to be passed
  // // as a result to the callback client contract
  // addToCallback(address)
  // addToCallback(claimedBlockNumber);

  // // Here is a list of all the data fetching APIs you can use in the REPL:

  // // fetch block header data
  // let header = getHeader(block);
  // let timestamp = header.timestamp();
  // let gasLimit = header.gasLimit();
  // // addToCallback(gasLimit);

  // // fetch account data
  // let acct = getAccount(block, addr);
  // let balance = acct.balance();
  // let nonce = acct.nonce();
  // // addToCallback(nonce);

  // // fetch storage data
  // let storage = getStorage(block, addr);
  // let slotVal = storage.slot(slot);
  // // addToCallback(slotVal);

  // // fetch Solidity mapping data
  // let mapping = getSolidityMapping(block, addr, mappingSlot);
  // let mappingVal = mapping.key(3);
  // mapping.nested()
  // addToCallback(mappingVal);

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

  // fetch receipt data
  // Deposit (index_topic_1 address payor, uint256 amt)
  // https://goerli.etherscan.io/tx/0xa4f781ad033d6dab5b13e3ab7c7cbdbd0ea4c0a2be3d9ffa7ed1e53d2d5bcc46
  // const eventSchema = "0xe1fffcc4923d04b559f4d29a8bfc6cda04eb5b0d3c460751c2402c5c5cc9109c";
  // let receipt = getReceipt(txHash);
  // let logVal = receipt.log(0);
  // let logAddr = logVal.address();
  // let topic = logVal.topic(1, eventSchema);
  // let data = logVal.data(0);
  // addToCallback(topic);
  // addToCallback(data);
};
