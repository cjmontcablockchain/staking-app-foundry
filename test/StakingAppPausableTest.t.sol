//SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import "forge-std/Test.sol";
import "../src/StakingToken.sol";
import "../src/StakingApp.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

/**
 * @title StakingAppPausableTest
 * @notice Tests para la funcionalidad Pausable del contrato StakingApp
 */
contract StakingAppPausableTest is Test {
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
        stakingApp =
            new StakingApp(address(stakingToken), owner_, stakingPeriod_, fixedStakingAmount_, rewardPerPeriod_);
    }

    // ============ PAUSABLE TESTS ============

    function testOwnerCanPause() external {
        vm.startPrank(owner_);

        stakingApp.pause();
        // Verificar que está pausado intentando depositar

        vm.stopPrank();

        vm.startPrank(randomUser);
        uint256 tokenAmount = stakingApp.fixedStakingAmount();
        stakingToken.mint(tokenAmount);
        IERC20(stakingToken).approve(address(stakingApp), tokenAmount);

        vm.expectRevert(); // Pausable: paused
        stakingApp.depositTokens(tokenAmount);

        vm.stopPrank();
    }

    function testOwnerCanUnpause() external {
        vm.startPrank(owner_);

        // Pausar
        stakingApp.pause();

        // Despausar
        stakingApp.unpause();

        vm.stopPrank();

        // Ahora debería funcionar normalmente
        vm.startPrank(randomUser);
        uint256 tokenAmount = stakingApp.fixedStakingAmount();
        stakingToken.mint(tokenAmount);
        IERC20(stakingToken).approve(address(stakingApp), tokenAmount);

        stakingApp.depositTokens(tokenAmount); // No debería revertir

        assert(stakingApp.userBalance(randomUser) == tokenAmount);

        vm.stopPrank();
    }

    function testNonOwnerCannotPause() external {
        vm.startPrank(randomUser);

        vm.expectRevert(); // Ownable: caller is not the owner
        stakingApp.pause();

        vm.stopPrank();
    }

    function testNonOwnerCannotUnpause() external {
        vm.startPrank(owner_);
        stakingApp.pause();
        vm.stopPrank();

        vm.startPrank(randomUser);

        vm.expectRevert(); // Ownable: caller is not the owner
        stakingApp.unpause();

        vm.stopPrank();
    }

    function testCannotDepositWhenPaused() external {
        vm.prank(owner_);
        stakingApp.pause();

        vm.startPrank(randomUser);
        uint256 tokenAmount = stakingApp.fixedStakingAmount();
        stakingToken.mint(tokenAmount);
        IERC20(stakingToken).approve(address(stakingApp), tokenAmount);

        vm.expectRevert(); // Pausable: paused
        stakingApp.depositTokens(tokenAmount);

        vm.stopPrank();
    }

    function testCanWithdrawWhenPaused() external {
        // Primero depositar
        vm.startPrank(randomUser);
        uint256 tokenAmount = stakingApp.fixedStakingAmount();
        stakingToken.mint(tokenAmount);
        IERC20(stakingToken).approve(address(stakingApp), tokenAmount);
        stakingApp.depositTokens(tokenAmount);
        vm.stopPrank();

        // Pausar el contrato
        vm.prank(owner_);
        stakingApp.pause();

        // Verificar que puede retirar incluso pausado (withdrawTokens no tiene whenNotPaused)
        vm.startPrank(randomUser);
        stakingApp.withdrawTokens();

        assert(stakingApp.userBalance(randomUser) == 0);

        vm.stopPrank();
    }

    function testCanClaimRewardsWhenPaused() external {
        // Primero depositar
        vm.startPrank(randomUser);
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

        // Pausar el contrato
        vm.prank(owner_);
        stakingApp.pause();

        // Verificar que puede reclamar incluso pausado (claimRewards no tiene whenNotPaused)
        vm.startPrank(randomUser);
        vm.warp(block.timestamp + stakingPeriod_);

        uint256 balanceBefore = address(randomUser).balance;
        stakingApp.claimRewards();
        uint256 balanceAfter = address(randomUser).balance;

        assert(balanceAfter - balanceBefore == rewardPerPeriod_);

        vm.stopPrank();
    }

    function testPauseEmitsEvent() external {
        vm.startPrank(owner_);

        vm.expectEmit(true, false, false, true);
        emit Paused(owner_);
        stakingApp.pause();

        vm.stopPrank();
    }

    function testUnpauseEmitsEvent() external {
        vm.startPrank(owner_);

        stakingApp.pause();

        vm.expectEmit(true, false, false, true);
        emit Unpaused(owner_);
        stakingApp.unpause();

        vm.stopPrank();
    }

    // Events
    event Paused(address account);
    event Unpaused(address account);
}
