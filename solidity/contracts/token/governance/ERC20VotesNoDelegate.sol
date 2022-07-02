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
    * @dev The Vote structure records the voting infomation of a proposal
    * @param voted is a mapping from an address to its voting information
    * @param agree_amount is the voted amount for "agree"
    * @param disagree_amount is the voted amount for "disagree"
    */
    struct Vote {
        mapping(address => int256) voted;
        uint128 agree_amount;
        uint128 disagree_amount;
    }

    /**
    * @dev All proposals
    * The mapping maps a proposal hash to a Vote structure
    */
    mapping(bytes32 => Vote) public proposals;

    /**
    * @dev Vote for a proposal
    * @param proposal is the proposal hash
    * @param option is the option to vote (agree / disagree)
    */
    function vote(bytes32 proposal, bool option) public {
        require(uint32(proposal) > block.timestamp); // Proposal is valid for voting
        uint256 voting_amount = getVotes(msg.sender);
        //Vote v(msg.sender, voting_power, option);
        //votes[proposal][msg.sender] = v;
        int256 last_voted_amount = proposals[proposal].voted[msg.sender];

        // Wipe out the last vote of the sender
        if (last_voted_amount > 0) {
            proposals[proposal].agree_amount -= last_voted_amount;
        } else if (last_voted_amount < 0) {
            proposals[proposal].disagree_amount += last_voted_amount;
        }

        // Add the new vote
        if (option) {
            proposals[proposal].agree_amount += voting_amount;
        } else {
            proposals[proposal].disagree_amount += voting_amount;
        }

    }

    /**
    * @dev Gets the current voting amount for `account`
    */
    function sqrt(uint x) public pure returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    /**
    * @dev Gets the current votes balance for `account`
    */
    function getVotes(address account) public view virtual override returns (uint256) {
        return sqrt(balanceOf(account));
    }

    /**
    * @dev Add a proposal
    * @param proposal is the hash of the proposal,
    * which is keccak256[(32 block.timestamp) (160 executor addr) (4*8 revenue share) (bytes4(keccak256(abi.encode(executor addr)))) + url] + 32 end_time,
    * where url is the Arweave url.
    */
    function addProposal(bytes32 proposal) public {
        require(proposals[proposal].agree_amount == 0 && proposals[proposal].disagree_amount == 0, "Proposal already exists.");
        Vote storage v = proposals[proposal];
        v.voted[msg.sender] = getVotes(msg.sender);
        v.agree_amount = getVotes(msg.sender);
    }
}