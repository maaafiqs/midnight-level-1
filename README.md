# ZkNumberGuesser

## Initial Product Idea
**ZkNumberGuesser** is a zero-knowledge number guessing game. Players submit their guesses as a private witness to the smart contract. The contract's circuit verifies the guess against a secret number (or simple mathematical rules). By using `disclose()`, the contract explicitly controls what becomes public: it only reveals whether the guess was correct and updates the public ledger state to reflect the number of attempts and if the game has been solved. The actual guess made by the player remains entirely private and is never exposed on the public blockchain.

## What You Will Learn
- Installing the Midnight toolchain (Compact compiler, proof server, Node 22, Docker)
- Writing a Compact contract with public ledger state and a private witness
- Using `disclose()` deliberately to control what becomes public
- Compiling to ZK circuits and deploying to Preprod

## Setup Instructions

1. **Prerequisites**:
   - Node.js 22
   - Docker (for running the proof server)
   - Midnight Compact compiler

2. **Installation**:
   ```bash
   npm install
   ```

3. **Compile the Compact Contract**:
   ```bash
   npm run compile
   ```
   This will generate the ZK circuits and keys in the `managed/` directory.

4. **Run Tests**:
   ```bash
   npm test
   ```

5. **Deploy to Preprod/Preview**:
   *(Instructions on how to run your deployment script once configured)*
   ```bash
   npm run deploy
   ```

## Public State vs Private Witness
- **Public Ledger State**: Information that everyone can see. In this contract, the public state stores whether the puzzle has been solved (`is_solved`) and the number of attempts (`attempts`).
- **Private Witness**: Information known only to the user executing the transaction. In this contract, the user's `guess` is a private witness. It is never stored on-chain.
- **`disclose()`**: We use the `disclose()` function to explicitly move data from the private domain to the public domain. For example, we disclose the boolean result of `guess == secret_number` so that the public ledger can be updated, but we do NOT disclose the `guess` itself.
