# 🔮 SRE Challenge 10 — Oracles

A full-stack Web3 project built as part of **SpeedRunEthereum Challenge 10**.

This challenge implements three decentralized oracle architectures: a **Whitelist Oracle**, a **Staking Oracle**, and an **Optimistic Oracle**.

The project explores how smart contracts can safely consume off-chain data, and compares the trade-offs between trusted data providers, economic incentives, and challenge-response dispute resolution.

---

## 🚀 Live Demo

- **Frontend (Vercel):** https://sre-challenge-10-oracles-nextjs.vercel.app/
- **Whitelist Oracle Contract (Sepolia):** `0x2BACc689F90031420D997027FE25bB3080efD784`
- **Staking Oracle Contract (Sepolia):** `0xBabbdab28Df196338b776642c3E680a442764B46`
- **Optimistic Oracle Contract (Sepolia):** `0x3c6D7C62e5E0DACC3f062f16Ae81084D8FD539ad`
- **Decider Contract (Sepolia):** `0xEd1D114bb7485F01ec3D466acFd9a6a64cF8D2AB`
- **ORA Token Contract (Sepolia):** `0x0E8fB5b3eFA697CcC2AB4ee6744425B046Fa2322`
- **Block Explorer:** https://sepolia.etherscan.io/address/0x3c6D7C62e5E0DACC3f062f16Ae81084D8FD539ad

---

## 🧱 Tech Stack

### 🖥 Smart Contracts

- Solidity `^0.8.x`
- Hardhat
- Sepolia Testnet
- `SimpleOracle.sol` - A single trusted price source
- `WhitelistOracle.sol` - A median-based oracle aggregator for trusted oracle nodes
- `OracleToken.sol` - ORA token used for staking and validator rewards
- `StakingOracle.sol` - A staking-based oracle with bucketed reports, rewards, inactivity penalties, and slashing
- `OptimisticOracle.sol` - Assertion, proposal, dispute, settlement, and reward-claiming flow
- `Decider.sol` - A dispute settlement contract for optimistic oracle assertions
- `StatisticsUtils.sol` - Sorting and median utilities for oracle aggregation

### 🎨 Frontend (Scaffold-ETH 2)

- Next.js App Router
- React
- TypeScript
- TailwindCSS
- Wagmi + Viem
- RainbowKit
- Scaffold-ETH 2 Debug Panel
- Oracle interaction pages for Whitelist, Staking, and Optimistic flows
- Deployment on Vercel

---

## 🎯 What This Oracle System Does

This project implements three core oracle designs used across Web3:

- **Whitelist Oracle:** trusted operators submit prices through whitelisted oracle nodes
- **Staking Oracle:** validators stake ORA, report prices, earn rewards, and risk slashing
- **Optimistic Oracle:** users assert event outcomes, others propose or dispute, and disputes are settled by a decider

Together, these systems demonstrate how different oracle architectures balance:

- Speed
- Security
- Cost
- Decentralization
- Latency
- Implementation complexity

---

## 🧠 Core Design Principles

- **Off-chain data brought on-chain**
- **Median-based price aggregation**
- **Freshness checks for stale data**
- **Economic incentives for honest reporting**
- **Slashing for inaccurate oracle reports**
- **Challenge-response dispute resolution**
- **Bonded proposals and disputes**
- **Clear state transitions for oracle assertions**
- **Composable oracle patterns for different use cases**

---

## 🏛 Whitelist Oracle

The Whitelist Oracle is the simplest design in the project. A central owner controls which oracle nodes are allowed to submit data.

Each trusted data provider owns a `SimpleOracle`, and the `WhitelistOracle` aggregates fresh prices from all active oracle nodes.

### 🔄 Price Aggregation Flow

```solidity
SimpleOracle A -> 100
SimpleOracle B -> 102
SimpleOracle C -> 98

WhitelistOracle -> sort [98, 100, 102] -> median = 100
```

### ✅ Features

- Add trusted oracle nodes
- Remove oracle nodes with swap-and-pop
- Collect reports from multiple `SimpleOracle` contracts
- Filter stale data
- Sort fresh prices
- Return the median price
- Query currently active oracle nodes

### ⚖️ Trade-off

The Whitelist Oracle is fast and cheap, but it requires trust in the whitelist authority and trusted data providers.

---

## 💰 Staking Oracle

The Staking Oracle replaces centralized trust with economic incentives.

Oracle nodes stake ORA tokens to participate, report prices once per bucket, and earn rewards for regular reporting. Nodes that report prices too far away from the recorded bucket median can be slashed.

### 🧮 Bucket Model

```solidity
bucketNumber = block.number / BUCKET_WINDOW + 1
```

Reports are grouped into block-based buckets. Past buckets can be finalized by recording their median price.

