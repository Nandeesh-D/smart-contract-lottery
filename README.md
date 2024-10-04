# Raffle Smart Contract

This repository contains a Solidity smart contract for a decentralized lottery system built using Chainlink VRF (Verifiable Random Function) for secure randomness.

## Overview

The Raffle smart contract allows participants to enter a lottery by paying an entry fee. After a set interval, the contract uses Chainlink VRF to select a winner randomly and fairly. The entire prize pool is then transferred to the winner.

## Features

- Decentralized lottery system
- Chainlink VRF integration for verifiable randomness
- Automated winner selection using Chainlink Keepers
- Configurable entry fee and raffle duration
- Safeguards against common smart contract vulnerabilities

## Technologies Used

- Solidity ^0.8.19
- Chainlink VRF V2 Plus
- Foundry (for development and testing)

## Smart Contract Details

The main contract `Raffle.sol` includes the following key functions:

- `enterRaffle()`: Allows users to enter the raffle by paying the entry fee
- `checkUpkeep()`: Checks if it's time to perform upkeep (select a winner)
- `performUpkeep()`: Initiates the process of selecting a winner
- `fulfillRandomWords()`: Callback function that receives random numbers from Chainlink VRF and selects the winner

## Setup and Deployment

1. Clone this repository:
   ```bash
   git clone https://github.com/your-username/raffle-smart-contract.git
   cd raffle-smart-contract
   ```

2. Install Foundry if you haven't already:
   ```bash
   curl -L https://foundry.paradigm.xyz | bash
   foundryup
   ```

3. Install dependencies:
   ```bash
   forge install
   ```

4. Compile the contract:
   ```bash
   forge build
   ```

5. Run tests:
   ```bash
   forge test
   ```

6. Deploy the contract (replace `NETWORK` with your target network):
   ```bash
   forge create --rpc-url $NETWORK_RPC_URL \
     --constructor-args $ENTRY_FEE $INTERVAL $VRF_COORDINATOR $GAS_LANE $SUBSCRIPTION_ID $CALLBACK_GAS_LIMIT \
     --private-key $PRIVATE_KEY \
     src/Raffle.sol:Raffle
   ```

## Configuration

Before deploying, make sure to configure the following parameters:

- `entryFee`: The cost to enter the raffle
- `interval`: The duration of the raffle
- `vrfCoordinator`: Address of the Chainlink VRF Coordinator
- `gasLane`: The gas lane to use for Chainlink VRF
- `subscriptionId`: Your Chainlink VRF subscription ID
- `callbackGasLimit`: Gas limit for the VRF callback

## Testing

This project uses Foundry for testing. Run the tests with:

```bash
forge test
```

## Security Considerations

- The contract uses Chainlink VRF for secure randomness
- Includes checks to prevent reentrancy and other common vulnerabilities
- Make sure to thoroughly audit and test the contract before deploying to mainnet

