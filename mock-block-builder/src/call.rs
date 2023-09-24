use ethers::{
    core::rand::thread_rng,
    signers::{LocalWallet, Signer},
};

#[allow(dead_code)]
#[tokio::main]
async fn main() -> anyhow::Result<()> {
    let wallet = LocalWallet::new(&mut thread_rng());

    let wallet = wallet.with_chain_id(1337u64);
    println!("Wallet address: {}", wallet.address());
    Ok(())
}
