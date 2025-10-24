# Vibe Vault

**AI-Powered No-Code DeFi Vault Creation Platform**

Vibe Vault democratizes DeFi vault creation by enabling anyone to design, deploy, and manage sophisticated yield strategies across multiple blockchains using natural language—no coding required.

---

## File Inventory

### 📋 ICO Proposals & Pitch Decks

**[docs/Legion_ICO_Proposal_Vibe_Vault.md](docs/Legion_ICO_Proposal_Vibe_Vault.md)**
- Complete Legion ICO proposal for $3M raise with merit-based token distribution; use as primary fundraising document for Legion platform submissions.

**[docs/MetaDAO_ICO_Proposal_Vibe_Vault.md](docs/MetaDAO_ICO_Proposal_Vibe_Vault.md)**
- Complete MetaDAO ICO proposal for $1-2M raise with futarchy governance; use as primary fundraising document for MetaDAO platform submissions.

**[docs/Vibe_Vault_Legion_Pitch_Deck.md](docs/Vibe_Vault_Legion_Pitch_Deck.md)**
- 25-slide pitch deck in markdown format covering problem, solution, partnership, and roadmap; convert to PowerPoint or use directly for presentations.

**[docs/Vibe_Vault_Legion_Pitch_Deck.pptx](docs/Vibe_Vault_Legion_Pitch_Deck.pptx)**
- PowerPoint version of the Legion pitch deck ready for investor presentations and pitch sessions.

**[docs/Legion_Whitepaper.pdf](docs/Legion_Whitepaper.pdf)**
- Legion platform whitepaper detailing merit-based fundraising and MiCA compliance; reference for understanding Legion's model and requirements.

---

### 🏗️ Vault Specifications

**[docs/Cross-Chain Leveraged Perpetual Vault.md](docs/Cross-Chain Leveraged Perpetual Vault.md)**
- Complete specification for flagship cross-chain perpetual vault example demonstrating USDC deposits, Hyperliquid integration, and automated market making; use as reference architecture for complex multi-chain vaults.

---

### 🤝 Partnership Documentation

**[docs/Kalani for Yearn Vault Management.md](docs/Kalani for Yearn Vault Management.md)**
- Yearn V3 and Kalani platform specifications covering ERC-4626 multi-strategy vaults; reference when building Yearn-compatible vault strategies.

**[docs/yearn_metrics.md](docs/yearn_metrics.md)**
- Complete list of 33 Yearn vaults with TVL ($965.92M total) and APY data; use for partnership materials and understanding Yearn ecosystem scope.

---

### 💻 Smart Contracts (Vyper)

**[contracts/kGOLDt.vy](contracts/kGOLDt.vy)** (608 lines)
- Main ERC-4626 vault contract for gold-backed yield vault with deposit/withdraw/mint/redeem functions, 15% buffer reserve, and withdrawal queue; deploy as primary vault contract on Ethereum.

**[contracts/VaultManager.vy](contracts/VaultManager.vy)** (517 lines)
- Multi-strategy vault manager handling up to 10 strategies with debt allocation, harvest coordination, and profit/loss reporting; deploy to coordinate multiple yield sources for a single vault.

**[contracts/AaveMidasStrategy.vy](contracts/AaveMidasStrategy.vy)** (607 lines)
- Strategy contract implementing Aave V3 collateralization (50% LTV) with Midas mRE7YIELD deployment and automated USDC→XAUt harvest via 1inch; deploy as strategy for VaultManager to generate yield through collateralized lending.

**[contracts/interfaces/IStrategy.vyi](contracts/interfaces/IStrategy.vyi)**
- Vyper interface defining standard strategy contract methods (deploy, withdraw, harvest, emergencyExit); implement this interface when creating new strategy contracts.

**[contracts/README.md](contracts/README.md)**
- Comprehensive documentation covering contract architecture, deployment steps, security considerations, and testing procedures; read before deploying any contracts.

---

### ⚙️ Paloma CosmWasm Automation

**[cosmwasm/harvest_job/src/contract.rs](cosmwasm/harvest_job/src/contract.rs)** (483 lines)
- Main CosmWasm contract coordinating automated daily harvests via Paloma Compass EVM with configurable intervals and LTV monitoring; deploy to Paloma Chain to automate vault operations cross-chain.

**[cosmwasm/harvest_job/src/msg.rs](cosmwasm/harvest_job/src/msg.rs)**
- Message types for instantiation, execution (harvest, update config, pause/resume), and queries; reference when interacting with deployed harvest job contract.

