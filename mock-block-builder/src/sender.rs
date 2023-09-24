use ethers::contract::abigen;
use ethers::core::{rand::thread_rng, types::transaction::eip2718::TypedTransaction};
use ethers::prelude::*;
use ethers::signers::{coins_bip39::English, LocalWallet, MnemonicBuilder};
use ethers_flashbots_test::*;
use serde::{Deserialize, Serialize};
use serde_json::json;
use std::convert::TryFrom;
use std::sync::Arc;
use url::Url;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BundleReq {
    pub tx: TypedTransaction,
}
#[allow(dead_code)]
const SEED_PHRASE: &str = "test test test test test test test test test test test junk";
abigen!(Proof, "src/abi/ProofOfIntegrity.json",);

#[derive(Debug, Serialize)]
pub struct Request<T> {
    pub jsonrpc: String,
    pub id: u64,
    pub method: String,
    pub params: T,
}
#[derive(Debug, Deserialize)]
pub struct Response<R> {
    pub jsonrpc: String,
    pub id: u64,
    pub result: R,
}
#[allow(dead_code)]
#[tokio::main]
async fn main() -> anyhow::Result<()> {
    let provider = Provider::<Http>::try_from("http://localhost:8545")?;

    let bundle_signer = LocalWallet::new(&mut thread_rng());
    let wallet = MnemonicBuilder::<English>::default()
        .phrase(SEED_PHRASE)
        .build()?;

    let client = Arc::new(SignerMiddleware::new(
        FlashbotsMiddleware::new(
            provider,
            Url::parse("http://127.0.0.1:3001")?,
            bundle_signer,
        ),
        wallet,
    ));

    let proof = Proof::new(
        "0x9fe46736679d2d9a65f0992f2272de9f3c7fa6e0".parse::<Address>()?,
        client.clone(),
    );

    let stamp_bundle = proof
        .stamp_bundle(U256::from(1), U256::from(5), U256::from(0))
        .tx;

    let bundle_req = BundleReq { tx: stamp_bundle };

    let params = vec![json!(bundle_req)];
    let req_body = Request {
        jsonrpc: "2.0".to_string(),
        method: "builder_receiveBundle".to_string(),
        params: params.clone(),
        id: 1,
    };

    let client = reqwest::Client::new();
    let response = client
        .post("http://127.0.0.1:3001")
        .json(&req_body)
        .send()
        .await?;
    let _str_response = response.text().await?;

    Ok(())
}
