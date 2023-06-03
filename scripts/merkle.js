const {MerkleTree} = require('merkletreejs');
const keccak256 = require('keccak256');

const addresses = [
    "0x9ff6a32529fcB40BDf708a6C80393352805476Ae",
    "0x60ba3872910361D32Ef2185f7A298Fa6369Bb01E",
    "0x5bB537867f3aD6dD73D545e0F5d3CAab9883cD64"
]





const leaves = addresses.map(addr => keccak256(addr));
const tree = new MerkleTree(leaves, keccak256, {sortPairs:true});
const root = tree.getRoot();
console.log('Whitelist Merkle Tree\n' , tree.toString());

const claimingAddress = leaves[1]; // сюда вместо нуля добавлять адрес, который вызывает пресейл минт и для него нужен аппрув

const hexProof = tree.getHexProof(claimingAddress);
console.log('Merkle Proof for address:', leaves[1].toString());
console.log(hexProof);


