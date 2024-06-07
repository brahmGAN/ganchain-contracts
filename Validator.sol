// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

interface IERC721 {
    function balanceOf(address nftOwner) external view returns(uint);
}

contract AddValidator is OwnableUpgradeable, UUPSUpgradeable {

    address NFTAddress;
    address[] ValidatorNFTAddresses;

    struct ValidatorInfo {
        string[] ss58Addresses;
        uint maxNFTCount;
        uint usedNFTCount;
    }

    mapping(address => ValidatorInfo) public validators;
    mapping(address => bool) private AddressAdded;

    modifier haveNFT(address validatorAddress){
        IERC721 nftContract = IERC721(NFTAddress);
        require(nftContract.balanceOf(validatorAddress) > 0, "Do not have NFT");
        _;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function initialize(address NftAddress) public initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        NFTAddress = NftAddress;
    }

    function addValidator(string calldata validatorSS58Address) public haveNFT(msg.sender) {
        uint nftBalance = calculateNFT(msg.sender);
        require(validators[msg.sender].ss58Addresses.length < nftBalance, "Max SS58 addresses already registered");

        if (!AddressAdded[msg.sender]) {
            ValidatorNFTAddresses.push(msg.sender);
            AddressAdded[msg.sender] = true;
            validators[msg.sender].maxNFTCount = nftBalance;
        }

        validators[msg.sender].ss58Addresses.push(validatorSS58Address);
        validators[msg.sender].usedNFTCount += 1;
    }

    function calculateNFT(address validatorAddress) internal view returns(uint) {
        IERC721 nftContract = IERC721(NFTAddress);
        return nftContract.balanceOf(validatorAddress);
    }
}
