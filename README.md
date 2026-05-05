# 🏦 StakingApp - Fixed Amount Staking with Rewards

A decentralized staking application built with Foundry that allows users to stake a fixed amount of ERC-20 tokens and earn ETH rewards after a predetermined period.

## 📋 Description

StakingApp is a smart contract system that implements a simple yet robust staking mechanism where:

- Users stake a **fixed amount** of ERC-20 tokens (e.g., 10 tokens)
- After a **staking period** elapses, users can claim **ETH rewards**
- Users can **withdraw** their staked tokens at any time
- Only the **owner** can fund the contract with ETH for rewards
- Comprehensive testing with **32 tests** covering security, edge cases, and integration scenarios

## 🎯 Key Features

### Staking Mechanics
- ✅ **Fixed staking amount**: All users must stake the exact amount
- ✅ **Time-based rewards**: Rewards unlock after the staking period
- ✅ **Multiple claim cycles**: Users can claim rewards multiple times
- ✅ **Flexible withdrawal**: Withdraw staked tokens anytime

### Security
- 🔒 **ReentrancyGuard**: Protection against reentrancy attacks on withdrawals and claims
- 🔒 **SafeERC20**: Safe token transfers with automatic return value checking
- 🔒 **Pausable**: Emergency stop mechanism for critical situations
- 🔒 **Access control**: Only owner can fund contract and pause/unpause
- 🔒 **Single deposit per user**: Prevents multiple deposits from the same address
- 🔒 **Balance validation**: Checks before transfers
- 🔒 **CEI Pattern**: Checks-Effects-Interactions pattern implemented

### Administration
- ⚙️ **Adjustable staking period**: Owner can modify the staking period
- ⚙️ **Pause/Unpause**: Owner can pause deposits in emergencies
- ⚙️ **Contract funding**: Owner funds the contract via `receive()` function
- ⚙️ **Event emission**: All critical actions emit events

## 🛠️ Technology Stack

- **Solidity** 0.8.24
- **Foundry** - Development framework and testing
- **OpenZeppelin Contracts** - Ownable, IERC20, SafeERC20, ReentrancyGuard, Pausable
- **Forge** - Compilation, testing, and deployment

## 📦 Installation

### Prerequisites

```bash
# Install Foundry
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

### Clone and Install

```bash
# Clone the repository
git clone https://github.com/cjmontcablockchain/staking-app.git
cd staking-app

# Install dependencies
forge install
```

## 🚀 Usage

### Compile the Contract

```bash
forge build
```

### Run Tests

```bash
# Run all tests
forge test

# Run with detailed output
forge test -vvv

# Run specific test file
forge test --match-contract StakingAppSecurityTest

# Run with gas report
forge test --gas-report

# Run with coverage
forge coverage
```

## 📊 Project Structure

```
staking-app/
├── src/
│   ├── StakingApp.sol         # Main staking contract
│   └── StakingToken.sol       # ERC-20 token for testing
├── test/
│   ├── StakingAppTest.t.sol              # Basic functionality tests (14 tests)
│   ├── StakingAppSecurityTest.t.sol      # Security tests (6 tests)
│   ├── StakingAppEdgeCasesTest.t.sol     # Edge case tests (5 tests)
│   ├── StakingAppIntegrationTest.t.sol   # Integration tests (6 tests)
│   ├── StakingAppPausableTest.t.sol      # Pausable functionality tests (9 tests)
│   └── StakingTokenTest.t.sol            # Token tests (1 test)
├── foundry.toml               # Foundry configuration
└── README.md
```

## 🧪 Testing

The project includes **41 comprehensive tests** organized in 5 test suites:

### Test Coverage

**StakingAppTest.t.sol** (14 tests)
- ✅ Deployment verification
- ✅ Owner functions (changeStakingPeriod, receive ether)
- ✅ Deposit validation (amount, single deposit)
- ✅ Withdrawal functionality
- ✅ Claim rewards (timing, balance checks)

**StakingAppSecurityTest.t.sol** (6 tests)
- ✅ Only owner can send ether
- ✅ Cannot claim without contract balance
- ✅ User balance reset after withdrawal
- ✅ Access control on period changes
- ✅ Deposit amount validation
- ✅ Single deposit enforcement

**StakingAppEdgeCasesTest.t.sol** (5 tests)
- ✅ Multiple claims across periods
- ✅ Cannot claim before full period
- ✅ Withdraw after claiming
- ✅ Elapsed period updates correctly
- ✅ Claim exactly at period end

**StakingAppIntegrationTest.t.sol** (6 tests)
- ✅ Multiple users staking
- ✅ Multiple users claiming rewards
- ✅ Full cycle: deposit → claim → withdraw
- ✅ Period changes affect users
- ✅ Contract balance tracking
- ✅ Fuzzing test for staking period

**StakingAppPausableTest.t.sol** (9 tests)
- ✅ Owner can pause contract
- ✅ Owner can unpause contract
- ✅ Non-owner cannot pause
- ✅ Non-owner cannot unpause
- ✅ Cannot deposit when paused
- ✅ Can withdraw when paused
- ✅ Can claim rewards when paused
- ✅ Pause emits event
- ✅ Unpause emits event

### Run Tests

```bash
forge test
```

**Expected output:**
```
Ran 41 tests
Test result: ok. 41 passed; 0 failed; finished in ~23ms
```

## 🔐 Smart Contract Functions

### Constructor

```solidity
constructor(
    address stakingToken_,
    address owner_,
    uint256 stakingPeriod_,
    uint256 stakingAmount_,
    uint256 rewardPerPeriod_
)
```

Initializes the staking contract with token address, owner, staking period, fixed amount, and reward per period.

### User Functions

```solidity
// Deposit fixed amount of tokens
function depositTokens(uint256 tokenAmountToDeposit_) external

