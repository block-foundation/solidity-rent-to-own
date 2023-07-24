// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract RentToOwn {

    address payable public landlord;
    address payable public tenant;
    uint public rentAmount;
    uint public totalPaid;
    uint public paymentCount;
    uint public paymentsNeededForOwnership;
    bool public propertyOwned;
    
    // Event to emit each time a payment is made
    event PaymentMade(address from, uint amount);

    constructor(
        address payable _landlord, 
        address payable _tenant, 
        uint _rentAmount, 
        uint _paymentsNeededForOwnership
    ) {
        landlord = _landlord;
        tenant = _tenant;
        rentAmount = _rentAmount;
        paymentsNeededForOwnership = _paymentsNeededForOwnership;
        totalPaid = 0;
        paymentCount = 0;
        propertyOwned = false;
    }
    
    function payRent() public payable {
        require(msg.sender == tenant, "Only the tenant can make payments.");
        require(msg.value == rentAmount, "Must pay the exact rent amount.");
        require(propertyOwned == false, "Property already owned.");
        
        totalPaid += msg.value;
        paymentCount += 1;

        if (paymentCount >= paymentsNeededForOwnership) {
            propertyOwned = true;
        }
        
        landlord.transfer(msg.value);
        
        emit PaymentMade(msg.sender, msg.value);
    }
    
    function checkOwnership() public view returns (bool) {
        return propertyOwned;
    }
}
