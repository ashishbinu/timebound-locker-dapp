// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

contract TimeboundLocker {

    struct Locker {
        uint money;
        uint deadline;
        bool initialised;
    }
    address public owner;
    mapping(address => Locker) public lockerOwner;

    constructor() {
        owner = msg.sender;
    }

    event Received(address,uint);
    event LockerCreated(address,uint,uint);
    event SentToOwner(address,uint);

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner");
        _;
    }

    receive() external payable {}

    function getContractBalance() public onlyOwner view returns (uint) {
        return address(this).balance;
    }

    function getMyBalance() public view returns (uint) {
        return lockerOwner[msg.sender].money;
    }

    function getLockerDeadline() public view returns (uint) {
        return lockerOwner[msg.sender].deadline;
    }

    function putMoneyInLocker(uint _deadline) public payable {
        require(msg.value != 0, "Not enough Money");
        require(lockerOwner[msg.sender].initialised == false,"You already have locker here.");
        lockerOwner[msg.sender] = Locker({money: msg.value,deadline: block.timestamp + _deadline,initialised: true});
        emit Received(msg.sender,msg.value);
        emit LockerCreated(msg.sender,msg.value,_deadline);
    }

    function addMoreMoneyToLocker() public payable {
        require(msg.value != 0, "Not enough Money");
        require(lockerOwner[msg.sender].initialised == true, "You don't have a locker here.");
        lockerOwner[msg.sender].money += msg.value;
        emit Received(msg.sender,msg.value);
    }

    function withdraw() public {
        require(lockerOwner[msg.sender].initialised == true,"You don't have a locker here.");
        require(lockerOwner[msg.sender].deadline <= block.timestamp, "Deadline is over.");

        uint amount = lockerOwner[msg.sender].money;

        (bool success,) = msg.sender.call{value: amount}("");
        require(success, "Failed to send ether");
        delete lockerOwner[msg.sender];
        emit SentToOwner(msg.sender,amount);
    }
}