// Withdraw staked tokens
function withdrawTokens() external

// Claim ETH rewards after staking period
function claimRewards() external
```

### Owner Functions

```solidity
// Change the staking period
function changeStakingPeriod(uint256 newStakingPeriod_) external onlyOwner

// Pause the contract (emergency stop)
function pause() external onlyOwner

// Unpause the contract
function unpause() external onlyOwner

// Fund the contract with ETH for rewards
receive() external payable onlyOwner
```

### View Functions

```solidity
uint256 public stakingPeriod;        // Current staking period
uint256 public fixedStakingAmount;   // Required staking amount
uint256 public rewardPerPeriod;      // ETH reward per period
mapping(address => uint256) public userBalance;     // User staked balance
mapping(address => uint256) public elapsedPeriod;   // User last claim timestamp
```

## 📝 Events

```solidity
event ChangeStakingPeriod(uint256 newStakingPeriod_);
event DepositTokens(address userAddress_, uint256 depositAmount_);
event WithdrawTokens(address userAddress_, uint256 withdrawAmount_);
event EtherSent(uint256 amount_);
```

## 🎓 Learning Outcomes

This project demonstrates proficiency in:

### Foundry Testing
- ✅ **Multiple test files**: Organized test suites for maintainability
- ✅ **setUp() pattern**: Proper test initialization
- ✅ **Foundry cheatcodes**: vm.prank(), vm.warp(), vm.deal(), vm.expectRevert()
- ✅ **Fuzzing**: Automated random input testing
- ✅ **Integration testing**: Multi-user scenarios

### Smart Contract Development
- ✅ **ERC-20 interactions**: Safe token transfers with SafeERC20
- ✅ **Time-based logic**: Block timestamp management
- ✅ **Access control**: OpenZeppelin Ownable implementation
- ✅ **State management**: Mappings for user balances and periods
- ✅ **Event emission**: Proper event logging

### Security Patterns
- ✅ **ReentrancyGuard**: Protection against reentrancy attacks
- ✅ **SafeERC20**: Automatic return value checking for token transfers
- ✅ **Pausable**: Emergency stop mechanism
- ✅ **Checks-Effects-Interactions**: Prevents reentrancy
- ✅ **Input validation**: Amount and balance checks
- ✅ **Access restrictions**: Owner-only functions
- ✅ **Safe ETH transfers**: Using low-level call with success check

## 🔍 Usage Example

### 1. Deploy Contracts

```solidity
// Deploy StakingToken
StakingToken token = new StakingToken("Staking Token", "STK");

// Deploy StakingApp
StakingApp stakingApp = new StakingApp(
    address(token),          // staking token
    msg.sender,              // owner
    7 days,                  // staking period
    100 * 10**18,           // fixed amount (100 tokens)
    0.1 ether               // reward per period
);
```

### 2. User Stakes Tokens

```solidity
// Mint tokens to user
token.mint(100 * 10**18);

// Approve staking contract
token.approve(address(stakingApp), 100 * 10**18);

// Deposit tokens
stakingApp.depositTokens(100 * 10**18);
```

### 3. Owner Funds Contract

```solidity
// Owner sends ETH to fund rewards
(bool success,) = address(stakingApp).call{value: 10 ether}("");
```

### 4. User Claims Rewards

```solidity
// Wait for staking period to pass
// ...

// Claim ETH rewards
stakingApp.claimRewards();  // Receives 0.1 ETH
```

### 5. User Withdraws Tokens

```solidity
// Withdraw staked tokens
stakingApp.withdrawTokens();  // Receives 100 tokens back
```

## 🌟 Differences: Multi-File Tests vs Single File

This project uses **multiple test files** for better organization:

| Aspect | Single File | Multiple Files (This Project) |
|--------|-------------|-------------------------------|
| **Organization** | All tests in one place | Tests grouped by category |
| **Maintainability** | Hard to navigate | Easy to find specific tests |
| **Execution** | Run all or use `--match-test` | Run specific suites with `--match-contract` |
| **Collaboration** | Merge conflicts | Parallel work on different suites |
| **Scalability** | Becomes unwieldy | Scales well |

**Run specific test suite:**
```bash
forge test --match-contract StakingAppSecurityTest
```

## 👨‍💻 Author

**Carlos J. Montero**

- GitHub: [@cjmontcablockchain](https://github.com/cjmontcablockchain)
- LinkedIn: [Carlos J. Montero ](https://www.linkedin.com/in/carlos-j-montero-cabrera-blockchain-web3/)

## 📄 License

This project is licensed under the MIT License.

## 🙏 Acknowledgments

- **Blockchain Accelerator** for the comprehensive Foundry training
- **@JoseCruz** for excellent mentorship and guidance
- Foundry team for creating an incredible development framework

---

**Note**: This is an educational project from the Blockchain Development program with Blockchain Accelerator.
