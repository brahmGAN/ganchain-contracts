const { ethers } = require("hardhat");
const { expect } = require("chai");

describe("Buy back", ()=>{
    let owner; 
    let user1; 
    let user2; 
    let buyBackFactory;
    let buyBackContract;
    before(async ()=>{
        [
            owner,
            user1, 
            user2
          ] = await ethers.getSigners();
          buyBackFactory = await ethers.getContractFactory("BuyBack");
          buyBackContract = await buyBackFactory.deploy(owner);
    });

    it("Should let users sell $GP", async()=>{
        await expect(
           await buyBackContract.connect(user1).sellGP({value: ethers.parseEther("69")}) 
        ).to.emit(buyBackContract,"soldGP").
        withArgs(user1, ethers.parseEther("69")); 
    });
});