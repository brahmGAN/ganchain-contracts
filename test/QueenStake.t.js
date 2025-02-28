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
  let queen5;
  let king1; 
  let king2;
  let king3;
  let king4; 
  let NFTFactory;
  let nftContract;
  let helper;
  let scheduler;
  let validator1;
  let validator2;
  let validatorSS58Address = "validatorSS58Address";
  let upgradedQueenStakeProxy;
  let stakesBeforeUpgrade;
  let pendingRewardsBeforeUpgrade;
  before(async () => {
    [
      owner,
      queen1,
      queen2,
      queen3,
      queen4,
      queen5,
      king1,
      king2,
      king3,
      king4, 
      helper,
      scheduler,
      validator1,
      validator2,
    ] = await ethers.getSigners();
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
      [gpuProxy.target, nftContract.target, ethers.parseEther("572")],
      { initializer: "initialize" },
    );
  });

  describe("Staking", () => {
    it("Should be able to stake", async () => {
      await expect(
        await queenStakeProxy
          .connect(queen1)
          .stake({ value: ethers.parseEther("1000") }),
      )
        .to.emit(queenStakeProxy, "staked")
        .withArgs(queen1, ethers.parseEther("1000"));

      await queenStakeProxy
        .connect(queen2)
        .stake({ value: ethers.parseEther("7000") });
    });
    it("Should revert when trying to stake without having the NFT node key", async () => {
      await expect(
        queenStakeProxy
          .connect(queen4)
          .stake({ value: ethers.parseEther("7000") }),
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
        await queenStakeProxy.connect(owner).validatorRewardsEnroll(validator1),
      )
        .to.emit(queenStakeProxy, "validatorEnrolled")
        .withArgs(validator1);
      await expect(
        await queenStakeProxy.connect(owner).validatorRewardsEnroll(validator2),
      )
        .to.emit(queenStakeProxy, "validatorEnrolled")
        .withArgs(validator2);
      await expect(
        await queenStakeProxy
          .connect(validator2)
          .stake({ value: ethers.parseEther("1000") }),
      )
        .to.emit(queenStakeProxy, "staked")
        .withArgs(validator2, ethers.parseEther("1000"));
    });
  });

  describe("Accumulate rewards", () => {
    it("Should let owner calculate daily queen rewards", async () => {
      await queenStakeProxy.connect(owner).accumulateDailyQueenRewards();
    });
  });

  describe("Unstake", () => {
    it("Should let queens unstake", async () => {
      await expect(
        queenStakeProxy.connect(queen2).unStake(ethers.parseEther("7000")),
      )
        .to.emit(queenStakeProxy, "unStaked")
        .withArgs(queen2, ethers.parseEther("7000"));
    });
    it("Should revert when there's nothing to unstake", async () => {
      await expect(
        queenStakeProxy.connect(queen3).unStake(0),
      ).to.be.revertedWithCustomError(queenStakeProxy, "ZeroUnstakeAmount");
    });
    it("Should revert when unstaking amount is greater than what's staked", async () => {
      await expect(
        queenStakeProxy.connect(queen3).unStake(ethers.parseEther("10000")),
      ).to.be.revertedWithCustomError(queenStakeProxy, "ExceedsStakedAmount");
    });
  });

  describe("Contract upgrade", () => {
    it("Should upgrade to a new queen contract", async () => {
      stakesBeforeUpgrade = await queenStakeProxy
        .connect(queen1)
        .getMyStakedAmount();

      pendingRewardsBeforeUpgrade = await queenStakeProxy
        .connect(queen1)
        .getMyPendingRewards();

      NewQueenStake = await ethers.getContractFactory("NewQueenStaking");

      upgradedQueenStakeProxy = await upgrades.upgradeProxy(
        queenStakeProxy.target,
        NewQueenStake,
      );
    });
  });

  describe("Staking after upgrade", () => {

    it("Should have the same staked amount as before the upgrade", async()=>{
      await expect(
        await queenStakeProxy.connect(queen1).getMyStakedAmount(),
      ).to.be.equals(stakesBeforeUpgrade);
    });

    it("Should have the same pending rewards as before the upgrade", async()=>{
      await expect(
        await queenStakeProxy.connect(queen1).getMyPendingRewards(),
      ).to.be.equals(pendingRewardsBeforeUpgrade);
    });

    it("Should fail when staking as the switch is off in the new implementation", async () => {
      await expect(
        queenStakeProxy
          .connect(queen1)
          .stake({ value: ethers.parseEther("1000") }),
      ).to.be.revertedWithCustomError(queenStakeProxy, "stakeNotYetAvailable");
    });

    it("Should switch on the stake ", async () => {
      await upgradedQueenStakeProxy
        .connect(owner)
        .setUserFunctionStatus(true, 0);
    });

    it("Should be able to stake", async () => {
      await expect(
        queenStakeProxy
          .connect(queen1)
          .stake({ value: ethers.parseEther("1000") }),
      )
        .to.emit(queenStakeProxy, "staked")
        .withArgs(queen1, ethers.parseEther("1000"));
    });

    it("Should retain pending rewards after Re-staking as auto-claim is removed", async()=> {
      await expect(
        await queenStakeProxy.connect(queen1).getMyPendingRewards(),
      ).to.be.equals(pendingRewardsBeforeUpgrade);
    });

    it("Staked amount should include the amount before and after the upgrade", async () => {
      await expect(
        await queenStakeProxy.connect(queen1).getMyStakedAmount(),
      ).to.be.equals(ethers.parseEther("1000") + stakesBeforeUpgrade);
    });

    it("Should be able to stake without having the NFT node key", async () => {
      await expect(
        await queenStakeProxy
          .connect(queen4)
          .stake({ value: ethers.parseEther("5000") }),
      )
        .to.emit(queenStakeProxy, "staked")
        .withArgs(queen4, ethers.parseEther("5000"));

        await queenStakeProxy
        .connect(queen2)
        .stake({ value: ethers.parseEther("1") });

        await queenStakeProxy
        .connect(queen5)
        .stake({ value: ethers.parseEther("50") }); 
    });
  });

  describe("Unstake after upgrade", () => {
    it("Should fail while un-staking since the switch is off in the new implimentation", async () => {
      await expect(
        queenStakeProxy.connect(queen1).unStake(ethers.parseEther("500")),
      )
        .to.be.revertedWithCustomError(queenStakeProxy,"unStakeNotYetAvailable");
    });

    it("Should switch on the un-stake ", async () => {
      await upgradedQueenStakeProxy
        .connect(owner)
        .setUserFunctionStatus(true, 1);
    });

    it("Should let queens unstake", async () => {
      await expect(
        queenStakeProxy.connect(queen1).unStake(ethers.parseEther("1000")),
      )
        .to.emit(queenStakeProxy, "unStaked")
        .withArgs(queen1, ethers.parseEther("1000"));
    });

    it("Should revert when unstaking amount is greater than what's staked", async () => {
      await expect(
        queenStakeProxy.connect(queen1).unStake(ethers.parseEther("10000")),
      ).to.be.revertedWithCustomError(queenStakeProxy, "ExceedsStakedAmount");
    });

    it("Should revert when there's nothing to unstake", async () => {
      await expect(
        queenStakeProxy.connect(queen1).unStake(0),
      ).to.be.revertedWithCustomError(queenStakeProxy, "ZeroUnstakeAmount");
    });
  });

  describe("Accumulate rewards after upgrade", () => {
    it("Should revert since setCastedVotes isn't called", async () => {
      await expect(
        queenStakeProxy.connect(owner).accumulateDailyQueenRewards(),
      ).to.be.revertedWithCustomError(queenStakeProxy, "setCastedVote");
    });

    it("Should setCastedVotes()", async () => {
      
      const queens = [
        queen1.address, 
        queen2.address,
        queen3.address, 
        queen4.address,
        queen5.address
      ];

      const castedVotes = [
        20, 
        100, 
        69,
        30,
        50
      ];

      await expect(
        upgradedQueenStakeProxy.connect(owner).setCastedVotes(queens, castedVotes),
      ).to.emit(upgradedQueenStakeProxy, "skippedQueens")
      .withArgs(2);
    });

    it("Should check the stakes of queen5 to be 50", async () => {
      await expect(
        await queenStakeProxy.connect(queen5).getMyStakedAmount(),
      ).to.be.equals(ethers.parseEther("50"));
    });

    it("Should let owner calculate daily queen rewards", async () => {
      await queenStakeProxy.connect(owner).accumulateDailyQueenRewards();
    });

    it("Should check the stakes of queen5 to be $GP 283.33", async () => {
      await expect(
        await queenStakeProxy.connect(queen5).getMyStakedAmount(),
      ).to.be.equals(ethers.parseEther("288.333333333333333333"));
    });
  });

  describe("Subnets", () => {
    describe("Create subnets", () => {

      it("Should revert since createSubnets() isn't available", async () => {

        await expect(
          upgradedQueenStakeProxy.connect(king1).createSubnet(),
        ).to.be.revertedWithCustomError(upgradedQueenStakeProxy, "createSubnetsNotYetAvailable");
      });

      it("Should switch on the createSubnets()", async () => {
        await upgradedQueenStakeProxy
          .connect(owner)
          .setUserFunctionStatus(true, 2);
      });

      it("should create a subnet", async()=>{
        await expect(
          upgradedQueenStakeProxy.connect(king1).createSubnet(),
        ).to.emit(upgradedQueenStakeProxy,"createdSubnet").withArgs(0,king1);
      });
    });

    describe("Delete subnets", () => {

      it("Should revert since deleteSubnets() isn't available", async () => {
        await expect(
          upgradedQueenStakeProxy.connect(king1).deleteSubnet(0),
        ).to.be.revertedWithCustomError(upgradedQueenStakeProxy, "deleteSubnetsNotYetAvailable");
      });

      it("Should switch on the deleteSubnets()", async () => {
        await upgradedQueenStakeProxy
          .connect(owner)
          .setUserFunctionStatus(true, 3);
      });

      it("Should revert since king is unauthorized", async () => {
        await expect(
          upgradedQueenStakeProxy.connect(king2).deleteSubnet(0),
        ).to.be.revertedWithCustomError(upgradedQueenStakeProxy, "unauthorizedKing");
      });

      it("should delete a subnet", async()=>{
        await expect(
          upgradedQueenStakeProxy.connect(king1).deleteSubnet(0),
        )
          .to.emit(upgradedQueenStakeProxy, "deletedSubnet")
          .withArgs(0,king1);
      });

      it("Should revert since subnet is already deleted", async () => {
        await expect(
         upgradedQueenStakeProxy.connect(king1).deleteSubnet(0),
        ).to.be.revertedWithCustomError(upgradedQueenStakeProxy, "subnetDeletedOrDoesntExist");
      });

      it("Should revert since subnet isn't created", async () => {
        await expect(
          upgradedQueenStakeProxy.connect(king1).deleteSubnet(1),
        ).to.be.revertedWithCustomError(upgradedQueenStakeProxy, "subnetDeletedOrDoesntExist");
      });
    });

    describe("Accumulate king rewards", () => {
      it("Should accumulate daily king rewards", async () => {
        const kings = [
          king1.address, 
          king2.address,
          king3.address, 
          king4.address
        ];
  
        const votesReceived = [
          50, 
          10, 
          15,
          25
        ];
        
        await upgradedQueenStakeProxy.connect(king2).createSubnet(); 

        await upgradedQueenStakeProxy.connect(king3).createSubnet()

        await expect(
          upgradedQueenStakeProxy.connect(owner).accumulateDailyKingRewards(kings,votesReceived,ethers.parseEther("1000")),
        )
          .to.emit(upgradedQueenStakeProxy, "accumulatedDailyKingRewards")
          .withArgs(1);
      });

      it("Should check the staked amount of king3 to be $GP 200", async () => {
        await expect(
          await queenStakeProxy.connect(king3).getMyStakedAmount(),
        ).to.be.equals(ethers.parseEther("200"));
      });

      it("Should check the rewards of king3 to be $GP 200", async () => {
        await expect(
          await queenStakeProxy.connect(king3).getMyTotalRewardsEarned(),
        ).to.be.equals(ethers.parseEther("200"));
      });
    });
  });
});
