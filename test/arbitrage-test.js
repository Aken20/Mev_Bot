const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("MEVArbitrageBot", function () {
  let bot, owner;

  beforeEach(async () => {
    [owner] = await ethers.getSigners();

    const ArbitrageBot = await ethers.getContractFactory("MEVArbitrageBot");
    bot = await ArbitrageBot.deploy(
      "0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f", // Uniswap V2 Router
      "0xC02aaA39b223FE8D0A0E5C4F27eAD9083C756Cc2" // WETH address
    );
    await bot.deployed();
  });

  it("Should execute an arbitrage and make a profit", async () => {
    const tokenA = "0x6B175474E89094C44Da98b954EedeAC495271d0F"; // DAI
    const tokenB = "0xA0b86991c6218b36c1d19D4a2e9EB0cE3606eB48"; // USDC
    const amountIn = ethers.utils.parseEther("1.0");

    const tx = await bot.executeArbitrage(tokenA, tokenB, amountIn);
    await tx.wait();

    const finalBalance = await ethers.provider.getBalance(bot.address);
    expect(finalBalance).to.be.gt(amountIn);
  });
});
