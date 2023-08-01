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
// limitations under the License.import { ethers } from "hardhat";


// Import required libraries
import { expect } from "chai";
import { Contract } from "@ethersproject/contracts";


// Define the testing block
describe("RentToOwn Contract", () => {
  // Declare necessary variables
  let landlord, tenant, other, RentToOwn, rentToOwn: Contract;

  // This function runs before each test, setting up a new contract instance
  beforeEach(async () => {
    // Get the ContractFactory and Signers (representing different addresses)
    [landlord, tenant, other] = await ethers.getSigners();
    RentToOwn = await ethers.getContractFactory("RentToOwn");

    // Deploy the contract with the landlord and tenant addresses, rent amount, payments for ownership, blocks for payment, and cancellation penalty
    rentToOwn = await RentToOwn.deploy(landlord.address, tenant.address, ethers.utils.parseEther("1"), 12, 210240, 10);
    await rentToOwn.deployed();
  });

  // This test checks if the contract was initialized correctly
  it("Should correctly initialize contract with initial values", async () => {
    expect(await rentToOwn.landlord()).to.equal(landlord.address);
    expect(await rentToOwn.tenant()).to.equal(tenant.address);
    expect(await rentToOwn.rentAmount()).to.equal(ethers.utils.parseEther("1"));
    expect(await rentToOwn.paymentsNeededForOwnership()).to.equal(12);
    expect(await rentToOwn.propertyOwned()).to.equal(false);
  });

  // This test checks if the contract correctly processes a tenant's rent payment
  it("Should allow tenant to make rent payments", async () => {
    await tenant.sendTransaction({to: rentToOwn.address, value: ethers.utils.parseEther("1")});
    expect(await rentToOwn.totalPaid()).to.equal(ethers.utils.parseEther("1"));
    expect(await rentToOwn.paymentCount()).to.equal(1);
  });

  // This test checks if the contract restricts rent payments to only the tenant
  it("Should only allow tenant to make rent payments", async () => {
    await expect(
      other.sendTransaction({to: rentToOwn.address, value: ethers.utils.parseEther("1")})
    ).to.be.revertedWith("Only the tenant can make payments.");
  });

  // This test checks if the contract restricts rent adjustments to only the landlord
  it("Should only allow landlord to adjust the rent", async () => {
    await expect(
      rentToOwn.connect(tenant).adjustRent(ethers.utils.parseEther("2"))
    ).to.be.revertedWith("Only the landlord can adjust the rent.");
  });

  // This test checks if the contract restricts rent adjustments to not exceed 10%
  it("Should not allow rent adjustment more than 10%", async () => {
    await expect(
      rentToOwn.connect(landlord).adjustRent(ethers.utils.parseEther("1.2"))
    ).to.be.revertedWith("Cannot increase rent by more than 10%.");
  });

  // This test checks if the contract correctly processes cancellation of the agreement by the tenant
  it("Should allow tenant to cancel the agreement", async () => {
    await tenant.sendTransaction({to: rentToOwn.address, value: ethers.utils.parseEther("1")});
    await rentToOwn.connect(tenant).cancelAgreement();
    expect(await rentToOwn.totalPaid()).to.equal(0);
    expect(await rentToOwn.paymentCount()).to.equal(0);
    expect(await rentToOwn.propertyOwned()).to.equal(false);
  });

  // This test checks if the contract restricts the landlord from cancelling the agreement when a payment is not due
  it("Should not allow landlord to cancel the agreement if payment is not due", async () => {
    await expect(
      rentToOwn.connect(landlord).landlordCancelAgreement()
    ).to.be.revertedWith("Cannot cancel if payment is not due.");
  });
});