```solidity
reported prices -> recordBucketMedian(bucket)
node report vs median -> slash if deviation > MAX_DEVIATION_BPS
```

### ✅ Features

- Register as an oracle node by staking ORA
- Add more stake after registration
- Report prices once per bucket
- Record median prices for past buckets
- Claim ORA rewards based on report count
- Penalize inactive nodes
- Identify outlier reports
- Slash nodes that deviate beyond the configured threshold
- Reward slashers for catching bad reports
- Exit and withdraw effective stake after the waiting period

### ⚖️ Trade-off

The Staking Oracle is more decentralized and economically aligned than a whitelist oracle, but it introduces more complexity, higher gas costs, and latency from bucket finalization.

---

## 🧠 Optimistic Oracle

The Optimistic Oracle answers true/false questions about real-world events.

It assumes proposals are correct unless someone disputes them. This makes it efficient for questions that do not need constant reporting, while still allowing disputes when someone believes a proposal is wrong.

### ⚡ Assertion Lifecycle

```solidity
asserter -> assertEvent(description, startTime, endTime) + reward
proposer -> proposeOutcome(assertionId, true/false) + bond
disputer -> disputeOutcome(assertionId) + matching bond
decider  -> settleAssertion(assertionId, resolvedOutcome)
winner   -> claim reward + bond refund
```

### ✅ Features

- Create reward-backed event assertions
- Propose true or false outcomes
- Require proposal bonds
- Dispute proposed outcomes with matching bonds
- Resolve disputes through a decider contract
- Claim undisputed proposal rewards
- Claim disputed rewards after settlement
- Refund asserters when no proposal is submitted
- Query assertion state
- Query final resolution

### ⚖️ Trade-off

The Optimistic Oracle is flexible and secure when disputes are monitored, but it has higher latency and depends heavily on the dispute resolution mechanism.

---

## 🔍 Oracle Comparison

| Aspect           | Whitelist Oracle       | Staking Oracle            | Optimistic Oracle        |
| ---------------- | ---------------------- | ------------------------- | ------------------------ |
| Speed            | Fast                   | Medium                    | Slow                     |
| Security         | Low, trusted authority | High, economic incentives | High, dispute resolution |
| Decentralization | Low                    | High                      | Depends on decider       |
| Cost             | Low                    | Medium                    | High                     |
| Complexity       | Simple                 | Medium                    | Complex                  |

---

## 🧪 Testing & Simulations

The challenge includes checkpoint-based tests for each implementation stage.

```bash
yarn test --grep "Checkpoint1"
yarn test --grep "Checkpoint2"
yarn test --grep "Checkpoint4"
yarn test --grep "Checkpoint5"
yarn test --grep "Checkpoint6"
```

The project also includes live oracle simulations:

```bash
yarn simulate:whitelist
yarn simulate:staking
yarn simulate:optimistic
```

To automatically slash outlier staking oracle nodes during simulation:

```bash
AUTO_SLASH=true yarn simulate:staking
```

---

## 🚢 Deployment

The contracts are designed to be deployed to a public EVM testnet such as Sepolia.

```bash
yarn deploy --network sepolia
```

After deployment, verify the contracts:

```bash
yarn verify --network sepolia
```

Then update:

- `packages/nextjs/scaffold.config.ts`
- README live demo links
- Home page contract links
- Vercel environment variables, if needed

---

## 🎮 Frontend dApp

The UI allows users to:

- Connect wallet
- View connected network and wallet address
- Interact with the Whitelist Oracle
- Add and remove trusted oracle nodes
- Observe median price aggregation
- Buy ORA tokens for staking
- Register as a staking oracle node
- Report prices per bucket
- Record bucket medians
- Slash deviating staking nodes
- Create optimistic oracle assertions
- Propose outcomes
- Dispute outcomes
- Settle disputes through the decider
- Claim rewards or refunds
- Debug contracts through **Scaffold-ETH 2**
- Inspect deployed contracts on **Etherscan**

---

## 📐 Learning Outcomes

By completing this challenge, you learn:

- Why smart contracts need oracles
- How whitelist oracles aggregate trusted data sources
- How median aggregation resists outliers
- How stale data checks protect oracle reads
- How staking creates economic incentives for accurate reporting
- How inactivity penalties encourage regular participation
- How slashing punishes inaccurate oracle nodes
- How optimistic assertions and disputes work
- Why optimistic systems trade speed for flexibility
- How oracle architecture affects decentralization and trust assumptions
- How to deploy full-stack dApps to **Sepolia + Vercel**

---

## 🎓 Part of SpeedRunEthereum

This project is part of:

🏃 **SpeedRunEthereum — Challenge 10: Oracle Challenge**  
https://speedrunethereum.com/challenge/oracles

Built using **Scaffold-ETH 2**, the modern full-stack Ethereum development framework.
