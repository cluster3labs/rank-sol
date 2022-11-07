// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import '@chainlink/contracts/src/v0.8/ChainlinkClient.sol';
import '@chainlink/contracts/src/v0.8/ConfirmedOwner.sol';

contract RankDynNft is ERC1155,ChainlinkClient {
    using Chainlink for Chainlink.Request;

    uint256 public volume;
    bytes32 private jobId;
    uint256 private fee;
    using Address for address;

    // base id to base
    address public owner;

    string public rankUrl;

    mapping(address => uint256) balanceMapping;

    event RequestVolume(bytes32 indexed requestId, uint256 volume);

    constructor() ERC1155("http://rank.flowingcloud.cn/openapi/token/{id}.json") {
        owner = msg.sender;
        setChainlinkToken(0x326C977E6efc84E512bB9C30f76E30c160eD06FB);
        setChainlinkOracle(0x40193c8518BB267228Fc409a613bDbD8eC5a97b3);
        jobId = '7da2702f37fd48e5b1b9a5715e3509b6';
        fee = (1 * LINK_DIVISIBILITY) / 10; // 0,1 * 10**18 (Varies by network and job)
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function mint(address to, uint256 tokenId) public onlyOwner {
        require(to != address(0), "can not mint to the zero address");

        // mint
        _mint(to, tokenId, 1, "");
        balanceMapping[to] = balanceMapping[to] + 1;
    }

    function uri(uint256 tokenId) override public pure returns (string memory) {
        return string.concat("http://rank.flowingcloud.cn/openapi/token/", Strings.toString(tokenId), ".json");
    }

    // balanceOf
    function balanceOf(address account) public view returns (uint256) {
        require(account != address(0), "address zero is not a valid owner");
        return balanceMapping[account];
    }

    function updateRankUrl() public onlyOwner {
        string memory rankUrlNew = requestVolumeData();
        rankUrl = rankUrlNew;
    }

    /**
     * Create a Chainlink request to retrieve API response, find the target
     * data, then multiply by 1000000000000000000 (to remove decimal places from data).
     */
    function requestVolumeData() public returns (string memory) {
        Chainlink.Request memory req = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);

        // Set the URL to perform the GET request on
        req.add('get', 'https://rank.flowingcloud.cn/openapi/token/rankUrl');

        // Set the path to find the desired data in the API response, where the response format is:
        // {"RAW":
        //   {"ETH":
        //    {"USD":
        //     {
        //      "VOLUME24HOUR": xxx.xxx,
        //     }
        //    }
        //   }
        //  }
        // request.add("path", "RAW.ETH.USD.VOLUME24HOUR"); // Chainlink nodes prior to 1.0.0 support this format
        req.add('path', 'data'); // Chainlink nodes 1.0.0 and later support this format

        // Multiply the result by 1000000000000000000 to remove decimals
        //        int256 timesAmount = 10**18;
        //        req.addInt('times', timesAmount);

        // Sends the request
        bytes32 chainLink = sendChainlinkRequest(req, fee);
        return bytes32ToString(chainLink);
    }

    /**
     * Receive the response in the form of uint256
     */
    function fulfill(bytes32 _requestId, uint256 _volume) public recordChainlinkFulfillment(_requestId) {
        emit RequestVolume(_requestId, _volume);
        volume = _volume;
    }

    function bytes32ToString(bytes32 _bytes32) public pure returns (string memory) {
        uint8 i = 0;
        while(i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }
}