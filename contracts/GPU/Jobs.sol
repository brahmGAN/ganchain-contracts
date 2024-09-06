// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.20;

import "./IGPU.sol";

contract AddJobs is IGPU {

    function createJob(uint machineId, uint gpuHours, string calldata sshPublicKey, bool requireDrill ) external payable {
        uint cost = calculateCost(machineId,gpuHours);
        require(consumers[msg.sender].exists, "!Exists");
        require(msg.value == cost, "RequireGPoints");
        require(bytes(sshPublicKey).length > 0, "!SSHkey");
        require(machines[machineId].status == MachineStatus.AVAILABLE, "!Machine");
        require(queensList.length > 0, "!Queen");

        address queenValidationAddress = getRandomQueen();
        uint gpuHoursInSeconds = gpuHours * tickSeconds;
        
        if(requireDrill) {
            jobs[jobID] = Job({                                                                                  
                machineID : machineId,
                consumerAddress : msg.sender,
                queenValidationAddress : queenValidationAddress,
                gpuHours : gpuHoursInSeconds,
                startedAt : 0,
                lastChecked : 0,
                completedTicks : 0,
                completedHours : 0,
                price : msg.value,
                sshPublicKey: sshPublicKey,
                status : JobStatus.VERIFYING,
                consumerRating: 0
            });
            machines[machineId].status = MachineStatus.VERIFYING;
        } else {
            jobs[jobID] = Job({                                                                                  
                machineID : machineId,
                consumerAddress : msg.sender,
                queenValidationAddress : queenValidationAddress,
                gpuHours : gpuHoursInSeconds,
                startedAt : block.timestamp,
                lastChecked : block.timestamp,
                completedTicks : 0,
                completedHours : 0,
                price : msg.value,
                sshPublicKey: sshPublicKey,
                status : JobStatus.RUNNING,
                consumerRating: 0
            });
            machines[machineId].status = MachineStatus.PROCESSING;
        }
        machines[machineId].currentJobID = jobID;
        machines[machineId].completedJobs.push(jobID);
        machines[machineId].currentQueen = queenValidationAddress;
        consumers[msg.sender].jobs.push(jobID);
        queens[queenValidationAddress].jobs.push(jobID);
        queenMachines[queenValidationAddress].push(machineId);

        emit JobCreated(msg.sender, machineId, queenValidationAddress, jobID, gpuHoursInSeconds, msg.value);
        
        jobID++;
    }

    function calculateCost(uint machineId, uint gpuHours) internal view returns (uint){
        uint gpuInd = machineInfo[machines[machineId].machineInfoID].gpuID;
        uint cost =  gpus[gpuInd].price * gpuHours;
        return cost;
    } 

    function updateAssignedJob(uint machineId, uint16 value) public {
        require(msg.sender == machines[machineId].currentQueen, "!Queen");
        require(jobs[machines[machineId].currentJobID].status ==  JobStatus.VERIFYING, "!Verifying");
        
        if(drillTest(value)) {
            updateMachineHealthScore(machineId, 1, true);
            machines[machineId].status = MachineStatus.PROCESSING;
            jobs[machines[machineId].currentJobID].status = JobStatus.RUNNING;
            jobs[machines[machineId].currentJobID].startedAt = block.timestamp;
            jobs[machines[machineId].currentJobID].lastChecked = block.timestamp;
        } else {
            updateMachineHealthScore(machineId, 3, false);
            machines[machineId].status = MachineStatus.AVAILABLE;
            machines[machineId].currentQueen = address(0);
            machines[machineId].currentJobID = 0;
            jobs[machines[machineId].currentJobID].status = JobStatus.DISABLED;
            payable(jobs[machines[machineId].currentJobID].consumerAddress).transfer(jobs[machines[machineId].currentJobID].price);
            emit AmountRefunded(jobs[machines[machineId].currentJobID].consumerAddress, jobs[machines[machineId].currentJobID].price);
        }
        machines[machineId].lastDrillResult = value;
        machines[machineId].lastDrillTime = block.timestamp;
        machines[machineId].lastChecked  = block.timestamp;

        emit JobUpdated(jobs[machines[machineId].currentJobID].consumerAddress, machineId, msg.sender, machines[machineId].currentJobID, jobs[machines[machineId].currentJobID].status); 
    }

    function healthCheckBundle(HealthCheckData[] calldata healthCheckDataArray) external {
        for (uint256 i = 0; i < healthCheckDataArray.length; i++) {
            healthCheckReport(healthCheckDataArray[i]);
        }

        emit HealthCheckDataBundle(healthCheckDataArray);
    }

    function healthCheckReport(HealthCheckData calldata data) internal {
        require(msg.sender == machines[data.machineID].currentQueen, "QueenReport");
        require(jobs[machines[data.machineID].currentJobID].status ==  JobStatus.RUNNING, "!Running");
        
        if (block.timestamp - jobs[machines[data.machineID].currentJobID].lastChecked >= (tickSeconds - gracePeriod)) {

            if (healthCheckTest(data.availabilityData)) {
                machines[data.machineID].sucessfulConsecutiveHealthChecks += 1;
                if(machines[data.machineID].sucessfulConsecutiveHealthChecks == 3) {
                    updateMachineHealthScore(data.machineID, 1, true);
                    machines[data.machineID].sucessfulConsecutiveHealthChecks = 0;
                }
                jobs[machines[data.machineID].currentJobID].completedTicks += 1;
            } else {
                updateMachineHealthScore(data.machineID, 1, false);
                machines[data.machineID].sucessfulConsecutiveHealthChecks = 0;
            }
            jobs[machines[data.machineID].currentJobID].completedHours += tickSeconds;
            jobs[machines[data.machineID].currentJobID].lastChecked = block.timestamp;
            machines[data.machineID].lastChecked  = block.timestamp;

            if (jobs[machines[data.machineID].currentJobID].completedHours >= jobs[machines[data.machineID].currentJobID].gpuHours) {
                jobs[machines[data.machineID].currentJobID].status = JobStatus.COMPLETED; 
                machines[data.machineID].status = MachineStatus.AVAILABLE;
                machines[data.machineID].currentQueen = address(0);
                machines[data.machineID].currentJobID = 0;
            
                emit JobCompleted(jobs[machines[data.machineID].currentJobID].consumerAddress, data.machineID, msg.sender, machines[data.machineID].currentJobID);
            } else {
                emit JobUpdated(jobs[machines[data.machineID].currentJobID].consumerAddress, data.machineID, msg.sender, machines[data.machineID].currentJobID, jobs[machines[data.machineID].currentJobID].status); 
            }
        }
    }
}