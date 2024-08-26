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

    struct CreditTransaction {
        string id;
        string userId;
        string amount;
        string medium;
        string transactionId;
        uint256 timestamp;
        string remarks;
    }

    struct BookingTransaction {
        string id;
        string userId;
        string machineId;
        string amountDeducted;
        uint256 durationInHours;
        string ratePerHour;
        uint256 timestamp;
        string remarks;
    }

    struct PreBookTransaction {
        string id;
        string userId;
        string config;
        uint256 countOfMachines;
        uint256 duration;
        string orderStatus;
        bool isPaymentPartial;
        string amount;
        uint256 timestamp;
        string remarks;
    }

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

    mapping(string => CreditTransaction) public creditTransactions;
    mapping(string => BookingTransaction) public bookingTransactions;
    mapping(string => PreBookTransaction) public preBookTransactions;
    mapping(string => Transaction) public transactions;
    mapping(string => Booking) public bookings;
    mapping(string => Rental) public rentals;
    mapping(string => bool) public creditTransactionExists;
    mapping(string => bool) public bookingTransactionExists;
    mapping(string => bool) public preBookTransactionExists;
    mapping(string => bool) public transactionExists;
    mapping(string => bool) public bookingExists;
    mapping(string => bool) public rentalExists;


    //Events 

    event CreditTransactionEvent(
        string id,
        string userId,
        string amount,
        string medium,
        string transactionId,
        uint256 indexed timestamp,
        string remarks
    );

    event BookingTransactionEvent(
        string id,
        string userId,
        string machineId,
        string amountDeducted,
        uint256 durationInHours,
        string ratePerHour,
        uint256 indexed timestamp,
        string remarks
    );

    event PreBookTransactionEvent(
        string id,
        string userId,
        string config,
        uint256 countOfMachines,
        uint256 duration,
        string orderStatus,
        bool isPaymentPartial,
        string amount,
        uint256 indexed timestamp,
        string remarks
    );

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

    // Functions to add transactions

    /// @notice Adds a new credit transaction
    /// @param id Unique identifier for the transaction
    /// @param userId Identifier of the user
    /// @param amount Amount credited
    /// @param medium Medium of transaction
    /// @param transactionId External transaction identifier
    /// @param timestamp Time of the transaction
    /// @param remarks Additional notes about the transaction
    function creditTransaction(
        string calldata id,
        string calldata userId,
        string calldata amount,
        string calldata medium,
        string calldata transactionId,
        uint256 timestamp,
        string calldata remarks
    ) external onlyOwner {

        if(creditTransactionExists[id]) 
            revert TransactionAlreadyExists();
        if(bytes(id).length == 0 || bytes(userId).length == 0) 
            revert InvalidId();
        
        creditTransactions[id] = CreditTransaction(
            id,
            userId,
            amount,
            medium,
            transactionId,
            timestamp,
            remarks
        );
        creditTransactionExists[id] = true;
        emit CreditTransactionEvent(
            id,
            userId,
            amount,
            medium,
            transactionId,
            timestamp,
            remarks
        );
    }

    /// @notice Adds a new booking transaction
    /// @param id Unique identifier for the transaction
    /// @param userId Identifier of the user
    /// @param machineId Identifier of the machine booked
    /// @param amountDeducted Amount deducted for the booking
    /// @param durationInHours Duration of the booking in hours
    /// @param ratePerHour Rate charged per hour
    /// @param timestamp Time of the transaction
    /// @param remarks Additional notes about the transaction
    function bookingTransaction(
        string calldata id,
        string calldata userId,
        string calldata machineId,
        string calldata amountDeducted,
        uint256 durationInHours,
        string calldata ratePerHour,
        uint256 timestamp,
        string calldata remarks
    ) external onlyOwner {

        if(bookingTransactionExists[id]) 
            revert TransactionAlreadyExists();
        if(bytes(id).length == 0 || bytes(userId).length == 0 || bytes(machineId).length == 0) 
            revert InvalidId();

        bookingTransactions[id] = BookingTransaction(
            id,
            userId,
            machineId,
            amountDeducted,
            durationInHours,
            ratePerHour,
            timestamp,
            remarks
        );
        bookingTransactionExists[id] = true;
        emit BookingTransactionEvent(
            id,
            userId,
            machineId,
            amountDeducted,
            durationInHours,
            ratePerHour,
            timestamp,
            remarks
        );
    }

    /// @notice Adds a new pre-book transaction
    /// @param id Unique identifier for the transaction
    /// @param userId Identifier of the user
    /// @param config Configuration details for the pre-booking
    /// @param countOfMachines Number of machines pre-booked
    /// @param duration Duration of the pre-booking
    /// @param orderStatus Status of the pre-booking order
    /// @param isPaymentPartial Whether the payment is partial
    /// @param amount Amount for the pre-booking
    /// @param timestamp Time of the transaction
    /// @param remarks Additional notes about the transaction
    function preBookTransaction(
        string calldata id,
        string calldata userId,
        string calldata config,
        uint256 countOfMachines,
        uint256 duration,
        string calldata orderStatus,
        bool isPaymentPartial,
        string calldata amount,
        uint256 timestamp,
        string calldata remarks
    ) external onlyOwner {

        if(preBookTransactionExists[id]) 
            revert TransactionAlreadyExists();
        if(bytes(id).length == 0 || bytes(userId).length == 0)
            revert InvalidId();

        preBookTransactions[id] = PreBookTransaction(
            id,
            userId,
            config,
            countOfMachines,
            duration,
            orderStatus,
            isPaymentPartial,
            amount,
            timestamp,
            remarks
        );
        preBookTransactionExists[id] = true;
        emit PreBookTransactionEvent(
            id,
            userId,
            config,
            countOfMachines,
            duration,
            orderStatus,
            isPaymentPartial,
            amount,
            timestamp,
            remarks
        );
    }

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

    //Functions to update transactions

    /// @notice Updates an existing credit transaction
    /// @param id Unique identifier for the transaction to update
    /// @param userId Updated user identifier
    /// @param amount Updated amount
    /// @param medium Updated medium of transaction
    /// @param transactionId Updated external transaction identifier
    /// @param timestamp Updated time of the transaction
    /// @param remarks Updated additional notes
    /// @dev Reverts if the transaction does not exist
    function updateCreditTransaction(
        string calldata id,
        string calldata userId,
        string calldata amount,
        string calldata medium,
        string calldata transactionId,
        uint256 timestamp,
        string calldata remarks
    ) external onlyOwner {
        if(!creditTransactionExists[id]) revert TransactionDoesNotExist();
        creditTransactions[id] = CreditTransaction(
            id,
            userId,
            amount,
            medium,
            transactionId,
            timestamp,
            remarks
        );
    }

    /// @notice Updates an existing booking transaction
    /// @param id Unique identifier for the transaction to update
    /// @param userId Updated user identifier
    /// @param machineId Updated machine identifier
    /// @param amountDeducted Updated amount deducted
    /// @param durationInHours Updated duration in hours
    /// @param ratePerHour Updated rate per hour
    /// @param timestamp Updated time of the transaction
    /// @param remarks Updated additional notes
    /// @dev Reverts if the transaction does not exist
    function updateBookingTransaction(
        string calldata id,
        string calldata userId,
        string calldata machineId,
        string calldata amountDeducted,
        uint256 durationInHours,
        string calldata ratePerHour,
        uint256 timestamp,
        string calldata remarks
    ) external onlyOwner {
        if(!bookingTransactionExists[id]) revert TransactionDoesNotExist();
        bookingTransactions[id] = BookingTransaction(
            id,
            userId,
            machineId,
            amountDeducted,
            durationInHours,
            ratePerHour,
            timestamp,
            remarks
        );
    }

    /// @notice Updates an existing pre-book transaction
    /// @param id Unique identifier for the transaction to update
    /// @param userId Updated user identifier
    /// @param config Updated configuration details
    /// @param countOfMachines Updated number of machines
    /// @param duration Updated duration
    /// @param orderStatus Updated order status
    /// @param isPaymentPartial Updated payment partial status
    /// @param amount Updated amount
    /// @param timestamp Updated time of the transaction
    /// @param remarks Updated additional notes 
    /// @dev Reverts if the transaction does not exist
    function updatePreBookTransaction(
        string calldata id,
        string calldata userId,
        string calldata config,
        uint256 countOfMachines,
        uint256 duration,
        string calldata orderStatus,
        bool isPaymentPartial,
        string calldata amount,
        uint256 timestamp,
        string calldata remarks
    ) external onlyOwner {
        if(!preBookTransactionExists[id]) revert TransactionDoesNotExist();
        preBookTransactions[id] = PreBookTransaction(
            id,
            userId,
            config,
            countOfMachines,
            duration,
            orderStatus,
            isPaymentPartial,
            amount,
            timestamp,
            remarks
        );
    }

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