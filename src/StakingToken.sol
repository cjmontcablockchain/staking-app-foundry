// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {ERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

/**
 * @title StakingToken
 * @notice Simple ERC20 token for testing staking functionality
 * @dev Public mint function - FOR TESTING ONLY
 */
contract StakingToken is ERC20 {
    /**
     * @notice Constructor
     * @param name_ Token name
     * @param symbol_ Token symbol
     */
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {}

    /**
     * @notice Mint tokens to the caller
     * @param amount_ Amount of tokens to mint
     * @dev Public mint - FOR TESTING ONLY, not for production
     */
    function mint(uint256 amount_) external {
        _mint(msg.sender, amount_);
    }
}
