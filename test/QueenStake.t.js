const { ethers } = require("hardhat");
const { expect } = require("chai");

describe("Queen Staking", () => {
  let owner;
  let QueenStake;
  let queenStakeProxy;
  let queen1;
  let queen2;
  let queen3;
  let queen4;
  let NFTFactory;
  let nftContract;
  let helper; 
  let scheduler;
  let validator1;
  let validator2;  
  let validatorSS58Address = "validatorSS58Address"; 
  before(async () => {
    [owner, queen1, queen2, queen3, queen4, helper, scheduler, validator1,validator2] = await ethers.getSigners();
    NFTFactory = await ethers.getContractFactory("GANNode");
    nftContract = await NFTFactory.deploy(owner);
    await nftContract.connect(owner).safeMint(queen1, 1);
    await nftContract.connect(owner).safeMint(queen2, 1);
    await nftContract.connect(owner).safeMint(queen3, 1);
    await nftContract.connect(owner).safeMint(validator1, 1);
    await nftContract.connect(owner).safeMint(validator2, 1);
    gpuFactory = await ethers.getContractFactory("GPU");
    gpuProxy = await upgrades.deployProxy(
      gpuFactory,
      [
        nftContract.target,
        69,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        helper.address,
        scheduler.address,
      ],
      { initializer: "initialize" },
    );
    QueenStake = await ethers.getContractFactory("QueenStaking");
    queenStakeProxy = await upgrades.deployProxy(
      QueenStake,
      [gpuProxy.target,nftContract.target, ethers.parseEther("576")],
      { initializer: "initialize" }
    );
  });

  describe("Staking", () => {
    it("Should be able to stake", async () => {
      await expect(
        await queenStakeProxy
          .connect(queen1)
          .stake({ value: ethers.parseEther("1000") })
      )
        .to.emit(queenStakeProxy, "staked")
        .withArgs(queen1, ethers.parseEther("1000"));
      await queenStakeProxy
        .connect(queen2)
        .stake({ value: ethers.parseEther("7000") });
        await expect(
          await queenStakeProxy
            .connect(validator1)
            .stake({ value: ethers.parseEther("99") })
        )
          .to.emit(queenStakeProxy, "staked")
          .withArgs(validator1, ethers.parseEther("99"));
    });
    it("Should revert when trying to stake without having the NFT node key", async () => {
      await expect(
        queenStakeProxy
          .connect(queen4)
          .stake({ value: ethers.parseEther("7000") })
      ).to.be.revertedWithCustomError(queenStakeProxy, "BuyNodeNFT");
    });
  });

  describe("Validator rewards with queen", () => {
    it("Owner sets `_openRewards` to true ", async () => {
      await queenStakeProxy.connect(owner).setOpenRewards(true); 
    });
    it("Add validators", async () => {
      await expect(
        await gpuProxy.connect(validator1).addValidator(validatorSS58Address),
      )
        .to.emit(gpuProxy, "ValidatorAdded")
        .withArgs(validator1, validatorSS58Address, 1);
      await expect(
        await gpuProxy.connect(validator2).addValidator(validatorSS58Address),
      )
        .to.emit(gpuProxy, "ValidatorAdded")
        .withArgs(validator2, validatorSS58Address, 1);
    });
    it("Enroll validators for queen rewards", async () => {
        await expect(
          await queenStakeProxy
            .connect(validator2)
            .validatorRewardsEnroll()
        )
          .to.emit(queenStakeProxy, "validatorEnrolled")
          .withArgs(validator2);
          await expect(
            await queenStakeProxy
              .connect(validator2)
              .stake({ value: ethers.parseEther("1000") })
          )
            .to.emit(queenStakeProxy, "staked")
            .withArgs(validator2, ethers.parseEther("1000"));
    });
  });

  describe("Accumulate rewards", () => {
    it("Should let owner calculate daily queen rewards", async () => {
      await queenStakeProxy
        .connect(owner)
        .accumulateDailyQueenRewards();
    });
    // it("Should revert when it hasn't been 24 hours since last rewards calculated", async () => {
    //   await expect(
    //     queenStakeProxy
    //       .connect(owner)
    //       .accumulateDailyQueenRewards(stakingHealth)
    //   ).to.be.revertedWithCustomError(queenStakeProxy, "InComplete24Hours");
    // });
  });

  describe("Claim", () => {
    it("Should let Queens claim rewards", async () => {
      const rewards = await queenStakeProxy.connect(queen1).getMyRewards();
      await expect(queenStakeProxy.connect(queen1).claimRewards())
        .to.emit(queenStakeProxy, "claimedRewards")
        .withArgs(queen1, rewards);
    });
    it("Should revert when there are no rewards to claim", async () => {
      await expect(
        queenStakeProxy.connect(queen4).claimRewards()
      ).to.be.revertedWithCustomError(queenStakeProxy, "NoRewards");
    });
  });

  // describe("Unstake", () => {
  //   it("Should let queens unstake", async () => {
  //     await expect(
  //       queenStakeProxy.connect(queen2).unStake(ethers.parseEther("7000"))
  //     )
  //       .to.emit(queenStakeProxy, "unStaked")
  //       .withArgs(queen2, ethers.parseEther("7000"));
  //   });
  //   it("Should revert when there's nothing to unstake", async () => {
  //     await expect(
  //       queenStakeProxy.connect(queen3).unStake(0)
  //     ).to.be.revertedWithCustomError(queenStakeProxy, "ZeroUnstakeAmount");
  //   });
  //   it("Should revert when unstaking amount is greater than what's staked", async () => {
  //     await expect(
  //       queenStakeProxy.connect(queen3).unStake(ethers.parseEther("10000"))
  //     ).to.be.revertedWithCustomError(queenStakeProxy, "ExceedsStakedAmount");
  //   });
  // });
});
