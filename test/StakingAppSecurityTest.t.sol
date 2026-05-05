//SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import "forge-std/Test.sol";
import "../src/StakingToken.sol";
import "../src/StakingApp.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

/**
 * @title StakingAppSecurityTest
 * @notice Tests de seguridad del contrato StakingApp
 */
contract StakingAppSecurityTest is Test {

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

    // ============ SECURITY TESTS ============

    function testOnlyOwnerCanSendEther() external {
        vm.startPrank(randomUser);
        vm.deal(randomUser, 10 ether);
        
        vm.expectRevert(); // Ownable: caller is not the owner
        (bool success,) = address(stakingApp).call{value: 1 ether}("");
        
        vm.stopPrank();
    }

    function testCannotClaimWithoutContractBalance() external {
        vm.startPrank(randomUser);
        
        uint256 tokenAmount = stakingApp.fixedStakingAmount();
        stakingToken.mint(tokenAmount);
        IERC20(stakingToken).approve(address(stakingApp), tokenAmount);
        stakingApp.depositTokens(tokenAmount);
        
        vm.warp(block.timestamp + stakingPeriod_);
        
        // NO se fondea el contrato con ETH
        vm.expectRevert("Transfer failed");
        stakingApp.claimRewards();
        
        vm.stopPrank();
    }

    function testUserBalanceIsZeroAfterWithdraw() external {
        vm.startPrank(randomUser);
        
        uint256 tokenAmount = stakingApp.fixedStakingAmount();
        stakingToken.mint(tokenAmount);
        IERC20(stakingToken).approve(address(stakingApp), tokenAmount);
        stakingApp.depositTokens(tokenAmount);
        
        stakingApp.withdrawTokens();
        
        uint256 balanceAfterWithdraw = stakingApp.userBalance(randomUser);
        assert(balanceAfterWithdraw == 0);
        
        vm.stopPrank();
    }

    function testOnlyOwnerCanChangeStakingPeriod() external {
        vm.startPrank(randomUser);
        
        vm.expectRevert();
        stakingApp.changeStakingPeriod(1000);
        
        vm.stopPrank();
    }

    function testCannotDepositZeroAmount() external {
        vm.startPrank(randomUser);
        
        vm.expectRevert("Incorrect Amount");
        stakingApp.depositTokens(0);
        
        vm.stopPrank();
    }

    function testCannotDepositTwice() external {
        vm.startPrank(randomUser);
        
        uint256 tokenAmount = stakingApp.fixedStakingAmount();
        stakingToken.mint(tokenAmount * 2); // Mintear el doble
        
        IERC20(stakingToken).approve(address(stakingApp), tokenAmount * 2);
        stakingApp.depositTokens(tokenAmount);
        
        // Segundo depósito debe fallar
        vm.expectRevert();
        stakingApp.depositTokens(tokenAmount);
        
        vm.stopPrank();
    }
}
