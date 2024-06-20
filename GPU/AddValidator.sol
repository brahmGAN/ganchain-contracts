// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;
import "./AGPU.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract AddValidator is IGPU {
    address NFTAddress;
    address[] ValidatorNFTAddresses;
    struct ValidatorInfo {
        string[] ss58Addresses;
        uint maxNFTCount;
        uint usedNFTCount;
    }
    mapping(address => ValidatorInfo) public validators;
   
    function addValidator(string calldata validatorSS58Address) public haveNft(msg.sender) {
        require(!isProvider[msg.sender], "AlreadyProvider");
        uint nftBalance = calculateNFT(msg.sender);
        require(validators[msg.sender].ss58Addresses.length < nftBalance, "LimitReached");
        if (!isValidator[msg.sender]) {
            ValidatorNFTAddresses.push(msg.sender);
            isValidator[msg.sender] = true;
            validators[msg.sender].maxNFTCount = nftBalance;
        }
        validators[msg.sender].ss58Addresses.push(validatorSS58Address);
        validators[msg.sender].usedNFTCount += 1;
    }

    function calculateNFT(address validatorAddress) internal view returns(uint) {
        IERC721 nftContract = IERC721(NFTAddress);
        return nftContract.balanceOf(validatorAddress);
    }
    function getValidators() public view returns(address[] memory){
        return ValidatorNFTAddresses;
    }
    function getSS58address(address validatorNFTAddress) public view returns(string[] memory){
        return validators[validatorNFTAddress].ss58Addresses;
    }
}