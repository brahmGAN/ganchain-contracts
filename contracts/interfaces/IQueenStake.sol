// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

interface IQueenStake {
    event staked(
        address queen, 
        uint88 stakedAmount
    );
    event claimedRewards(
        address queen, 
        uint96 rewardsClaimed
    );
    event accumulatedDailyQueenRewards(
        uint40 lastRewardCalculated
    );
    event unStaked(
        address queen, 
        uint amount
    );
    function stake() external payable;
    function claimRewards() external; 
    function accumulateDailyQueenRewards(uint[] calldata stakingHealth) external;
    function unStake(uint amount) external; 
}