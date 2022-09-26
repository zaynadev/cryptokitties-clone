const Marketplace = artifacts.require("KittyMarketPlace");
const Token = artifacts.require("KittyContract");

module.exports = function (deployer) {
  deployer.deploy(Marketplace, Token.address);
};
