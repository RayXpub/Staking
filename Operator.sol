// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.5;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Operator is Ownable {
    IERC20 public immutable rewardToken;
    mapping(address => bool) approvedContracts;

    constructor(address _rewardToken) {
        rewardToken = IERC20(_rewardToken);
    }

    function whitelist(address _address) external onlyOwner {
        approvedContracts[_address] = true;
        rewardToken.approve(_address, rewardToken.balanceOf(address(this)));
    }
}
