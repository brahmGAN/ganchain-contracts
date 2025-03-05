const { ethers } = require("hardhat");
const { expect } = require("chai");

describe("Buy back", () => {
  let owner;
  let user1;
  let user2;
  let buyBackFactory;
  let buyBackContract;
  before(async () => {
    [owner, user1, user2] = await ethers.getSigners();
    buyBackFactory = await ethers.getContractFactory("BuyBack");
    buyBackContract = await buyBackFactory.deploy(owner);
  });

  it("Should let users sell $GP", async () => {
    await expect(
      await buyBackContract
        .connect(user1)
        .sellGP({ value: ethers.parseEther("69") }),
    )
      .to.emit(buyBackContract, "soldGP")
      .withArgs(user1, ethers.parseEther("69"));
  });

  it("Should let users sell nodes", async () => {
    await expect(await buyBackContract.connect(user1).sellNodes(69))
      .to.emit(buyBackContract, "soldNodes")
      .withArgs(user1, 69);
  });

  it("Should return the right amount of sold GP", async () => {
    await expect(await buyBackContract.connect(user1)._soldGP(user1)).to.equals(
      ethers.parseEther("69"),
    );
  });

  it("Should return the right amount of sold nodes", async () => {
    await expect(
      await buyBackContract.connect(user1)._nodesSold(user1),
    ).to.equals(69);
  });
});
