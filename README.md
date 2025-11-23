# Foundry Smart Contract Lottery

Decentralized lottery smart contract using Chainlink VRF for random number generation and Chainlink Automation for automated winner selection.

**Technical Notes:**
- V2.5 of Chainlink VRF uses `uint256` as subId instead of `uint64`
- Uses `0.1.0` of `foundry-devops` package (no `ffi=true` required)

- [Getting Started](#getting-started)
  - [Requirements](#requirements)
  - [Quickstart](#quickstart)
- [Usage](#usage)
  - [Start a local node](#start-a-local-node)
  - [Deploy](#deploy)
  - [Testing](#testing)
- [Deployment to a testnet or mainnet](#deployment-to-a-testnet-or-mainnet)
  - [Scripts](#scripts)
  - [Estimate gas](#estimate-gas)
- [Formatting](#formatting)

# Getting Started

## Requirements

- [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
- [foundry](https://getfoundry.sh/)

## Quickstart

```bash
git clone <repository-url>
cd foundry-smart-contract-lottery
forge build
```

# Usage

## Start a local node

```bash
make anvil
```

## Deploy

Local deployment (requires running anvil node in another terminal):

```bash
make deploy
```

For other networks, see [Deployment to a testnet or mainnet](#deployment-to-a-testnet-or-mainnet)

Optional - if having issues with chainlink library:

```bash
forge install smartcontractkit/chainlink-brownie-contracts@0.6.1 --no-commit
```

## Testing

Run tests:

```bash
forge test
```

Fork testing:

```bash
forge test --fork-url $SEPOLIA_RPC_URL
```

Test coverage:

```bash
forge coverage
```

# Deployment to a testnet or mainnet

1. **Setup environment variables**

Create a `.env` file (see `.env.example`):

- `SEPOLIA_RPC_URL`: RPC endpoint (e.g., from [Alchemy](https://alchemy.com/?a=673c802981))
- `PRIVATE_KEY`: Your wallet private key (**WARNING: Use a test wallet only, no real funds**)
- `ETHERSCAN_API_KEY`: For contract verification (optional)

2. **Get testnet ETH**

Get testnet ETH from [faucets.chain.link](https://faucets.chain.link/)

3. **Deploy**

```bash
make deploy ARGS="--network sepolia"
```

This automatically creates a ChainlinkVRF Subscription and adds your contract as a consumer. If you have an existing subscription, update it in `scripts/HelperConfig.s.sol`.

4. **Register Chainlink Automation Upkeep**

Go to [automation.chain.link](https://automation.chain.link/new) and register a new upkeep with `Custom logic` trigger.

[Documentation](https://docs.chain.link/chainlink-automation/compatible-contracts)

![Automation](./img/automation.png)

## Scripts

Enter raffle using cast:

```bash
cast send <RAFFLE_CONTRACT_ADDRESS> "enterRaffle()" --value 0.1ether --private-key <PRIVATE_KEY> --rpc-url $SEPOLIA_RPC_URL
```

Create ChainlinkVRF Subscription:

```bash
make createSubscription ARGS="--network sepolia"
```

## Estimate gas

```bash
forge snapshot
```

Output: `.gas-snapshot`

# Formatting

```bash
forge fmt
```