**[cosmwasm/harvest_job/src/state.rs](cosmwasm/harvest_job/src/state.rs)**
- State management for harvest configuration, statistics tracking, and contract settings; reference when querying contract state or understanding storage layout.

**[cosmwasm/harvest_job/src/error.rs](cosmwasm/harvest_job/src/error.rs)**
- Error types and handling for harvest job failures and validation; reference when debugging contract execution failures.

**[cosmwasm/harvest_job/src/lib.rs](cosmwasm/harvest_job/src/lib.rs)**
- Library exports for CosmWasm contract compilation; required for building the contract with `cargo build`.

**[cosmwasm/harvest_job/Cargo.toml](cosmwasm/harvest_job/Cargo.toml)**
- Rust package configuration with CosmWasm dependencies; use `cargo build --release --target wasm32-unknown-unknown` to compile for Paloma deployment.

---

### 📚 Reference Documentation

**[docs/palomachain_docs.md](docs/palomachain_docs.md)**
- Paloma Chain documentation covering cross-chain messaging, Compass EVM, and validator network; reference when integrating Paloma infrastructure.

**[docs/paloma_lightNode.md](docs/paloma_lightNode.md)**
- Paloma LightNode specification for decentralized frontend hosting; reference when building user-facing Vibe Vault interface.

**[docs/brainstorm.md](docs/brainstorm.md)**
- Initial brainstorming and ideation notes; reference for understanding project evolution and early design decisions.

**[docs/Omnipair_Proposal #31 to MetaDAO has passed.md](docs/Omnipair_Proposal #31 to MetaDAO has passed.md)**
- Example successful MetaDAO proposal showing futarchy governance format; reference when understanding MetaDAO proposal structure.

**[docs/docs.metadao.fi_.2025-10-23T06_59_46.854Z.md](docs/docs.metadao.fi_.2025-10-23T06_59_46.854Z.md)**
- MetaDAO documentation snapshot covering futarchy, conditional markets, and governance mechanics; reference when preparing MetaDAO submission.

---

### 🤖 AI Agent Guidance

**[CLAUDE.md](CLAUDE.md)**
- Instructions for Claude AI instances working in this repository covering project architecture, key decisions, and development guidelines; read first before making any code changes or additions.

---

## Quick Start Guide

### For Fundraising
1. Use **Legion_ICO_Proposal_Vibe_Vault.md** or **MetaDAO_ICO_Proposal_Vibe_Vault.md** depending on target platform
2. Reference **Vibe_Vault_Legion_Pitch_Deck.pptx** for investor presentations
3. Share **yearn_metrics.md** to demonstrate partnership value and market opportunity

### For Development
1. Read **CLAUDE.md** to understand project architecture and decisions
2. Review **contracts/README.md** for deployment procedures and security guidelines
3. Reference **Cross-Chain Leveraged Perpetual Vault.md** or **kGOLDt spec** for vault architecture patterns
4. Deploy Vyper contracts from **contracts/** directory to Ethereum
5. Deploy CosmWasm harvest job from **cosmwasm/harvest_job/** to Paloma Chain for automation

### For Partnership Discussions
1. Reference **Kalani for Yearn Vault Management.md** for technical integration details
2. Use **yearn_metrics.md** to demonstrate $965.92M TVL ecosystem opportunity
3. Share relevant ICO proposal sections covering partnership benefits and launch metrics

---

## Technology Stack

- **Smart Contracts:** Vyper 0.3.10 (Ethereum)
- **Automation:** CosmWasm (Paloma Chain)
- **Vault Standard:** ERC-4626
- **Cross-Chain:** Paloma Compass EVM
- **Database:** SerenDB (AI-native)
- **DeFi Protocols:** Aave V3, Midas Protocol, Yearn Finance, 1inch

---

## Project Status

**Current Phase:** Fundraising & Partnership Development

- ✅ Complete ICO proposals for Legion and MetaDAO
- ✅ 25-slide pitch deck with comprehensive partnership details
- ✅ Reference vault implementations (kGOLDt Vyper contracts)
- ✅ Paloma CosmWasm automation contracts
- ✅ Strategic partnership with Yearn Finance ($965.92M TVL, 33 vaults)
- 🔄 Seeking $1-3M funding through MetaDAO or Legion platforms
- 📅 6-month timeline to production launch and TGE

---

## Contact

**Project Lead:** Taariq Lewis
**Paloma Chain:** https://palomachain.com
**Paloma Documentation:** https://docs.palomachain.com/
**SerenDB:** https://serendb.com
**Legion Platform:** https://legion.cc
