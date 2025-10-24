# NusaLend

<div align="center">
  <h1>🌉 NusaLend</h1>
  <p><strong>Cross-Chain Lending Protocol Powered by LayerZero</strong></p>
  
  [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
  [![Solidity](https://img.shields.io/badge/Solidity-^0.8.20-blue)](https://soliditylang.org/)
  [![LayerZero](https://img.shields.io/badge/LayerZero-V2-purple)](https://layerzero.network/)
  [![Foundry](https://img.shields.io/badge/Foundry-Built-orange)](https://getfoundry.sh/)
</div>

## Overview

NusaLend is a decentralized cross-chain lending protocol that enables users to supply liquidity, provide collateral, and borrow assets across multiple blockchain networks. Built on LayerZero V2, NusaLend provides seamless cross-chain borrowing capabilities while maintaining security and decentralization.

## ✨ Key Features

### 🌐 Cross-Chain Operations
- **Cross-chain borrowing**: Borrow assets on one chain using collateral from another
- **LayerZero V2 integration**: Secure and efficient cross-chain messaging
- **Multi-chain support**: Deploy on multiple EVM-compatible chains

### 💰 Lending & Borrowing
- **Collateral-based lending**: Supply assets as collateral to borrow other tokens
- **Dynamic interest rates**: Rates adjust based on utilization and market conditions
- **Share-based accounting**: Transparent and efficient accounting system
- **Configurable LTV ratios**: Flexible loan-to-value ratios per asset

### 🛡️ Security & Governance
- **Upgradeable contracts**: UUPS proxy pattern for future improvements
- **Role-based access control**: Multi-tier permission system
- **Pausable operations**: Emergency controls for protocol safety
- **Reentrancy protection**: Comprehensive security measures

### 📊 Price & Risk Management
- **Real-time price feeds**: Integrated oracle system for accurate pricing
- **Health factor monitoring**: Automated risk assessment
- **Dynamic risk parameters**: Adjustable risk management settings

## 🏗️ Architecture

### Core Contracts

#### LendingPool
The main contract that manages all lending and borrowing operations:
- Handles collateral deposits and withdrawals
- Manages liquidity supply and withdrawals
- Processes cross-chain borrow requests
- Calculates and accrues interest

#### OAppBorrow
LayerZero OApp contract for cross-chain operations:
- Sends and receives cross-chain messages
- Integrates with LendingPool for borrow execution
- Manages cross-chain token mappings

#### Router
Cross-chain configuration management:
- Manages supported chains and tokens
- Handles token address mappings across chains
- Configures cross-chain parameters

#### TokenDataStream
Oracle integration for price feeds:
- Provides real-time price data
- Ensures accurate collateral valuations

### Supported Networks

Currently deployed on:
- **Base** (Chain ID: 8453)
- **Arbitrum** (Chain ID: 42161)
- **Local Testnet** (Chain ID: 999)

## 🚀 Quick Start

### Prerequisites

- [Foundry](https://getfoundry.sh/) (latest version)
- Node.js 18+
- Git

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd nusa-sc
```

2. Install dependencies:
```bash
forge install
```

3. Build the project:
```bash
forge build
```

4. Run tests:
```bash
forge test
```

### Environment Setup

Create a `.env` file with your configuration:

```bash
# RPC URLs
BASE_MAINNET_RPC=https://mainnet.base.org
ARB_MAINNET_RPC=https://arb1.arbitrum.io/rpc

# Private keys (for deployment)
PRIVATE_KEY=your_private_key_here

# LayerZero endpoint addresses
BASE_ENDPOINT=0x1a44076050125825900e736c501f859c50fE728c
ARB_ENDPOINT=0x1a44076050125825900e736c501f859c50fE728c
```

## 📖 Usage

### Deploy Contracts

Deploy to Base mainnet:
```bash
forge script script/Nusa.s.sol --rpc-url base_mainnet --broadcast --verify
```

Deploy to Arbitrum mainnet:
```bash
forge script script/Nusa.s.sol --rpc-url arb_mainnet --broadcast --verify
```

### Supply Liquidity

Supply assets to earn interest:
```bash
forge script script/Shortcut/SupplyLiquidity.s.sol --rpc-url <rpc_url> --broadcast
```

### Borrow Cross-Chain

Borrow assets on a different chain:
```bash
forge script script/BorrowCrosschain.s.sol --rpc-url <rpc_url> --broadcast
```

### Mint Tokens

Mint test tokens for development:
```bash
forge script script/Shortcut/Mint.s.sol --rpc-url <rpc_url> --broadcast
```

## 🔧 Development

### Project Structure

```
nusa-sc/
├── src/                    # Source contracts
│   ├── LendingPool.sol    # Main lending pool contract
│   ├── L0/
│   │   └── OAppBorrow.sol # Cross-chain borrowing contract
│   ├── interfaces/        # Contract interfaces
│   ├── mocks/            # Mock contracts for testing
│   └── devTools/         # Development utilities
├── script/               # Deployment scripts
├── test/                 # Test files
├── lib/                  # External dependencies
└── broadcast/            # Deployment artifacts
```

### Testing

Run all tests:
```bash
forge test
```

Run specific test file:
```bash
forge test --match-path test/Nusa.t.sol
```

Run tests with gas reporting:
```bash
forge test --gas-report
```

### Code Quality

Format code:
```bash
forge fmt
```

Check for issues:
```bash
forge build
```

## 🔐 Security

### Audit Status
- Contracts are built using OpenZeppelin's battle-tested libraries
- LayerZero V2 integration for secure cross-chain messaging
- Comprehensive test coverage

### Best Practices
- Always verify contract addresses before interacting
- Use multi-sig wallets for administrative functions
- Regularly monitor protocol health and risk parameters

## 📊 Monitoring

### Key Metrics
- Total Value Locked (TVL)
- Utilization rates per asset
- Cross-chain message success rates
- Interest rate trends

### Health Monitoring
The protocol includes built-in health monitoring through the `IsHealthy` contract, which tracks:
- Collateral ratios
- Liquidity levels
- Cross-chain message status

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Commit your changes: `git commit -m 'Add amazing feature'`
4. Push to the branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Links

- [LayerZero Documentation](https://docs.layerzero.network/v2)
- [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts/)
- [Foundry Documentation](https://book.getfoundry.sh/)

## ⚠️ Disclaimer

This software is provided "as is" without warranty of any kind. Users should conduct their own due diligence before using this protocol with real funds.

---

<div align="center">
  <p>Built with ❤️ by the Nusa Protocol Team</p>
  <p>Powered by LayerZero V2</p>
</div>