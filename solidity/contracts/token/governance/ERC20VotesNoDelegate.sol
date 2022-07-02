// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Votes.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/governance/utils/IVotes.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./ERC20CarbonDAO.sol";

/**
 * @dev Extension of ERC20 to support Compound-like voting and delegation. This version is more generic than Compound's,
 * and supports token supply up to 2^224^ - 1, while COMP is limited to 2^96^ - 1.
 *
 * NOTE: If exact COMP compatibility is required, use the {ERC20VotesComp} variant of this module.
 *
 * This extension keeps a history (checkpoints) of each account's vote power. Vote power can be delegated either
 * by calling the {delegate} function directly, or by providing a signature to be used with {delegateBySig}. Voting
 * power can be queried through the public accessors {getVotes} and {getPastVotes}.
 *
 * By default, token balance does not account for voting power. This makes transfers cheaper. The downside is that it
 * requires users to delegate to themselves in order to activate checkpoints and have their voting power tracked.
 *
 * _Available since v4.2._
 */
abstract contract ERC20VotesNoDelegate is ERC20CarbonDAO, IVotes {

    /**
    * @dev The Vote structure is like a ballot
    * @param addr is the address of the voter
    * @param amount is the voting power of the voter
    * @param option is the option of the voter
    */
    struct Vote {
        address addr;
        uint256 amount;
        //uint128 proposal;
        uint8 option; 
    }

    /**
    * @dev All votes
    * The first mapping maps a proposal id to the second mapping
    * The second mapping maps an address to its ballot
    */
    mapping(uint => mapping(address => Vote)) public votes;

    /**
    * @dev All proposals
    */
    uint[] public proposals;

    /**
    * @dev Vote for a proposal
    * @param proposal is the proposal id
    * @param option is the option to vote (e.g. endorse, oppose, etc.)
    */
    function vote(uint proposal, uint8 option) public {
        require(uint32(proposal) > block.timestamp); // Proposal is valid for voting
        uint256 voting_power = getVotes(msg.sender);
        Vote v(msg.sender, voting_power, option);
        votes[proposal][msg.sender] = v;
    }

    /**
    * @dev Gets the current votes balance for `account`
    */
    function getVotes(address account) public view virtual override returns (uint256) {
        return balanceOf(account);
    }

    /**
    * @dev Add a proposal
    * @param proposal is the hash of the proposal,
    * which is keccak256[(32 proposal id) (160 executor addr) (4*8 revenue share) (bytes4(keccak256(abi.encode(block.timestamp, executor addr)))) + url] + 32 end_time,
    * where url is the Arweave url.
    */
    function addProposal(byte32 proposal) public {
        proposals.push(proposal);
    }
}