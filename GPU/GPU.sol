// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.20;

import "./AddProvider.sol";
import "./AddQueen.sol";
import "./Jobs.sol";
import "./AddConsumer.sol";

contract GPU is AddProvider, AddQueen, AddJobs, AddConsumer {
    function initialize(address NftContractAddress, uint16 TickSeconds, uint GpuID, uint UserID, uint MachineID, uint MachineInfoID, uint JobID, 
        uint MinDrillTestRange, uint MinMachineAvailability, uint MaxMachineUnavailability, uint GracePeriod) public initializer {
        require(!initialized, "ContractInitialized");
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        nftContractAddress = NftContractAddress;
        tickSeconds = TickSeconds;
        gpuID = GpuID;
        userID = UserID;
        machineID = MachineID;
        machineInfoID = MachineInfoID;
        jobID = JobID;

        minDrillTestRange = MinDrillTestRange;
        minMachineAvailability = MinMachineAvailability;
        maxMachineUnavailability = MaxMachineUnavailability;
        gracePeriod = GracePeriod;

        initialized = true;

        emit Initialized(msg.sender, nftContractAddress, tickSeconds, gpuID, userID, machineID, machineInfoID, jobID);
        emit InitializedDrillTestValues(minDrillTestRange, minMachineAvailability, maxMachineUnavailability, gracePeriod);
    }

    function addGpuType(string calldata gpuName, uint256 priceInWei, uint computeUnit) external onlyOwner {
        gpus[gpuID] = Gpu({
            name : gpuName,
            price : priceInWei,
            computeUnit : computeUnit,
            exists : true
        });
        gpuID++;

        emit AddedGpuType(gpuName, priceInWei, computeUnit);
    }
    
    function updateGpuPrice(uint16 gpuMappedID, uint256 updatedPriceInWei) public onlyOwner {
        gpus[gpuMappedID].price = updatedPriceInWei;
        emit UpdatedGpuPrice(gpuMappedID, updatedPriceInWei); 
    }
}

