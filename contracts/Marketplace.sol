// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

error TransactionDoesNotExist();
error BookingDoesNotExist();
error RentalDoesNotExist();
error TransactionAlreadyExists();
error BookingAlreadyExists();
error RentalAlreadyExists();
error InvalidId();

contract Marketplace is UUPSUpgradeable, OwnableUpgradeable {

    //Structs

    struct Transaction {
        bytes32 id;
        bytes32 userId; 
        bytes32 amount; 
        bytes32 balanceRemaining;
        bool isDebit; 
        bytes32 notes; 
        bytes32 createdAt;
        bytes32 updatedAt; 
    }

    struct Booking {
        bytes32 id; 
        bytes32 userId; 
        bytes32 machineId; 
        bytes32 startTime; 
        bytes32 endTime; 
        bytes32 baseCost;
        bytes32 totalCost; 
        bytes32 sshKeyId; 
        bytes32 status; 
        bytes32 notes; 
        bytes32 createdAt; 
        bytes32 updatedAt; 
    }

    struct Rental {
        bytes32 id; 
        bytes32 userId; 
        bytes32 machineId; 
        uint256 machineCount; 
        bytes32 startTime; 
        bytes32 endTime;
        bytes32 advancePaid; 
        bytes32 totalCost; 
        bytes32 sshKeyId; 
        bytes32 status; 
        bytes32 notes; 
        bytes32 createdAt; 
        bytes32 updatedAt;  
    }

    //Mappings

    mapping(bytes32 => Transaction) public transactions;
    mapping(bytes32 => Booking) public bookings;
    mapping(bytes32 => Rental) public rentals;
    mapping(bytes32 => bool) public transactionExists;
    mapping(bytes32 => bool) public bookingExists;
    mapping(bytes32 => bool) public rentalExists;


    //Events 

    event TransactionEvent(
        bytes32 id,
        bytes32 userId, 
        bytes32 amount, 
        bytes32 balanceRemaining,
        bool isDebit, 
        bytes32 notes, 
        bytes32 createdAt,
        bytes32 updatedAt  
    );

    event BookingEvent(
        bytes32 id, 
        bytes32 userId, 
        bytes32 machineId, 
        bytes32 startTime, 
        bytes32 endTime, 
        bytes32 baseCost,
        bytes32 totalCost, 
        bytes32 sshKeyId,
        bytes32 status, 
        bytes32 notes, 
        bytes32 createdAt, 
        bytes32 updatedAt 
    );

    event RentalEvent(
        bytes32 id, 
        bytes32 userId, 
        bytes32 machineId, 
        uint256 machineCount, 
        bytes32 startTime, 
        bytes32 endTime,
        bytes32 advancePaid, 
        bytes32 totalCost, 
        bytes32 sshKeyId, 
        bytes32 status, 
        bytes32 notes, 
        bytes32 createdAt, 
        bytes32 updatedAt 
    );

    /// @notice Initializes the contract
    /// @dev This function is called once when the contract is deployed
    function initialize(address initialOwner) external initializer {
        __Ownable_init(initialOwner);
    }

    /// @notice Authorizes an upgrade to a new implementation
    /// @dev This function is called as part of the upgrade process
    /// @param newImplementation Address of the new implementation contract
    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    // Functions to add data

    /// @notice Adds a new transaction
    /// @param id Unique identifier for the transaction
    /// @param userId Identifier of the user
    /// @param amount Amount credited
    /// @param balanceRemaining The remaining balance 
    /// @param isDebit Boolean for whether it is debited
    /// @param notes Remark notes 
    /// @param createdAt Transaction created at
    /// @param updatedAt Transaction updated at
    function transaction(
        bytes32  id,
        bytes32  userId,
        bytes32  amount, 
        bytes32  balanceRemaining,
        bool isDebit,
        bytes32  notes,  
        bytes32 createdAt,
        bytes32 updatedAt
    ) external onlyOwner {

        if(transactionExists[id]) 
            revert TransactionAlreadyExists();
        if(id.length == 0 || userId.length == 0) 
            revert InvalidId();
        
        transactions[id] = Transaction(
            id,
            userId,
            amount,
            balanceRemaining,
            isDebit,
            notes,
            createdAt,
            updatedAt
        );
        transactionExists[id] = true;
        emit TransactionEvent(
            id,
            userId,
            amount,
            balanceRemaining,
            isDebit,
            notes,
            createdAt,
            updatedAt
        );
    }

    /// @notice Adds a new booking
    /// @param id Unique identifier for the transaction
    /// @param userId Identifier of the user
    /// @param machineId Unique identifier for the machine
    /// @param startTime Machine usage start time
    /// @param endTime Machine usage end time
    /// @param baseCost Per hour cost of the GPU
    /// @param totalCost Total cost incurred for the usage of GPU
    /// @param sshKeyId sshKeyId value
    /// @param status Machine usage status
    /// @param notes Remarks text
    /// @param createdAt Transaction created at
    /// @param updatedAt Transaction updated at 
    function booking(
        bytes32  id, 
        bytes32  userId, 
        bytes32  machineId, 
        bytes32 startTime, 
        bytes32 endTime, 
        bytes32 baseCost,
        bytes32 totalCost, 
        bytes32  sshKeyId, 
        bytes32  status, 
        bytes32  notes, 
        bytes32 createdAt, 
        bytes32 updatedAt 
    ) external onlyOwner {

        if(bookingExists[id]) 
            revert BookingAlreadyExists();
        if(id.length == 0 || userId.length == 0) 
            revert InvalidId();
        
        bookings[id] = Booking(
            id, 
            userId, 
            machineId, 
            startTime, 
            endTime, 
            baseCost,
            totalCost, 
            sshKeyId, 
            status, 
            notes, 
            createdAt, 
            updatedAt 
        );
        bookingExists[id] = true;
        emit BookingEvent(
            id, 
            userId, 
            machineId, 
            startTime, 
            endTime, 
            baseCost,
            totalCost, 
            sshKeyId, 
            status, 
            notes, 
            createdAt, 
            updatedAt 
        );
    }

    /// @notice Adds a new booking
    /// @param id Unique identifier for the transaction
    /// @param userId Identifier of the user
    /// @param machineId Unique identifer for the machine
    /// @param machineCount Total machines rented
    /// @param startTime Machine usage start time
    /// @param endTime Machine usage end time
    /// @param advancePaid Advance paid for machine usage
    /// @param totalCost Total cost for machine usage
    /// @param sshKeyId sshKeyId value
    /// @param status Status of the machine usage
    /// @param notes Remarks notes
    /// @param createdAt Transaction created at
    /// @param updatedAt Transaction updated at
    function rental(
        bytes32  id,    
        bytes32  userId, 
        bytes32  machineId, 
        uint256 machineCount, 
        bytes32 startTime, 
        bytes32 endTime,
        bytes32 advancePaid, 
        bytes32 totalCost, 
        bytes32  sshKeyId, 
        bytes32  status, 
        bytes32  notes,
        bytes32 createdAt, 
        bytes32 updatedAt  
    ) external onlyOwner {

        if(rentalExists[id]) 
            revert RentalAlreadyExists();
        if(id.length == 0 || userId.length == 0) 
            revert InvalidId();
        
        rentals[id] = Rental(
            id, 
            userId, 
            machineId, 
            machineCount, 
            startTime, 
            endTime,
            advancePaid, 
            totalCost, 
            sshKeyId, 
            status, 
            notes,
            createdAt, 
            updatedAt  
        );
        rentalExists[id] = true;
        emit RentalEvent(
            id, 
            userId, 
            machineId, 
            machineCount, 
            startTime, 
            endTime,
            advancePaid, 
            totalCost, 
            sshKeyId, 
            status, 
            notes,
            createdAt, 
            updatedAt 
        );
    }

    //Functions to update data

    /// @notice Updates an existing transaction
    /// @param id Unique identifier for the transaction
    /// @param userId Identifier of the user
    /// @param amount Amount credited
    /// @param balanceRemaining Remaining balance 
    /// @param isDebit Boolean for whether it is debited 
    /// @param notes Remarks notes
    /// @param createdAt Transaction created at
    /// @param updatedAt Transation updated at
    function updateTransaction(
        bytes32  id,
        bytes32  userId,
        bytes32  amount, 
        bytes32  balanceRemaining,
        bool isDebit,
        bytes32  notes, 
        bytes32 createdAt,
        bytes32 updatedAt
    ) external onlyOwner {

        if(!transactionExists[id]) revert TransactionDoesNotExist();
        
        transactions[id] = Transaction(
            id,
            userId,
            amount,
            balanceRemaining,
            isDebit,
            notes,
            createdAt,
            updatedAt
        );
        emit TransactionEvent(
            id,
            userId,
            amount,
            balanceRemaining,
            isDebit,
            notes,
            createdAt,
            updatedAt
        );
    }

    /// @notice updates an existing booking 
    /// @param id Unique identifier for the transaction
    /// @param userId Identifier of the user
    /// @param machineId Unique identifier for the machine
    /// @param startTime Machine usage start time
    /// @param endTime Machine usage end time
    /// @param baseCost Per hour cost of the GPU
    /// @param totalCost Total usage costs of the GPU
    /// @param sshKeyId sshKeyId value 
    /// @param status Machine usage status
    /// @param notes Remarks notes
    /// @param createdAt Transaction created at
    /// @param updatedAt Transaction updated at 
    function updateBooking(
        bytes32  id, 
        bytes32  userId, 
        bytes32  machineId, 
        bytes32 startTime, 
        bytes32 endTime, 
        bytes32 baseCost,
        bytes32 totalCost, 
        bytes32  sshKeyId, 
        bytes32  status, 
        bytes32  notes, 
        bytes32 createdAt, 
        bytes32 updatedAt 
    ) external onlyOwner {

        if(!bookingExists[id]) revert BookingDoesNotExist();
        
        bookings[id] = Booking(
            id, 
            userId, 
            machineId, 
            startTime, 
            endTime, 
            baseCost,
            totalCost, 
            sshKeyId, 
            status, 
            notes, 
            createdAt, 
            updatedAt 
        );
        emit BookingEvent(
            id, 
            userId, 
            machineId, 
            startTime, 
            endTime, 
            baseCost,
            totalCost, 
            sshKeyId, 
            status, 
            notes, 
            createdAt, 
            updatedAt 
        );
    }

    /// @notice Updates and existing booking
    /// @param id Unique identifier for the transaction
    /// @param userId Identifier of the user
    /// @param machineId Unique identifer for the machine
    /// @param machineCount Total machines rented
    /// @param startTime Machine usage start time
    /// @param endTime Machine usage end time
    /// @param advancePaid Advance amount paid for GPU usage
    /// @param totalCost Total cost for machine usage
    /// @param sshKeyId sshKeyId value
    /// @param status Status of the machine usage
    /// @param notes Remarks notes
    /// @param createdAt Transaction created at
    /// @param updatedAt Transaction updated at
    function updateRental(
        bytes32  id, 
        bytes32  userId, 
        bytes32  machineId, 
        uint256 machineCount, 
        bytes32 startTime, 
        bytes32 endTime,
        bytes32 advancePaid, 
        bytes32 totalCost, 
        bytes32  sshKeyId, 
        bytes32  status, 
        bytes32  notes,
        bytes32 createdAt, 
        bytes32 updatedAt  
    ) external onlyOwner {

        if(!rentalExists[id]) revert RentalDoesNotExist();
        
        rentals[id] = Rental(
            id, 
            userId, 
            machineId, 
            machineCount, 
            startTime, 
            endTime,
            advancePaid, 
            totalCost, 
            sshKeyId, 
            status, 
            notes,
            createdAt, 
            updatedAt  
        );
        emit RentalEvent(
            id, 
            userId, 
            machineId, 
            machineCount, 
            startTime, 
            endTime,
            advancePaid, 
            totalCost, 
            sshKeyId, 
            status, 
            notes,
            createdAt, 
            updatedAt 
        );
    }
}