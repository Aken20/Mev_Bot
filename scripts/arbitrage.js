const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  const balance = await deployer.getBalance();
  console.log("Account balance:", ethers.utils.formatEther(balance));

  const ArbitrageBot = await ethers.getContractFactory("MEVArbitrageBot");
  const bot = await ArbitrageBot.deploy(
    "0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f", // Uniswap V2 Router Address
    "0xC02aaA39b223FE8D0A0E5C4F27eAD9083C756Cc2" // WETH address
  );
  await bot.deployed();

  console.log("MEV Arbitrage Bot deployed to:", bot.address);

  // Run an example arbitrage
  const tokenA = "0x6B175474E89094C44Da98b954EedeAC495271d0F"; // DAI
  const tokenB = "0xA0b86991c6218b36c1d19D4a2e9EB0cE3606eB48"; // USDC
  const amountIn = ethers.utils.parseEther("1.0");

  console.log("Starting arbitrage...");
  const tx = await bot.executeArbitrage(tokenA, tokenB, amountIn, { gasLimit: 3000000 });
  await tx.wait();

  console.log("Arbitrage complete");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
