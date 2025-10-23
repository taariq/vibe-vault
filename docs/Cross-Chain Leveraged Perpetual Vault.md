# EPIC 06/02/25: Cross-Chain Leveraged Perpetual Vault Launch and Claim System

## Introduction

Leveraged trading through perpetual futures offers powerful financial tools, but users face challenges including complexity, margin management, and cross-chain access. Our goal is to simplify leveraged exposure to major crypto assets by offering vault-style products that launch automatically upon reaching targeted asset under management (AUM). Users can easily participate from their preferred blockchain and seamlessly claim funds post-vault maturity or liquidation.

## Problem

- Users desire easy, cross-chain access to leveraged perpetual trading.
- Managing individual perpetual positions is complex and risky.
- Traditional vault implementations lack cross-chain interoperability and seamless redemption processes.

## Solution

Implement an automated vault launch system that simplifies user experience:

1. **Vault Creation and AUM Threshold**
    - Users propose a leveraged vault specifying a target asset, leverage, and AUM threshold.
    - The vault opens for USDC contributions across multiple chains.
2. **Cross-Chain Contributions**
    - Users deposit USDC on their preferred blockchain (e.g., Ethereum, Arbitrum, Optimism, Base).
    - Contributions are tracked and aggregated off-chain via indexing and bridging protocols (LayerZero or Wormhole).
3. **Automated Activation**
    - When the vault reaches the defined AUM threshold, **90% of contributed USDC is bridged to Hyperliquid** to open a leveraged perpetual position matching vault criteria (asset, leverage, and direction).
    - **The remaining 10% is paired with a portion of vault tokens to form a Paloma DEX liquidity pool**, enabling limited secondary market trading.
4. **Tokenized Claims**
    - Vault equity is represented by ERC-20 tokens distributed proportionally to users' contributions.
    - Users hold these tokens as proof-of-stake in the vault, tradable on decentralized exchanges (DEX) with liquidity seeded from the 10% allocation.
5. **Vault Resolution (Maturity or Liquidation)**
    - Upon vault maturity (time-based or target-based) or liquidation, positions are closed automatically on Hyperliquid.
    - Remaining USDC funds are bridged back to Arbitrum and then to Paloma for distribution.
    - Vault token redemption opens; users can burn their tokens to reclaim their share of final USDC.
6. **Cross-Chain Redemption**
    - Users burn their vault tokens to claim USDC, redeemable on their preferred chain.
    - Redemption interface provides transparent tracking and straightforward claim functionality.
    - **DEX liquidity remains open for secondary trading.**

## Considerations and Drawbacks

- **Leverage Drift**: Target leverage (e.g., 3x Bitcoin) will drift with price movements; the vault will not maintain the advertised leverage.
- **Liquidity and Entry/Exit Constraints**: Users cannot freely enter or exit positions outside the vault lifecycle; deposits and redemptions only occur during scheduled windows. The vault may enter or exit its position at prices that users did not intend.
- **Holding Period Restrictions**: Tokens should not be held long-term; users must proactively claim their assets post-vault resolution.
- **Launch Risk**: Vault may fail to reach the target AUM threshold, resulting in returned funds and potential user frustration..
- **Market Fragmentation:** The Vault approach necessitates the creation of many products with the same underlying and that expire. There will be no single market where volume and liquidity can aggregate.
- **No Direct Intervention**: Users cannot individually manage or intervene in vault liquidations, potentially exposing them to unfavorable forced liquidations during rapid market downturns.
- **Execution Risk**: Temporary market moves (or manipulation or glitches) on Hyperliquid might trigger liquidations at the worst possible prices.

## User Stories

### Vault Proposal and Activation

As a DeFi user, I want to propose and contribute to vaults targeting leveraged perpetual positions so that I can gain exposure to leveraged markets easily.

**Acceptance Criteria:**

- Users can propose vaults specifying asset, leverage, and AUM threshold.
- Users can deposit USDC across multiple blockchains.
- Vault activation occurs automatically upon reaching target AUM threshold.
- 90% of raised USDC is deployed into a perpetual position; 10% is allocated to create a Paloma DEX liquidity pool.
- Contributors receive ERC-20 tokens representing their proportional stake in the vault.

### Tokenized Claim Management

As a vault participant, I want clear tokenized proof of my stake, enabling transparent tracking and tradability.

**Acceptance Criteria:**

- Tokenized vault claims are issued as ERC-20 tokens.
- Tokens are proportionally distributed based on user contributions.
- Tokens are tradable on decentralized exchanges (DEX) with initial liquidity seeded from vault proceeds.

### Redemption Process

As a vault participant, I want a straightforward redemption process to reclaim my funds after vault maturity or liquidation.

**Acceptance Criteria:**

- Users can burn vault tokens to redeem USDC.
- Redemption supports multiple blockchain options.
- Transparent tracking of vault status and redemption eligibility is available.

## Q/A

[API | Hyperliquid Docs](https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api)

[https://github.com/kylebolton/HyperliquidMarketMaker](https://github.com/kylebolton/HyperliquidMarketMaker)

[🔥 Hyperliquid - Hummingbot](https://hummingbot.org/exchanges/hyperliquid/)