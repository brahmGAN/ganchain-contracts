// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;


contract BuyBack
{
    address constant public _fundsHandler = 0x70d99faA2505884029F95f5291E82eBD05aB4439; 

    mapping(address => uint120) public _soldGP;

    mapping(address => uint16) public _nodesSold; 

    event soldGP(
        address soldBy, 
        uint120 amount
    );

    event soldNodes(
        address soldBy, 
        uint120 amount
    ); 

    function sellGP() external payable 
    {
        _soldGP[msg.sender] += uint120(msg.value); 
        (bool success,) = payable(_fundsHandler).call{value: msg.value}("");
        require(success, "TransferFailed");
        emit soldGP(msg.sender, uint120(msg.value));
    } 

    function sellNodes(uint16 totalNodes) external 
    {
        _nodesSold[msg.sender] += totalNodes; 
        emit soldNodes(msg.sender, totalNodes);
    }   
}