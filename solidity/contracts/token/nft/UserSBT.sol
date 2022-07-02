pragma solidity ^0.8.7;
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/SignatureCheckerUpgradeable.sol";
contract UserSBT is ERC721Upgradeable, PausableUpgradeable {
    // struct Information {
//
    // }
    function initialize() initializer public {
        __ERC721_init("MyCollectible", "MCO");
    }

    function executeTransfer(address token, address to, uint256 number) public {

    }
    function calculateVoteWeight(uint proposal, address voter) public {
        5**1;
    }
    

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override whenNotPaused {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }
    function sqrt(uint x) public returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    struct VoteInformation {
        uint32 timestamp; //end time
        address receiver;
        uint32 ratio; // 4-> dao, 4-> voters, 4-> treasury, 4 -> executor
        bytes4 proposer; // bytes4(address(proposer))
        string url;
    }
// (32) (160) (4*8) (bytes4(keccak256(abi.encode(block.timestamp,proposer)))) + url
// hash
// signature
// hash (32) (160) (4*8) (bytes4(keccak256(abi.encode(block.timestamp,proposer)))) + url
// url
// calldata

    function createProposal(VoteInformation calldata info) public returns(bool) {
        bytes32 proposalId = getProposalHash(info, block.timestamp);
        
    }

    function getProposalHash(VoteInformation calldata info, uint32 startTime) internal returns(bytes32) {
        return keccak256(abi.encode(info.timestamp, info.receiver, info.ratio, info.proposer, info.url, startTime));
    }

    function checkProposalHash(bytes32 hash, VoteInformation calldata info, uint32 startTime) public returns(bool) {
        if(hash == getProposalHash(info, startTime)) {
            return true;
        }
        return false;
    }
}