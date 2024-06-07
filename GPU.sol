// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.20;

import "./IGPU.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

interface IERC721 {
    function balanceOf(address nftOwner) external view returns(uint);
}

contract GPU is IGPU, OwnableUpgradeable, UUPSUpgradeable {
    
    bool public initialized;
    address public nftContractAddress;
    uint16 public tickSeconds;
    uint public gpuID;
    uint public userID;
    uint public machineID;
    uint public machineInfoID;
    uint public jobID;

    uint public minDrillTestRange;
    uint public minMachineAvailability;
    uint public maxMachineUnavailability;
    uint public gracePeriod;
    
    address[] public queensList;
    address[] public providersList;

    mapping(address => bool) public nftCheck;
    mapping(uint => Gpu) public gpus;
    mapping(uint => User) public users;
    mapping(address => Queen) public queens;
    mapping(address => Provider) public providers;
    mapping(address => Consumer) public consumers;
    mapping(uint => Machine) public machines;
    mapping(uint => MachineInfo) public machineInfo;
    mapping(uint => Job) public jobs;
    mapping(address => uint[]) public queenMachines;
    mapping(address => uint[]) public drillQueenMachines;
    mapping(address => uint[]) public healthCheckQueenMachines;

    modifier haveNft(address nftAddress){
        IERC721 nftContract = IERC721(nftContractAddress);
        require(nftContract.balanceOf(nftAddress) > 0, "Do not have NFT");
        _;
    }

    event Initialized(address owner, address nftContractAddress, uint16 tickSeconds, uint gpuID, uint userID, uint machineID, uint machineInfoID, uint jobID);
    event InitializedDrillTestValues(uint minDrillTestRange, uint minMachineAvailability, uint maxMachineUnavailability, uint256 gracePeriod);
    event AmountWithdrawal(address user, uint amount);
    event AddedGpuType(string gpuType, uint priceInWei, uint computeUnit);
    event UpdatedGpuPrice(uint gpuID, uint updatedPriceInWei);
    event QueenAdded(address sender, string publicKey, string userName);
    event ConsumerAdded(address consumerAddress, string userName, string organisation);
    event ProviderAdded(address indexed providerAddress, address indexed providerNFTAddress);
    event MachineAdded(address indexed providerAddress, uint indexed gpuID, uint indexed gpuQuantity);
    event MachineStatusUpdated(address indexed providerAddress, uint machineId, uint16 lastDrillResult);
    event MachineDrillRequested( address indexed providerAddress, uint machineId);
    event MachineHealthScoreUpdated(uint indexed machineId, uint indexed newHealthScore);
    event MachineDisabled(address indexed providerAddress, uint machineId);
    event JobCreated(address indexed consumerAddress, uint indexed machineId, address queenValidationAddress, uint jobId, uint gpuHoursInSeconds, uint price);
    event JobUpdated(address indexed consumerAddress, uint indexed machineId, address indexed queenAddress, uint jobId, JobStatus status);
    event JobCompleted(address indexed consumerAddress, uint indexed machineId, address indexed currentQueenAddress, uint jobID);
    event QueenReassign(address indexed consumerAddress, uint indexed machineId, address indexed queenAddress, uint jobId);
    event HealthCheckDataBundle(HealthCheckData[] healthCheckDataArray);
    event AmountRefunded(address indexed consumerAddress, uint amount);

    event UpdatedInitializedValues(address owner, address nftContractAddress, uint16 tickSeconds, uint gpuID, uint userID, uint machineID, uint machineInfoID, uint jobID);
    event UpdatedInitializedDrillTestValues(uint minDrillTestRange, uint minMachineAvailability, uint maxMachineUnavailability, uint256 gracePeriod);

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function initialize(address NftContractAddress, uint16 TickSeconds, uint GpuID, uint UserID, uint MachineID, uint MachineInfoID, uint JobID, 
        uint MinDrillTestRange, uint MinMachineAvailability, uint MaxMachineUnavailability, uint GracePeriod) public initializer {
        require(!initialized, "Contract is already initialized");
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

    function withdraw(uint amount) external onlyOwner {
        payable(msg.sender).transfer(amount);
        emit AmountWithdrawal(msg.sender, amount);
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

    function addQueen(address queenAddress, string calldata publicKey, string calldata userName) external onlyOwner {
        require(!queens[queenAddress].exists, "Queen already present");
        require(!providers[queenAddress].exists, "Already a Provider");
        require(bytes(userName).length > 0, "User name is empty");
        require(bytes(publicKey).length > 0, "Public key is empty");

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

        emit QueenAdded(queenAddress, publicKey, userName);
    }

    function addConsumer(address consumerAddress, string calldata userName, string calldata organisation) external {
        require(!consumers[consumerAddress].exists, "Consumer already present");

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

    function addProvider(address providerAddress) external {
        require(!nftCheck[msg.sender],"NFT address already used");
        require(!providers[providerAddress].exists, "Provider already present");
        require(!queens[providerAddress].exists, "Already a Queen");
        
        nftCheck[msg.sender] = true;
        providers[providerAddress] = Provider({
            nftAddress : msg.sender,
            machineIDs : new uint[](0),
            exists : true
        });

        users[userID] = User({
            userAddress : providerAddress,
            userType : UserType.Provider
        });
        userID++;

        users[userID] = User({
            userAddress : msg.sender,
            userType : UserType.NFTAddress
        });
        userID++;

        providersList.push(providerAddress);

        emit ProviderAdded(providerAddress, msg.sender);
    }

    function addMachine(MachineInfo memory machineDetails) external {
        require(providers[msg.sender].exists, "Provider not present");
        require(gpus[machineDetails.gpuID].exists, "GPU not present" );
        require(machineDetails.gpuQuantity > 0, "GPU quantity not found");
        require(machineDetails.gpuMemory > 0, "GPU memory required");
        require(bytes(machineDetails.connectionType).length > 0, "Connection type not found");
        require(bytes(machineDetails.cpuName).length > 0, "CPU name not found");
        require(machineDetails.cpuCoreCount > 0, "CPU core count required");
        require(machineDetails.uploadBandWidth > 0 && machineDetails.downloadBandWidth > 0, "bandwidth not found");
        require(bytes(machineDetails.storageType).length > 0, "GPU storage not found");
        require(machineDetails.storageAvailable > 0, "Available storage value not found");
        require(machineDetails.portsOpen.length > 0, "Ports not found");
        require(bytes(machineDetails.region).length > 0, "Region not found");

        machineInfo[machineInfoID] = machineDetails;
        address queenValidationAddress = getRandomQueen();

        machines[machineID] = Machine({
            machineInfoID : machineInfoID,
            providerAddress : msg.sender,
            lastDrillResult : 0,
            lastDrillTime : 0,
            completedJobs : new uint[](0),
            currentQueen : queenValidationAddress,
            healthScore : 5,
            lastChecked : 0,
            currentJobID : 0,
            entryTime : 0,
            sucessfulConsecutiveHealthChecks: 0,
            status : MachineStatus.NEW,
            exists : true
        });

        drillQueenMachines[queenValidationAddress].push(machineID);
        providers[msg.sender].machineIDs.push(machineID);
        machineInfoID++;
        machineID++;
        
        emit MachineAdded(msg.sender, machineDetails.gpuID, machineDetails.gpuQuantity);
    }

    function updateMachineStatus(uint machineId,uint16 value) public {
        require(msg.sender == machines[machineId].currentQueen, "Only assigned queen can call");
        if(drillTest(value)) {
            if(machines[machineId].status == MachineStatus.NEW){
                machines[machineId].entryTime = block.timestamp;
            }
            machines[machineId].status = MachineStatus.AVAILABLE;
            updateMachineHealthScore(machineId, 1, true);
        } else {
            updateMachineHealthScore(machineId, 3, false);
            machines[machineId].entryTime = block.timestamp;
        }
        machines[machineId].currentQueen = address(0);
        machines[machineId].lastDrillResult = value;
        machines[machineId].lastDrillTime = block.timestamp;
        machines[machineId].lastChecked  = block.timestamp;

        emit MachineStatusUpdated(msg.sender, machineId, value);
    }

    function randomDrillTest(uint machineId) external onlyOwner{
        require(machines[machineId].exists, "Machine not present");
        require(machines[machineId].status == MachineStatus.NEW || machines[machineId].status == MachineStatus.AVAILABLE,"Machine busy");
        address queenValidationAddress = getRandomQueen();
        machines[machineId].currentQueen = queenValidationAddress;
        drillQueenMachines[queenValidationAddress].push(machineId);
        if(!(machines[machineId].status == MachineStatus.NEW))
            machines[machineId].status == MachineStatus.VERIFYING;
    }

    function randomHealthCheck(uint machineId) external onlyOwner {
        require(machines[machineId].exists,"Machine not present");
        require(block.timestamp >= machines[machineId].lastChecked + 3 hours, "every 3 hrs");
        require(machines[machineId].status == MachineStatus.AVAILABLE ,"Machine is busy");
        address queenValidationAddress = getRandomQueen();
        machines[machineId].currentQueen = queenValidationAddress;
        machines[data.machineID].status = MachineStatus.VERIFYING;
        healthCheckQueenMachines[queenValidationAddress].push(machineId);
    }

    function randomHealthCheckReport(HealthCheckData calldata data) internal {
        require(msg.sender == machines[data.machineID].currentQueen, "Only assigned queen can call");
            if (healthCheckTest(data.availabilityData)) {
                machines[data.machineID].sucessfulConsecutiveHealthChecks += 1;
                if(machines[data.machineID].sucessfulConsecutiveHealthChecks == 3) {
                    updateMachineHealthScore(data.machineID, 1, true);
                    machines[data.machineID].sucessfulConsecutiveHealthChecks = 0;
                }
            } else {
                updateMachineHealthScore(data.machineID, 1, false);
                machines[data.machineID].sucessfulConsecutiveHealthChecks = 0;
            }
            machines[data.machineID].lastChecked  = block.timestamp;
            machines[data.machineID].status = MachineStatus.AVAILABLE;
            machines[data.machineID].currentQueen = address(0);
            }
    }

    function randomHealthCheckBundle(HealthCheckData[] calldata healthCheckDataArray) external {
        for (uint256 i = 0; i < healthCheckDataArray.length; i++) {
            randomHealthCheckReport(healthCheckDataArray[i]);
        }

        emit HealthCheckDataBundle(healthCheckDataArray);
    }

    function createJob(uint machineId, uint gpuHours, string calldata sshPublicKey, bool requireDrill ) external payable {
        uint cost = calculateCost(machineId,gpuHours);
        require(consumers[msg.sender].exists, "Consumer must exist");
        require(msg.value == cost, "Deposit some GPoints");
        require(bytes(sshPublicKey).length > 0, "SSH public key not found");
        require(machines[machineId].status == MachineStatus.AVAILABLE, "Machine not available");
        require(queensList.length > 0, "Queen not present");

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
        require(msg.sender == machines[machineId].currentQueen, "Only assigned queen can call");
        require(jobs[machines[machineId].currentJobID].status ==  JobStatus.VERIFYING, "Call only when job is verifying");
        
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

    function getRandomQueen() internal view returns (address) {
        uint randomIndex = uint(keccak256(abi.encodePacked(block.timestamp, block.number, msg.sender)));
        address randomQueen = queensList[randomIndex % queensList.length];
        return randomQueen;
    }

    function drillTest(uint value) internal view returns(bool){
        if (value > minDrillTestRange) {
            return true;
        }
        return false;
    }

    function healthCheckBundle(HealthCheckData[] calldata healthCheckDataArray) external {
        for (uint256 i = 0; i < healthCheckDataArray.length; i++) {
            healthCheckReport(healthCheckDataArray[i]);
        }

        emit HealthCheckDataBundle(healthCheckDataArray);
    }

    function healthCheckReport(HealthCheckData calldata data) internal {
        require(msg.sender == machines[data.machineID].currentQueen, "Only assigned queen can call");
        require(jobs[machines[data.machineID].currentJobID].status ==  JobStatus.RUNNING, "Call only when job is running");
        
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

    function reassignQueen(uint machineId) external {
        require(machines[machineId].status == MachineStatus.PROCESSING, "Provider not running");
        require(machines[machineId].providerAddress == msg.sender, "Not your machine");
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

    function healthCheckTest(uint16[] calldata value) internal view returns(bool){
        if (value[0] > minMachineAvailability && value[1] < maxMachineUnavailability) {
            return true;
        }
        return false;
    }

    function disableMachine(uint machineId) public {
        require(msg.sender == machines[machineId].providerAddress, "Not your machine");
        machines[machineId].status = MachineStatus.DISABLED;
        emit MachineDisabled(msg.sender, machineId);
    }

    function submitConsumerRating(uint jobId, uint rating) public {
        require(msg.sender == jobs[jobId].consumerAddress, "invalid consumer");
        require(jobs[jobId].consumerRating == 0, "rating already submitted");

        jobs[jobId].consumerRating = rating;
        if(rating == 10){
            updateMachineHealthScore(jobs[jobId].machineID, 1, true);
        } else if(rating >=4 && rating <= 6) {
            updateMachineHealthScore(jobs[jobId].machineID, 1, false);
        } else if(rating >=1 && rating <= 3) {
            updateMachineHealthScore(jobs[jobId].machineID, 2, false);
        }
    }

    function updateMachineHealthScore(uint machineId, uint8 score, bool increase) internal {
        uint newHealthScore = (increase == true) ? (machines[machineId].healthScore + score) : (machines[machineId].healthScore - score);
        if(newHealthScore > 10) { newHealthScore = 10; }
        if(newHealthScore < 0) { newHealthScore = 0; }
        machines[machineId].healthScore = newHealthScore;

        emit MachineHealthScoreUpdated(machineId, newHealthScore);
    }

    function updateInitializedValues(address newNftContractAddress, uint16 newTickSeconds, uint newGpuID, uint newUserID, uint newMachineID, uint newMachineInfoID, uint newJobID, 
        uint newMinDrillTestRange, uint newMinMachineAvailability, uint newMaxMachineUnavailability, uint newGracePeriod) external onlyOwner {
        nftContractAddress = newNftContractAddress;
        tickSeconds = newTickSeconds;
        gpuID = newGpuID;
        userID = newUserID;
        machineID = newMachineID;
        machineInfoID = newMachineInfoID;
        jobID = newJobID;

        minDrillTestRange = newMinDrillTestRange;
        minMachineAvailability = newMinMachineAvailability;
        maxMachineUnavailability = newMaxMachineUnavailability;
        gracePeriod = newGracePeriod;

        emit UpdatedInitializedValues(msg.sender, nftContractAddress, tickSeconds, gpuID, userID, machineID, machineInfoID, jobID);
        emit UpdatedInitializedDrillTestValues(minDrillTestRange, minMachineAvailability, maxMachineUnavailability, gracePeriod);
    }

    //GETTER FUNCTION
    function getProviders() public view returns(address[] memory) {
        return providersList;
    }

    function getNFTAddress(address providerAddress) public view returns (address){
        return providers[providerAddress].nftAddress;
    }

    function getProviderComputeDetails(address providerAddress) public  view  returns (uint,uint) {
        uint[] memory machineArray = providers[providerAddress].machineIDs;
        uint totalComputeUnit = 0;
        uint totalHealthScore = 0;
        uint numberOfMachines = machineArray.length;
        for (uint i= 0; i < numberOfMachines; i++){
            if(machines[machineArray[i]].status == MachineStatus.AVAILABLE || machines[machineArray[i]].status == MachineStatus.VERIFYING || machines[machineArray[i]].status == MachineStatus.PROCESSING)
            {
                uint machineInfoId = machines[machineArray[i]].machineInfoID;
                totalComputeUnit += machineInfo[machineInfoId].gpuQuantity * gpus[machineInfo[machineInfoId].gpuID].computeUnit;
                totalHealthScore += machines[machineArray[i]].healthScore;
            } 
        }
        uint avgHealthScore = numberOfMachines > 0 ? totalHealthScore / numberOfMachines : 0;
        return (totalComputeUnit, avgHealthScore);
    }

    function getDrillQueenMachines(address queenAddress) public view returns(uint[] memory){
        return drillQueenMachines[queenAddress];
    }

    function getQueenMachines(address queenAddress) public view returns(uint[] memory){
        return queenMachines[queenAddress];
    }

    function getProviderMachines() public view returns (uint[] memory){
        return providers[msg.sender].machineIDs;
    }

    function getHealthQueenMachines(address queenAddress) public view returns(uint[] memory){
        return healthCheckQueenMachines[queenAddress];
    }

}