const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Withdrawal allowed for other chains not mapped to user", function () {
  let mockUSDT, mockGPU, usdtVault, gpuVault;
  let deployer, orderbook, user1, user2, user3, attacker;
  
  // Test amounts
  const USDT_AMOUNT = ethers.parseUnits("1000", 6); // 1000 USDT (6 decimals)
  const GPU_AMOUNT = ethers.parseEther("100"); // 100 GPU (18 decimals)
  
  beforeEach(async function () {
    console.log("🚀 Setting up enhanced test environment...");
    
    // Get signers
    [deployer, orderbook, user1, user2, user3, attacker] = await ethers.getSigners();
    
    console.log("👥 Test accounts:");
    console.log("  Deployer:", deployer.address);
    console.log("  Orderbook:", orderbook.address);
    console.log("  User1:", user1.address);
    console.log("  User2:", user2.address);
    console.log("  User3:", user3.address);
    
    // Deploy mock tokens
    console.log("🪙 Deploying mock tokens...");
    
    const MockUSDT = await ethers.getContractFactory("MockUSDT");
    mockUSDT = await MockUSDT.deploy(deployer.address);
    await mockUSDT.waitForDeployment();
    console.log("  MockUSDT:", await mockUSDT.getAddress());
    
    const MockGPU = await ethers.getContractFactory("MockGPU");
    mockGPU = await MockGPU.deploy(deployer.address);
    await mockGPU.waitForDeployment();
    console.log("  MockGPU:", await mockGPU.getAddress());
    
    // Deploy enhanced vaults
    console.log("🏦 Deploying enhanced vaults...");
    
    const USDTVault = await ethers.getContractFactory("USDTVault");
    usdtVault = await USDTVault.deploy(await mockUSDT.getAddress());
    await usdtVault.waitForDeployment();
    console.log("  Enhanced USDTVault:", await usdtVault.getAddress());
    
    const GPUVault = await ethers.getContractFactory("GPUVault");
    gpuVault = await GPUVault.deploy(await mockGPU.getAddress());
    await gpuVault.waitForDeployment();
    console.log("  Enhanced GPUVault:", await gpuVault.getAddress());
    
    // Set orderbook addresses
    console.log("⚙️ Configuring orderbook...");
    await usdtVault.setOrderbook(orderbook.address);
    await gpuVault.setOrderbook(orderbook.address);
    
    // Mint tokens to users
    console.log("💰 Minting test tokens...");
    await mockUSDT.mint(user1.address, USDT_AMOUNT * 10n);
    await mockUSDT.mint(user2.address, USDT_AMOUNT * 10n);
    await mockUSDT.mint(user3.address, USDT_AMOUNT * 10n);
    
    await mockGPU.mint(user1.address, GPU_AMOUNT * 10n);
    await mockGPU.mint(user2.address, GPU_AMOUNT * 10n);
    await mockGPU.mint(user3.address, GPU_AMOUNT * 10n);
    
    console.log("✅ Enhanced test setup completed\n");
  });

  describe("🔄 Cross-User Balance Transfer Tests", function () {
    
    it("Should transfer locked balance between users", async function () {
      console.log("🔄 Testing transferLocked functionality...");
      
      // User1 deposits USDT
      await mockUSDT.connect(user1).approve(await usdtVault.getAddress(), USDT_AMOUNT);
      await usdtVault.connect(user1).deposit(USDT_AMOUNT);
      
      console.log("  ✅ User1 deposited", ethers.formatUnits(USDT_AMOUNT, 6), "USDT");
      expect(await usdtVault.lockedBalances(user1.address)).to.equal(USDT_AMOUNT);
      expect(await usdtVault.lockedBalances(user2.address)).to.equal(0);
      
      // Orderbook transfers locked balance from User1 to User2
      await expect(usdtVault.connect(orderbook).transferLocked(user1.address, user2.address, USDT_AMOUNT))
        .to.emit(usdtVault, "LockedTransfer")
        .withArgs(user1.address, user2.address, USDT_AMOUNT, await getLatestTimestamp() + 1);
      
      console.log("  ✅ Locked balance transferred User1 → User2");
      
      // Verify transfer
      expect(await usdtVault.lockedBalances(user1.address)).to.equal(0);
      expect(await usdtVault.lockedBalances(user2.address)).to.equal(USDT_AMOUNT);
      
      console.log("  Final locked balances:");
      console.log("    User1:", ethers.formatUnits(await usdtVault.lockedBalances(user1.address), 6), "USDT");
      console.log("    User2:", ethers.formatUnits(await usdtVault.lockedBalances(user2.address), 6), "USDT");
    });

    it("Should use transferAndUnlock for gas optimization", async function () {
      console.log("⚡ Testing transferAndUnlock (gas optimized)...");
      
      // User1 deposits GPU
      await mockGPU.connect(user1).approve(await gpuVault.getAddress(), GPU_AMOUNT);
      await gpuVault.connect(user1).deposit(GPU_AMOUNT);
      
      // One transaction: transfer locked balance from User1 to User2 and unlock it
      await expect(gpuVault.connect(orderbook).transferAndUnlock(user1.address, user2.address, GPU_AMOUNT))
        .to.emit(gpuVault, "LockedTransfer")
        .withArgs(user1.address, user2.address, GPU_AMOUNT, await getLatestTimestamp() + 1)
        .and.to.emit(gpuVault, "Unlock")
        .withArgs(user2.address, GPU_AMOUNT, await getLatestTimestamp() + 1);
      
      console.log("  ✅ Transfer and unlock completed in one transaction");
      
      // Verify: User1 has no balance, User2 has unlocked balance ready for withdrawal
      expect(await gpuVault.lockedBalances(user1.address)).to.equal(0);
      expect(await gpuVault.lockedBalances(user2.address)).to.equal(0);
      expect(await gpuVault.unlockedBalances(user2.address)).to.equal(GPU_AMOUNT);
      
      console.log("  User2 can now withdraw:", ethers.formatEther(await gpuVault.unlockedBalances(user2.address)), "GPU");
    });

    it("Should prevent unauthorized transfers", async function () {
      console.log("🛡️ Testing transfer security...");
      
      await mockUSDT.connect(user1).approve(await usdtVault.getAddress(), USDT_AMOUNT);
      await usdtVault.connect(user1).deposit(USDT_AMOUNT);
      
      // User tries to transfer their own balance (should fail)
      await expect(usdtVault.connect(user1).transferLocked(user1.address, user2.address, USDT_AMOUNT))
        .to.be.revertedWith("USDTVault: Only Orderbook can call this");
      
      // Attacker tries to transfer someone else's balance (should fail)
      await expect(usdtVault.connect(attacker).transferLocked(user1.address, attacker.address, USDT_AMOUNT))
        .to.be.revertedWith("USDTVault: Only Orderbook can call this");
      
      console.log("  ✅ Transfer security working correctly");
    });

    it("Should prevent self-transfers", async function () {
      await mockUSDT.connect(user1).approve(await usdtVault.getAddress(), USDT_AMOUNT);
      await usdtVault.connect(user1).deposit(USDT_AMOUNT);
      
      // Try to transfer to self (should fail)
      await expect(usdtVault.connect(orderbook).transferLocked(user1.address, user1.address, USDT_AMOUNT))
        .to.be.revertedWith("USDTVault: Cannot transfer to self");
      
      console.log("  ✅ Self-transfer prevention working");
    });
  });

  describe("🎯 Real Cross-Chain Trading Simulation", function () {
    
    it("Should execute complete USDT ↔ GPU cross-chain trade", async function () {
      console.log("\n🔄 REAL Cross-Chain Trade: User1 (USDT) ↔ User2 (GPU)");
      
      // === STEP 1: Initial Deposits ===
      console.log("\n📥 Step 1: Users deposit their assets");
      
      // User1 deposits USDT (wants to buy GPU)
      await mockUSDT.connect(user1).approve(await usdtVault.getAddress(), USDT_AMOUNT);
      await usdtVault.connect(user1).deposit(USDT_AMOUNT);
      console.log("  ✅ User1 deposited", ethers.formatUnits(USDT_AMOUNT, 6), "USDT");
      
      // User2 deposits GPU (wants to sell GPU for USDT)
      await mockGPU.connect(user2).approve(await gpuVault.getAddress(), GPU_AMOUNT);
      await gpuVault.connect(user2).deposit(GPU_AMOUNT);
      console.log("  ✅ User2 deposited", ethers.formatEther(GPU_AMOUNT), "GPU");
      
      // Verify initial state
      expect(await usdtVault.lockedBalances(user1.address)).to.equal(USDT_AMOUNT);
      expect(await gpuVault.lockedBalances(user2.address)).to.equal(GPU_AMOUNT);
      
      // === STEP 2: Virtual Trading (Your Rust Orderbook) ===
      console.log("\n💱 Step 2: Trade matching and execution");
      console.log("  📊 Virtual balances before trade:");
      console.log("    User1: 1000 USDT, 0 GPU (wants GPU)");
      console.log("    User2: 0 USDT, 100 GPU (wants USDT)");
      
      console.log("  🔄 Executing trade: 1000 USDT ↔ 100 GPU");
      
      // === STEP 3: Cross-User Balance Transfers ===
      console.log("\n🔄 Step 3: Cross-user balance transfers");
      
      // Transfer User1's USDT to User2 and unlock for withdrawal
      await usdtVault.connect(orderbook).transferAndUnlock(user1.address, user2.address, USDT_AMOUNT);
      console.log("  ✅ User1's USDT → User2 (unlocked for withdrawal)");
      
      // Transfer User2's GPU to User1 and unlock for withdrawal  
      await gpuVault.connect(orderbook).transferAndUnlock(user2.address, user1.address, GPU_AMOUNT);
      console.log("  ✅ User2's GPU → User1 (unlocked for withdrawal)");
      
      // === STEP 4: Verify Post-Trade Balances ===
      console.log("\n📊 Step 4: Verify balances after trade execution");
      
      // User1 should have GPU unlocked for withdrawal
      expect(await gpuVault.unlockedBalances(user1.address)).to.equal(GPU_AMOUNT);
      expect(await gpuVault.lockedBalances(user1.address)).to.equal(0);
      console.log("  ✅ User1 has", ethers.formatEther(GPU_AMOUNT), "GPU ready for withdrawal");
      
      // User2 should have USDT unlocked for withdrawal
      expect(await usdtVault.unlockedBalances(user2.address)).to.equal(USDT_AMOUNT);
      expect(await usdtVault.lockedBalances(user2.address)).to.equal(0);
      console.log("  ✅ User2 has", ethers.formatUnits(USDT_AMOUNT, 6), "USDT ready for withdrawal");
      
      // === STEP 5: Users Withdraw Their Traded Assets ===
      console.log("\n💸 Step 5: Users withdraw their traded assets");
      
      // Get balances before withdrawal
      const user1GpuBefore = await mockGPU.balanceOf(user1.address);
      const user2UsdtBefore = await mockUSDT.balanceOf(user2.address);
      
      // User1 withdraws GPU (what they wanted)
      await gpuVault.connect(user1).withdraw(GPU_AMOUNT);
      console.log("  ✅ User1 withdrew", ethers.formatEther(GPU_AMOUNT), "GPU");
      
      // User2 withdraws USDT (what they wanted)
      await usdtVault.connect(user2).withdraw(USDT_AMOUNT);
      console.log("  ✅ User2 withdrew", ethers.formatUnits(USDT_AMOUNT, 6), "USDT");
      
      // === STEP 6: Verify Final Balances ===
      console.log("\n🎉 Step 6: Verify successful trade completion");
      
      // User1 should have received GPU
      const user1GpuAfter = await mockGPU.balanceOf(user1.address);
      expect(user1GpuAfter).to.equal(user1GpuBefore + GPU_AMOUNT);
      console.log("  ✅ User1 final GPU balance:", ethers.formatEther(user1GpuAfter));
      
      // User2 should have received USDT
      const user2UsdtAfter = await mockUSDT.balanceOf(user2.address);
      expect(user2UsdtAfter).to.equal(user2UsdtBefore + USDT_AMOUNT);
      console.log("  ✅ User2 final USDT balance:", ethers.formatUnits(user2UsdtAfter, 6));
      
      // Verify vaults are empty for these users
      expect(await usdtVault.getTotalBalance(user1.address)).to.equal(0);
      expect(await usdtVault.getTotalBalance(user2.address)).to.equal(0);
      expect(await gpuVault.getTotalBalance(user1.address)).to.equal(0);
      expect(await gpuVault.getTotalBalance(user2.address)).to.equal(0);
      
      console.log("  🎊 CROSS-CHAIN TRADE COMPLETED SUCCESSFULLY!");
      console.log("  📈 Trade Summary:");
      console.log("    User1: Traded 1000 USDT → Received 100 GPU");
      console.log("    User2: Traded 100 GPU → Received 1000 USDT");
    });

    it("Should handle multiple simultaneous trades", async function () {
      console.log("\n🔄 Multiple Simultaneous Trades Test");
      
      // Setup multiple deposits
      const halfUSDT = USDT_AMOUNT / 2n;
      const halfGPU = GPU_AMOUNT / 2n;
      
      // User1 deposits USDT, wants GPU
      await mockUSDT.connect(user1).approve(await usdtVault.getAddress(), USDT_AMOUNT);
      await usdtVault.connect(user1).deposit(USDT_AMOUNT);
      
      // User2 deposits GPU, wants USDT
      await mockGPU.connect(user2).approve(await gpuVault.getAddress(), GPU_AMOUNT);
      await gpuVault.connect(user2).deposit(GPU_AMOUNT);
      
      // User3 deposits USDT, wants GPU
      await mockUSDT.connect(user3).approve(await usdtVault.getAddress(), halfUSDT);
      await usdtVault.connect(user3).deposit(halfUSDT);
      
      console.log("  ✅ Multiple users deposited assets");
      
      // Execute partial trades
      // User1 gets half of User2's GPU
      await gpuVault.connect(orderbook).transferAndUnlock(user2.address, user1.address, halfGPU);
      
      // User3 gets other half of User2's GPU  
      await gpuVault.connect(orderbook).transferAndUnlock(user2.address, user3.address, halfGPU);
      
      // User2 gets User1's USDT
      await usdtVault.connect(orderbook).transferAndUnlock(user1.address, user2.address, USDT_AMOUNT);
      
      console.log("  ✅ Multiple trades executed");
      
      // Verify complex trade state
      expect(await gpuVault.unlockedBalances(user1.address)).to.equal(halfGPU);
      expect(await gpuVault.unlockedBalances(user3.address)).to.equal(halfGPU);
      expect(await usdtVault.unlockedBalances(user2.address)).to.equal(USDT_AMOUNT);
      
      // User3 still has locked USDT (no one wanted it yet)
      expect(await usdtVault.lockedBalances(user3.address)).to.equal(halfUSDT);
      
      console.log("  🎉 Multiple simultaneous trades handled correctly");
    });
  });

  describe("🛡️ Enhanced Security Tests", function () {
    
    it("Should prevent transfer of insufficient balance", async function () {
      await mockUSDT.connect(user1).approve(await usdtVault.getAddress(), USDT_AMOUNT);
      await usdtVault.connect(user1).deposit(USDT_AMOUNT);
      
      // Try to transfer more than available
      await expect(usdtVault.connect(orderbook).transferLocked(user1.address, user2.address, USDT_AMOUNT * 2n))
        .to.be.revertedWith("USDTVault: Insufficient locked balance");
      
      console.log("  ✅ Insufficient balance protection working");
    });

    it("Should handle zero amounts correctly", async function () {
      await expect(usdtVault.connect(orderbook).transferLocked(user1.address, user2.address, 0))
        .to.be.revertedWith("USDTVault: Amount must be greater than 0");
      
      console.log("  ✅ Zero amount protection working");
    });

    it("Should maintain total balance integrity", async function () {
      // Multiple users deposit
      await mockUSDT.connect(user1).approve(await usdtVault.getAddress(), USDT_AMOUNT);
      await usdtVault.connect(user1).deposit(USDT_AMOUNT);
      
      await mockUSDT.connect(user2).approve(await usdtVault.getAddress(), USDT_AMOUNT);
      await usdtVault.connect(user2).deposit(USDT_AMOUNT);
      
      const totalBefore = await usdtVault.getContractBalance();
      
      // Transfer between users
      await usdtVault.connect(orderbook).transferLocked(user1.address, user2.address, USDT_AMOUNT);
      
      const totalAfter = await usdtVault.getContractBalance();
      
      // Total contract balance should remain unchanged
      expect(totalAfter).to.equal(totalBefore);
      
      console.log("  ✅ Total balance integrity maintained during transfers");
    });
  });

  describe("📊 Enhanced View Functions", function () {
    
    it("Should return accurate transfer capability information", async function () {
      await mockUSDT.connect(user1).approve(await usdtVault.getAddress(), USDT_AMOUNT);
      await usdtVault.connect(user1).deposit(USDT_AMOUNT);
      
      // Should be able to transfer deposited amount
      expect(await usdtVault.canTransfer(user1.address, USDT_AMOUNT)).to.be.true;
      expect(await usdtVault.canTransfer(user1.address, USDT_AMOUNT * 2n)).to.be.false;
      
      // User with no deposit can't transfer
      expect(await usdtVault.canTransfer(user2.address, USDT_AMOUNT)).to.be.false;
      
      console.log("  ✅ Transfer capability checks working");
    });

    it("Should track balances accurately through complex operations", async function () {
      // User1 deposits USDT
      await mockUSDT.connect(user1).approve(await usdtVault.getAddress(), USDT_AMOUNT);
      await usdtVault.connect(user1).deposit(USDT_AMOUNT);
      
      // Transfer half to User2
      const halfAmount = USDT_AMOUNT / 2n;
      await usdtVault.connect(orderbook).transferLocked(user1.address, user2.address, halfAmount);
      
      // Unlock remaining for User1
      await usdtVault.connect(orderbook).unlock(user1.address, halfAmount);
      
      // Check balances
      const [user1Locked, user1Unlocked] = await usdtVault.getBalances(user1.address);
      const [user2Locked, user2Unlocked] = await usdtVault.getBalances(user2.address);
      
      expect(user1Locked).to.equal(0);
      expect(user1Unlocked).to.equal(halfAmount);
      expect(user2Locked).to.equal(halfAmount);
      expect(user2Unlocked).to.equal(0);
      
      expect(await usdtVault.getTotalBalance(user1.address)).to.equal(halfAmount);
      expect(await usdtVault.getTotalBalance(user2.address)).to.equal(halfAmount);
      
      console.log("  ✅ Complex balance tracking accurate");
      console.log("    User1 locked:", ethers.formatUnits(user1Locked, 6), "USDT");
      console.log("    User1 unlocked:", ethers.formatUnits(user1Unlocked, 6), "USDT");
      console.log("    User2 locked:", ethers.formatUnits(user2Locked, 6), "USDT");
      console.log("    User2 unlocked:", ethers.formatUnits(user2Unlocked, 6), "USDT");
    });
  });

  describe("⚡ Gas Optimization Tests", function () {
    
    it("Should compare gas usage: separate vs combined operations", async function () {
      // Setup
      await mockUSDT.connect(user1).approve(await usdtVault.getAddress(), USDT_AMOUNT);
      await usdtVault.connect(user1).deposit(USDT_AMOUNT);
      
      await mockUSDT.connect(user2).approve(await usdtVault.getAddress(), USDT_AMOUNT);
      await usdtVault.connect(user2).deposit(USDT_AMOUNT);
      
      // Method 1: Separate transfer and unlock
      const tx1 = await usdtVault.connect(orderbook).transferLocked(user1.address, user3.address, USDT_AMOUNT);
      const receipt1 = await tx1.wait();
      
      const tx2 = await usdtVault.connect(orderbook).unlock(user3.address, USDT_AMOUNT);
      const receipt2 = await tx2.wait();
      
      const separateGas = receipt1.gasUsed + receipt2.gasUsed;
      
      // Method 2: Combined transferAndUnlock
      const tx3 = await usdtVault.connect(orderbook).transferAndUnlock(user2.address, user3.address, USDT_AMOUNT);
      const receipt3 = await tx3.wait();
      
      const combinedGas = receipt3.gasUsed;
      
      console.log("  ⛽ Gas usage comparison:");
      console.log("    Separate operations:", separateGas.toString(), "gas");
      console.log("    Combined operation:", combinedGas.toString(), "gas");
      console.log("    Gas saved:", (separateGas - combinedGas).toString(), "gas");
      
      // Combined should use less gas
      expect(combinedGas).to.be.lt(separateGas);
      console.log("  ✅ Combined operation is more gas efficient");
    });
  });

  describe("🔄 Backwards Compatibility", function () {
    
    it("Should maintain compatibility with original functions", async function () {
      console.log("🔄 Testing backwards compatibility...");
      
      // Original deposit/unlock/withdraw flow should still work
      await mockUSDT.connect(user1).approve(await usdtVault.getAddress(), USDT_AMOUNT);
      await usdtVault.connect(user1).deposit(USDT_AMOUNT);
      
      await usdtVault.connect(orderbook).unlock(user1.address, USDT_AMOUNT);
      await usdtVault.connect(user1).withdraw(USDT_AMOUNT);
      
      // Should complete without issues
      expect(await usdtVault.getTotalBalance(user1.address)).to.equal(0);
      
      console.log("  ✅ Original deposit/unlock/withdraw flow still works");
      console.log("  ✅ Backwards compatibility maintained");
    });
  });
});

// Helper function to get latest block timestamp
async function getLatestTimestamp() {
  const block = await ethers.provider.getBlock("latest");
  return block.timestamp;
}