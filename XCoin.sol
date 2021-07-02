// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.5;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract XCoin is ERC20, Ownable {
    using SafeMath for uint256;

    uint256 private _totalSupply;

    constructor() ERC20("XCoin", "XCN") {
        _totalSupply = 10000000000000000;
    }

    function sendToOperator(address _operator) public onlyOwner {
        _mint(_operator, _totalSupply);
    }
}
