const { network } = require("hardhat")
const { developmentChains } = require("../helper-hardhat-config")
const { verify } = require("../utils/verify");
const { log } = require("console");
const { processFile } = require("solhint");

module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, logs } = deployments;
    const { deployer } = await getNamedAccounts();

    log("--------------------------------------------------------");

    const args = [];

    const basicNft = await deploy("BasicNft", {
        from: deployer,
        args: args,
        log: true,
        waitConfirmations: network.config.blockConfirmations || 1 
    })

    //verify the Deployment
    if (!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
        log("verifying....");
        await verify(basicNft.address,args)
    }
    
}


module.exports.tags = ["all","basicnft","main"]