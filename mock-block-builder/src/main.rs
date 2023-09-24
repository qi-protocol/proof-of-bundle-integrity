mod sender;
use async_trait::async_trait;
use dotenv::dotenv;
use env_logger::Env;
use ethers::{
    contract::abigen,
    prelude::{MiddlewareBuilder, NonceManagerMiddleware, SignerMiddleware},
    providers::{Http, Middleware, Provider},
    signers::{coins_bip39::English, LocalWallet, MnemonicBuilder, Signer},
    types::{Address, TransactionRequest, U256},
    utils::{Geth, GethInstance},
};
use ethers_flashbots_test::relay::SendBundleResponse;
use jsonrpsee::server::ServerBuilder;
use jsonrpsee::{core::RpcResult, proc_macros::rpc};
use sender::BundleReq;
use std::sync::Arc;
use std::{ops::Mul, time::Duration};
use tempdir::TempDir;
use tracing_subscriber;

const SEED_PHRASE: &str = "test test test test test test test test test test test junk";

pub type SignerType<M> = NonceManagerMiddleware<SignerMiddleware<Arc<M>, LocalWallet>>;
abigen!(WETH, "src/abi/WETH.json",);
abigen!(ERC20, "src/abi/ERC20.json",);
abigen!(Proof, "src/abi/ProofOfIntegrity.json",);

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    env_logger::Builder::from_env(Env::default().default_filter_or("info")).init();

    if std::env::var("RUST_LOG").is_ok() {
        tracing_subscriber::fmt::init();
    }

    dotenv().ok();
    let (_geth, client): (_, SignerType<Provider<Http>>) = setup_geth().await?;
    let client = Arc::new(client);
    let _erc20 = deploy_weth(client.clone()).await?;
    let _weth = deploy_weth(client.clone()).await?;
    let _proof = deploy_proof(client.clone()).await?;

    let _ = std::thread::Builder::new()
        .name("mock-builder".to_string())
        .stack_size(128 * 1024 * 1024)
        .spawn(move || {
            let rt = tokio::runtime::Builder::new_multi_thread()
                .enable_all()
                .thread_stack_size(128 * 1024 * 1024)
                .build()
                .expect("Failed to create Tokio runtime");

            let _ = rt.block_on(async {
                log::info!("Starting ERC-4337 AA Bundler");

                let task = tokio::spawn(async move {
                    log::info!("Starting RPC server");
                    let server = ServerBuilder::new()
                        .build("127.0.0.1:3001".to_string())
                        .await
                        .map_err(|e| anyhow::anyhow!("Error starting server: {:?}", e))
                        .unwrap();

                    log::info!("Started RPC server at {}", server.local_addr().unwrap());

                    let mock_builder = MockBuilder::new(client.clone());

                    let _handle = server.start(mock_builder.into_rpc());

                    loop {
                        let stopped = _handle.is_stopped();
                        log::info!("The server is running: {}", !stopped);
                        tokio::time::sleep(tokio::time::Duration::from_secs(60)).await;
                    }

                    // Ok::<(), anyhow::Error>(())
                });
                let _ = task.await;
            });
            rt.block_on(async {
                let ctrl_c = tokio::signal::ctrl_c();
                tokio::select! {
                    _ = ctrl_c => {
                        println!("Ctrl+C received, shutting down");
                    }
                    else => {
                        println!("Server stopped unexpectedly");
                    }
                }
            });
        })?
        .join()
        .unwrap();
    Ok(())
}

pub struct DeployedContract<C> {
    contract: C,
    pub address: Address,
}

impl<C> DeployedContract<C> {
    pub fn new(contract: C, addr: Address) -> Self {
        Self {
            contract,
            address: addr,
        }
    }

    pub fn contract(&self) -> &C {
        &self.contract
    }
}

pub async fn setup_geth() -> anyhow::Result<(GethInstance, SignerType<Provider<Http>>)> {
    let chain_id: u64 = 1337;
    let tmp_dir = TempDir::new("test_geth")?;
    let wallet = MnemonicBuilder::<English>::default()
        .phrase(SEED_PHRASE)
        .build()?;

    let port = 8545u16;
    let geth = Geth::new()
        .data_dir(tmp_dir.path().to_path_buf())
        .port(port)
        .spawn();

    let provider = Arc::new(
        Provider::<Http>::try_from(geth.endpoint())?.interval(Duration::from_millis(10u64)),
    );

    let client = SignerMiddleware::new(provider.clone(), wallet.clone().with_chain_id(chain_id))
        .nonce_manager(wallet.address());

    let coinbase = client.get_accounts().await?[0];
    let tx = TransactionRequest::new()
        .to(wallet.address())
        .value(U256::from(10).pow(U256::from(18)).mul(100))
        .from(coinbase);
    provider.send_transaction(tx, None).await?.await?;
    Ok((geth, client))
}
pub async fn deploy_proof<M: Middleware + 'static>(
    client: Arc<M>,
) -> anyhow::Result<DeployedContract<Proof<M>>> {
    let (saf, receipt) = Proof::deploy(
        client,
        (
            "0xddd453864b2C7a56FC934F7F26A4e8c608B1A4a4".parse::<Address>()?,
            "0x8DdE5D4a8384F403F888E1419672D94C570440c9".parse::<Address>()?,
        ),
    )?
    .send_with_receipt()
    .await?;
    println!("saf:{:?}", saf);
    let addr = receipt.contract_address.unwrap_or(Address::zero());
    Ok(DeployedContract::new(saf, addr))
}
pub async fn deploy_weth<M: Middleware + 'static>(
    client: Arc<M>,
) -> anyhow::Result<DeployedContract<WETH<M>>> {
    let (saf, receipt) = WETH::deploy(client, ())?.send_with_receipt().await?;
    let addr = receipt.contract_address.unwrap_or(Address::zero());
    Ok(DeployedContract::new(saf, addr))
}
pub async fn deploy_erc20<M: Middleware + 'static>(
    client: Arc<M>,
) -> anyhow::Result<DeployedContract<ERC20<M>>> {
    let (saf, receipt) = ERC20::deploy(client, ())?.send_with_receipt().await?;
    let addr = receipt.contract_address.unwrap_or(Address::zero());
    Ok(DeployedContract::new(saf, addr))
}

#[derive(Debug, Clone)]
pub struct MockBuilder<M: Middleware + 'static + Send> {
    pub provider: Arc<M>,
}

impl<M: Middleware + 'static + Send> MockBuilder<M> {
    pub fn new(provider: Arc<M>) -> Self {
        Self { provider }
    }
}

#[rpc(server, namespace = "builder")]
pub trait BuilderApi {
    #[method(name = "receiveBundle")]
    async fn receive_bundle(&self, bundle: BundleReq) -> RpcResult<SendBundleResponse>;
}

#[async_trait]
impl<M: Middleware + 'static + Send> BuilderApiServer for MockBuilder<M> {
    // This always revert without inserting the block builder transaction
    async fn receive_bundle(&self, bundle: BundleReq) -> RpcResult<SendBundleResponse> {
        let tx = bundle.tx;
        let res = self
            .provider
            .call(&tx, None)
            .await
            .map_err(|e| anyhow::anyhow!("{:?}", e));
        println!("{:?}", res);
        println!("stampBundle() call's execution reverted. Block builder needs to call verifyBundle() first to verify the bundle");

        Ok(SendBundleResponse::default())
    }
}
