// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract RentToOwn {

    // Parameters
    // ========================================================================

    address payable public landlord;
    address payable public tenant;
    uint public rentAmount;
    uint public totalPaid;
    uint public paymentCount;
    uint public paymentsNeededForOwnership;
    bool public propertyOwned;
    uint public lastPaymentBlock;
    uint public blocksForPayment; // Number of blocks to wait for payment
    uint public cancellationPenalty; // Percentage of totalPaid to keep on cancellation


    // Constructor
    // ========================================================================

    constructor(
        address payable _landlord, 
        address payable _tenant, 
        uint _rentAmount, 
        uint _paymentsNeededForOwnership,
        uint _blocksForPayment,
        uint _cancellationPenalty
    ) {
        landlord = _landlord;
        tenant = _tenant;
        rentAmount = _rentAmount;
        paymentsNeededForOwnership = _paymentsNeededForOwnership;
        totalPaid = 0;
        paymentCount = 0;
        propertyOwned = false;
        lastPaymentBlock = block.number;
        blocksForPayment = _blocksForPayment;
        cancellationPenalty = _cancellationPenalty;
    }

    // Events
    // ========================================================================

    // Event to emit each time a payment is made
    event PaymentMade(
        address from,
        uint amount
    );

    // Methods
    // ========================================================================

    function payRent() public payable {
        require(
            msg.sender == tenant,
            "Only the tenant can make payments."
        );
        require(
            msg.value >= rentAmount,
            "Must pay at least the rent amount."
        );
        require(
            propertyOwned == false,
            "Property already owned."
        );
        
        uint excessAmount = msg.value - rentAmount;
        if (excessAmount > 0) {
            // Refund excess payment
            msg.sender.transfer(excessAmount);
        }
        
        totalPaid += rentAmount;
        paymentCount += 1;

        if (paymentCount >= paymentsNeededForOwnership) {
            propertyOwned = true;
        }
        
        landlord.transfer(rentAmount);
        
        // Update the last payment block
        lastPaymentBlock = block.number;
        
        emit PaymentMade(msg.sender, rentAmount);
    }

    function adjustRent(uint _newRentAmount) public {
        require(
            msg.sender == landlord,
            "Only the landlord can adjust the rent."
        );
        require(
            _newRentAmount <= rentAmount * 110 / 100,
            "Cannot increase rent by more than 10%."
        );
        
        rentAmount = _newRentAmount;
    }
    
    function cancelAgreement() public {
        require(
            msg.sender == tenant,
            "Only the tenant can cancel the agreement."
        );
        
        uint refundAmount = totalPaid * (100 - cancellationPenalty) / 100;
        
        // Return the refund amount to the tenant
        tenant.transfer(refundAmount);
        
        // Reset the state of the contract
        totalPaid = 0;
        paymentCount = 0;
        propertyOwned = false;
    }

    function checkPaymentDue() public view returns (bool) {
        return block.number > lastPaymentBlock + blocksForPayment;
    }

    function landlordCancelAgreement() public {
        require(
            msg.sender == landlord,
            "Only the landlord can cancel the agreement."
        );
        require(
            checkPaymentDue(),
            "Cannot cancel if payment is not due."
        );

        // The tenant forfeits a percentage of what they've paid
        uint refundAmount = totalPaid * (100 - cancellationPenalty) / 100;

        // Return the refund amount to the tenant
        tenant.transfer(refundAmount);

        // Reset the state of the contract
        totalPaid = 0;
        paymentCount = 0;
        propertyOwned = false;
    }
    
    function checkOwnership() public view returns (bool) {
        return propertyOwned;
    }

}
