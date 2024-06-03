// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

interface IGPU {

    enum MachineStatus { NEW, AVAILABLE, VERIFYING, PROCESSING, OFFLINE, DISABLED }
    enum QueenStatus { ACTIVE, DISABLED }
    enum JobStatus { VERIFYING, RUNNING, COMPLETED, DISABLED }
    enum UserType {Provider, Consumer, Queen, NFTAddress}


    struct Gpu {
        string name;
        uint price;
        uint computeUnit; // it should be divide by 10
        bool exists;
    }

    struct User {
        address userAddress;
        UserType userType;
    }

    struct Queen {
        // address nftAddress;
        string publicKey;
        string userName;
        QueenStatus status;
        uint[] jobs;
        bool exists;
    }

    struct Provider {
        address nftAddress;
        uint[] machineIDs;
        bool exists;
    }

    struct Consumer {
        string userName;
        string organisation;
        uint[] jobs;
        bool exists;
    }

    struct MachineInfo {
        // string gpuName;
        uint gpuID;
        uint gpuQuantity; // ask aryan
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
        string ipAddress;
    }

    struct Machine {
        uint machineInfoID;
        address providerAddress;
        uint16 lastDrillResult; // array?
        uint256 lastDrillTime;
        uint lastChecked;
        uint[] completedJobs;
        address currentQueen;
        uint currentJobID;
        uint healthScore; // (0-10) for escaping float values
        uint entryTime;
        uint8 sucessfulConsecutiveHealthChecks;
        MachineStatus status;
        bool exists;
    }
   
    struct Job {
        uint machineID;
        address consumerAddress;
        address queenValidationAddress; // may have more than 1 in case of reassignQueen
        uint gpuHours;
        uint256 startedAt;
        uint256 lastChecked;
        uint16 completedTicks;
        uint256 completedHours;
        uint price;
        string sshPublicKey;
        JobStatus status;
        uint consumerRating;
    }

    struct HealthCheckData {
        uint machineID;
        uint16[] availabilityData;
    }

}