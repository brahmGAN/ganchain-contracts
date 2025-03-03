// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @dev Errors only interface for the {GPU} implementations.
 */
interface IErrors {
  /**
   * @dev Displayed when the user doesn't have a Node NFT key.  
   */
  error BuyNodeNFT();

  /**
   * @dev Displayed when it's not been 24 hours since last call. 
   */
  error InComplete24Hours();

  /**
   * @dev Displayed when the staking amount is less than the minimum required, which is 1000 GPoints. 
   */
  error InsufficientStakes();

  /**
   * @dev Displayed when there are no rewards to claim
   */
  error NoRewards();

  /**
   * @dev Displayed when transfer failed 
   */
  error TransferFailed();
  
  /**
   * @dev Displayed when un-stake amount exceeds staked amount
   */
  error ExceedsStakedAmount();

  /**
   * @dev Displayed when un-stake amount is 0
   */
  error ZeroUnstakeAmount();

  /**
    * @dev Displayed when stake() isn't yet available for users
   */
  error stakeNotYetAvailable();

  /**
    * @dev Displayed when unStake() isn't yet available for users
   */
  error unStakeNotYetAvailable(); 

  /**
    * @dev Displayed when claim() isn't yet available for users
   */
  error claimNotYetAvailable();   

  /**
    * @dev Displayed when a wrong functionType is passed as a parameter
   */
  error wrongFunctionType();

  /**
    * @dev Displayed there's a mismatch in the queen array length that's passed into accumulate rewards
   */
  error incorrectArraySize();

  /**
    * @dev Displayed when setCastedVotes isn't called by the owner 
   */
  error setCastedVote();

  /**
    * @dev Displayed when createSubnet() isn't yet available for users
   */
  error createSubnetsNotYetAvailable();   

  /**
    * @dev Displayed when deleteSubnet() isn't yet available for users
   */
  error deleteSubnetsNotYetAvailable();  
  
   /**
    * @dev Displayed when the user isn't the king of the subnet
   */
  error unauthorizedKing();

  /**
    * @dev Displayed when the subnet is either already deleted or doesn't exist
   */
  error subnetDeletedOrDoesntExist();

  /**
    * @dev Displayed when the users can't create multiple subnets 
   */
  error cannotCreateMultipleSubnets();
}