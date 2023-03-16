// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract StakeContract {
    address public immutable I_OWNER;

    IERC721 public nft;
    IERC20 public token;
    uint public rewardRate;
    uint public stakingStartTime;
    uint public stakingEndTime;

    struct Stake {
        uint stakeAmount;
        uint stakeStartTime;
    }

    mapping(address => Stake) stakes;

    event Staked(address indexed staker, uint stakedAmount);

    event Unstaked(address indexed staker, uint unstakedAmount);

    event ClaimedStakeRewards(address indexed staker, uint reward);

    constructor(
        address _requiredNftAddress,
        address _requiredTokenAddress,
        uint _rewardRate,
        uint _stakingStartTime,
        uint _stakingEndTime
    ) {
        I_OWNER = msg.sender;
        nft = IERC721(_requiredNftAddress);
        token = IERC20(_requiredTokenAddress);
        rewardRate = _rewardRate;
        stakingStartTime = _stakingStartTime;
        stakingEndTime = _stakingEndTime;
    }

    function stake(uint _amount) external {
        // checking if the user has the nft
        require(nft.balanceOf(msg.sender) > 0);

        // checking that the user has sufficient balance
        require(token.balanceOf(msg.sender) > _amount, "Not enough tokens");

        // checking that the time for staking has started
        require(
            block.timestamp > stakingStartTime,
            "staking has not started yet"
        );

        // transfer tokens from  staker to staking contract address
        token.transferFrom(msg.sender, address(this), _amount);

        Stake storage newStake = stakes[msg.sender];
        newStake.stakeAmount += _amount;
        newStake.stakeStartTime = block.timestamp;

        emit Staked(msg.sender, _amount);
    }

    function unstake(uint _amount) external onlyStaker {
        token.transferFrom(address(this), msg.sender, _amount);

        stakes[msg.sender].stakeAmount -= _amount;

        emit Unstaked(msg.sender, _amount);
    }

    function calculateStakingReward(
        address staker
    ) public view returns (uint256) {
        uint timeStakedInDays = (stakingEndTime -
            stakes[staker].stakeStartTime) /
            60 /
            60 /
            24;
        uint reward = stakes[staker].stakeAmount *
            rewardRate *
            timeStakedInDays;
        return reward;
    }

    function claimStakingReward() external onlyStaker {
        require(
            block.timestamp > stakingEndTime,
            "staking period has not ended"
        );

        uint reward = calculateStakingReward(msg.sender);

        bool transferRewardSuccess = token.transferFrom(
            address(this),
            msg.sender,
            reward
        );
        require(transferRewardSuccess);
        bool transferStakedTokenSuccess = token.transferFrom(
            address(this),
            msg.sender,
            stakes[msg.sender].stakeAmount
        );
        require(transferStakedTokenSuccess);

        stakes[msg.sender].stakeAmount = 0;
        stakes[msg.sender].stakeStartTime = 0;

        emit ClaimedStakeRewards(msg.sender, reward);
    }

    modifier onlyStaker() {
        require(stakes[msg.sender].stakeAmount > 0, "You are not a staker");
        _;
    }

    fallback() external {}
}
