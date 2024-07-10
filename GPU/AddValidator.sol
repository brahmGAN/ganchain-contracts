// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;
import "./AGPU.sol";
contract AddValidator is IGPU {
    address[] ValidatorNFTAddresses;
    struct ValidatorInfo {
        string ss58Address;
        uint NFTCount;
    }
    mapping(address => ValidatorInfo) public validators;
    function addValidator(string calldata validatorSS58Address) public haveNft(msg.sender){
        require(!isProvider[msg.sender], "AlreadyProvider");
        require(!isValidator[msg.sender], "AlreadyValidator");
        require(bytes(validatorSS58Address).length > 0, "!SS58");
        uint nftBalance = calculateNFT(msg.sender);
        ValidatorNFTAddresses.push(msg.sender);
        validators[msg.sender] = ValidatorInfo({
            ss58Address: validatorSS58Address,
            NFTCount: nftBalance
        });
        isValidator[msg.sender] = true;
        emit ValidatorAdded(msg.sender, validatorSS58Address, nftBalance);
    }
    function calculateNFT(address validatorAddress) internal view returns(uint) {
        IERC721 nftContract = IERC721(nftAddress);
        return nftContract.balanceOf(validatorAddress);
    }
    function updateValidatorNFTCount(address validator)public {
        require(isValidator[validator], "!Validator");
        validators[validator].NFTCount = calculateNFT(validator);
        emit UpdatedValidatorNFTCount(validator, validators[validator].ss58Address ,validators[validator].NFTCount);
    }
    function getValidators() public view returns(address[] memory){
        return ValidatorNFTAddresses;
    }
}