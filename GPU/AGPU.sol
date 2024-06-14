// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

interface IERC721 {
    function balanceOf(address nftOwner) external view returns (uint256);
}

abstract contract IGPU is OwnableUpgradeable, UUPSUpgradeable {
    enum MachineStatus {
        NEW,
        AVAILABLE,
        VERIFYING,
        PROCESSING,
        OFFLINE,
        DISABLED
    }
    enum QueenStatus {
        ACTIVE,
        DISABLED
    }
    enum JobStatus {
        VERIFYING,
        RUNNING,
        COMPLETED,
        DISABLED
    }
    enum UserType {
        Provider,
        Consumer,
        Queen,
        NFTAddress
    }

    struct Gpu {
        string name;
        uint256 price;
        uint256 computeUnit;
        bool exists;
    }

    struct User {
        address userAddress;
        UserType userType;
    }

    struct Queen {
        string publicKey;
        string userName;
        QueenStatus status;
        uint256[] jobs;
        bool exists;
    }

    struct Provider {
        address nftAddress;
        uint256[] machineIDs;
        bool exists;
    }

    struct Consumer {
        string userName;
        string organisation;
        uint256[] jobs;
        bool exists;
    }

    struct MachineInfo {
        uint256 gpuID;
        uint256 gpuQuantity;
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
        uint256 machineInfoID;
        address providerAddress;
        uint16 lastDrillResult;
        uint256 lastDrillTime;
        uint256 lastChecked;
        uint256[] completedJobs;
        address currentQueen;
        uint256 currentJobID;
        uint256 healthScore;
        uint256 entryTime;
        uint8 sucessfulConsecutiveHealthChecks;
        MachineStatus status;
        bool exists;
    }

    struct Job {
        uint256 machineID;
        address consumerAddress;
        address queenValidationAddress;
        uint256 gpuHours;
        uint256 startedAt;
        uint256 lastChecked;
        uint16 completedTicks;
        uint256 completedHours;
        uint256 price;
        string sshPublicKey;
        JobStatus status;
        uint256 consumerRating;
    }

    struct HealthCheckData {
        uint256 machineID;
        uint16[] availabilityData;
    }

    bool public initialized;
    address public nftContractAddress;
    uint16 public tickSeconds;
    uint256 public gpuID;
    uint256 public userID;
    uint256 public machineID;
    uint256 public machineInfoID;
    uint256 public jobID;

    uint256 public minDrillTestRange;
    uint256 public minMachineAvailability;
    uint256 public maxMachineUnavailability;
    uint256 public gracePeriod;

    address[] public queensList;
    address[] public providersList;

    mapping(address => bool) public nftCheck;
    mapping(uint256 => Gpu) public gpus;
    mapping(uint256 => User) public users;
    mapping(address => Queen) public queens;
    mapping(address => Provider) public providers;
    mapping(address => Consumer) public consumers;
    mapping(uint256 => Machine) public machines;
    mapping(uint256 => MachineInfo) public machineInfo;
    mapping(uint256 => Job) public jobs;
    mapping(address => uint256[]) queenMachines;
    mapping(address => uint256[]) drillQueenMachines;
    mapping(address => uint256[]) healthCheckQueenMachines;
    mapping(address => bool) isProvider;
    mapping(address => bool) isValidator;

    modifier haveNft(address nftAddress) {
        IERC721 nftContract = IERC721(nftContractAddress);
        require(nftContract.balanceOf(nftAddress) > 0, "Do not have NFT");
        _;
    }

    event Initialized(
        address owner,
        address nftContractAddress,
        uint16 tickSeconds,
        uint256 gpuID,
        uint256 userID,
        uint256 machineID,
        uint256 machineInfoID,
        uint256 jobID
    );
    event InitializedDrillTestValues(
        uint256 minDrillTestRange,
        uint256 minMachineAvailability,
        uint256 maxMachineUnavailability,
        uint256 gracePeriod
    );
    event AmountWithdrawal(address user, uint256 amount);
    event AddedGpuType(string gpuType, uint256 priceInWei, uint256 computeUnit);
    event UpdatedGpuPrice(uint256 gpuID, uint256 updatedPriceInWei);
    event QueenAdded(address sender, string publicKey, string userName);
    event ConsumerAdded(
        address consumerAddress,
        string userName,
        string organisation
    );
    event ProviderAdded(
        address indexed providerAddress,
        address indexed providerNFTAddress
    );
    event MachineAdded(
        address indexed providerAddress,
        uint256 indexed gpuID,
        uint256 indexed gpuQuantity
    );
    event MachineStatusUpdated(
        address indexed providerAddress,
        uint256 machineId,
        uint16 lastDrillResult
    );
    event MachineDrillRequested(
        address indexed providerAddress,
        uint256 machineId
    );
    event MachineHealthScoreUpdated(
        uint256 indexed machineId,
        uint256 indexed newHealthScore
    );
    event MachineDisabled(address indexed providerAddress, uint256 machineId);
    event JobCreated(
        address indexed consumerAddress,
        uint256 indexed machineId,
        address queenValidationAddress,
        uint256 jobId,
        uint256 gpuHoursInSeconds,
        uint256 price
    );
    event JobUpdated(
        address indexed consumerAddress,
        uint256 indexed machineId,
        address indexed queenAddress,
        uint256 jobId,
        JobStatus status
    );
    event JobCompleted(
        address indexed consumerAddress,
        uint256 indexed machineId,
        address indexed currentQueenAddress,
        uint256 jobID
    );
    event QueenReassign(
        address indexed consumerAddress,
        uint256 indexed machineId,
        address indexed queenAddress,
        uint256 jobId
    );
    event HealthCheckDataBundle(HealthCheckData[] healthCheckDataArray);
    event RandomHealthCheckDataBundle(HealthCheckData[] healthCheckDataArray);
    event AmountRefunded(address indexed consumerAddress, uint256 amount);

    event UpdatedNftAddress(address newNftAddress);
    event UpdatedTickSeconds(uint256 newTickSeconds);
    event UpdatedGpuId(uint256 newGpuID);
    event UpdatedUserId(uint256 newUserId);
    event UpdatedMachineId(uint256 newMachineId);
    event UpdatedMachineInfoId(uint256 machineInfoId);
    event UpdatedJobId(uint256 newJobId);

    event UpdatedMinDrillTestValue(uint256 newMinDrillTestRange);
    event UpdatedMinMachineAvailability(uint256 newMinAvailability);
    event UpdatedMaxMachineUnavailability(uint256 newMaxUnavailability);
    event UpdatedLatencyPeriod(uint256 newGracePeriod);

    event UpdatedInitializedValues(
        address owner,
        address nftContractAddress,
        uint16 tickSeconds,
        uint256 gpuID,
        uint256 userID,
        uint256 machineID,
        uint256 machineInfoID,
        uint256 jobID
    );
    event UpdatedInitializedDrillTestValues(
        uint256 minDrillTestRange,
        uint256 minMachineAvailability,
        uint256 maxMachineUnavailability,
        uint256 gracePeriod
    );

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    function getRandomQueen() internal view returns (address) {
        uint256 randomIndex = uint256(
            keccak256(
                abi.encodePacked(block.timestamp, block.number, msg.sender)
            )
        );
        address randomQueen = queensList[randomIndex % queensList.length];
        return randomQueen;
    }

    function randomDrillTest(uint256 machineId) external onlyOwner {
        require(machines[machineId].exists, "Machine not present");
        require(
            machines[machineId].status == MachineStatus.NEW ||
                machines[machineId].status == MachineStatus.AVAILABLE,
            "Machine busy"
        );
        require(
            block.timestamp >= machines[machineId].lastDrillTime + 24 hours,
            "every 24 hrs"
        );
        address queenValidationAddress = getRandomQueen();
        machines[machineId].currentQueen = queenValidationAddress;
        drillQueenMachines[queenValidationAddress].push(machineId);
        if (!(machines[machineId].status == MachineStatus.NEW))
            machines[machineId].status == MachineStatus.VERIFYING;
    }

    function randomHealthCheck(uint256 machineId) external onlyOwner {
        require(machines[machineId].exists, "Machine not present");
        require(
            block.timestamp >= machines[machineId].lastChecked + 3 hours,
            "every 3 hrs"
        );
        require(
            machines[machineId].status == MachineStatus.AVAILABLE,
            "Machine is busy"
        );
        address queenValidationAddress = getRandomQueen();
        machines[machineId].currentQueen = queenValidationAddress;
        machines[machineId].status = MachineStatus.VERIFYING;
        healthCheckQueenMachines[queenValidationAddress].push(machineId);
    }

    function randomHealthCheckReport(HealthCheckData calldata data) internal {
        require(
            msg.sender == machines[data.machineID].currentQueen,
            "Only assigned queen can call"
        );
        if (healthCheckTest(data.availabilityData)) {
            machines[data.machineID].sucessfulConsecutiveHealthChecks += 1;
            if (
                machines[data.machineID].sucessfulConsecutiveHealthChecks == 3
            ) {
                updateMachineHealthScore(data.machineID, 1, true);
                machines[data.machineID].sucessfulConsecutiveHealthChecks = 0;
            }
        } else {
            updateMachineHealthScore(data.machineID, 1, false);
            machines[data.machineID].sucessfulConsecutiveHealthChecks = 0;
        }
        machines[data.machineID].lastChecked = block.timestamp;
        machines[data.machineID].status = MachineStatus.AVAILABLE;
        machines[data.machineID].currentQueen = address(0);
    }

    function randomHealthCheckBundle(
        HealthCheckData[] calldata healthCheckDataArray
    ) external {
        for (uint256 i = 0; i < healthCheckDataArray.length; i++) {
            randomHealthCheckReport(healthCheckDataArray[i]);
        }

        emit RandomHealthCheckDataBundle(healthCheckDataArray);
    }

    function drillTest(uint256 value) internal view returns (bool) {
        if (value > minDrillTestRange) {
            return true;
        }
        return false;
    }

    function updateMachineHealthScore(
        uint256 machineId,
        uint8 score,
        bool increase
    ) internal {
        uint256 newHealthScore = (increase == true)
            ? (machines[machineId].healthScore + score)
            : (machines[machineId].healthScore - score);
        if (newHealthScore > 10) {
            newHealthScore = 10;
        }
        if (newHealthScore < 0) {
            newHealthScore = 0;
        }
        machines[machineId].healthScore = newHealthScore;

        emit MachineHealthScoreUpdated(machineId, newHealthScore);
    }

    function healthCheckTest(uint16[] calldata value)
        internal
        view
        returns (bool)
    {
        if (
            value[0] > minMachineAvailability &&
            value[1] < maxMachineUnavailability
        ) {
            return true;
        }
        return false;
    }

    function isRegistered(address user) public view returns (bool) {
        return isProvider[user] || isValidator[user];
    }

    function getProviders() public view returns (address[] memory) {
        return providersList;
    }

    function getNFTAddress(address providerAddress)
        public
        view
        returns (address)
    {
        return providers[providerAddress].nftAddress;
    }

    function getProviderComputeDetails(address providerAddress)
        public
        view
        returns (uint256, uint256)
    {
        uint256[] memory machineArray = providers[providerAddress].machineIDs;
        uint256 totalComputeUnit = 0;
        uint256 totalHealthScore = 0;
        uint256 numberOfMachines = machineArray.length;
        for (uint256 i = 0; i < numberOfMachines; i++) {
            if (
                machines[machineArray[i]].status == MachineStatus.AVAILABLE ||
                machines[machineArray[i]].status == MachineStatus.VERIFYING ||
                machines[machineArray[i]].status == MachineStatus.PROCESSING
            ) {
                uint256 machineInfoId = machines[machineArray[i]].machineInfoID;
                totalComputeUnit +=
                    machineInfo[machineInfoId].gpuQuantity *
                    gpus[machineInfo[machineInfoId].gpuID].computeUnit;
                totalHealthScore += machines[machineArray[i]].healthScore;
            }
        }
        uint256 avgHealthScore = numberOfMachines > 0
            ? totalHealthScore / numberOfMachines
            : 0;
        return (totalComputeUnit, avgHealthScore);
    }

    function getDrillQueenMachines(address queenAddress)
        public
        view
        returns (uint256[] memory)
    {
        return drillQueenMachines[queenAddress];
    }

    function getQueenMachines(address queenAddress)
        public
        view
        returns (uint256[] memory)
    {
        return queenMachines[queenAddress];
    }

    function getProviderMachines() public view returns (uint256[] memory) {
        return providers[msg.sender].machineIDs;
    }

    function getHealthQueenMachines(address queenAddress)
        public
        view
        returns (uint256[] memory)
    {
        return healthCheckQueenMachines[queenAddress];
    }
}