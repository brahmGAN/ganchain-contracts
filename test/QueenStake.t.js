const { ethers } = require("hardhat");

describe("Queen Staking",() => {
    let owner;
    let QueenStake;
    let queenStakeProxy;
    let queen1;
    let queen2; 
    let queen3;
    let NFTFactory; 
    let nftContract; 
    before(async () => {
        [owner, queen1, queen2, queen3] = await ethers.getSigners();
        NFTFactory= await ethers.getContractFactory("GANNode");
        nftContract= await NFTFactory.deploy(owner);
        await nftContract.connect(owner).safeMint(queen1,1);
        await nftContract.connect(owner).safeMint(queen2,1);
        await nftContract.connect(owner).safeMint(queen3,1);
        QueenStake = await ethers.getContractFactory("QueenStaking");
        queenStakeProxy = await upgrades.deployProxy(
        QueenStake,
        [nftContract.target,ethers.parseEther("576")],
        { initializer: "initialize" },
        );
    });

    describe("Staking",()=>{
        it("Should be able to stake",async()=>{
            await queenStakeProxy.connect(queen1).stake({value:ethers.parseEther("1000")});
            await queenStakeProxy.connect(queen2).stake({value:ethers.parseEther("7000")});
            await queenStakeProxy.connect(queen3).stake({value:ethers.parseEther("7000")});
        });
    });
});