const { expect, assert } = require("chai");
const { ethers } = require("hardhat");

describe("Stake Contract", function () {
    let stakeContract, owner, user;
    beforeEach(async function () {
        const nftContractAddress = "0xA53f375F375F633f4F8db67aF19dfF1B9fCF735F";
        const tokenContractAddress =
            "0x9C9e6ccCe1De4f892e22C4b5D9Ce4De398Be1874";
        const rewardRate = 1;
        const startDate = new Date("2023-01-01").getTime() / 1000;

        const endDate = new Date("2023-05-30").getTime() / 1000;

        const StakeContractFactory = await ethers.getContractFactory(
            "StakeContract"
        );
        stakeContract = await StakeContractFactory.deploy(
            nftContractAddress,
            tokenContractAddress,
            rewardRate,
            startDate,
            endDate
        );
        await stakeContract.deployed();

        owner = ethers.provider.getSigner(0);
        user = ethers.provider.getSigner(1);
    });

    it("should store the owner of the contract", async function () {
        const _owner = await stakeContract.I_OWNER.call();
        assert.equal(_owner, await owner.getAddress());
    });

    it("should transfer staked tokens to contract", async function () {
        const tx = await stakeContract.connect(user).stake(10);
        await tx.wait();
        const stake = await stakeContract.stakes(await user.getAddress());

        assert.equal(stake.stakeAmount, 10);
    });
});
