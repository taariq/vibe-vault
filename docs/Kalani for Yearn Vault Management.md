# Kalani - Yearn Vault Management Platform

Kalani is a comprehensive DeFi vault management platform built as a monorepo for interacting with Yearn V3 vaults and ERC-4626 compliant yield-bearing strategies. The project provides both a frontend application for vault discovery, monitoring, and management, as well as a backend API for indexing vault data, processing blockchain events, and proxying external services. It enables users to deploy new vaults, manage strategies, allocate capital, configure roles and permissions, and track performance across multiple EVM chains.

The platform consists of four main packages: a React-based web frontend (`packages/web`) with wallet integration via RainbowKit and Wagmi, a Next.js API (`packages/api`) for data indexing and job queue management, a shared library (`packages/lib`) containing ABIs, type definitions, and utility functions, and automation scripts (`packages/scripts`) for testnet setup and management. The architecture supports multi-chain deployments including Ethereum mainnet, Polygon, Arbitrum, Base, and custom chains, with comprehensive role-based access control following the Yearn V3 vault specification.

## API Endpoints

### Vault Indexing Endpoint

POST endpoint for registering and indexing a new Yearn V3 vault into the platform's database and job queue system.

```typescript
// POST /api/kong/index/vault
// Request body with vault details and signature verification
const response = await fetch('https://api.kalani.com/api/kong/index/vault', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    chainId: 137,
    address: '0x28F53bA70E5c8ce8D03b1FaD41E9dF11Bb646c36',
    asset: '0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270',
    decimals: 18,
    apiVersion: '3.0.2',
    category: 1,
    projectId: '0x7965726e0000000000000000000000000000000000000000000000000000000',
    projectName: 'Yearn Finance',
    roleManager: '0xC4ad0000E223E398DC329235e6C497Db5470B626',
    inceptBlock: '45678900',
    inceptTime: 1672531200,
    signature: '0xabcd1234...' // EIP-191 signature from vault's chad (admin)
  })
});

const result = await response.json();
// Expected output: { ok: true }
// Triggers backend jobs: postThing, extractLogs, extractSnapshot
```

### Message Queue Job Status

GET endpoint for checking the status of background jobs in the message queue system.

```typescript
// GET /api/kong/mq/job?queueName=extract-137&jobId=abc123
const queueName = 'extract-137';
const jobId = 'abc123';

const response = await fetch(
  `https://api.kalani.com/api/kong/mq/job?queueName=${queueName}&jobId=${jobId}`,
  { headers: { 'Content-Type': 'application/json' } }
);

const job = await response.json();
console.log('Job status:', job.finishedOn ? 'completed' : 'pending');
console.log('Failed reason:', job.failedReason || 'none');

// Expected output:
// {
//   id: 'abc123',
//   name: 'evmlog',
//   data: { chainId: 137, address: '0x...', from: 45678900n, to: 45678902n },
//   finishedOn: 1672531250000,
//   failedReason: null,
//   returnvalue: { extracted: 15 }
// }
```

### Token Asset Proxy

GET endpoint that proxies token logo images with fallback to transparent PNG if unavailable.

```typescript
// GET /api/assets/token/[chainId]/[address]
const chainId = 137;
const tokenAddress = '0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270';

const imageUrl = `https://api.kalani.com/api/assets/token/${chainId}/${tokenAddress}`;

// Usage in HTML/React
const tokenImage = <img src={imageUrl} alt="Token logo" width="128" height="128" />;

// Response: PNG image (128x128 logo or 1x1 transparent fallback)
// Content-Type: image/png
```

## Core Library Functions

### BigInt Math Operations

Utility functions for precise financial calculations with BigInt values, avoiding floating-point errors.

```typescript
import { div, mul, mulb, priced } from '@kalani/lib/bmath';

// Divide BigInt with decimal precision
const tokenAmount = 1500000000000000000n; // 1.5 tokens (18 decimals)
const totalSupply = 10000000000000000000n; // 10 tokens
const sharePercentage = div(tokenAmount, totalSupply, 18);
console.log(sharePercentage); // 0.15 (15%)

