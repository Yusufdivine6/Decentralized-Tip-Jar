# Decentralized Tip Jar

## Overview

This project implements a decentralized tip jar system using smart contracts. Users can send tips, and the contract keeps track of the total tips and individual user contributions.

## Features

- **Send Tip**: Allows users to send a tip to the contract.
- **Total Tips**: Tracks the total amount of tips received by the contract.
- **User Tips**: Tracks the total amount of tips sent by individual users.

## Smart Contract Details

### Data Variables
- `total-tips`: A uint variable that tracks the total tips received.

### Data Maps
- `user-tips`: A map that associates a user (`principal`) with their tip amount (`uint`).

### Public Functions
1. **`send-tip (amount uint)`**:
   - Allows a user to send a tip.
   - Validates that the tip amount is greater than zero.
   - Updates the total tips and the user's individual contribution.
   - Returns the tip amount.

### Read-Only Functions
1. **`get-total-tips`**:
   - Returns the total tips received.
2. **`get-user-tips (user principal)`**:
   - Returns the total tips sent by a specific user.

### Error Codes
- `ERR_INVALID_TIP` (u100): Returned if the tip amount is not greater than zero.

## Unit Tests

The unit tests are implemented using the **Vitest** framework. They mock the behavior of the smart contract and validate its functionality.

### Key Tests
- Users can send valid tips.
- The contract accurately tracks total tips and individual user contributions.
- Multiple users can send tips, and their contributions are tracked separately.
- Invalid tip amounts are rejected.

## How to Use

1. **Deploy the Contract**: Deploy the contract on a blockchain platform.
2. **Send a Tip**: Use the `send-tip` function to contribute tips.
3. **Track Contributions**: Use the `get-total-tips` and `get-user-tips` functions to track total and individual contributions.

## Development

### Prerequisites
- Node.js
- Vitest for testing

### Running Tests
```bash
npm install
npm test
