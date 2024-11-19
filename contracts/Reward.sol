// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "./GPU/GPU.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

contract Reward is OwnableUpgradeable, UUPSUpgradeable, ReentrancyGuardUpgradeable {

    GPU public GPUInstance;
    uint256 lastRewardCalculated;
    uint256 rewardGPsPerDay;
    uint256 LOCK_PERIOD;

    // Mappings
    mapping (address => uint256) public providerRewards;
    mapping (address => uint256) public lastWithdrawalTime;

    // Events
    event DailyProviderRewardsAccumulated(address owner, uint256 timestamp);
    event RewardWithdrawn(address indexed provider, uint256 amount);

    // Functions
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function initialize(address _GPUAddress, uint256 RewardGPsPerDay) public initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        GPUInstance = GPU(_GPUAddress);
        lastRewardCalculated = block.timestamp;
        rewardGPsPerDay = RewardGPsPerDay;
        LOCK_PERIOD = 30 days;
    }

    function accumulateDailyProviderRewards() public onlyOwner {
        require(block.timestamp >= lastRewardCalculated + 24 hours, "24 hrs not completed");
        address[] memory providers = GPUInstance.getProviders();
        uint256[] memory computeScores = new uint256[](providers.length);
        uint256 totalComputeScore = 0;
        for (uint256 i = 0; i < providers.length; i++) {
            (uint256 computeUnits, uint256 healthScore) = GPUInstance.getProviderComputeDetails(providers[i]);
            uint256 computeMultiplier = getComputeMultiplier(computeUnits);
            // Compute Score (CS) = CU * CM * CH
            computeScores[i] = (computeUnits * computeMultiplier * healthScore);
            //100 for computeMultiplier, 10 for computeUnits, 10 for healthScore
            totalComputeScore += computeScores[i];
        }
        if (totalComputeScore > 0) { // Avoid division by zero
            for (uint256 i = 0; i < providers.length; i++) {
                // P’s reward per day = (Pcs / ∑Pcs )  * 1152  GP
                uint256 todaysReward = (computeScores[i] * rewardGPsPerDay * 10**18) / (totalComputeScore); // In wei
                address providerNFTAddress = GPUInstance.getNFTAddress(providers[i]);
                providerRewards[providerNFTAddress] += todaysReward;
            }
        }
        lastRewardCalculated = block.timestamp;
        emit DailyProviderRewardsAccumulated(msg.sender, block.timestamp);
    }

    function getComputeMultiplier(uint256 computeUnits) public pure returns(uint256) {
        if (computeUnits < 81) {
            return 100;
        } else if (computeUnits < 641) {
            return 125;
        } else if (computeUnits < 5121) {
            return 150;
        } else if (computeUnits < 40961) {
            return 175;
        } else {
            return 200;
        }
    }

    function withdrawReward() public nonReentrant {
        require(block.timestamp >= lastWithdrawalTime[msg.sender] + LOCK_PERIOD, "Withdrawal locked for 30 days");
        //require(amount <= providerRewards[msg.sender], "Insufficient reward balance");
        require(address(this).balance >= providerRewards[msg.sender], "Contract balance is insufficient");
        uint256 _providerRewards = providerRewards[msg.sender];
        providerRewards[msg.sender] = 0;
        (bool success,) = payable(msg.sender).call{value: _providerRewards}("");
        require(success, "TransferFailed");
        lastWithdrawalTime[msg.sender] = block.timestamp;
        emit RewardWithdrawn(msg.sender, providerRewards[msg.sender]);
    }
}