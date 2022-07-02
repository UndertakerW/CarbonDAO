const Web3 = require('web3');
let fs = require('fs');
function generateKeys() {
    web3 = new Web3("https://rinkeby.arbitrum.io/rpc");
    let s = '';
    let key = web3.eth.accounts.create();
    console.log(key);
    web3.eth.accounts.wallet.add(key);
    s += key.privateKey + '\n';
    fs.writeFileSync('priv_key.txt', s);
}
generateKeys();
