const { ethers } = require("hardhat");
const { expect } = require("chai");

describe("GPU", () => {
  let owner;
  let gpuFactory;
  let gpuProxy;
  let user1;
  let user2;
  let NFTFactory;
  let nftContract;
  let helper;
  let scheduler;
  let validatorSS58Address = "validatorSS58Address";
  let publicKey = "publicKey";
  let userName = "userName";
  before(async () => {
    [owner, user1, user2, helper, scheduler, provider] =
      await ethers.getSigners();
    NFTFactory = await ethers.getContractFactory("GANNode");
    nftContract = await NFTFactory.deploy(owner);
    await nftContract.connect(owner).safeMint(user1, 1);
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
  });

  describe("Add user as a validator,queen and as a provider", () => {
    it("Should be able to add user1 as a Validator", async () => {
      await expect(
        await gpuProxy.connect(user1).addValidator(validatorSS58Address),
      )
        .to.emit(gpuProxy, "ValidatorAdded")
        .withArgs(user1.address, validatorSS58Address, 1);
    });
    it("Should be able to add user1 as a Queen", async () => {
      await expect(
        await gpuProxy
          .connect(helper)
          .addQueen(user1.address, publicKey, userName),
      )
        .to.emit(gpuProxy, "QueenAdded")
        .withArgs(user1.address, publicKey, userName);
    });
    it("Should be able to add user1 as a Provider", async () => {
      await expect(await gpuProxy.connect(user1).addProvider(provider.address))
        .to.emit(gpuProxy, "ProviderAdded")
        .withArgs(provider.address, user1.address);
    });
    it("Should revert when trying to add a queen without a node NFT key", async () => {
      await expect(
        gpuProxy.connect(helper).addQueen(user2.address, publicKey, userName),
      ).to.be.revertedWith("NoNFT");
    });

    it("Should set validator to false",async()=>{
      await expect(await gpuProxy.isValidator(user1))
      .to.be.equal(true);
      await gpuProxy.connect(owner).setValidator(user1,false); 
      await expect(await gpuProxy.isValidator(user1))
      .to.be.equal(false);
    });
  });
});
