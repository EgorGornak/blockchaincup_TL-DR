var Web3 = require("web3");
web3 = new Web3(new Web3.providers.HttpProvider('http://127.0.0.1:8545'));
var SimpleABI = ABI;
var ContractAdress = "0xc90cd3e4ec814cff2abb8318f334bebb9c9290f5";

var SimpleContract = web3.eth.contract(SimpleABI, ContractAdress);
console.log("Results:");
var results = SimpleContract.projectsArray;
console.log(results);
var results = SimpleContract.projectsVotes;
console.log(results);
console.log(eth.accounts.length);
