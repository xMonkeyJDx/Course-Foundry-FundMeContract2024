// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19; //version of solidity

import {Test, console} from "forge-std/Test.sol"; //importing the Test.sol file from forge-std
import {FundMe} from "../../src/FundMe.sol"; //importing the FundMe.sol file from src
import {DeployFundMe} from "../../script/DeployFundMe.s.sol"; //importing the DeployFundMe.sol file from script

contract FundMeTest is Test {
    FundMe fundMe; //declaring the variable fundMe of type FundMe

    address USER = makeAddr("user"); //declaring the address variable USER
    uint256 constant SEND_VALUE = 0.1 ether; //declaring the constant variable FIVE
    uint256 constant STARTING_BALANCE = 100 ether; //declaring the constant variable STARTING_BALANCE

    function setUp() external {
        // fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMe = new DeployFundMe(); //creating a new instance of DeployFundMe
        fundMe = deployFundMe.run(); //running the instance of DeployFundMe
        vm.deal(USER, STARTING_BALANCE);
    }
    function testMinimumUsdIsFive() public view {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public view {
        assertEq(fundMe.i_owner(), msg.sender);
    }
    function testPriceFeedVersionIsAccurate() public view {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailsWhithoutEnoughEth() public {
        vm.expectRevert(); //expecting a revert
        fundMe.fund(); //calling the fund function
    }

    //*CREATE A NEW ADDRESS FALSE AND VERIFY IF THE VALUE SENDED IS EQUAL TO THE VALUE OF THE ADDRESS
    function testFundUpdateFundedDataStructure() public {
        vm.prank(USER); //prank -> the next transaction will be executed by USER
        fundMe.fund{value: SEND_VALUE}(); //calling the fund function with the value of SEND_VALUE

        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddFunderToArrayOfFunders() public {
        vm.prank(USER); //prank -> the next transaction will be executed by USER
        fundMe.fund{value: SEND_VALUE}(); //calling the fund function with the value of SEND_VALUE
        address funder = fundMe.getFunder(0); //getting the funder at index 0
        console.log("User: ", USER);
        console.log("Funder: ", funder);
        assertEq(USER, funder); //asserting that USER is equal to funder
    }

    //* This is a good practice to avoid writing the same code over and over again
    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert();
        vm.prank(USER);
        fundMe.withdraw();
    }

    function testWithdrawWithSingleFunder() public funded {
        //TODO Metodology to any test

        //? Arrange -> Setup the test
        uint256 startingOwnerBalance = fundMe.getOwner().balance; //* i_owner balance = 79228162514264337593543950335
        uint256 startingFundMeBalance = address(fundMe).balance; //* fundMe balance = 100000000000000000
        console.log(address(fundMe).balance);

        //? Act -> Call the function or action we want to test
        // uint256 gasStart = gasleft(); //* gasleft() -> returns the amount of gas left in the current call
        // vm.txGasPrice(GAS_PRICE);

        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        // uint256 gasEnd = gasleft();
        // uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;

        //? Assert -> Check the result of the action
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;

        assertEq(endingFundMeBalance, 0);
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            endingOwnerBalance
        );
    }

    function testWithdrawWithMultipleFunders() public {
        //* Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFounderIndex = 1;

        for (uint160 i = startingFounderIndex; i <= numberOfFunders; i++) {
            //* vm.prank
            //* vm.deal
            //* hoax let you simulate an address and make vm.deal at the same time
            hoax(address(i), SEND_VALUE);
            //* fund the FundMe
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //* Act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        //* Assert
        assert(address(fundMe).balance == 0);
        //! Becareful with this assert because you spend gas withdrawing so,
        //! the OnwerBalance = startingOwnerBalance + startingFundMeBalance - GAS
        assert(
            startingFundMeBalance + startingOwnerBalance ==
                fundMe.getOwner().balance
        );
    }
}