// Multiply BigInt by number
const currentBalance = 5000000000000000000n; // 5 tokens
const multiplier = 1.1; // 10% increase
const newBalance = mul(currentBalance, multiplier, 18);
console.log(newBalance); // 5.5

// Calculate USD value from token amount
const vaultBalance = 2500000000000000000n; // 2.5 tokens (18 decimals)
const decimals = 18;
const priceUsd = 1850.50; // $1,850.50 per token
const balanceUsd = priced(vaultBalance, decimals, priceUsd);
console.log(balanceUsd); // 4626.25 (2.5 * 1850.50)
```

### Number and Token Formatting

Formatting utilities for displaying numbers, USD values, percentages, and token amounts in human-readable formats.

```typescript
import { fUSD, fPercent, fTokens, fNumber, fEvmAddress } from '@kalani/lib/format';

// Format USD amounts with K/M/B suffixes
const tvl = 15_750_000;
console.log(fUSD(tvl)); // "$ 15.75M"
console.log(fUSD(tvl, { full: true })); // "$ 15,750,000.00"

// Format percentages with precision
const apy = 0.0847; // 8.47%
console.log(fPercent(apy)); // "8.47%"
console.log(fPercent(0.125, { fixed: 1 })); // "12.5%"

// Format token amounts from BigInt
const balance = 1234567890000000000n; // 1.23456789 tokens
console.log(fTokens(balance, 18, { fixed: 2 })); // "1.23"
console.log(fTokens(balance, 18, { fixed: 4 })); // "1.2345"

// Format addresses
const vaultAddress = '0x28F53bA70E5c8ce8D03b1FaD41E9dF11Bb646c36';
console.log(fEvmAddress(vaultAddress)); // "0x28F5...c36"
console.log(fEvmAddress(vaultAddress, true)); // "0x28F5"
```

### Chain Configuration

Multi-chain support with RPC configuration for various EVM networks.

```typescript
import { chains, getRpc } from '@kalani/lib/chains';
import { createPublicClient, http } from 'viem';

// Get configured chains
const polygonChain = chains[137]; // Polygon
const mainnetChain = chains[1]; // Ethereum mainnet
const arbitrumChain = chains[42161]; // Arbitrum

// Get RPC URL for chain
const rpcUrl = getRpc(137); // Returns process.env.RPC_137 or TESTNET_RPC_137
console.log(rpcUrl); // "https://polygon-rpc.com"

// Create viem client with chain config
const client = createPublicClient({
  chain: chains[137],
  transport: http(getRpc(137))
});

// Read vault data
const vaultAddress = '0x28F53bA70E5c8ce8D03b1FaD41E9dF11Bb646c36';
const totalAssets = await client.readContract({
  address: vaultAddress,
  abi: abis.vault,
  functionName: 'totalAssets'
});
console.log('Total assets:', totalAssets); // 5000000000000000000n
```

### Vault Role Management

Type-safe role management for Yearn V3 vault permissions using bitmask operations.

```typescript
import { ROLES, containsRole, ALL_ROLES_MASK } from '@kalani/lib/types';
import abis from '@kalani/lib/abis';
import { createPublicClient, http, getContract } from 'viem';

// Check if account has specific role
const vaultAddress = '0x28F53bA70E5c8ce8D03b1FaD41E9dF11Bb646c36';
const accountAddress = '0x70997970C51812dc3A010C7d01b50e0d17dc79C8';

const client = createPublicClient({
  chain: chains[137],
  transport: http(getRpc(137))
});

const vault = getContract({
  address: vaultAddress,
  abi: abis.vault,
  client
});

const roleMask = await vault.read.roles([accountAddress]);
console.log('Raw role mask:', roleMask); // 4160n

// Check individual roles
const canAddStrategy = containsRole(roleMask, ROLES.ADD_STRATEGY_MANAGER);
const canManageDebt = containsRole(roleMask, ROLES.DEBT_MANAGER);
const isEmergencyManager = containsRole(roleMask, ROLES.EMERGENCY_MANAGER);

