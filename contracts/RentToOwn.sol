// SPDX-License-Identifier: Apache-2.0


// Copyright 2023 Stichting Block Foundation
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.


pragma solidity ^0.8.19;


/// @title Rent-to-Own Contract
/// @dev This contract facilitates rent-to-own agreements where a portion of monthly rent payments goes towards eventual ownership of the property.
contract RentToOwn {


    // Parameters
    // ========================================================================

    /// @notice The landlord's address
    /// @dev This address is payable, meaning it can receive funds
    address payable public landlord;

    /// @notice The tenant's address
    /// @dev This address is payable, meaning it can receive funds
    address payable public tenant;

    /// @notice The monthly rent amount
    uint public rentAmount;

    /// @notice The total amount that has been paid so far
    uint public totalPaid;

    /// @notice The number of payments that have been made
    uint public paymentCount;

    /// @notice The total number of payments needed to transfer ownership
    uint public paymentsNeededForOwnership;

    /// @notice Whether or not the property is owned by the tenant
    bool public propertyOwned;

    /// @notice The block number of the last payment
    uint public lastPaymentBlock;

    /// @notice The number of blocks to wait for each payment
    uint public blocksForPayment;

    /// @notice The penalty percentage of total paid on cancellation
    uint public cancellationPenalty;


    // Constructor
    // ========================================================================

    /// @notice Creates a new rent-to-own contract
    /// @param _landlord The address of the landlord
    /// @param _tenant The address of the tenant
    /// @param _rentAmount The monthly rent amount
    /// @param _paymentsNeededForOwnership The total number of payments needed to transfer ownership
    /// @param _blocksForPayment The number of blocks to wait for each payment
    /// @param _cancellationPenalty The penalty percentage of total paid on cancellation
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

    /// @notice Emitted when a payment is made
    /// @param from The address making the payment
    /// @param amount The amount of the payment
    event PaymentMade(
        address from,
        uint amount
    );


    // Methods
    // ========================================================================
    /// @notice Allows the tenant to pay the rent
    /// @dev This function accepts payment from the tenant and transfers it to the landlord. If the total paid is sufficient, it marks the property as owned.
    function payRent() public payable {
        // Checks that the sender is the tenant
        require(
            msg.sender == tenant,
            "Only the tenant can make payments."
        );
        // Checks that the sent value is at least the rent amount
        require(
            msg.value >= rentAmount,
            "Must pay at least the rent amount."
        );
        // Checks that the property isn't already owned
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

    /// @notice Allows the landlord to adjust the rent
    /// @dev This function allows the landlord to adjust the rent, with restrictions on the increase amount.
    /// @param _newRentAmount The new rent amount
    function adjustRent(uint _newRentAmount) public {
        // Checks that the sender is the landlord
        require(
            msg.sender == landlord,
            "Only the landlord can adjust the rent."
        );
        // Checks that the new rent isn't more than 10% higher than the old rent
        require(
            _newRentAmount <= rentAmount * 110 / 100,
            "Cannot increase rent by more than 10%."
        );
        
        rentAmount = _newRentAmount;
    }

    /// @notice Allows the tenant to cancel the agreement
    /// @dev Refunds the tenant and resets the state of the contract
    function cancelAgreement() public {
        // Checks that the sender is the tenant
        require(
            msg.sender == tenant,
            "Only the tenant can cancel the agreement."
        );
        
        // Calculates the refund amount (total paid minus the cancellation penalty)
        uint refundAmount = totalPaid * (100 - cancellationPenalty) / 100;
        
        // Return the refund amount to the tenant
        tenant.transfer(refundAmount);
        
        // Reset the state of the contract
        totalPaid = 0;
        paymentCount = 0;
        propertyOwned = false;
    }

    /// @notice Checks if a rent payment is due
    /// @dev Compares the current block number to the last payment block and the blocks per payment
    /// @return true if a payment is due, false otherwise
    function checkPaymentDue() public view returns (bool) {
        return block.number > lastPaymentBlock + blocksForPayment;
    }

    /// @notice Allows the landlord to cancel the agreement if a payment is due
    /// @dev Refunds the tenant and resets the state of the contract
    function landlordCancelAgreement() public {
        // Checks that the sender is the landlord
        require(
            msg.sender == landlord,
            "Only the landlord can cancel the agreement."
        );
        // Checks that a payment is due
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
    
    /// @notice Checks if the property is owned by the tenant
    /// @dev Returns the state of the propertyOwned variable
    /// @return true if the property is owned by the tenant, false otherwise
    function checkOwnership() public view returns (bool) {
        return propertyOwned;
    }

}
