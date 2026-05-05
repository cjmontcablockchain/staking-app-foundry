//SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import "forge-std/Test.sol";
import "../src/StakingToken.sol";
import "../src/StakingApp.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

/**
 * @title StakingAppIntegrationTest
 * @notice Tests de integración y escenarios complejos del contrato StakingApp
 */
contract StakingAppIntegrationTest is Test {

    StakingToken stakingToken;
    StakingApp stakingApp;

    // StakingToken parameters
    string name_ = "Staking Token";
    string symbol_ = "STK";

    //StakingApp parameters
    address owner_ = vm.addr(1);
    uint256 stakingPeriod_ = 1000000000000000;
    uint256 fixedStakingAmount_ = 10;
    uint256 rewardPerPeriod_ = 1 ether;

    address user1 = vm.addr(10);
    address user2 = vm.addr(11);
    address user3 = vm.addr(12);

    function setUp() external {
        stakingToken = new StakingToken(name_, symbol_);
        stakingApp = new StakingApp(address(stakingToken), owner_, stakingPeriod_, fixedStakingAmount_, rewardPerPeriod_);
    }

    // ============ INTEGRATION TESTS ============

    function testMultipleUsersCanStake() external {
        uint256 tokenAmount = stakingApp.fixedStakingAmount();
        
        // User 1 stakes
        vm.startPrank(user1);
        stakingToken.mint(tokenAmount);
        IERC20(stakingToken).approve(address(stakingApp), tokenAmount);
        stakingApp.depositTokens(tokenAmount);
        vm.stopPrank();
        
        // User 2 stakes
        vm.startPrank(user2);
        stakingToken.mint(tokenAmount);
        IERC20(stakingToken).approve(address(stakingApp), tokenAmount);
        stakingApp.depositTokens(tokenAmount);
        vm.stopPrank();
        
        // User 3 stakes
        vm.startPrank(user3);
        stakingToken.mint(tokenAmount);
        IERC20(stakingToken).approve(address(stakingApp), tokenAmount);
        stakingApp.depositTokens(tokenAmount);
        vm.stopPrank();
        
        assert(stakingApp.userBalance(user1) == tokenAmount);
        assert(stakingApp.userBalance(user2) == tokenAmount);
        assert(stakingApp.userBalance(user3) == tokenAmount);
    }

    function testMultipleUsersCanClaimRewards() external {
        uint256 tokenAmount = stakingApp.fixedStakingAmount();
        
        // Todos depositan
        vm.startPrank(user1);
        stakingToken.mint(tokenAmount);
        IERC20(stakingToken).approve(address(stakingApp), tokenAmount);
        stakingApp.depositTokens(tokenAmount);
        vm.stopPrank();
        
        vm.startPrank(user2);
        stakingToken.mint(tokenAmount);
        IERC20(stakingToken).approve(address(stakingApp), tokenAmount);
        stakingApp.depositTokens(tokenAmount);
        vm.stopPrank();
        
        // Owner fondea el contrato
        vm.startPrank(owner_);
        vm.deal(owner_, 1000 ether);
        (bool success,) = address(stakingApp).call{value: 1000 ether}("");
        require(success);
        vm.stopPrank();
        
        // Pasa el tiempo
        vm.warp(block.timestamp + stakingPeriod_);
        
        // User 1 reclama
        vm.startPrank(user1);
        uint256 balance1Before = address(user1).balance;
        stakingApp.claimRewards();
        uint256 balance1After = address(user1).balance;
        vm.stopPrank();
        
        // User 2 reclama
        vm.startPrank(user2);
        uint256 balance2Before = address(user2).balance;
        stakingApp.claimRewards();
        uint256 balance2After = address(user2).balance;
        vm.stopPrank();
        
        assert(balance1After - balance1Before == rewardPerPeriod_);
        assert(balance2After - balance2Before == rewardPerPeriod_);
    }

    function testFullCycleDepositClaimWithdraw() external {
        vm.startPrank(user1);
        
        // 1. Deposit
        uint256 tokenAmount = stakingApp.fixedStakingAmount();
        stakingToken.mint(tokenAmount);
        IERC20(stakingToken).approve(address(stakingApp), tokenAmount);
        stakingApp.depositTokens(tokenAmount);
        
        uint256 tokenBalanceAfterDeposit = IERC20(stakingToken).balanceOf(user1);
        assert(tokenBalanceAfterDeposit == 0); // Todos los tokens están en staking
        
        vm.stopPrank();
        
        // Owner fondea
        vm.startPrank(owner_);
        vm.deal(owner_, 100 ether);
        (bool success,) = address(stakingApp).call{value: 100 ether}("");
        require(success);
        vm.stopPrank();
        
        vm.startPrank(user1);
        
        // 2. Wait and Claim
        vm.warp(block.timestamp + stakingPeriod_);
        uint256 ethBalanceBefore = address(user1).balance;
        stakingApp.claimRewards();
        uint256 ethBalanceAfter = address(user1).balance;
        
        assert(ethBalanceAfter - ethBalanceBefore == rewardPerPeriod_);
        
        // 3. Withdraw
        stakingApp.withdrawTokens();
        uint256 tokenBalanceAfterWithdraw = IERC20(stakingToken).balanceOf(user1);
        
        assert(tokenBalanceAfterWithdraw == tokenAmount); // Recuperó sus tokens
        assert(stakingApp.userBalance(user1) == 0); // Balance en mapping es 0
        
        vm.stopPrank();
    }

    function testOwnerCanChangePeriodAndUsersAreAffected() external {
        vm.startPrank(user1);
        
        uint256 tokenAmount = stakingApp.fixedStakingAmount();
        stakingToken.mint(tokenAmount);
        IERC20(stakingToken).approve(address(stakingApp), tokenAmount);
        stakingApp.depositTokens(tokenAmount);
        
        vm.stopPrank();
        
        // Owner cambia el período
        vm.startPrank(owner_);
        uint256 newPeriod = 500;
        stakingApp.changeStakingPeriod(newPeriod);
        vm.deal(owner_, 100 ether);
        (bool success,) = address(stakingApp).call{value: 100 ether}("");
        require(success);
        vm.stopPrank();
        
        vm.startPrank(user1);
        
        // Con el nuevo período más corto, puede reclamar antes
        vm.warp(block.timestamp + newPeriod);
        stakingApp.claimRewards(); // No debería revertir
        
        vm.stopPrank();
    }

    function testContractBalanceDecreasesAfterClaims() external {
        uint256 tokenAmount = stakingApp.fixedStakingAmount();
        
        // User 1 deposita
        vm.startPrank(user1);
        stakingToken.mint(tokenAmount);
        IERC20(stakingToken).approve(address(stakingApp), tokenAmount);
        stakingApp.depositTokens(tokenAmount);
        vm.stopPrank();
        
        // User 2 deposita
        vm.startPrank(user2);
        stakingToken.mint(tokenAmount);
        IERC20(stakingToken).approve(address(stakingApp), tokenAmount);
        stakingApp.depositTokens(tokenAmount);
        vm.stopPrank();
        
        // Owner fondea
        vm.startPrank(owner_);
        uint256 fundAmount = 100 ether;
        vm.deal(owner_, fundAmount);
        (bool success,) = address(stakingApp).call{value: fundAmount}("");
        require(success);
        vm.stopPrank();
        
        uint256 contractBalanceBefore = address(stakingApp).balance;
        
        // Pasa el tiempo
        vm.warp(block.timestamp + stakingPeriod_);
        
        // User 1 reclama
        vm.prank(user1);
        stakingApp.claimRewards();
        
        // User 2 reclama
        vm.prank(user2);
        stakingApp.claimRewards();
        
        uint256 contractBalanceAfter = address(stakingApp).balance;
        
        // El contrato debe tener menos ETH
        assert(contractBalanceBefore - contractBalanceAfter == rewardPerPeriod_ * 2);
    }

    function testFuzzChangeStakingPeriod(uint256 newPeriod) external {
        vm.assume(newPeriod > 0);
        vm.assume(newPeriod < 365 days);
        
        vm.startPrank(owner_);
        stakingApp.changeStakingPeriod(newPeriod);
        
        assert(stakingApp.stakingPeriod() == newPeriod);
        
        vm.stopPrank();
    }
}
