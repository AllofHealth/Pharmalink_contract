// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {Deployer} from "../script/AllofHealthV2.script.sol";
import {AllofHealthv2} from "../src/AllofHealthV2.sol";

contract AllofHealthV2Test is Test {
    event HospitalCreated(address indexed admin, uint256 indexed hospitalId);
    event SystemAdminAdded(address indexed admin, uint256 indexed adminId);
    event MedicalRecordAccessApproved(
        address indexed patient,
        address indexed approvedDoctor,
        uint256 indexed medicalRecordId
    );

    Deployer deployer;
    AllofHealthv2 allofHealth;

    uint256 constant STARTING_BALANCE = 10e18;
    address public patientAddress = makeAddr("user1");
    address public doctorAddress = makeAddr("user2");
    address public deployerAddress = makeAddr("user5");
    address public hospitalAdminAddress = makeAddr("user3");
    address public adminAddress = makeAddr("user4");
    address public pharmacistAddress = makeAddr("user6");

    function setUp() external {
        deployer = new Deployer();
        allofHealth = deployer.run();

        vm.deal(doctorAddress, STARTING_BALANCE);
        vm.deal(patientAddress, STARTING_BALANCE);
        vm.deal(adminAddress, STARTING_BALANCE);
        vm.deal(pharmacistAddress, STARTING_BALANCE);
    }

    modifier bootstrap_hospital() {
        vm.startPrank(hospitalAdminAddress);
        allofHealth.createHospital();
        vm.stopPrank();
        _;
    }

    modifier bootstrap_doctor() {
        vm.startPrank(doctorAddress);
        allofHealth.createDoctor(1, doctorAddress);
        vm.stopPrank();
        _;
    }

    modifier bootstrap_pharmacist() {
        vm.startPrank(pharmacistAddress);
        allofHealth.createPharmacist(1, pharmacistAddress);
        vm.stopPrank();
        _;
    }

    modifier bootstrap_patient() {
        vm.startPrank(patientAddress);
        allofHealth.addPatient();
        vm.stopPrank();
        _;
    }

    modifier bootstrap_approveDoctor() {
        vm.startPrank(hospitalAdminAddress);
        uint256 hospitalId = 1;
        uint256 doctorId = 1;
        allofHealth.approveDoctor(doctorAddress, hospitalId, doctorId);
        vm.stopPrank();
        _;
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

    function test_createPatient() external {
        vm.startPrank(patientAddress);
        allofHealth.addPatient();
        vm.stopPrank();

        uint256 patientCount = allofHealth.patientCount();

        assertEq(patientCount, 1);
    }

    function test_createPharmacist() external bootstrap_hospital {
        vm.startPrank(pharmacistAddress);
        allofHealth.createPharmacist(1, pharmacistAddress);
        vm.stopPrank();

        uint256 hospitalCount = allofHealth.hospitalCount();
        uint256 pharmacistCount = allofHealth.pharmacistCount();

        assertEq(hospitalCount, 1);
        assertEq(pharmacistCount, 1);
    }

    function test_approveDoctor() external bootstrap_hospital bootstrap_doctor {
        vm.startPrank(hospitalAdminAddress);
        uint256 hospitalId = 1;
        uint256 doctorId = 1;
        allofHealth.approveDoctor(doctorAddress, hospitalId, doctorId);
        vm.stopPrank();

        bool isDoctorApproved = allofHealth.approvedDoctors(doctorAddress);
        assertEq(isDoctorApproved, true);
    }

    function test_approvePharmacist()
        external
        bootstrap_hospital
        bootstrap_pharmacist
    {
        vm.startPrank(hospitalAdminAddress);
        uint256 hospitalId = 1;
        uint256 pharmacistId = 1;
        allofHealth.approvePharmacist(
            pharmacistAddress,
            hospitalId,
            pharmacistId
        );
        vm.stopPrank();

        bool isPharmacistApproved = allofHealth.approvedPharmacists(
            pharmacistAddress
        );
        assertEq(isPharmacistApproved, true);
    }

    function test_approveAccessToAddNewRecord()
        external
        bootstrap_hospital
        bootstrap_doctor
        bootstrap_approveDoctor
        bootstrap_patient
    {
        uint256 patientId = 1;
        vm.startPrank(patientAddress);
        allofHealth.approveAccessToAddNewRecord(doctorAddress, patientId);
        vm.stopPrank();

        bool isAccessApproved = allofHealth.isApprovedByPatientToAddNewRecord(
            patientId,
            doctorAddress
        );
        assertEq(isAccessApproved, true);
    }

    function initApproveAccessToAddNewRecord()
        internal
        bootstrap_hospital
        bootstrap_doctor
        bootstrap_approveDoctor
        bootstrap_patient
    {
        uint256 patientId = 1;
        vm.startPrank(patientAddress);
        allofHealth.approveAccessToAddNewRecord(doctorAddress, patientId);
        vm.stopPrank();
    }

    function test_addMedicalRecord() external {
        initApproveAccessToAddNewRecord();
        uint256 patientId = 1;
        string memory recordDetailsUri = "https://example.com/medical-record";

        vm.startPrank(doctorAddress);
        allofHealth.addMedicalRecord(
            doctorAddress,
            patientAddress,
            patientId,
            recordDetailsUri
        );
        vm.stopPrank();

        uint256 medicalRecordId = 1;

        vm.startPrank(patientAddress);
        string memory recordUri = allofHealth.viewMedicalRecord(
            medicalRecordId,
            patientId,
            patientAddress
        );
        vm.stopPrank();

        console.log("Expected:", recordDetailsUri);
        console.log("Actual:", recordUri);
        bool isDoctorStillApprovedToAddRecord = allofHealth
            .isApprovedByPatientToAddNewRecord(patientId, doctorAddress);
        assertEq(isDoctorStillApprovedToAddRecord, false);
        assertEq(
            keccak256(abi.encodePacked(recordUri)),
            keccak256(abi.encodePacked(recordDetailsUri))
        );
    }
}
