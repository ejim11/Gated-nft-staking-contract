const { ethers, run, network } = require("hardhat");

async function main() {
    const nftContractAddress = "";
    const tokenContractAddress = "";
    const rewardRate = 1;
    const startDate = new Date("2023-04-01").getTime() / 1000;
    const endDate = new Date("2023-05-30").getTime() / 1000;

    const StakeContractFactory = await ethers.getContractFactory(
        "StakeContract"
    );
    const stakeContract = await StakeContractFactory.deploy(
        nftContractAddress,
        tokenContractAddress,
        rewardRate,
        startDate,
        endDate
    );
    await stakeContract.deployed();

    if (network.config.chainId === 11155111 && process.env.ETHERSCAN_API_KEY) {
        await stakeContract.deployTransaction.wait(6);
        await verify(stakeContract.address, [
            nftContractAddress,
            tokenContractAddress,
            rewardRate,
            startDate,
            endDate,
        ]);
    }
}

async function verify(contractAddress, args) {
    try {
        await run("verify: verify", {
            address: contractAddress,
            constructorArguments: args,
        });
    } catch (error) {
        if (error.message.toLowerCase().includes("already verified")) {
            console.log("Already verified");
        } else {
            console.log(error);
        }
    }
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