console.log('Can add strategy:', canAddStrategy); // true (if bit 0 set)
console.log('Can manage debt:', canManageDebt); // true (if bit 6 set)
console.log('Emergency manager:', isEmergencyManager); // false

// Grant multiple roles
const newRoles = ROLES.ADD_STRATEGY_MANAGER | ROLES.DEBT_MANAGER | ROLES.REPORTING_MANAGER;
// Write transaction: vault.write.set_role([accountAddress, newRoles])
```

### Zod Schema Validation

Type-safe validation for EVM addresses, hex strings, and ERC-20 token data.

```typescript
import { EvmAddressSchema, HexStringSchema, Erc20Schema } from '@kalani/lib/types';

// Validate and normalize EVM address
const rawAddress = '0x28f53ba70e5c8ce8d03b1fad41e9df11bb646c36'; // lowercase
const validatedAddress = EvmAddressSchema.parse(rawAddress);
console.log(validatedAddress); // "0x28F53bA70E5c8ce8D03b1FaD41E9dF11Bb646c36" (checksummed)

// Validate hex string
const signature = '0xabcd1234567890';
const validatedHex = HexStringSchema.parse(signature);
console.log(validatedHex); // "0xabcd1234567890"

// Validate ERC-20 token data
const tokenData = {
  chainId: 137,
  address: '0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270',
  name: 'Wrapped Matic',
  symbol: 'WMATIC',
  decimals: 18
};

const validatedToken = Erc20Schema.parse(tokenData);
console.log(validatedToken.symbol); // "WMATIC"
console.log(validatedToken.address); // Checksummed address

// Error handling
try {
  EvmAddressSchema.parse('0xinvalid');
} catch (error) {
  console.error('Invalid address format'); // Validation fails
}
```

### Message Queue Job Management

Internal API functions for managing background jobs in the Kong message queue system.

```typescript
import { postThing, extractSnapshot, extractLogs } from '@/app/api/kong/lib';

// Register new vault/strategy/accountant in database
const thingResult = await postThing(
  137, // chainId
  '0x28F53bA70E5c8ce8D03b1FaD41E9dF11Bb646c36', // address
  'vault', // label
  {
    erc4626: true,
    v3: true,
    yearn: false,
    asset: '0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270',
    decimals: 18,
    apiVersion: '3.0.2',
    category: 1,
    projectId: '0x796561726e000000000000000000000000000000000000000000000000000000',
    projectName: 'Yearn Finance',
    inceptBlock: 45678900n,
    inceptTime: 1672531200
  }
);
// Returns job result after completion or failure

// Extract current state snapshot from contract
const snapshotResult = await extractSnapshot(
  'yearn/3/vault', // abiPath
  137, // chainId
  '0x28F53bA70E5c8ce8D03b1FaD41E9dF11Bb646c36' // address
);
// Polls job until completion, returns snapshot data

// Extract event logs from blockchain
const logsResult = await extractLogs(
  'yearn/3/vault', // abiPath
  137, // chainId
  '0x28F53bA70E5c8ce8D03b1FaD41E9dF11Bb646c36', // address
  45678900n, // from block
  45678910n // to block
);
// Returns extracted Deposit, Withdraw, StrategyReported events
```

## React Hooks

### useBalance Hook

React hook for fetching ERC-20 token balance with USD valuation for a specific address.

```typescript
import { useBalance } from '@/hooks/useBalance';
import { fTokens, fUSD } from '@kalani/lib/format';

function WalletBalance() {
  const userAddress = '0x70997970C51812dc3A010C7d01b50e0d17dc79C8';
  const usdcAddress = '0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359';

  const balance = useBalance({
    chainId: 137,
    token: usdcAddress,
    address: userAddress
  });

  if (!balance.data) return <div>Loading...</div>;

  return (
    <div>
      <p>Token: {balance.symbol}</p>
      <p>Balance: {fTokens(balance.balance, balance.decimals, { fixed: 2 })}</p>
      <p>USD Value: {fUSD(balance.balanceUsd)}</p>
      <p>Price: {fUSD(balance.price)}</p>
    </div>
  );

  // Expected output:
  // Token: USDC
  // Balance: 10,000.00
  // USD Value: $ 10.00K
  // Price: $ 1.00
}
```

### useWriteContract Hook

Enhanced wagmi hook wrapper for executing vault write transactions with automatic validation.

```typescript
import { useWriteContract } from '@/hooks/useWriteContract';
import abis from '@kalani/lib/abis';
import { parseEther } from 'viem';

