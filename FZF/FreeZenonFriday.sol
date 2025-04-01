// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract FreeZenonFriday {
    address public owner;
    uint256 public entryFee = 0;
    uint256 public firstPrize = 2.1 ether;
    uint256 public secondPrize = 0.9 ether;
    address[] public participants;
    uint256 public nextDrawTime;
    bool public isActive = false;

    uint256 constant WEEK = 7 days;

    event NewEntry(address participant);
    event WinnersSelected(address firstWinner, uint256 firstAmount, address secondWinner, uint256 secondAmount);
    event Withdrawn(address to, uint256 amount);

    constructor() {
        owner = msg.sender;
        nextDrawTime = 1743796800; // Friday, April 4, 2025, 20:00 UTC
    }

    function enter() external payable {
        require(isActive, "Competition not active");
        require(block.timestamp < nextDrawTime, "Draw already ended");
        require(msg.value >= entryFee, "Not enough xZNN sent");
        participants.push(msg.sender);
        emit NewEntry(msg.sender);
    }

    function selectWinners() external {
        require(msg.sender == owner, "Only owner can pick winners");
        require(block.timestamp >= nextDrawTime, "Too early");
        require(participants.length >= 2, "Need at least 2 players");

        uint256 random1 = uint256(keccak256(abi.encodePacked(block.timestamp))) % participants.length;
        address firstWinner = participants[random1];
        participants[random1] = participants[participants.length - 1];
        participants.pop();

        uint256 random2 = uint256(keccak256(abi.encodePacked(block.timestamp + 1))) % participants.length;
        address secondWinner = participants[random2];

        payable(firstWinner).transfer(firstPrize);
        payable(secondWinner).transfer(secondPrize);
        emit WinnersSelected(firstWinner, firstPrize, secondWinner, secondPrize);

        delete participants;
        nextDrawTime = nextDrawTime + WEEK;
    }

    function startCompetition() external {
        require(msg.sender == owner, "Only owner");
        isActive = true;
    }

    function setEntryFee(uint256 newFee) external {
        require(msg.sender == owner, "Only owner");
        entryFee = newFee;
    }

    function withdraw() external {
        require(msg.sender == owner, "Only owner");
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        payable(owner).transfer(balance);
        emit Withdrawn(owner, balance);
    }

    function getParticipantCount() public view returns (uint256) {
        return participants.length;
    }

    receive() external payable {}
}