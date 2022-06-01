//SPDX-License-Identifier:MIT
pragma solidity ^0.8.10;

contract Crowdfunding{


    /* Features 
    
    Donation-based crwodfunding

    User creates a campaign with the required time , and the amount to be raised
    donaters can donate to the campaign they like while they are running
    The user can withdraw the funds if thry have achieved the target or 
    the deadline is met . in that case they withdraw the funds they have collected till that time.

    */



    struct project{
        string title;
        uint amount;
        uint daysReq;
        address owner;
        uint deployedTime;
        uint fundCollected;
        uint index;
        bool status;
    }

    project[] public projects;

// requesting funds

function request(string memory _title , uint _amount , uint _daysReq) public returns(bool){

    uint prevArrLen = projects.length;

    project memory _project;
    _project.title = _title;
    _project.amount = _amount;
    _project.daysReq = _daysReq;
    _project.owner = msg.sender;
    _project.deployedTime = block.timestamp;
    _project.index = projects.length;
    _project.status = true;

    projects.push(_project);

    if(projects.length == prevArrLen+1){
        return true;
    }else{
        return false;
    }
}

// modifiers
modifier onlyOwner(uint _index) {
    require (projects[_index].owner == msg.sender , "You are not the owner of this fund");
    _;
}

modifier isComplete(uint _index) {
    require(projects[_index].fundCollected >= projects[_index].amount || block.timestamp > projects[_index].deployedTime + projects[_index].daysReq * 1 days , "funding not completed" );
    _;
}

modifier isNotComplete(uint _index) {
    require(projects[_index].fundCollected < projects[_index].amount && block.timestamp < projects[_index].deployedTime + projects[_index].daysReq * 1 days && projects[_index].status == true , "funding completed");
    _;
}



// donate

function donate(uint _index ) public payable isNotComplete(_index) {

    projects[_index].fundCollected += msg.value;
    projects[_index].status == false;

    
}

// taking out the funds

function takeOut(uint _index) public onlyOwner(_index) isComplete(_index){
    payable(msg.sender).transfer(projects[_index].fundCollected);
}

}