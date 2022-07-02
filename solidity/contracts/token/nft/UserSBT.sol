// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/SignatureCheckerUpgradeable.sol";
import "../governance/ERC20VotesNoDelegate.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract UserSBT is ERC721Upgradeable, PausableUpgradeable {
    address governanceToken;
    struct VoteInformation {
        uint32 endtime; //end time
        address receiver;
        uint32 ratio; // 4-> dao, 4-> voters, 4-> treasury, 4 -> executor
        bytes4 proposer; // bytes4(address(proposer))
        string url;
    }
    function initialize() initializer public {
        __ERC721_init("MyCollectible", "MCO");
    }

    

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override whenNotPaused {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }
    

    
// (32) (160) (4*8) (bytes4(keccak256(abi.encode(block.timestamp,proposer)))) + url
// hash
// signature
// hash (32) (160) (4*8) (bytes4(keccak256(abi.encode(block.timestamp,proposer)))) + url
// url
// calldata

    // function createProposal(VoteInformation calldata info, address result_executor) public returns(bool) {
    //     bytes32 proposalId = (getProposalHash(info, uint32(block.timestamp))<<224 | bytes4(info.endtime));
    //     //ERC20VotesNoDelegate(governanceToken).addProposal(proposalId, result_executor);
    // }

    // function getProposalHash(VoteInformation calldata info, uint32 startTime) internal returns(bytes32) {
    //     return keccak256(abi.encode(info.receiver, info.ratio, info.proposer, info.url, startTime));
    // }

    // function checkProposalHash(bytes32 hash, VoteInformation calldata info, uint32 startTime) public returns(bool) {
    //     if(hash == (getProposalHash(info, startTime) << 224 | bytes4(info.endtime))) {
    //         return true;
    //     }
    //     return false;
    // }
}