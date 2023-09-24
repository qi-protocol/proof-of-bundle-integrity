* [Contract](https://github.com/qi-protocol/proof-of-bundle-integrity/tree/master/src)
* [Front-end](https://github.com/qi-protocol/proof-of-bundle-integrity/tree/master/axiom-starter)
* [Mock block builder](https://github.com/qi-protocol/proof-of-bundle-integrity/tree/master/mock-block-builder)

Proof of Bundle Integrity allows bundle senders to express exact slot he/she wants his/her bundle to be placed on a block and trustlessly prove whether a block builder has tempered with the bundle leveraging zero knowledge proof

To test the contracts, run
```
forge test
```

To run mock block builder, go  to the [Mock block builder](https://github.com/qi-protocol/proof-of-bundle-integrity/tree/master/mock-block-builder) directory and run
```
cargo run --bin mock-block-builder
```
to call the `stampBundle()` function run
```
cargo run --bin sender
```

To run the front end app locally, to to the * [Front-end](https://github.com/qi-protocol/proof-of-bundle-integrity/tree/master/axiom-starter) directory and run 
```
yarn dev
```
