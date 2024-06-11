// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract PaymentHandler is Ownable, ReentrancyGuard {
    address public fundsHandler;
    mapping(address => uint256) public payerfund;
    address[] payers;
    // Events
    event PaymentReceived(address indexed sender, uint256 amount, address indexed receiver);
    
    constructor(address initialOwner, address initialFundsHandler) Ownable(initialOwner) {
        require(initialOwner != address(0), "Invalid initial owner address");
        require(initialFundsHandler != address(0), "Invalid initial funds handler address");
        fundsHandler = initialFundsHandler;
    }

    function pay() public payable nonReentrant {
        require(msg.value > 0, "Payment zero");
        require(fundsHandler != address(0), "Funds handler not set");
        (bool success, ) = payable(fundsHandler).call{value: msg.value}("");
        require(success, "Payment failed");
        payers.push(msg.sender);
        payerfund[msg.sender] += msg.value;
        emit PaymentReceived(msg.sender, msg.value,fundsHandler);
    }

    function setFundsHandler(address _newFundsHandler) external onlyOwner {
        require(_newFundsHandler != address(0), "Invalid address");
        fundsHandler = _newFundsHandler;
    }

    function getPayers() public view returns(address[] memory){
        return payers;
    }
}




