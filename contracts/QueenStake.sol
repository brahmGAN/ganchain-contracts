// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "./GPU/GPU.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "./interfaces/IErrors.sol";


contract QueenStaking is OwnableUpgradeable, UUPSUpgradeable, ReentrancyGuardUpgradeable,IErrors {

    /// @dev The last rewards calculated for the queen at 
    /// @dev Can hold upto 30,000 years of timestamp
    uint40 _lastRewardAt; 

    /// @dev The rewards set aside for the entire queen nodes pool per day 
    /// @dev Can hold upto 10 million rewards per day 
    uint120 _rewardsPerDay; 

    /// @dev Instance of the 
    GPU public _GPUInstance; 

    // Not yet finalized 
    mapping(address => uint) stakeHealth; 

    /// @dev Maps the amount staked by a particular queen node 
    mapping(address => uint) stakedAmount;

    // Functions

    /// @dev Authorizes the upgrade to a new implementation. Only callable by the owner.
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /// @dev Initializes the contract with GPU contract address and rewards per day for the queen nodes pool.
    function initialize(address gpuAddress, uint256 rewardsPerDay) public initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        _GPUInstance = GPU(gpuAddress);
        _lastRewardAt = uint40(block.timestamp);
        /// @dev Store the rewards per day in wei
        _rewardsPerDay = uint120(rewardsPerDay) * 1e18;
    }

    modifier ownNFT(address nftOwner) {
        IERC721 nftContract = IERC721(_GPUInstance.nftAddress());
        if(nftContract.balanceOf(nftOwner) < 1) revert GetNodeNFT(); 
        _;
    }

    /// @dev Allows the users to stake and become a queen node.
    /// @dev Anyone with the NFT node key can become a queen by staking a minimum of 1000 GPoints
    function stake() public payable ownNFT(msg.sender) {

    }  

    //unstake

    //claim rewards

    // add staking health 
}