// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.20;
interface IGPU {
    // Enums
    enum ConsumerStatus { ACTIVE, DISABLED }
    enum ProviderStatus { NEW, AVAILABLE, VERIFYING, PROCESSING, OFFLINE, DISABLED }
    enum QueenStatus { ACTIVE, DISABLED }
    enum JobStatus { VERIFYING, RUNNING, COMPLETED, DISABLED }
    
   
    // Structs
    struct Queen {
        string publicKey;
        string userName;
        QueenStatus status;
        bool exists;
    }

    struct Provider {
        uint16 gpuType;
        string ipAddress;
        uint machineId;
        uint16 currentJobId;
        address currentConsumer;
        address currentQueen;
        uint16 lastDrillResult;
        uint256 lastDrillTime;
        bool exists;
        ProviderStatus status;
    }
    
    struct Consumer {
        string userName;
        string organisation;
        uint16 nextJobId;
        uint16[] jobs;
        bool exists;
    }
    
    struct Job {
        address providerAddress;
        address consumerAddress;
        address queenValidationAddress;
        uint16 gpuType;
        uint256 gpuHours; 
        uint256 startedAt;
        uint256 lastChecked;
        uint16 completedTicks;
        uint256 completedHours;
        uint price;
        string sshPublicKey;
        JobStatus status;
    }
    
    struct HealthCheckData {
        address providerAddress;
        uint16[] availabilityData;
    }

    struct Machine {
        string gpuName;
        uint16 gpuQuantity;
        uint64 gpuMemory;
        string connectionType;
        string cpuName;
        uint256 cpuCoreCount;
        uint256 uploadBandWidth;
        uint256 downloadBandWidth;
        string storageType;
        uint256 storageAvailable;
        uint256[] portsOpen;
        string region;
    }
}