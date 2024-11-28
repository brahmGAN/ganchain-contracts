// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.20;

import "./IGPU.sol";

contract AddQueen is IGPU {

    function addQueen(address queenAddress, string calldata publicKey, string calldata userName) external haveNft(queenAddress){
        require(helper == msg.sender,"OH");
        require(!queens[queenAddress].exists, "QueenPresent");
        //require(!providers[queenAddress].exists, "AlreadyProvider");
        require(bytes(userName).length > 0, "!Name");
        require(bytes(publicKey).length > 0, "!Key");
        //Add a check to ensure the queen has staked the sufficient amount
        
        queens[queenAddress] = Queen({
            jobs :  new uint[](0),
            publicKey: publicKey,
            userName : userName,
            status: QueenStatus.ACTIVE,
            exists: true            
        });
        queensList.push(queenAddress);

        users[userID] = User({
            userAddress : queenAddress,
            userType : UserType.Queen
        });
        userID++;
        
        //isQueen[queenAddress] = true; 

        emit QueenAdded(queenAddress, publicKey, userName);
    }

    function reassignQueen(uint machineId) external {
        require(machines[machineId].status == MachineStatus.PROCESSING, "!Running");
        require(machines[machineId].providerAddress == msg.sender, "!Machine");
        if (jobs[machines[machineId].currentJobID].lastChecked < block.timestamp - (2 * tickSeconds)) {
            address newQueen = getRandomQueen();
            jobs[machines[machineId].currentJobID].queenValidationAddress = newQueen;
            machines[machineId].currentQueen = newQueen;

            if (jobs[machines[machineId].currentJobID].gpuHours - jobs[machines[machineId].currentJobID].completedHours >= (2 * tickSeconds)) {
                jobs[machines[machineId].currentJobID].completedTicks += 2;
                jobs[machines[machineId].currentJobID].completedHours += 2 * tickSeconds;
                machines[machineId].sucessfulConsecutiveHealthChecks += 2;
                if(machines[machineId].sucessfulConsecutiveHealthChecks >= 3) {
                    updateMachineHealthScore(machineId, 1, true);
                    machines[machineId].sucessfulConsecutiveHealthChecks -= 3;
                }
            } else {
                jobs[machines[machineId].currentJobID].completedTicks += 1;
                jobs[machines[machineId].currentJobID].completedHours += tickSeconds;
                machines[machineId].sucessfulConsecutiveHealthChecks += 1;
                if(machines[machineId].sucessfulConsecutiveHealthChecks == 3) {
                    updateMachineHealthScore(machineId, 1, true);
                    machines[machineId].sucessfulConsecutiveHealthChecks = 0;
                }
            }

            jobs[machines[machineId].currentJobID].lastChecked = block.timestamp;
            machines[machineId].lastChecked = block.timestamp;

            if (jobs[machines[machineId].currentJobID].completedHours >= jobs[machines[machineId].currentJobID].gpuHours) {
                jobs[machines[machineId].currentJobID].status = JobStatus.COMPLETED;
                machines[machineId].status = MachineStatus.AVAILABLE;
                machines[machineId].currentQueen = address(0);
                machines[machineId].currentJobID = 0;

                emit JobCompleted(jobs[machines[machineId].currentJobID].consumerAddress, machineId, newQueen, machines[machineId].currentJobID);
            } else {
                queenMachines[newQueen].push(machineId);
                emit JobUpdated(jobs[machines[machineId].currentJobID].consumerAddress, machineId, newQueen, machines[machineId].currentJobID, jobs[machines[machineId].currentJobID].status); 
                emit QueenReassign(jobs[machines[machineId].currentJobID].consumerAddress, machineId, newQueen, machines[machineId].currentJobID);
            }
        }
    }

}