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



// Import required libraries from the Hardhat package
import { ethers, run } from "hardhat";

// Main deployment function
async function main() {
  // Compile our contract
  // This command ensures the contract code is compiled to the necessary format for Ethereum
  await run("compile");

  // Get the ContractFactory for our RentToOwn contract
  // A ContractFactory in ethers.js is an abstraction used to deploy new smart contracts, so RentToOwn here is a factory for instances of our contract.
  const RentToOwn = await ethers.getContractFactory("RentToOwn");

  // Define the parameters for our contract
  // These values should be adapted for the specific situation and contract
  const landlord = "0xYourLandlordAddress"; // Replace with your landlord address
  const tenant = "0xYourTenantAddress"; // Replace with your tenant address
  const rentAmount = ethers.utils.parseEther("1"); // The rent amount in ether
  const paymentsNeededForOwnership = 12; // Number of payments needed for ownership
  const blocksForPayment = 210240; // Number of blocks for payment
  const cancellationPenalty = 10; // Cancellation penalty percentage
  
  // Deploy the contract with the specified parameters
  // This will create a transaction, sign it with the default account and send it to the network.
  const rentToOwn = await RentToOwn.deploy(
    landlord,
    tenant,
    rentAmount,
    paymentsNeededForOwnership,
    blocksForPayment,
    cancellationPenalty
  );

  // Wait for the contract to be mined
  // This makes sure the transaction was accepted and included in a block by the Ethereum network.
  await rentToOwn.deployed();

  // Log the address of the contract to the console
  // This is very useful for interacting with the contract later, so keep it safe!
  console.log("Contract deployed to address:", rentToOwn.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0)) // Successful execution
  .catch((error) => {
    console.error(error); // Log the error
    process.exit(1); // Exit with an error code
  });
