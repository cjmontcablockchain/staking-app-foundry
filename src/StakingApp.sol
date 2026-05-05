//SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "../lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {Pausable} from "../lib/openzeppelin-contracts/contracts/utils/Pausable.sol";

/**
 * @title StakingApp
 * @notice Fixed amount staking contract with time-based ETH rewards
 * @dev Implements ReentrancyGuard and Pausable for security
 */
contract StakingApp is Ownable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;

    // State variables
    address public stakingToken; 
    uint256 public stakingPeriod;   
    uint256 public fixedStakingAmount;
    uint256 public rewardPerPeriod;
    mapping(address => uint256) public userBalance;
    mapping(address => uint256) public elapsedPeriod;

    // Events
    event ChangeStakingPeriod(uint256 newStakingPeriod_);
    event DepositTokens(address indexed userAddress_, uint256 depositAmount_);
    event WithdrawTokens(address indexed userAddress_, uint256 withdrawAmount_);
    event EtherSent(uint256 amount_);

    /**
     * @notice Constructor
     * @param stakingToken_ Address of the ERC20 token to stake
     * @param owner_ Address of the contract owner
     * @param stakingPeriod_ Time period for staking rewards
     * @param stakingAmount_ Fixed amount required for staking
     * @param rewardPerPeriod_ ETH reward amount per period
     */
    constructor(
        address stakingToken_, 
        address owner_, 
        uint256 stakingPeriod_, 
        uint256 stakingAmount_, 
        uint256 rewardPerPeriod_
    ) Ownable(owner_) {
        stakingToken = stakingToken_;
        stakingPeriod = stakingPeriod_;
        fixedStakingAmount = stakingAmount_;
        rewardPerPeriod = rewardPerPeriod_;
    }

    /**
     * @notice Deposit tokens to start staking
     * @param tokenAmountToDeposit_ Amount of tokens to deposit
     * @dev Can only deposit the exact fixed amount, once per address
     */
    function depositTokens(uint256 tokenAmountToDeposit_) external whenNotPaused {
        require(tokenAmountToDeposit_ == fixedStakingAmount, "Incorrect Amount");
        require(userBalance[msg.sender] == 0, "User already deposited");

        IERC20(stakingToken).safeTransferFrom(msg.sender, address(this), tokenAmountToDeposit_);
        userBalance[msg.sender] += tokenAmountToDeposit_;
        elapsedPeriod[msg.sender] = block.timestamp;

        emit DepositTokens(msg.sender, tokenAmountToDeposit_);
    }

    /**
     * @notice Withdraw staked tokens
     * @dev Can withdraw at any time, resets user balance to zero
     */
    function withdrawTokens() external nonReentrant {
        uint256 userBalance_ = userBalance[msg.sender];
        userBalance[msg.sender] = 0;
        IERC20(stakingToken).safeTransfer(msg.sender, userBalance_);

        emit WithdrawTokens(msg.sender, userBalance_);
    }

    /**
     * @notice Claim ETH rewards after staking period
     * @dev Requires full staking period to have elapsed
     */
    function claimRewards() external nonReentrant {
        // 1. Check balance
        require(userBalance[msg.sender] == fixedStakingAmount, "Not staking");

        // 2. Calculate reward amount
        uint256 elapsedPeriod_ = block.timestamp - elapsedPeriod[msg.sender];
        require(elapsedPeriod_ >= stakingPeriod, "Need to wait");

        // 3. Update state
        elapsedPeriod[msg.sender] = block.timestamp;

        // 4. Transfer rewards
        (bool success,) = msg.sender.call{value: rewardPerPeriod}("");
        require(success, "Transfer failed");
    }

    /**
     * @notice Pause the contract (emergency stop)
     * @dev Only owner can pause
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause the contract
     * @dev Only owner can unpause
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Change the staking period
     * @param newStakingPeriod_ New staking period in seconds
     * @dev Only owner can change the staking period
     */
    function changeStakingPeriod(uint256 newStakingPeriod_) external onlyOwner {
        stakingPeriod = newStakingPeriod_;
        emit ChangeStakingPeriod(newStakingPeriod_);
    }

    /**
     * @notice Receive ETH to fund rewards
     * @dev Only owner can send ETH to the contract
     */
    receive() external payable onlyOwner {
        emit EtherSent(msg.value);
    }
}
