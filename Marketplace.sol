// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

error TransactionDoesNotExist();
error TransactionAlreadyExists();
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

    struct RefundTransaction {
        string id;
        string userId;
        string amount;
        uint256 timestamp;
        string remarks;
    }

    struct PreBookTransaction{
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

    //Mappings

    mapping(string => CreditTransaction) public creditTransactions;
    mapping(string => BookingTransaction) public bookingTransactions;
    mapping(string => RefundTransaction) public refundTransactions;
    mapping(string => PreBookTransaction) public preBookTransactions;
    mapping(string => bool) public creditTransactionExists;
    mapping(string => bool) public bookingTransactionExists;
    mapping(string => bool) public refundTransactionExists;
    mapping(string => bool) public preBookTransactionExists;


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

    event RefundTransactionEvent(
        string id,
        string userId,
        string amount,
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

    /// @notice Adds a new refund transaction
    /// @param id Unique identifier for the transaction
    /// @param userId Identifier of the user
    /// @param amount Amount refunded
    /// @param timestamp Time of the transaction
    /// @param remarks Additional notes about the transaction
    function refundTransaction(
        string calldata id,
        string calldata userId,
        string calldata amount,
        uint256 timestamp,
        string calldata remarks
    ) external onlyOwner {

        if(refundTransactionExists[id]) 
            revert TransactionAlreadyExists();
        if(bytes(id).length == 0 || bytes(userId).length == 0)
            revert InvalidId();

        refundTransactions[id] = RefundTransaction(
            id,
            userId,
            amount,
            timestamp,
            remarks
        );
        refundTransactionExists[id] = true;
        emit RefundTransactionEvent(id, userId, amount, block.timestamp, remarks);
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

    /// @notice Updates an existing refund transaction
    /// @param id Unique identifier for the transaction to update
    /// @param userId Updated user identifier
    /// @param amount Updated refund amount
    /// @param timestamp Updated time of the transaction
    /// @param remarks Updated additional notes
    /// @dev Reverts if the transaction does not exist
    function updateRefundTransaction(
        string calldata id,
        string calldata userId,
        string calldata amount,
        uint256 timestamp,
        string calldata remarks
    ) external onlyOwner {
        if(!refundTransactionExists[id]) revert TransactionDoesNotExist();
        refundTransactions[id] = RefundTransaction(
            id,
            userId,
            amount,
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
}