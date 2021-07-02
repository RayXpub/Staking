// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.5;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./XCoin.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract Staking is Ownable {
    using SafeMath for uint256;
    using Math for uint256;

    address public operator;

    uint256 private liquidityMiningStart;
    uint256 private periodFinish = liquidityMiningStart + 365 days;
    uint256 public rewardRate = 5;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    uint256 public queuedRewards = 0;
    uint256 public currentRewards = 0;
    uint256 private _totalStakedSupply = address(this).balance;

    mapping(address => uint256) private _balances;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    IERC20 public immutable rewardToken;

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);

    AggregatorV3Interface internal priceFeed;

    constructor(address _rewardToken, address _operator) {
        priceFeed = AggregatorV3Interface(
            0x9326BFA02ADD2366b30bacB125260Af641031331
        );
        rewardToken = IERC20(_rewardToken);
        operator = _operator;
    }

    function getThePrice() public view returns (uint256) {
        (
            uint80 roundID,
            int256 price,
            uint256 startedAt,
            uint256 timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        return uint256(price);
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earnedReward(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    function totalStakedSupply() public view returns (uint256) {
        return _totalStakedSupply;
    }

    function stakerBalance(address account) public view returns (uint256) {
        return _balances[account];
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.number, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        uint256 supply = address(this).balance;
        if (supply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(rewardRate)
                    .mul(1e18)
                    .div(supply)
            );
    }

    function earnedReward(address account) internal view returns (uint256) {
        return
            stakerBalance(account)
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
                .div(1e18)
                .add(rewards[account]);
    }

    function launchLiquidityMining() public onlyOwner {
        require(
            liquidityMiningStart == 0,
            "Liquidity mining has already started"
        );
        liquidityMiningStart = block.number;
    }

    function stake() public payable updateReward(msg.sender) {
        require(msg.value > 0, "RewardPool : Cannot stake 0");
        require(
            liquidityMiningStart != 0,
            "Liquidity mining has not started yet"
        );

        _balances[msg.sender] = _balances[msg.sender].add(msg.value);

        emit Staked(msg.sender, msg.value);
    }

    function withdraw(uint256 _amount) public payable updateReward(msg.sender) {
        require(_amount > 0, "RewardPool : Cannot withdraw 0");
        require(_amount <= _balances[msg.sender], "Not enough funds");

        _balances[msg.sender] = _balances[msg.sender].sub(_amount);
        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success, "Withdrawal failed");

        emit Withdrawn(msg.sender, _amount);
    }

    function harverst(address _account) public updateReward(msg.sender) {
        uint256 reward = earnedReward(_account);
        require(reward > 0, "No reward available for harvest");
        rewards[_account] = 0;
        rewardToken.transferFrom(operator, msg.sender, reward);
        emit RewardPaid(_account, reward);
    }

    function getRewards(address _account)
        public
        updateReward(msg.sender)
        returns (uint256)
    {
        return rewards[_account];
    }
}
