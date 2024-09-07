// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "./interfaces/IErrors.sol"; 
import "./GPU/GPU.sol";

contract QueenStaking is OwnableUpgradeable, UUPSUpgradeable, ReentrancyGuardUpgradeable,IErrors {

    /// @dev Timestamp of the last rewards calculated at 
    uint40 public _lastRewardCalculated; 

    /// @dev Timestamp of staking health last set 
    uint40 public _stakingHealthSetAt; 

    /// @dev The rewards set aside for the entire queen nodes pool per day 
    /// @dev Can hold up to 100 million rewards in GPoints per day, denominated in wei
    uint88 public _rewardsPerDay; 

    /// @dev Instance of the NFT contract that holds the node keys 
    IERC721 public _nftContract; 

    /// @dev Instance of the GPU contract 
    //GPU public GPUInstance;

    // Not yet finalized 
    mapping(address => uint) _stakingHealth; 

    /// @dev Maps the amount staked by a particular queen node 
    mapping(address => uint88) _stakedAmount;

    /// @dev Total stakes in the staking pool
    /// @dev Can hold upto 10 Billion GPoints in wei 
    uint96 _totalStakes; 

    /// @dev Queen's rewards which is calculated every day
    mapping(address => uint) _queenRewards;

    /// @dev List of queens that stakes
    address[] public _queens; 

    /// @dev Authorizes the upgrade to a new implementation. Only callable by the owner.
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /// @dev Initializes the contract with GPU contract address and rewards per day for the queen nodes pool.
    /// @dev `rewardsPerDay` should be passed in wei and not as GPoints 
    function initialize(address nftContract, uint256 rewardsPerDay) public initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        _nftContract = IERC721(nftContract);
        _rewardsPerDay = uint88(rewardsPerDay);
        _lastRewardCalculated = uint40(block.timestamp); 
        _stakingHealthSetAt = uint40(block.timestamp);
    }

    /// @dev Allows the users to stake and become a queen node.
    /// @dev Anyone with the NFT node key can become a queen by staking a minimum of 1000 GPoints initially. 
    function stake() public payable {
        if(_nftContract.balanceOf(msg.sender) < 1) revert BuyNodeNFT();
        if(_stakedAmount[msg.sender] > 0) {
            claimRewards();
        }
        else {
            if(msg.value < 1e21) revert InsufficientStakes();
        }
        _totalStakes += uint96(msg.value); 
        _stakedAmount[msg.sender] += uint88(msg.value); 
        _queens.push(msg.sender);
        //@note emit
    }  

    function claimRewards() public {
        uint rewards = _queenRewards[msg.sender]; 
        if(rewards == 0) revert NoRewards(); 
        _queenRewards[msg.sender] = 0; 
        (bool success,) = payable(msg.sender).call{value: rewards}("");
        if(!success) revert TransferFailed(); 
        //@note emit
    }

    function setStakingHealth(uint[] memory stakingHealth) public onlyOwner {
        if(block.timestamp < _stakingHealthSetAt + 24 hours) revert InComplete24Hours();
        address[] memory queens = _queens; 
        uint queensLength = queens.length; 
        for(uint i = 0; i < queensLength; i++) {
            _stakingHealth[queens[i]] = stakingHealth[i];
        }
        _stakingHealthSetAt = uint40(block.timestamp);
    }

    function accumulateDailyQueenRewards() public onlyOwner {
        if(block.timestamp < _lastRewardCalculated + 24 hours) revert InComplete24Hours();
        address[] memory queens = _queens; 
        uint totalQueens = queens.length; 
        uint256[] memory stakeScores = new uint256[](totalQueens); 
        uint256 totalStakeScore;
        for(uint i = 0; i < totalQueens; i++) {
            // Stake score = SU * SM * SH 
            stakeScores[i] = _stakedAmount[msg.sender] * _stakingHealth[queens[i]]; 
        }
    }

    function stakingMultiplier(address queen) public {
        uint8 factor = 100; 
        uint stakedAmount = _stakedAmount[queen]; 
        
    }

    //unstake

    // add staking health 
}