function DepositButton() {
  const vaultAddress = '0x28F53bA70E5c8ce8D03b1FaD41E9dF11Bb646c36';
  const { writeContract, isPending, isSuccess, error } = useWriteContract();

  const handleDeposit = async () => {
    const amount = parseEther('1.5'); // 1.5 tokens
    const receiver = '0x70997970C51812dc3A010C7d01b50e0d17dc79C8';

    try {
      const hash = await writeContract({
        address: vaultAddress,
        abi: abis.vault,
        functionName: 'deposit',
        args: [amount, receiver]
      });

      console.log('Transaction hash:', hash);
      // Expected: "0xabcd1234..."
    } catch (err) {
      console.error('Deposit failed:', err);
    }
  };

  return (
    <button onClick={handleDeposit} disabled={isPending}>
      {isPending ? 'Depositing...' : 'Deposit 1.5 Tokens'}
    </button>
  );
}
```

## Testnet Scripts

### Polygon Testnet Setup

Automation script for configuring testnet environments with custom balances and role transfers.

```typescript
// Run with: bun run packages/scripts/src/testnet/polygon_setup.ts
import { createTestnetClient } from '@kalani/lib/tenderly';
import { parseEther, parseUnits, getContract } from 'viem';
import abis from '@kalani/lib/abis';

const ALICE = '0x70997970C51812dc3A010C7d01b50e0d17dc79C8';
const yWMATIC = '0x28F53bA70E5c8ce8D03b1FaD41E9dF11Bb646c36';
const USDC = '0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359';

const client = createTestnetClient(polygonChain);
const snapshot = await client.snapshot(); // Save state for revert

try {
  // Fund test accounts
  await client.setBalance(ALICE, parseEther('1000'));
  await client.setErc20Balance(ALICE, USDC, parseUnits('100000', 6));

  // Transfer vault role manager
  const vault = getContract({ abi: abis.vault, address: yWMATIC, client });
  await vault.write.transfer_role_manager([ALICE], {
    account: currentRoleManager
  });
  await vault.write.accept_role_manager({ account: ALICE });

  // Grant roles
  await vault.write.set_role([ALICE, ROLES.DEBT_MANAGER], { account: ALICE });

  console.log('Setup complete');
} catch (error) {
  await client.revert(snapshot); // Restore on error
  console.error('Setup failed:', error);
}
```

## Use Cases and Integration

Kalani serves as a comprehensive management interface for Yearn V3 vault operators, strategy developers, and DeFi users across multiple blockchain networks. The primary use case is vault management where operators can deploy new ERC-4626 vaults, add and configure yield strategies, allocate capital between strategies, manage debt limits, process performance reports, and collect fees. Strategy developers use the platform to register their strategies, monitor performance metrics, track gains and losses, and manage strategy-specific parameters. End users interact with the platform to discover high-yield vaults, deposit and withdraw assets, track portfolio performance, and monitor real-time APY calculations.

The platform integrates with several key DeFi protocols and tools including RainbowKit for multi-wallet connection support (MetaMask, WalletConnect, Coinbase Wallet), Wagmi and Viem for type-safe contract interactions and transaction handling, Tenderly for testnet forking and transaction simulation, and Moralis/custom APIs for token pricing and metadata. The backend message queue system powered by Kong API handles asynchronous blockchain data extraction, event log processing, state snapshot creation, and vault/strategy indexing. The modular architecture allows developers to extend functionality by adding custom strategies, implementing new allocator algorithms, integrating additional chains via viem's chain definitions, and building custom analytics dashboards using the exposed hooks and API endpoints.
