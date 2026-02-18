# FundMe

A decentralized crowdfunding smart contract built with Solidity and tested using the [Foundry](https://getfoundry.sh/) framework. Contributors can fund the contract in ETH (enforcing a minimum USD value via a Chainlink price feed), and only the contract owner can withdraw the collected funds.

## Features

- **Minimum funding threshold** — rejects contributions below $5 USD equivalent in ETH, enforced on-chain via Chainlink's `AggregatorV3Interface`.
- **Owner-only withdrawal** — uses a custom `FundMe__NotOwner` error and `onlyOwner` modifier to restrict withdrawals.
- **Gas-optimised withdrawal** — `cheaperWithdraw` caches the funders array length in memory to reduce storage reads during iteration.
- **Automatic funding via `receive`/`fallback`** — plain ETH transfers and calls with data both route to `fund()`.
- **Multi-network support** — `HelperConfig` automatically selects the correct Chainlink price feed address for Sepolia, Ethereum mainnet, or deploys a `MockV3Aggregator` on a local Anvil chain.
- **Interaction scripts** — `FundFundMe` and `WithdrawFundMe` scripts use `foundry-devops` to target the most recently deployed contract on any chain.

## Project Structure

```
├── src/
│   ├── FundMe.sol           # Core crowdfunding contract
│   └── PriceConverter.sol   # Library: ETH → USD conversion via Chainlink
├── script/
│   ├── DeployFundMe.s.sol   # Deployment script
│   ├── HelperConfig.s.sol   # Network config & mock management
│   └── Interactions.s.sol   # Fund & withdraw interaction scripts
├── test/
│   ├── unit/
│   │   └── FundMeTest.t.sol         # Unit tests
│   ├── integration/
│   │   └── InteractionsTest.t.sol   # Integration tests
│   └── mocks/
│       └── MockV3Aggregator.sol     # Chainlink price feed mock
├── foundry.toml
└── Makefile
```

## Requirements

- [Foundry](https://getfoundry.sh/) — `forge`, `cast`, `anvil`
- [Git](https://git-scm.com/)

## Installation

```bash
git clone https://github.com/<your-username>/foundry-fund-me-f23
cd foundry-fund-me-f23
forge install
```

## Environment Variables

Create a `.env` file in the project root:

```env
SEPOLIA_RPC_URL=<your-sepolia-rpc-url>
ACCOUNT_NAME=<your-cast-wallet-account-name>
ETHERSCAN_API_KEY=<your-etherscan-api-key>
```

> **Never commit your `.env` file.** Use `cast wallet import` to manage private keys securely.

## Usage

### Build

```bash
forge build
# or
make build
```

### Test

```bash
forge test
# or
make test
```

Run tests with full verbosity:

```bash
forge test -vvvv
```

Run a specific test:

```bash
forge test --match-test testWithdrawWithASingleFunder -vvv
```

Run tests against a forked network (e.g. Sepolia):

```bash
forge test --fork-url $SEPOLIA_RPC_URL
```

### Deploy

**Local Anvil chain:**

```bash
anvil
forge script script/DeployFundMe.s.sol:DeployFundMe --rpc-url http://localhost:8545 --broadcast
```

**Sepolia testnet:**

```bash
make deploy-sepolia
```

This runs:

```bash
forge script script/DeployFundMe.s.sol:DeployFundMe \
  --rpc-url $SEPOLIA_RPC_URL \
  --account $ACCOUNT_NAME \
  --broadcast \
  --verify \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  -vvvv
```

### Interact with a Deployed Contract

Fund the most recently deployed `FundMe` contract:

```bash
forge script script/Interactions.s.sol:FundFundMe \
  --rpc-url $SEPOLIA_RPC_URL \
  --account $ACCOUNT_NAME \
  --broadcast
```

Withdraw as the owner:

```bash
forge script script/Interactions.s.sol:WithdrawFundMe \
  --rpc-url $SEPOLIA_RPC_URL \
  --account $ACCOUNT_NAME \
  --broadcast
```

## Contract Overview

### `FundMe.sol`

| Function | Access | Description |
|---|---|---|
| `fund()` | Public payable | Contribute ETH (min. $5 USD) |
| `withdraw()` | Owner only | Withdraw all funds |
| `cheaperWithdraw()` | Owner only | Gas-optimised withdraw |
| `getVersion()` | View | Chainlink price feed version |
| `getOwner()` | View | Returns the contract owner |
| `getFunder(index)` | View | Returns funder address at index |
| `getAddressToAmountFunded(addr)` | View | Returns total funded by address |

### `HelperConfig.s.sol`

| Chain | Price Feed |
|---|---|
| Ethereum Mainnet (1) | `0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419` |
| Sepolia (11155111) | `0x694AA1769357215DE4FAC081bf1f309aDC325306` |
| Anvil (local) | Deployed `MockV3Aggregator` (8 decimals, $2000 initial price) |

## Gas Optimisations

- State variables are `private` — avoids auto-generated public getter overhead.
- The owner address is `immutable` — set once at construction, stored in bytecode.
- `cheaperWithdraw` reads `s_funders.length` into a local memory variable once rather than on every loop iteration, saving repeated `SLOAD` operations.

## Acknowledgements

Built as part of the [Cyfrin Foundry Solidity Course (f23)](https://github.com/Cyfrin/foundry-fund-me-f23) by Patrick Collins.
