//SPDX-License-Identifier:MIT
pragma solidity ^0.8.10;

/* donating ERC20 tokens

Crowd fund ERC20 token

User creates a campaign.
Users can pledge, transferring their token to a campaign.
After the campaign ends, campaign creator can claim the funds if total amount pledged is more than the campaign goal.
Otherwise, campaign did not reach it's goal, users can withdraw their pledge.


*/

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CrowdFund{


    event Launch(uint id , address indexed creator , uint goal , uint32 startAt , uint32 endAt);
    event Cancel(uint id);
    event Pledge(uint indexed id, address indexed caller , uint amount);
    event Unpledge(uint indexed id, address indexed caller , uint amount);
    event Claim(uint id);
    event Refund(uint indexed id , address indexed caller , uint amount);

    struct Campaign{
        address creator;
        uint goal;
        uint pledged;
        uint32 startAt;
        uint32 endAt;
        bool claimed;
    }

    IERC20 public immutable token;
    uint public count;
    mapping(uint => Campaign) public campaigns;
    mapping (uint => mapping (address => uint)) public pledgedAmount;

    constructor(address _token) {
        token = IERC20(_token);
    }

    function launch (uint _goal ,uint32 _startAt , uint32 _endAt) external {
        require (_startAt >= block.timestamp , "start at <now");
        require (_endAt > _startAt , "end at < start at");
        require (_endAt <= block.timestamp + 90 * 1 days , "end at > max duration ");

        count += 1;
        campaigns[count] = Campaign({
                          creator: msg.sender,
                          goal: _goal,
                          pledged: 0,
                          startAt: _startAt,
                          endAt: _endAt,
                          claimed: false
        });

        emit Launch(count , msg.sender , _goal , _startAt , _endAt);
    }

    function cancel(uint _id) external {
        Campaign memory campaign = campaigns[_id];
        require(msg.sender == campaign.creator , "Not creator");
        require(block.timestamp < campaign.startAt , "campaign already started");
        delete campaigns[_id];

        emit Cancel(_id);
    }

    function pledge(uint _id , uint _amount) external {
        Campaign storage campaign = campaigns[_id];
        require(block.timestamp >= campaign.startAt && block.timestamp <= campaign.endAt);

        campaign.pledged += _amount;
        pledgedAmount[_id][msg.sender] += _amount;
        token.transferFrom(msg.sender, address(this), _amount);

        emit Pledge(_id , msg.sender , _amount);
    }

    function unpledge(uint _id , uint _amount) external{
        Campaign storage campaign = campaigns[_id];
        require(block.timestamp >= campaign.startAt && block.timestamp <= campaign.endAt);
        require(_amount <= pledgedAmount[_id][msg.sender]);

        campaign.pledged -= _amount;
        pledgedAmount[_id][msg.sender] -= _amount;
        token.transfer(msg.sender, _amount);

        emit Unpledge(_id , msg.sender , _amount);
    }

    function claim(uint _id) external {
        Campaign storage campaign = campaigns[_id];
        require (block.timestamp > campaign.endAt && campaign.pledged >= campaign.goal);
        require(msg.sender == campaign.creator);
        require(!campaign.claimed);

        campaign.claimed = true;
        token.transfer(msg.sender, campaign.pledged);

        emit Claim(_id);
    }

    function refund(uint _id) external {
        Campaign storage campaign = campaigns[_id];
        require (block.timestamp > campaign.endAt && campaign.pledged < campaign.goal);
        require(!campaign.claimed);

        uint bal = pledgedAmount[_id][msg.sender];
        pledgedAmount[_id][msg.sender] = 0;
        token.transfer(msg.sender, bal);

        emit Refund(_id , msg.sender , bal);
    }

}