//SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import "forge-std/Test.sol";
import "../src/StakingToken.sol";
import "../src/StakingApp.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

/**
 * @title StakingAppEdgeCasesTest
 * @notice Tests de casos límite del contrato StakingApp
 */
contract StakingAppEdgeCasesTest is Test {

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

    address randomUser = vm.addr(2);

    function setUp() external {
        stakingToken = new StakingToken(name_, symbol_);
        stakingApp = new StakingApp(address(stakingToken), owner_, stakingPeriod_, fixedStakingAmount_, rewardPerPeriod_);
    }

    // ============ EDGE CASES TESTS ============

    function testCanClaimMultipleTimesAfterPeriods() external {
        vm.startPrank(randomUser);
        
        // Depositar tokens
        uint256 tokenAmount = stakingApp.fixedStakingAmount();
        stakingToken.mint(tokenAmount);
        IERC20(stakingToken).approve(address(stakingApp), tokenAmount);
        stakingApp.depositTokens(tokenAmount);
        
        vm.stopPrank();
        
        // Fondear contrato
        vm.startPrank(owner_);
        vm.deal(owner_, 100 ether);
        (bool success,) = address(stakingApp).call{value: 100 ether}("");
        require(success);
        vm.stopPrank();
        
        vm.startPrank(randomUser);
        
        // Primera reclamación
        vm.warp(block.timestamp + stakingPeriod_);
        uint256 balanceBefore1 = address(randomUser).balance;
        stakingApp.claimRewards();
        uint256 balanceAfter1 = address(randomUser).balance;
        
        // Segunda reclamación (otro período)
        vm.warp(block.timestamp + stakingPeriod_);
        uint256 balanceBefore2 = address(randomUser).balance;
        stakingApp.claimRewards();
        uint256 balanceAfter2 = address(randomUser).balance;
        
        assert(balanceAfter1 - balanceBefore1 == rewardPerPeriod_);
        assert(balanceAfter2 - balanceBefore2 == rewardPerPeriod_);
        
        vm.stopPrank();
    }

    function testCannotClaimRewardsBeforeFullPeriod() external {
        vm.startPrank(randomUser);
        
        uint256 tokenAmount = stakingApp.fixedStakingAmount();
        stakingToken.mint(tokenAmount);
        IERC20(stakingToken).approve(address(stakingApp), tokenAmount);
        stakingApp.depositTokens(tokenAmount);
        
        // Avanzar tiempo CASI un período completo
        vm.warp(block.timestamp + stakingPeriod_ - 1);
        
        vm.expectRevert("Need to wait");
        stakingApp.claimRewards();
        
        vm.stopPrank();
    }

    function testCanWithdrawAfterClaiming() external {
        vm.startPrank(randomUser);
        
        uint256 tokenAmount = stakingApp.fixedStakingAmount();
        stakingToken.mint(tokenAmount);
        IERC20(stakingToken).approve(address(stakingApp), tokenAmount);
        stakingApp.depositTokens(tokenAmount);
        
        vm.stopPrank();
        
        vm.startPrank(owner_);
        vm.deal(owner_, 100 ether);
        (bool success,) = address(stakingApp).call{value: 100 ether}("");
        require(success);
        vm.stopPrank();
        
        vm.startPrank(randomUser);
        vm.warp(block.timestamp + stakingPeriod_);
        stakingApp.claimRewards();
        
        // Verificar que después de claim puede retirar
        uint256 tokenBalanceBefore = IERC20(stakingToken).balanceOf(randomUser);
        stakingApp.withdrawTokens();
        uint256 tokenBalanceAfter = IERC20(stakingToken).balanceOf(randomUser);
        
        assert(tokenBalanceAfter - tokenBalanceBefore == tokenAmount);
        
        vm.stopPrank();
    }

    function testElapsedPeriodUpdatesAfterClaim() external {
        vm.startPrank(randomUser);
        
        uint256 tokenAmount = stakingApp.fixedStakingAmount();
        stakingToken.mint(tokenAmount);
        IERC20(stakingToken).approve(address(stakingApp), tokenAmount);
        stakingApp.depositTokens(tokenAmount);
        
        uint256 depositTime = block.timestamp;
        
        vm.stopPrank();
        
        vm.startPrank(owner_);
        vm.deal(owner_, 100 ether);
        (bool success,) = address(stakingApp).call{value: 100 ether}("");
        require(success);
        vm.stopPrank();
        
        vm.startPrank(randomUser);
        
        uint256 newTimestamp = block.timestamp + stakingPeriod_;
        vm.warp(newTimestamp);
        stakingApp.claimRewards();
        
        uint256 elapsedAfterClaim = stakingApp.elapsedPeriod(randomUser);
        
        assert(elapsedAfterClaim == newTimestamp);
        assert(elapsedAfterClaim > depositTime);
        
        vm.stopPrank();
    }

    function testCanClaimExactlyAtPeriodEnd() external {
        vm.startPrank(randomUser);
        
        uint256 tokenAmount = stakingApp.fixedStakingAmount();
        stakingToken.mint(tokenAmount);
        IERC20(stakingToken).approve(address(stakingApp), tokenAmount);
        stakingApp.depositTokens(tokenAmount);
        
        vm.stopPrank();
        
        vm.startPrank(owner_);
        vm.deal(owner_, 100 ether);
        (bool success,) = address(stakingApp).call{value: 100 ether}("");
        require(success);
        vm.stopPrank();
        
        vm.startPrank(randomUser);
        
        // Avanzar EXACTAMENTE un período
        vm.warp(block.timestamp + stakingPeriod_);
        
        uint256 balanceBefore = address(randomUser).balance;
        stakingApp.claimRewards();
        uint256 balanceAfter = address(randomUser).balance;
        
        assert(balanceAfter - balanceBefore == rewardPerPeriod_);
        
        vm.stopPrank();
    }
}
