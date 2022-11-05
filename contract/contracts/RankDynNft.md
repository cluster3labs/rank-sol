### contract data
1. mapping(address => uint256) balanceMapping; record address total token num

### contract function
1. mint, mint a nft to address
2. uri, uri return a url of nft metadata
3. balanceOf, balance of return an address total  num mint by this contract

### build java
1. sudo truffle compile
2. web3j generate truffle --truffle-json ./build/contracts/BadgeNft.json --outputDir src -p com.xingyun.cluster3