// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {Deployer} from "../script/AllofHealthV2.script.sol";
import {AllofHealthv2} from "../src/AllofHealthV2.sol";

contract AllofHealthV2Test is Test {
    event HospitalCreated(address indexed admin, uint256 indexed hospitalId);
    Deployer deployer;
    AllofHealthv2 allofHealth;

    uint256 constant STARTING_BALANCE = 10e18;
    address public patientAddress = makeAddr("user1");
    address public doctorAddress = makeAddr("user2");
    address public hospitalAdminAddress = makeAddr("user3");

    function setUp() external {
        deployer = new Deployer();
        allofHealth = deployer.run();
        vm.deal(doctorAddress, STARTING_BALANCE);
        vm.deal(patientAddress, STARTING_BALANCE);
    }

    function testCreateHospitalSuccessfully() external {
        vm.expectEmit(true, true, false, false);
        vm.startPrank(hospitalAdminAddress);
        emit HospitalCreated(hospitalAdminAddress, 1);

        allofHealth.createHospital();
        vm.stopPrank();

        uint256 hospitalCount = allofHealth.hospitalCount();
        assertEq(hospitalCount, 1);
    }

    function testCreateDoctorSuccessfully() external {
        vm.startPrank(hospitalAdminAddress);
        allofHealth.createHospital();
        vm.stopPrank();

        vm.startPrank(doctorAddress);
        allofHealth.createDoctor(1, doctorAddress);
        vm.stopPrank();

        uint256 hospitalCount = allofHealth.hospitalCount();
        uint256 doctorCount = allofHealth.doctorCount();

        assertEq(hospitalCount, 1);
        assertEq(doctorCount, 1);
    }
}
