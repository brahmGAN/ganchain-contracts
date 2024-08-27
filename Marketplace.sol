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
        string id;
        string userId; 
        string amount; 
        string balanceRemaining;
        bool isDebit; 
        string notes; 
        uint256 createdAt;
        uint256 updatedAt; 
    }

    struct Booking {
        string id; 
        string userId; 
        string machineId; 
        uint256 startTime; 
        uint256 endTime; 
        uint256 baseCost;
        uint256 totalCost; 
        string sshKeyId; 
        string status; 
        string notes; 
        uint256 createdAt; 
        uint256 updatedAt; 
    }

    struct Rental {
        string id; 
        string userId; 
        string machineId; 
        uint256 machineCount; 
        uint256 startTime; 
        uint256 endTime;
        uint256 advancePaid; 
        uint256 totalCost; 
        string sshKeyId; 
        string status; 
        string notes; 
        uint256 createdAt; 
        uint256 updatedAt;  
    }

    //Mappings

    mapping(string => Transaction) public transactions;
    mapping(string => Booking) public bookings;
    mapping(string => Rental) public rentals;
    mapping(string => bool) public transactionExists;
    mapping(string => bool) public bookingExists;
    mapping(string => bool) public rentalExists;


    //Events 

    event TransactionEvent(
        string id,
        string userId, 
        string amount, 
        string balanceRemaining,
        bool isDebit, 
        string notes, 
        uint256 indexed createdAt,
        uint256 updatedAt  
    );

    event BookingEvent(
        string id, 
        string userId, 
        string machineId, 
        uint256 startTime, 
        uint256 endTime, 
        uint256 baseCost,
        uint256 totalCost, 
        string sshKeyId,
        string status, 
        string notes, 
        uint256 createdAt, 
        uint256 updatedAt 
    );

    event RentalEvent(
        string id, 
        string userId, 
        string machineId, 
        uint256 machineCount, 
        uint256 startTime, 
        uint256 endTime,
        uint256 advancePaid, 
        uint256 totalCost, 
        string sshKeyId, 
        string status, 
        string notes, 
        uint256 createdAt, 
        uint256 updatedAt 
    );

    /// @notice Initializes the contract
    /// @dev This function is called once when the contract is deployed
    function initialize() external initializer {
        __Ownable_init();
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
    /// @param balanceRemaining 
    /// @param isDebit 
    /// @param notes 
    /// @param createdAt 
    /// @param updatedAt 
    function transaction(
        string calldata id,
        string calldata userId,
        string calldata amount, 
        string calldata balanceRemaining,
        bool calldata isDebit,
        string calldata notes,  
        uint256 calldata createdAt,
        uint256 calldata updatedAt
    ) external onlyOwner {

        if(transactionExists[id]) 
            revert TransactionAlreadyExists();
        if(bytes(id).length == 0 || bytes(userId).length == 0) 
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
    /// @param baseCost 
    /// @param totalCost
    /// @param sshKeyId 
    /// @param status Machine usage status
    /// @param notes 
    /// @param createdAt
    /// @param updatedAt
    function booking(
        string id, 
        string userId, 
        string machineId, 
        uint256 startTime, 
        uint256 endTime, 
        uint256 baseCost,
        uint256 totalCost, 
        string sshKeyId, 
        string status, 
        string notes, 
        uint256 createdAt, 
        uint256 updatedAt 
    ) external onlyOwner {

        if(bookingExists[id]) 
            revert BookingAlreadyExists();
        if(bytes(id).length == 0 || bytes(userId).length == 0) 
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
    /// @param advancePaid
    /// @param totalCost Total cost for machine usage
    /// @param sshKeyId
    /// @param status
    /// @param notes
    /// @param createdAt
    /// @param updatedAt 
    function rental(
        string id, 
        string userId, 
        string machineId, 
        uint256 machineCount, 
        uint256 startTime, 
        uint256 endTime,
        uint256 advancePaid, 
        uint256 totalCost, 
        string sshKeyId, 
        string status, 
        string notes,
        uint256 createdAt, 
        uint256 updatedAt  
    ) external onlyOwner {

        if(rentalExists[id]) 
            revert RentalAlreadyExists();
        if(bytes(id).length == 0 || bytes(userId).length == 0) 
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
    /// @param balanceRemaining 
    /// @param isDebit 
    /// @param notes 
    /// @param createdAt 
    /// @param updatedAt
    function updateTransaction(
        string calldata id,
        string calldata userId,
        string calldata amount, 
        string calldata balanceRemaining,
        bool calldata isDebit,
        string calldata notes, 
        uint256 calldata createdAt,
        uint256 calldata updatedAt
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
    /// @param baseCost 
    /// @param totalCost
    /// @param sshKeyId 
    /// @param status Machine usage status
    /// @param notes
    /// @param createdAt
    /// @param updatedAt
    function updateBooking(
        string id, 
        string userId, 
        string machineId, 
        uint256 startTime, 
        uint256 endTime, 
        uint256 baseCost,
        uint256 totalCost, 
        string sshKeyId, 
        string status, 
        string notes, 
        uint256 createdAt, 
        uint256 updatedAt 
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
    /// @param advancePaid
    /// @param totalCost Total cost for machine usage
    /// @param sshKeyId
    /// @param status
    /// @param notes
    /// @param createdAt
    /// @param updatedAt 
    function updateRental(
        string id, 
        string userId, 
        string machineId, 
        uint256 machineCount, 
        uint256 startTime, 
        uint256 endTime,
        uint256 advancePaid, 
        uint256 totalCost, 
        string sshKeyId, 
        string status, 
        string notes,
        uint256 createdAt, 
        uint256 updatedAt  
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