// deploy_scroll_sepolia.js

async function main() {
    // Get the deployer's account
    const [deployer] = await ethers.getSigners();
  
    // Employee address for scroll-sepolia network
    const addressMapping = {
      "Employee1": "0xFc081bA8a9154446fe731F518c0766d2f0203E2a"
    };
  
    const emp1 = addressMapping["Employee1"];
  
    console.log("Deploying contracts with the account:", deployer.address);
  
    // Get the ContractFactory and deploy the contract
    const MainPay = await ethers.getContractFactory("MainPay");
    const mainpay = await MainPay.deploy();
  
    await mainpay.deployed();
  
    console.log("MainPay contract deployed to:", mainpay.address);
  
    // Fund the smart contract with 0.1 ETH
    const initialFundAmount = ethers.utils.parseEther("0.01");
    await deployer.sendTransaction({ to: mainpay.address, value: initialFundAmount });
  
    console.log("MainPay contract funded with 0.01 ETH");
  
    // Transfer 0.0001 ETH to emp2
    await mainpay.connect(deployer).transferToEmployee(emp1);
  
    console.log("Transferred 0.0001 ETH to Employee1");
  }
  
  // Run the main function
  main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });
    