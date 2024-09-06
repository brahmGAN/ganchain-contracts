// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "./interfaces/IErrors.sol";
import "./interfaces/IERC721.sol"; 


contract QueenStaking is OwnableUpgradeable, UUPSUpgradeable, ReentrancyGuardUpgradeable,IErrors {

    /// @dev The last rewards calculated for the queen at 
    /// @dev Can hold upto 30,000 years of timestamp
    uint40 _lastRewardAt; 

    /// @dev The rewards set aside for the entire queen nodes pool per day 
    /// @dev Can hold up to 100 million rewards in GPoints per day, denominated in wei.
    uint88 _rewardsPerDay; 

    /// @dev Instance of the NFT contract that holds the node keys 
    IERC721 public _nftContract; 

    // Not yet finalized 
    mapping(address => uint) stakeHealth; 

    /// @dev Maps the amount staked by a particular queen node 
    mapping(address => uint88) stakedAmount;

    /// @dev Total stakes in the staking pool.
    /// @dev Can hold upto 10 Billion GPoints in wei 
    uint96 _totalStakes; 

    // Functions

    /// @dev Authorizes the upgrade to a new implementation. Only callable by the owner.
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /// @dev Initializes the contract with GPU contract address and rewards per day for the queen nodes pool.
    /// @dev `rewardsPerDay` should be passed in wei and not as GPoints 
    function initialize(address nftContract, uint256 rewardsPerDay) public initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        _nftContract = IERC721(nftContract);
        _lastRewardAt = uint40(block.timestamp);
        _rewardsPerDay = uint88(rewardsPerDay);
    }

    /// @dev Allows the users to stake and become a queen node.
    /// @dev Anyone with the NFT node key can become a queen by staking a minimum of 1000 GPoints initially. 
    function stake() public payable {
        if(_nftContract.balanceOf(msg.sender) < 1) revert BuyNodeNFT();
        if(stakedAmount[msg.sender] > 0) {
            //claimRewards();
        }
        else {
            if(msg.value < 1000000000000000000000) revert InsufficientStakes();
        }
        _totalStakes += uint96(msg.value); 
        stakedAmount[msg.sender] += uint88(msg.value); 
    }  

    //unstake

    //claim rewards

    // add staking health 
}