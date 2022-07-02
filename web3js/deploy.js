const {ethers} = require("ethers")
const fs = require('fs')
 
let provider = new ethers.providers.JsonRpcProvider('http://localhost:8545')
 
function getHexString(prikeyPath) {
     const privKeyFile = fs.readFileSync(prikeyPath).toString().trim();
     const privKey = new Buffer.from(privKeyFile, 'hex');
     return privKey
}
 
// var privKey = getHexString(".secret")
var privKey = '0x403d...23d5'
let wallet = new ethers.Wallet(privKey,provider)
 
var jsonStr = fs.readFileSync('./build/contracts/EventValue.json')
var jsonInfo = JSON.parse(jsonStr)
var jsonAbi = jsonInfo.abi
var bytecode = jsonInfo.bytecode
 
async function deployContract(abi,bytecode,wallet) {
     let factory = new ethers.ContractFactory(abi,bytecode,wallet)
     let contractObj = await factory.deploy(100)
     console.log('contractAddress=',contractObj.address)
     console.log('deploy txHash=',contractObj.deployTransaction.hash)
 
     await contractObj.deployed()
}
 
deployContract(jsonAbi,bytecode,wallet)