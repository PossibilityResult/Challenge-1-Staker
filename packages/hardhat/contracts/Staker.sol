pragma solidity 0.8.4;

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {

  ExampleExternalContract public exampleExternalContract;

  mapping ( address => uint256) public balances;
  uint256 public constant threshold = 1 ether;
  uint256 public deadline = block.timestamp + 50 seconds;
  bool openForWithdraw = false;
  //events
  event Stake(address, uint256);

  modifier timeIsLeft() {
    require(timeLeft() > 0, "There is no time left, you can't stake anymore!");
    _;
  }

  modifier timeIsNotLeft() {
    require(timeLeft() == 0, "There is time left, you can't do that!");
    _;
  }

  modifier notCompleted() {
    require(!exampleExternalContract.completed(), "External contract has received funds, staking is completed");
    _;
  }

  constructor(address exampleExternalContractAddress) public {
      exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  //  ( make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
  function stake() public payable timeIsLeft {
    require(msg.value > 0, "You can't stake nothing!");
    balances[msg.sender] += msg.value;
    emit Stake(msg.sender, msg.value);
  }

  // After some `deadline` allow anyone to call an `execute()` function
  //  It should either call `exampleExternalContract.complete{value: address(this).balance}()` to send all the value
  function execute() public timeIsNotLeft notCompleted {
    if (address(this).balance >= threshold) {
      exampleExternalContract.complete{value: address(this).balance}();
    }
    else {
      openForWithdraw = true;
    }
  }

  // if the `threshold` was not met, allow everyone to call a `withdraw()` function
  function withdraw(address payable pay) public timeIsNotLeft notCompleted {
    require(openForWithdraw, "The threshold was met or execute has not been called, can't withdraw");
    require(address(this).balance > 0, "There is no more ether in this contract");
    pay.transfer(balances[msg.sender]);
    balances[msg.sender] = 0;
  }


  // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
  function timeLeft() public view returns (uint256){
    if (block.timestamp >= deadline) {
      return 0;
    }
    else {
      return deadline - block.timestamp;
    }
  }

  // Add the `receive()` special function that receives eth and calls stake()
  receive() external payable {
    stake();
  }

}
