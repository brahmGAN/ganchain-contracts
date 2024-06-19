// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.20;

import "./AGPU.sol";

contract AddConsumer is IGPU {
    
    function addConsumer(address consumerAddress, string calldata userName, string calldata organisation) external  {
        require(helper == msg.sender,"OH");
        require(!consumers[consumerAddress].exists, "Exists");

        consumers[consumerAddress] = Consumer({
            userName : userName, 
            organisation : organisation,
            jobs :  new uint[](0),
            exists : true
        });
        
        users[userID] = User({
            userAddress : consumerAddress,
            userType : UserType.Consumer
        });
        userID++;

        emit ConsumerAdded(consumerAddress, userName, organisation);
    }

}