# Block Sherpa — Smart Contract Developer Assessment

**Candidate:** Arush  
**Role:** Smart Contract Developer (Pet360 project)

---

## Overview

I was given the [REChain](https://github.com/0xjoseOlivencia/Skill-Assessment) repository — a pre-built full-stack real estate platform. My task was to write a `PropertyRegistry` Solidity contract, deploy it to Polygon Amoy testnet, and wire a "Register on Blockchain" feature into the existing frontend.

Everything in `contracts/` is written by me from scratch. In `frontend/`, I added two new files and modified one existing page. The backend was not touched except for the `.env` where I added a dummy MongoDB URI to get the project running locally.

## Time Taken

The assessment window was 3–4 hours. My first commit (repo clone) was at ~15:10 IST and my last commit (excluding README) at ~19:08 IST — but being true, I think I went a little over 4 hours. The extra time was spent getting the existing backend running locally, which required configuring MongoDB, something I hadn't worked with before. The contract, tests, deployment, and frontend integration were all done within the intended window. Commit history is in the repo for reference.

---

## Structure

```
Skill-Assessment/
├── contracts/                              ← created from scratch
│   ├── src/PropertyRegistry.sol
│   ├── test/PropertyRegistry.t.sol
│   ├── script/Deploy.s.sol
│   └── foundry.toml
└── frontend/
    └── src/
        ├── config/propertyRegistry.ts      ← new
        ├── hooks/usePropertyRegistry.ts    ← new
        └── pages/PropertyDetailsPage.tsx   ← modified
```

---

## What I Built

### 1. Smart Contract — `contracts/src/PropertyRegistry.sol`

Written in Solidity `0.8.19` using Foundry. The contract registers real-world properties on-chain and tracks ownership.

```solidity
struct Property {
    string  propertyAddress;
    address owner;
    uint256 price;
    bool    exists;
}
```

**Functions:**

| Function | Description |
|---|---|
| `registerProperty(string, uint256)` | Registers a new property owned by `msg.sender`, returns the assigned ID |
| `transferOwnership(uint256, address)` | Transfers ownership — reverts if caller isn't the owner, property doesn't exist, or new owner is zero address |
| `getProperty(uint256)` | Returns the full property struct — reverts if ID not registered |
| `getNextPropertyCount()` | Returns total properties registered so far |

**Events:**
```solidity
event PropertyRegistered(uint256 indexed propertyId, address indexed owner, string propertyAddress, uint256 price);
event OwnershipTransferred(uint256 indexed propertyId, address indexed previousOwner, address indexed newOwner);
```

**Custom errors:**
```solidity
error PropertyDoesNotExist(uint256 propertyId);
error NotPropertyOwner(uint256 propertyId, address caller);
error InvalidAddress();
```

**Key design decisions:**
- `bool exists` in the struct — without it, ID 0 silently returns empty data for unregistered properties, making it impossible to distinguish a missing property from a zero-value one
- `external` over `public` — none of these functions are called internally, so `external` is cheaper
- `Property storage prop` — caches the storage pointer rather than re-reading from storage on every access
- Custom errors with parameters over `require` strings — more gas-efficient and gives callers useful context (e.g. which ID failed, which address was rejected)
- `indexed` on event parameters — makes logs filterable off-chain by `propertyId`, `owner`, and `newOwner`

---

### 2. Tests — `contracts/test/PropertyRegistry.t.sol`

- Written with Foundry's `forge-std` test library.
- 11 tests, all passing.
- 100% coverage on the contract.
- AI was used to get the context for what-all to test to achieve this coverage (more down at `## AI Usage`)

```bash
forge test -vvv
```

| Test | What it covers |
|---|---|
| `test_RegisterProperty_StoresCorrectData` | Happy path — all fields stored correctly |
| `test_RegisterProperty_EmitsEvent` | `PropertyRegistered` fires with correct args |
| `test_RegisterProperty_IncrementsId` | IDs auto-increment, count is tracked |
| `test_TransferOwnership_UpdatedOwner` | Owner field updated after transfer |
| `test_TransferOwnership_EmitsEvent` | `OwnershipTransferred` fires with correct args |
| `test_RevertWhen_NonOwnerTransfers` | Non-owner rejected with `NotPropertyOwner` |
| `test_RevertWhen_TransferToZeroAddress` | Zero address rejected with `InvalidAddress` |
| `test_RevertWhen_GetNonExistentProperty` | Reading missing ID reverts with `PropertyDoesNotExist` |
| `test_RevertWhen_TransferNonExistentProperty` | Transferring missing ID reverts with `PropertyDoesNotExist` |
| `testFuzz_RegisterProperty_PriceAlwaysMatches` | Fuzz (256 runs) — stored price always equals input |
| `testFuzz_OnlyOwnerCanTransfer` | Fuzz (256 runs) — access control holds for any random attacker |

---

### 3. Deployment — Polygon Amoy Testnet

I wrote a Foundry deploy script at `contracts/script/Deploy.s.sol` and deployed to Polygon Amoy.

**Contract address:** [`0xa26069660F55946cFC912b2320379e0FeE724416`](https://amoy.polygonscan.com/address/0xa26069660F55946cFC912b2320379e0FeE724416)  
**Deploy tx:** [`0x538fb75ca91963734af4cc34cfd642638c6fdff885dcd41716bb5593c9511d14`](https://amoy.polygonscan.com/tx/0x538fb75ca91963734af4cc34cfd642638c6fdff885dcd41716bb5593c9511d14)  
**Network:** Polygon Amoy (chain ID `80002`)

```bash
# from contracts/
source .env
forge script script/Deploy.s.sol --rpc-url $AMOY_RPC_URL --private-key $PRIVATE_KEY --broadcast
```

---

### 4. Frontend Integration

No backend changes. I added two files and modified one existing page in `frontend/src/`.

**`frontend/src/config/propertyRegistry.ts`** *(new)*  
Holds the deployed contract address, human-readable ABI, and the Amoy chain ID constant. Single source of truth — nothing is hardcoded elsewhere.

**`frontend/src/hooks/usePropertyRegistry.ts`** *(new)*  
A custom React hook that encapsulates the entire wallet → network → contract flow. It exposes `{ status, txHash, error, registerOnChain }`.

The status machine progresses: `idle → connecting → pending → confirmed | error`

- Detects missing MetaMask and surfaces a clear error
- Automatically prompts a network switch to Polygon Amoy if the user is on the wrong chain (`wallet_switchEthereumChain`)
- Calls `registerProperty` on the deployed contract with the property's location and price
- Captures the tx hash immediately on submission (before confirmation) so the UI can show it

**`frontend/src/pages/PropertyDetailsPage.tsx`** *(modified)*  
Added a "Blockchain Status" card to the right sidebar alongside the existing schedule-viewing card. It renders differently based on the hook's status:

- **idle** — "Not registered on blockchain" + Register button
- **connecting** — "Connecting wallet..."
- **pending** — "Transaction pending..."
- **confirmed** — tx hash as a clickable Amoy Polygonscan link
- **error** — error message in red

The button passes `property.location` and `parseEther(property.price.toString())` directly into `registerOnChain`, using the property's existing off-chain data as the on-chain inputs.

---

## Running Locally

**Contract:**
```bash
cd contracts
forge build
forge test -vvv
```

**Frontend:**
```bash
cd frontend
npm install
npm run dev
# http://localhost:5173 — navigate to any property detail page
```

MetaMask must be installed and connected to Polygon Amoy (chain ID `80002`) to use the blockchain registration feature.

---

## AI Usage

Block Sherpa's assessment explicitly encourages AI-assisted development, so I want to be transparent about where and how I used it. It was a very minimal project, AI was not much needed but I saved some time.

- **Claude Sonnet 4.5** — Used for the frontend integration. Tailwind CSS and React are my weaker areas, so I used it to help with the JSX structure and Tailwind classes in `PropertyDetailsPage.tsx`. TypeScript and ethers.js I know just enough to work with independently. 
    - I also asked it what I should be testing to get 100% coverage on the contract — not to write the tests, but to make sure I wasn't missing any edge cases or vulnerable paths before I wrote them myself (AI can write tests for a minimal project like this easily but I had enough time — not expecting later issues).
- **Gemini 3.1 Pro** — Used to help debug the MongoDB connection issue when getting the existing backend running locally. I hadn't worked with MongoDB before and needed to get it running just to have a working frontend to integrate into.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Smart contract | Solidity `0.8.19` |
| Toolchain | Foundry (forge, cast) |
| Network | Polygon Amoy |
| Frontend | React 18 + TypeScript |
| Web3 | ethers.js v6 |
| Styling | Tailwind CSS |
