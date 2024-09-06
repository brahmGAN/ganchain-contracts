// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.20;

import "./IGPU.sol";

contract AddProvider is IGPU {

    function addProvider(address providerAddress) external haveNft(msg.sender){
        require(!isValidator[msg.sender],"AlreadyValidator");
        require(!isProvider[msg.sender], "AddressUsed");
        require(!providers[providerAddress].exists, "Exists");
        require(!queens[providerAddress].exists, "AlreadyQueen");

        providers[providerAddress] = Provider({
            nftAddress: msg.sender,
            machineIDs: new uint256[](0),
            exists: true
        });

        users[userID] = User({
            userAddress: providerAddress,
            userType: UserType.Provider
        });
        userID++;

        users[userID] = User({
            userAddress: msg.sender,
            userType: UserType.NFTAddress
        });
        userID++;

        providersList.push(providerAddress);

        isProvider[msg.sender] = true;

        nftAddressToProviderAddress[msg.sender] = providerAddress;

        emit ProviderAdded(providerAddress, msg.sender);
    }

    function addMachine(MachineInfo memory machineDetails) external {
        require(providers[msg.sender].exists, "!Provider");
        require(gpus[machineDetails.gpuID].exists, "!GPU");
        require(machineDetails.gpuQuantity > 0, "!GPUQuantity");
        require(machineDetails.gpuMemory > 0, "!GPUMemory");
        require(
            bytes(machineDetails.connectionType).length > 0,
            "!ConnectionType"
        );
        require(bytes(machineDetails.cpuName).length > 0, "!Name");
        require(machineDetails.cpuCoreCount > 0, "!Corecount");
        require(
            machineDetails.uploadBandWidth > 0 &&
                machineDetails.downloadBandWidth > 0,
            "!Bandwidth"
        );
        require(
            bytes(machineDetails.storageType).length > 0,
            "!GPUStorage"
        );
        require(
            machineDetails.storageAvailable > 0,
            "!AvailableStorage"
        );
        require(machineDetails.portsOpen.length > 0, "!Ports");
        require(bytes(machineDetails.region).length > 0, "!Region");

        machineDetails.machineInfoId = machineInfoID;
        machineInfo[machineInfoID] = machineDetails;
        address queenValidationAddress = getRandomQueen();

        machines[machineID] = Machine({
            machineId: machineID,
            machineInfoID: machineInfoID,
            providerAddress: msg.sender,
            lastDrillResult: 0,
            lastDrillTime: 0,
            completedJobs: new uint256[](0),
            currentQueen: queenValidationAddress,
            healthScore: 5,
            lastChecked: 0,
            currentJobID: 0,
            entryTime: 0,
            sucessfulConsecutiveHealthChecks: 0,
            status: MachineStatus.NEW,
            exists: true
        });

        drillQueenMachines[queenValidationAddress].push(machineID);
        providers[msg.sender].machineIDs.push(machineID);

        emit MachineAdded(
            msg.sender,
            machineID
        );
        machineInfoID++;
        machineID++;

        
    }

    function updateMachineStatus(uint machineId,uint16 value) public {
        require(msg.sender == machines[machineId].currentQueen, "!Queen");
        if(drillTest(value)) {
            if(machines[machineId].status == MachineStatus.NEW){
                machines[machineId].entryTime = block.timestamp;
            }
            machines[machineId].status = MachineStatus.AVAILABLE;
            updateMachineHealthScore(machineId, 1, true);
        } else {
            updateMachineHealthScore(machineId, 3, false);
        }
        machines[machineId].currentQueen = address(0);
        machines[machineId].lastDrillResult = value;
        machines[machineId].lastDrillTime = block.timestamp;
        machines[machineId].lastChecked  = block.timestamp;

        emit MachineStatusUpdated(msg.sender, machineId, value);
    }

    function disableMachine(uint256 machineId) public {
        require(
            msg.sender == machines[machineId].providerAddress || msg.sender == scheduler,
            "!Machine"
        );
        machines[machineId].status = MachineStatus.DISABLED;
        emit MachineDisabled(msg.sender, machineId);
    }

}