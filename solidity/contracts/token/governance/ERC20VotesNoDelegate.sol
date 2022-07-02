// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Votes.sol)

pragma solidity ^0.8.0;


import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/governance/utils/IVotes.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../nft/UserSBT.sol";

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

contract ERC20CarbonDAO is Ownable, ERC20{

    UserSBT public SbtContract;

    /**
    * @dev Control transactions
    * When paused is true, transaction is not allowed
    */
    bool public paused;

    constructor(string memory name_, string memory symbol_) ERC20(name_,symbol_) {
    }

    /**
     * @dev Require the to address is valid,
     * which means it has an NFT.
     */
    modifier hasNft(address to) {
        require(SbtContract.balanceOf(to) > 0);
        _;
    }

    /**
     * @dev Require the contract is not paused.
     */
    modifier requireNotPaused() {
        require(!paused, "Not allowed!");
        _;
    }

    /**
     * @dev Set the contract address of the SBT
     */
    function setSbtAddress(address addr) external onlyOwner {
        SbtContract = UserSBT(addr);
    }

    /**
     * @dev Set the paused variable
     */
    function setPaused(bool new_paused) external onlyOwner {
        paused = new_paused;
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public override hasNft(to) requireNotPaused returns (bool)  {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public override hasNft(spender) requireNotPaused returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function assign(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

}

contract ERC20VotesNoDelegate is ERC20CarbonDAO {

    constructor(string memory name_, string memory symbol_) ERC20CarbonDAO(name_,symbol_) {
    }

    /**
    * @dev The Vote structure records the voting infomation of a proposal
    * @param voted is a mapping from an address to its voting information
    * @param agree_amount is the voted amount for "agree"
    * @param disagree_amount is the voted amount for "disagree"
    */
    struct Proposal {
        mapping(address => int48) voted;
        uint48 agree_amount;
        uint48 disagree_amount;
        address result_executor;
    }


    /**
    * @dev All proposals
    * The mapping maps a proposal hash to a Vote structure
    */
    mapping(bytes32 => Proposal) public proposals;
    uint256 public constant passRate = 80;

    /**
    * @dev Vote for a proposal
    * @param proposal is the proposal hash
    * @param option is the option to vote (agree / disagree)
    */
    function vote2(bytes32 proposal, bool option) public {
        require(uint32(uint256(proposal)) > block.timestamp); // Proposal is valid for voting
        uint48 voting_amount = uint48(getVotes(msg.sender));
        //Vote v(msg.sender, voting_power, option);
        //votes[proposal][msg.sender] = v;
        int48 last_voted_amount = proposals[proposal].voted[msg.sender];

        
        // Wipe out the last vote of the sender
        if (last_voted_amount > 0) {
            proposals[proposal].agree_amount -= uint48(last_voted_amount);
        } else if (last_voted_amount < 0) {
            proposals[proposal].disagree_amount -= uint48(-last_voted_amount);
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
    function getVotes(address account) public view returns (uint48) {
        return uint48(sqrt(super.balanceOf(account)));
    }

    /**
    * @dev Add a proposal
    * @param proposal_id is the hash of the proposal,
    * which is keccak256[(32 block.timestamp) (160 executor addr) (4*8 revenue share) (bytes4(keccak256(abi.encode(executor addr)))) + url] + 32 end_time,
    * where url is the Arweave url.
    */
    function addProposal(bytes32 proposal_id, address result_executor) public {
        require(proposals[proposal_id].result_executor == address(0x0) , "Proposal already exists.");
        Proposal storage v = proposals[proposal_id];
        v.voted[msg.sender] = int48(getVotes(msg.sender));
        v.agree_amount = getVotes(msg.sender);
        v.result_executor = result_executor;
    }

    function getResult(bytes32 proposal) public {
        Proposal storage v = proposals[proposal];
        require((v.result_executor != address(0x0)), "Proposal does not exist.");
        uint128 agree = v.agree_amount;
        uint128 disagree = v.disagree_amount;
        address result_executor = v.result_executor;
        if(100 * agree > passRate * (agree + disagree)) {
            (bool success,) = result_executor.call(abi.encodeWithSelector(bytes4(keccak256("proposalPass()"))));
            require(success, "Execute failed");
        }
    }

}