// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test{

    FundMe fundMe;

    address public constant USER = address(1);
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;

    function setUp() external {

        //fundMe = new FundMe();
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER,STARTING_BALANCE);

    }

    function testMinimumDollarIsFiveDemo() public {
         assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public {
        
        console.log(fundMe.getOwner());
        console.log(address(this));

         //assertEq(fundMe.i_owner(), address(this));
         assertEq(fundMe.getOwner(), msg.sender);
    }

    function testThisVersionIsAccurate() public {

        uint256 version = fundMe.getVersion();

        console.log(version);
        console.log("Version should have been printed");
        
        assertEq(version,4);
    }

    function testFundFailWithoutEnoughEth() public {

        vm.expectRevert();
        //assert(this tx fails / reverts)
        fundMe.fund();

    }

    function testFundUpdatesFundedDataStructure() public {

        //vm.expectRevert();
        //assert(this tx fails / reverts)

        vm.prank(USER);        
        fundMe.fund{value: SEND_VALUE}();
        uint256 amountFunded = fundMe.getAdddresstoAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();

        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);


    }

    modifier funded(){
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;

    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();

        vm.prank(USER);
        vm.expectRevert();
        fundMe.withdraw();

    }

    function testWithdrawWithASingleFunder() public funded {
        //arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //act
        //uint256 gasStart = gasleft();
        
        vm.txGasPrice(GAS_PRICE);
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        //uint256 gasEnd = gasleft();
        //uint256 gasUsed = (gasStart - gasEnd)  * tx.gasprice;
        //console.log(gasUsed);

        //asssert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance,0);
        assertEq(startingFundMeBalance+startingOwnerBalance, endingOwnerBalance);

    }

    function testWithdrawFromMultipleFunders() public funded {

        
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;

        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++ ){

            hoax(address(i),SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();

        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        assertEq(address(fundMe).balance, 0);
        assertEq(startingFundMeBalance + startingOwnerBalance, fundMe.getOwner().balance);
    }
}
