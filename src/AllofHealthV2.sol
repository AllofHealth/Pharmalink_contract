// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract AllofHealthv2 {
    /**
     * Erorrs
     */
    error Unauthorized();
    error HospitalNotApproved();
    error DoctorNotApproved();
    error OnlyAdminAllowed();
    error OnlyPatientAllowed();
    error OnlySystemAdminAllowed();
    error RecordNotFound();
    error InvalidHospitalId();
    error InvalidDoctorId();
    error InvalidPharmacistId();
    error InvalidPatientId();
    error InvalidMedicalRecordId();
    error InvalidRecordType();
    error InvalidRegNo();
    error DuplicateHospitalRegNo();
    error DuplicateDoctorAddress();
    error DuplicatePharmacistAddress();
    error DuplicatePatientAddress();
    error DuplicatePatientFamilyMember();
    error DuplicateDoctorRegNo();
    error InvalidAddress();
    error DoctorNotFound();
    error DoctorAlreadyRejected();
    error PharmacistNotFound();
    error PharmacistNotApproved();
    error PharmacistAlreadyRejected();
    error NotRecordOwner();
    error AccessToRecordAlreadyGranted();
    error AccessToRecordNotGranted();
    error MedicalRecordNotFound();
    error MedicalRecordAccessRevoked();
    error AccessAlreadyGranted();
    error AccessNotGranted();
    error InvalidMedicalRecordDetail();
    error InvalidFamilyMemberId();
    error InvalidPractitioner();
    error PractitionerNotApproved();

    /**
     * Type Declarations
     */
    enum approvalType {
        Pending,
        Approved,
        Rejected
    }

    struct Hospital {
        uint256 hospitalId;
        uint256 doctorsCount;
        uint256 pharmacistsCount;
        address admin;
        approvalType approvalStatus;
    }

    struct Doctor {
        uint256 doctorId;
        uint256 hospitalId;
        address doctor;
        approvalType approvalStatus;
    }

    struct Pharmacist {
        uint256 pharmacistId;
        uint256 hospitalId;
        address pharmacist;
        approvalType approvalStatus;
    }

    struct Patient {
        uint256 patientId;
        uint256 approvalCount;
        uint256 patientMedicalRecordCount;
        uint256 patientFamilyMemberCount;
        address walletAddress;
    }

    struct PatientFamilyMember {
        uint256 patientId;
        uint256 approvalCount;
        uint256 principalPatientId;
        uint256 familyMemberMedicalRecordCount;
    }

    struct MedicalRecord {
        uint256 medicalRecordId;
        uint256 patientId;
        uint256 duration;
        uint256 expiration;
        address patient;
        address approvedDoctor;
        bytes32 diagnosis;
        bytes32 recordDetailsUri;
        bytes32 recordImageUri;
    }

    struct PatientFamilyMedicalRecord {
        uint256 medicalRecordId;
        uint256 principalPatientId;
        uint256 patientId;
        uint256 duration;
        uint256 expiration;
        address approvedDoctor;
        bytes32 diagnosis;
        bytes32 recordDetailsUri;
        bytes32 recordImageUri;
    }

    /**
     * State Variables
     */
    address public immutable ADMIN;
    uint256 public hospitalCount;
    uint256 public doctorCount;
    uint256 public approvedDoctorCount;
    uint256 public approvedPharmacistCount;
    uint256 public pharmacistCount;
    uint256 public patientCount;
    uint256 public systemAdminCount;

    mapping(address => bool) public systemAdmins;
    mapping(address => bool) public isDoctor;
    mapping(address => bool) public approvedDoctors;
    mapping(address => bool) public isPharmacist;
    mapping(address => bool) public approvedPharmacists;
    mapping(address => bool) public isPatient;
    mapping(uint256 => Hospital) public hospitals;
    mapping(uint256 => Patient) public patients;
    mapping(uint256 => Doctor) public doctors;
    mapping(uint256 => Pharmacist) public pharmacists;
    mapping(uint256 => bool) public hospitalExists;
    mapping(uint256 => bool) public doctorExists;
    mapping(uint256 => bool) public pharmacistExists;

    mapping(uint256 => mapping(address => bool))
        public hospitalApprovedPractitioners;

    mapping(uint256 => mapping(uint256 => address)) public hospitalDoctors;
    mapping(uint256 => mapping(uint256 => address)) public hospitalPharmacists;

    mapping(uint256 => mapping(uint256 => MedicalRecord))
        public patientMedicalRecords;

    mapping(uint256 => mapping(uint256 => mapping(address => bool)))
        public isPatientApprovedDoctors;
    mapping(uint256 => mapping(address => bool))
        public isApprovedByPatientToAddNewRecord;

    mapping(uint256 => mapping(uint256 => mapping(uint256 => mapping(address => bool))))
        public isPatientApprovedDoctorForFamilyMember;
    mapping(uint256 => mapping(uint256 => mapping(address => bool)))
        public isApprovedByPatientToAddNewRecordForFamilyMember;
    mapping(uint256 => mapping(uint256 => bool)) public isPatientFamilyMember;
    mapping(uint256 => mapping(uint256 => PatientFamilyMember))
        public patientFamilyMembers;
    mapping(uint256 => mapping(uint256 => mapping(uint256 => PatientFamilyMedicalRecord)))
        public patientFamilyMedicalRecord;

    /**
     * Events
     */
    event HospitalCreated(address indexed admin, uint256 indexed hospitalId);
    event HospitalApproved(uint256 indexed hospitalId);
    event HospitalRejected(uint256 indexed hospitalId);
    event AdminAdded(address indexed admin);
    event AdminRemoved(address indexed admin);
    event SystemAdminAdded(address indexed admin, uint256 indexed adminId);
    event SystemAdminRemoved(address indexed admin, uint256 indexed adminId);
    event DoctorAdded(
        address indexed doctor,
        uint256 indexed hospitalId,
        uint256 indexed doctorId
    );
    event DoctorRejected(address indexed doctor, uint256 indexed doctorId);
    event HospitalRemovedDoctor(
        address indexed doctor,
        uint256 indexed hospitalId
    );
    event HospitalRemovedPharmacist(
        address indexed pharmacist,
        uint256 indexed hospitalId
    );
    event DoctorApproved(
        uint256 indexed hospitalId,
        uint256 indexed doctorId,
        address indexed doctor
    );

    event PharmacistApproved(
        uint256 indexed hospitalId,
        uint256 indexed pharmacistId,
        address indexed pharmacist
    );
    event PharmacistAdded(
        address indexed pharmacist,
        uint256 indexed hospitalId,
        uint256 indexed pharmacistId
    );
    event PharmacistRejected(
        address indexed pharmacist,
        uint256 indexed pharmacistId
    );
    event MedicalRecordAdded(
        address indexed doctor,
        address indexed patient,
        uint256 indexed medicalRecordId
    );

    event FamilyMemberMedicalRecordAdded(
        address doctor,
        address indexed principalPatient,
        uint256 indexed familyMemberId,
        uint256 indexed medicalRecordId
    );

    event MedicalRecordAccessApproved(
        address indexed patient,
        address indexed approvedDoctor,
        uint256 indexed medicalRecordId
    );

    event WriteAccessGranted(address indexed doctor, uint256 indexed patientId);
    event WriteAccessRevoked(address indexed doctor, uint256 indexed patientId);

    event RecordAccessRevoked(
        address indexed patient,
        address indexed approvedDoctor,
        uint256 indexed medicalRecordId
    );

    event MedicalRecordAccessed(
        bytes32 indexed diagnosis,
        bytes32 indexed recordDetailsUri,
        bytes32 indexed recordImageUri
    );

    event PatientAdded(address indexed patient, uint256 indexed patientId);
    event PatientFamilyMemberAdded(
        uint256 indexed principalPatientId,
        uint256 indexed patientId
    );

    /**
     * Modifiers
     */
    modifier onlyAdmin() {
        if (msg.sender != ADMIN) {
            revert OnlyAdminAllowed();
        }
        _;
    }

    modifier onlySystemAdmin() {
        if (!systemAdmins[msg.sender]) {
            revert OnlySystemAdminAllowed();
        }
        _;
    }

    modifier onlyHospitalAdmin(uint256 _hospitalId) {
        if (hospitals[_hospitalId].admin != msg.sender) {
            revert Unauthorized();
        }
        _;
    }

    modifier onlyPatient(address _patientAddress) {
        if (!isPatient[_patientAddress]) {
            revert OnlyPatientAllowed();
        }
        _;
    }

    modifier onlyPrincipalPatient(uint256 _patientId) {
        if (patients[_patientId].walletAddress != msg.sender) {
            revert Unauthorized();
        }
        _;
    }

    modifier onlyApprovedHospitals(uint256 _hospitalId) {
        if (hospitals[_hospitalId].approvalStatus != approvalType.Approved) {
            revert HospitalNotApproved();
        }
        _;
    }

    modifier hospitalIdCompliance(uint256 _hospitalId) {
        if (_hospitalId > hospitalCount || _hospitalId == 0) {
            revert InvalidHospitalId();
        }
        _;
    }

    modifier patientIdCompliance(uint256 _patientId) {
        if (_patientId > patientCount || _patientId == 0) {
            revert InvalidPatientId();
        }

        _;
    }

    modifier recordIdCompliance(uint256 _recordId, uint256 _patientId) {
        if (
            _recordId > patients[_patientId].patientMedicalRecordCount ||
            _recordId == 0
        ) {
            revert InvalidMedicalRecordId();
        }
        _;
    }

    modifier doctorCompliance(address _doctorAddress) {
        if (_doctorAddress == address(0)) {
            revert InvalidAddress();
        }

        if (!isDoctor[_doctorAddress]) {
            revert DoctorNotFound();
        }

        if (!approvedDoctors[_doctorAddress]) {
            revert DoctorNotApproved();
        }
        _;
    }

    modifier doctorOrPharmacistCompliance(address _practitionerAddress) {
        if (_practitionerAddress == address(0)) {
            revert InvalidAddress();
        }

        if (
            !isDoctor[_practitionerAddress] &&
            !isPharmacist[_practitionerAddress]
        ) {
            revert InvalidPractitioner();
        }

        if (
            !approvedDoctors[_practitionerAddress] &&
            !approvedPharmacists[_practitionerAddress]
        ) {
            revert PractitionerNotApproved();
        }
        _;
    }

    modifier onlyApprovedDoctor(uint256 _hospitalId, address _doctorAddress) {
        if (!hospitalApprovedPractitioners[_hospitalId][_doctorAddress]) {
            revert DoctorNotApproved();
        }
        _;
    }

    modifier onlyPatientApprovedDoctor(
        uint256 _patientId,
        uint256 _recordId,
        address _doctorsAddress
    ) {
        if (!isPatientApprovedDoctors[_patientId][_recordId][_doctorsAddress]) {
            revert Unauthorized();
        }
        _;
    }

    constructor() {
        ADMIN = msg.sender;
        systemAdmins[msg.sender] = true;
    }

    receive() external payable {}

    /**
     * External Functions
     */
    function addSystemAdmin(address _admin) external onlyAdmin {
        require(_admin != address(0), "Invalid address");
        systemAdmins[_admin] = true;
        systemAdminCount++;
        emit SystemAdminAdded(_admin, systemAdminCount);
    }

    function removeSystemAdmin(address _admin) external onlyAdmin {
        require(_admin != address(0), "Invalid address");
        systemAdmins[_admin] = false;
        systemAdminCount--;
        emit SystemAdminRemoved(_admin, systemAdminCount + 1);
    }

    function createHospital() external {
        hospitalCount++;
        Hospital memory hospital = Hospital({
            hospitalId: hospitalCount,
            doctorsCount: 0,
            pharmacistsCount: 0,
            admin: msg.sender,
            approvalStatus: approvalType.Pending
        });
        hospitals[hospitalCount] = hospital;
        hospitalExists[hospitalCount] = true;

        emit HospitalCreated(msg.sender, hospitalCount);
    }

    function approveHospital(uint256 _hospitalId) external onlySystemAdmin {
        if (_hospitalId > hospitalCount) {
            revert InvalidHospitalId();
        }
        hospitals[_hospitalId].approvalStatus = approvalType.Approved;
        emit HospitalApproved(_hospitalId);
    }

    function reassignHospitalAdmin(
        uint256 _hospitalId,
        address _admin
    )
        external
        hospitalIdCompliance(_hospitalId)
        onlyHospitalAdmin(_hospitalId)
    {
        if (_admin == address(0)) {
            revert InvalidAddress();
        }
        hospitals[_hospitalId].admin = _admin;
        emit AdminAdded(_admin);
    }

    function rejectHospital(uint256 _hospitalId) external onlySystemAdmin {
        if (_hospitalId > hospitalCount) {
            revert InvalidHospitalId();
        }
        hospitals[_hospitalId].approvalStatus = approvalType.Rejected;
        emit HospitalRejected(_hospitalId);
    }

    function createDoctor(
        uint256 _hospitalId,
        address _doctorAddress
    ) external hospitalIdCompliance(_hospitalId) {
        if (_doctorAddress == address(0)) {
            revert InvalidAddress();
        }

        if (hospitalApprovedPractitioners[_hospitalId][_doctorAddress]) {
            revert DuplicateDoctorAddress();
        }

        doctorCount++;

        Doctor memory doctor = Doctor({
            doctorId: doctorCount,
            hospitalId: _hospitalId,
            doctor: _doctorAddress,
            approvalStatus: approvalType.Pending
        });

        doctorExists[doctorCount] = true;
        doctors[doctorCount] = doctor;
        isDoctor[_doctorAddress] = true;
        emit DoctorAdded(_doctorAddress, _hospitalId, doctorCount);
    }

    function approveDoctor(
        address _doctorAddress,
        uint256 _hospitalId,
        uint256 _doctorId
    )
        external
        hospitalIdCompliance(_hospitalId)
        onlyHospitalAdmin(_hospitalId)
    {
        if (_doctorAddress == address(0)) {
            revert InvalidAddress();
        }
        if (!isDoctor[_doctorAddress]) {
            revert DoctorNotFound();
        }

        if (_doctorId > doctorCount) {
            revert InvalidDoctorId();
        }

        if (!doctorExists[_doctorId]) {
            revert DoctorNotFound();
        }

        if (hospitalApprovedPractitioners[_hospitalId][_doctorAddress]) {
            revert DuplicateDoctorAddress();
        }

        approvedDoctorCount++;
        hospitals[_hospitalId].doctorsCount++;
        uint256 doctorId = hospitals[_hospitalId].doctorsCount;

        if (!approvedDoctors[_doctorAddress]) {
            approvedDoctors[_doctorAddress] = true;
        }
        hospitalApprovedPractitioners[_hospitalId][_doctorAddress] = true;
        hospitalDoctors[_hospitalId][doctorId] = _doctorAddress;

        doctors[_doctorId].approvalStatus = approvalType.Approved;
        emit DoctorApproved(_hospitalId, _doctorId, _doctorAddress);
    }

    /**
     * @dev Removes a doctor from a hospital, updates the approval status of the doctor within the hospital but leaves the approval status of the doctor as approved.
     */
    function removeDoctorFromHospital(
        address _doctorAddress,
        uint256 _hospitalId,
        uint256 _doctorHospitalId
    )
        external
        hospitalIdCompliance(_hospitalId)
        doctorCompliance(_doctorAddress)
        onlyHospitalAdmin(_hospitalId)
    {
        if (_doctorHospitalId > hospitals[_hospitalId].doctorsCount) {
            revert InvalidDoctorId();
        }

        if (!hospitalApprovedPractitioners[_hospitalId][_doctorAddress]) {
            revert DoctorNotApproved();
        }

        hospitals[_hospitalId].doctorsCount--;
        hospitalApprovedPractitioners[_hospitalId][_doctorAddress] = false;

        hospitalDoctors[_hospitalId][_doctorHospitalId] = address(0);

        emit HospitalRemovedDoctor(_doctorAddress, _hospitalId);
    }

    /**
     * @dev this function sets global approval status of a doctor to Rejected
     */
    function rejectDoctor(
        address _doctorAddress,
        uint256 _doctorId
    ) external onlySystemAdmin doctorCompliance(_doctorAddress) {
        if (_doctorId > doctorCount) {
            revert InvalidDoctorId();
        }

        if (doctors[_doctorId].approvalStatus == approvalType.Rejected) {
            revert DoctorAlreadyRejected();
        }
        approvedDoctorCount--;
        doctors[_doctorId].approvalStatus = approvalType.Rejected;
        approvedDoctors[_doctorAddress] = false;

        emit DoctorRejected(_doctorAddress, _doctorId);
    }

    function createPharmacist(
        uint256 _hospitalId,
        address _pharmacistAddress
    ) external hospitalIdCompliance(_hospitalId) {
        if (_pharmacistAddress == address(0)) {
            revert InvalidAddress();
        }

        if (hospitalApprovedPractitioners[_hospitalId][_pharmacistAddress]) {
            revert DuplicatePharmacistAddress();
        }

        pharmacistCount++;

        Pharmacist memory pharmacist = Pharmacist({
            pharmacistId: pharmacistCount,
            hospitalId: _hospitalId,
            pharmacist: _pharmacistAddress,
            approvalStatus: approvalType.Pending
        });

        pharmacistExists[pharmacistCount] = true;
        pharmacists[pharmacistCount] = pharmacist;
        isPharmacist[_pharmacistAddress] = true;

        emit PharmacistAdded(_pharmacistAddress, _hospitalId, pharmacistCount);
    }

    function approvePharmacist(
        address _pharmacistAddress,
        uint256 _hospitalId,
        uint256 _pharmacistId
    )
        external
        hospitalIdCompliance(_hospitalId)
        onlyHospitalAdmin(_hospitalId)
    {
        if (_pharmacistAddress == address(0)) {
            revert InvalidAddress();
        }

        if (!isPharmacist[_pharmacistAddress]) {
            revert PharmacistNotFound();
        }

        if (_pharmacistId > pharmacistCount) {
            revert InvalidPharmacistId();
        }

        if (!pharmacistExists[_pharmacistId]) {
            revert PharmacistNotFound();
        }

        if (hospitalApprovedPractitioners[_hospitalId][_pharmacistAddress]) {
            revert DuplicatePharmacistAddress();
        }

        approvedPharmacistCount++;
        hospitals[_hospitalId].pharmacistsCount++;
        uint256 pharmacistId = hospitals[_hospitalId].pharmacistsCount;

        if (!approvedPharmacists[_pharmacistAddress]) {
            approvedPharmacists[_pharmacistAddress] = true;
        }

        hospitalApprovedPractitioners[_hospitalId][_pharmacistAddress] = true;
        hospitalPharmacists[_hospitalId][pharmacistId] = _pharmacistAddress;

        pharmacists[_pharmacistId].approvalStatus = approvalType.Approved;
        emit PharmacistApproved(_hospitalId, _pharmacistId, _pharmacistAddress);
    }

    /**
     * @dev Removes a pharmacist from a hospital, updates the approval status of the pharmacist within the hospital but leaves the global approval status state
     */
    function removePharmacistFromHospital(
        address _pharmacistAddress,
        uint256 _hospitalId,
        uint256 _pharmacistHospitalId
    )
        external
        hospitalIdCompliance(_hospitalId)
        onlyHospitalAdmin(_hospitalId)
    {
        if (_pharmacistAddress == address(0)) {
            revert InvalidAddress();
        }

        if (_pharmacistHospitalId > hospitals[_hospitalId].pharmacistsCount) {
            revert InvalidPharmacistId();
        }

        if (!isPharmacist[_pharmacistAddress]) {
            revert PharmacistNotFound();
        }

        if (!hospitalApprovedPractitioners[_hospitalId][_pharmacistAddress]) {
            revert PharmacistNotApproved();
        }

        hospitals[_hospitalId].pharmacistsCount--;
        hospitalApprovedPractitioners[_hospitalId][_pharmacistAddress] = false;

        hospitalPharmacists[_hospitalId][_pharmacistHospitalId] = address(0);

        emit HospitalRemovedPharmacist(_pharmacistAddress, _hospitalId);
    }

    function rejectPharmacist(
        address _pharmacistAddress,
        uint256 _pharmacistId
    ) external onlySystemAdmin {
        if (_pharmacistAddress == address(0)) {
            revert InvalidAddress();
        }

        if (_pharmacistId > pharmacistCount) {
            revert InvalidPharmacistId();
        }

        if (!isPharmacist[_pharmacistAddress]) {
            revert PharmacistNotFound();
        }

        if (!approvedPharmacists[_pharmacistAddress]) {
            revert PharmacistNotApproved();
        }

        if (
            pharmacists[_pharmacistId].approvalStatus == approvalType.Rejected
        ) {
            revert PharmacistAlreadyRejected();
        }

        approvedPharmacistCount--;
        pharmacists[_pharmacistId].approvalStatus = approvalType.Rejected;
        approvedPharmacists[_pharmacistAddress] = false;

        emit PharmacistRejected(_pharmacistAddress, _pharmacistId);
    }

    function addPatient() external {
        if (isPatient[msg.sender]) {
            revert DuplicatePatientAddress();
        }
        patientCount++;
        uint256 id = patientCount;
        Patient memory patient = Patient({
            patientId: id,
            approvalCount: 0,
            patientMedicalRecordCount: 0,
            patientFamilyMemberCount: 0,
            walletAddress: msg.sender
        });

        patients[id] = patient;
        isPatient[msg.sender] = true;

        emit PatientAdded(msg.sender, id);
    }

    function addPatientFamilyMember(
        uint256 _principalPatientId
    )
        external
        onlyPatient(msg.sender)
        patientIdCompliance(_principalPatientId)
    {
        patients[_principalPatientId].patientFamilyMemberCount++;
        uint256 familyMemberId = patients[_principalPatientId]
            .patientFamilyMemberCount;

        isPatientFamilyMember[_principalPatientId][familyMemberId] = true;
        PatientFamilyMember memory familyMember = PatientFamilyMember({
            patientId: familyMemberId,
            approvalCount: 0,
            principalPatientId: _principalPatientId,
            familyMemberMedicalRecordCount: 0
        });

        patientFamilyMembers[_principalPatientId][
            familyMemberId
        ] = familyMember;
        emit PatientFamilyMemberAdded(_principalPatientId, familyMemberId);
    }

    function approveMedicalRecordAccess(
        address _practitionerAddress,
        uint256 _patientId,
        uint256 _recordId,
        uint256 _duration
    )
        external
        onlyPatient(msg.sender)
        patientIdCompliance(_patientId)
        doctorOrPharmacistCompliance(_practitionerAddress)
        recordIdCompliance(_patientId, _recordId)
    {
        if (
            patientMedicalRecords[_patientId][_recordId].patient != msg.sender
        ) {
            revert NotRecordOwner();
        }

        MedicalRecord storage record = patientMedicalRecords[_patientId][
            _recordId
        ];

        if (
            record.approvedDoctor == _practitionerAddress &&
            block.timestamp < record.expiration
        ) {
            revert AccessToRecordAlreadyGranted();
        }
        patients[_patientId].approvalCount++;
        isPatientApprovedDoctors[_patientId][_recordId][
            _practitionerAddress
        ] = true;

        record.approvedDoctor = _practitionerAddress;
        record.duration = _duration;
        record.expiration = block.timestamp + _duration;

        emit MedicalRecordAccessApproved(
            msg.sender,
            _practitionerAddress,
            _recordId
        );
    }

    function approveFamilyMemberMedicalRecordAccess(
        address _doctorAddress,
        uint256 _principalPatientId,
        uint256 _familyMemberId,
        uint256 _recordId,
        uint256 _duration
    )
        external
        onlyPatient(msg.sender)
        onlyPrincipalPatient(_principalPatientId)
        doctorCompliance(_doctorAddress)
    {
        if (
            _familyMemberId >
            patients[_principalPatientId].patientFamilyMemberCount
        ) {
            revert InvalidFamilyMemberId();
        }

        if (
            _recordId >
            patientFamilyMembers[_principalPatientId][_familyMemberId]
                .familyMemberMedicalRecordCount
        ) {
            revert InvalidMedicalRecordId();
        }

        bool isDoctorApproved = isPatientApprovedDoctorForFamilyMember[
            _principalPatientId
        ][_familyMemberId][_recordId][_doctorAddress];
        PatientFamilyMedicalRecord storage record = patientFamilyMedicalRecord[
            _principalPatientId
        ][_familyMemberId][_recordId];

        if (
            isDoctorApproved &&
            record.approvedDoctor == _doctorAddress &&
            block.timestamp < record.expiration
        ) {
            revert AccessToRecordAlreadyGranted();
        }

        isPatientApprovedDoctorForFamilyMember[_principalPatientId][
            _familyMemberId
        ][_recordId][_doctorAddress] = true;
        patientFamilyMembers[_principalPatientId][_familyMemberId]
            .approvalCount++;
        record.approvedDoctor = _doctorAddress;
        record.duration = _duration;
        record.expiration = block.timestamp + _duration;

        emit MedicalRecordAccessApproved(msg.sender, _doctorAddress, _recordId);
    }

    function approveAccessToAddNewRecord(
        address _doctorAddress,
        uint256 _patientId
    )
        external
        onlyPatient(msg.sender)
        patientIdCompliance(_patientId)
        doctorCompliance(_doctorAddress)
    {
        if (isApprovedByPatientToAddNewRecord[_patientId][_doctorAddress]) {
            revert AccessAlreadyGranted();
        }

        patients[_patientId].approvalCount++;
        isApprovedByPatientToAddNewRecord[_patientId][_doctorAddress] = true;
        emit WriteAccessGranted(_doctorAddress, _patientId);
    }

    function approveAccessToAddNewRecordForFamilyMember(
        address _doctorAddress,
        uint256 _patientId,
        uint256 _principalPatientId
    )
        external
        onlyPatient(msg.sender)
        onlyPrincipalPatient(_principalPatientId)
        doctorCompliance(_doctorAddress)
    {
        if (
            isApprovedByPatientToAddNewRecordForFamilyMember[_patientId][
                _principalPatientId
            ][_doctorAddress]
        ) {
            revert AccessAlreadyGranted();
        }

        patientFamilyMembers[_principalPatientId][_patientId].approvalCount++;
        isApprovedByPatientToAddNewRecordForFamilyMember[_patientId][
            _principalPatientId
        ][_doctorAddress] = true;

        emit WriteAccessGranted(_doctorAddress, _patientId);
    }

    function revokeAccessToAddNewRecord(
        address _doctorAddress,
        uint256 _patientId
    )
        external
        onlyPatient(msg.sender)
        patientIdCompliance(_patientId)
        doctorCompliance(_doctorAddress)
    {
        if (!isApprovedByPatientToAddNewRecord[_patientId][_doctorAddress]) {
            revert AccessNotGranted();
        }

        patients[_patientId].approvalCount--;
        isApprovedByPatientToAddNewRecord[_patientId][_doctorAddress] = false;
        emit WriteAccessRevoked(_doctorAddress, _patientId);
    }

    function revokeAccessToAddNewRecordForFamilyMember(
        address _doctorAddress,
        uint256 _patientId,
        uint256 _principalPatientId
    )
        external
        onlyPatient(msg.sender)
        onlyPrincipalPatient(_principalPatientId)
        doctorCompliance(_doctorAddress)
    {
        if (
            !isApprovedByPatientToAddNewRecordForFamilyMember[_patientId][
                _principalPatientId
            ][_doctorAddress]
        ) {
            revert AccessNotGranted();
        }

        patientFamilyMembers[_principalPatientId][_patientId].approvalCount--;
        isApprovedByPatientToAddNewRecordForFamilyMember[_patientId][
            _principalPatientId
        ][_doctorAddress] = false;

        emit WriteAccessRevoked(_doctorAddress, _patientId);
    }

    function revokeMedicalRecordAccess(
        uint256 _patientId,
        uint256 _recordId,
        address _doctorAddress
    )
        external
        onlyPatient(msg.sender)
        doctorCompliance(_doctorAddress)
        patientIdCompliance(_patientId)
        recordIdCompliance(_recordId, _patientId)
    {
        if (!patientHasRecords(_patientId)) {
            revert MedicalRecordNotFound();
        }
        if (
            isPatientApprovedDoctors[_patientId][_recordId][_doctorAddress] ==
            false
        ) {
            revert AccessToRecordNotGranted();
        }
        patientMedicalRecords[_patientId][_recordId].approvedDoctor = address(
            0
        );
        isPatientApprovedDoctors[_patientId][_recordId][_doctorAddress] = false;
        patients[_patientId].approvalCount--;

        emit RecordAccessRevoked(msg.sender, _doctorAddress, _recordId);
    }

    function revokeFamilyMemberMedicalRecordAccess(
        address _doctorAddress,
        uint256 _recordId,
        uint256 _principalPatientId,
        uint256 _familyMemberId
    )
        external
        onlyPatient(msg.sender)
        onlyPrincipalPatient(_principalPatientId)
        doctorCompliance(_doctorAddress)
    {
        if (
            !patientFamilyMemberHasRecords(_principalPatientId, _familyMemberId)
        ) {
            revert MedicalRecordNotFound();
        }
        if (
            _familyMemberId >
            patients[_principalPatientId].patientFamilyMemberCount
        ) {
            revert InvalidFamilyMemberId();
        }

        if (
            _recordId >
            patientFamilyMembers[_principalPatientId][_familyMemberId]
                .familyMemberMedicalRecordCount
        ) {
            revert InvalidMedicalRecordId();
        }
        isPatientApprovedDoctorForFamilyMember[_principalPatientId][
            _familyMemberId
        ][_recordId][_doctorAddress] = false;
        patientFamilyMedicalRecord[_principalPatientId][_familyMemberId][
            _recordId
        ].approvedDoctor = address(0);
        patientFamilyMembers[_principalPatientId][_familyMemberId]
            .approvalCount--;

        emit RecordAccessRevoked(msg.sender, _doctorAddress, _recordId);
    }

    function viewMedicalRecord(
        uint256 _recordId,
        uint256 _patientId,
        address _viewer
    )
        public
        patientIdCompliance(_patientId)
        recordIdCompliance(_recordId, _patientId)
    {
        if (_viewer == address(0)) {
            revert InvalidAddress();
        }

        if (msg.sender != _viewer) {
            revert Unauthorized();
        }

        MedicalRecord memory record = patientMedicalRecords[_patientId][
            _recordId
        ];

        if (
            _viewer == record.patient ||
            viewerHasAccessToMedicalRecord(_viewer, _patientId, _recordId)
        ) {
            emit MedicalRecordAccessed(
                record.diagnosis,
                record.recordDetailsUri,
                record.recordImageUri
            );
        }
    }

    function viewFamilyMemberMedicalRecord(
        uint256 _recordId,
        uint256 _principalPatientId,
        uint256 _familyMemberId,
        address _viewer
    ) external patientIdCompliance(_principalPatientId) {
        if (_viewer == address(0)) {
            revert InvalidAddress();
        }

        if (msg.sender != _viewer) {
            revert Unauthorized();
        }

        if (
            _recordId >
            patientFamilyMembers[_principalPatientId][_familyMemberId]
                .familyMemberMedicalRecordCount
        ) {
            revert InvalidMedicalRecordId();
        }

        PatientFamilyMedicalRecord memory record = patientFamilyMedicalRecord[
            _principalPatientId
        ][_familyMemberId][_recordId];

        if (
            _viewer == patients[_principalPatientId].walletAddress ||
            viewerHasAccessToPatientFamilyMemberMedicalRecord(
                _viewer,
                _principalPatientId,
                _familyMemberId,
                _recordId
            )
        ) {
            emit MedicalRecordAccessed(
                record.diagnosis,
                record.recordDetailsUri,
                record.recordImageUri
            );
        }
    }

    function addMedicalRecord(
        address _doctorAddress,
        address _patientAddress,
        uint256 _patientId,
        bytes32 _diagnosis,
        bytes32 _recordDetailsUri,
        bytes32 _recordImageUri
    )
        external
        patientIdCompliance(_patientId)
        doctorCompliance(_doctorAddress)
    {
        if (_diagnosis == bytes32(0) || _recordDetailsUri == bytes32(0)) {
            revert InvalidMedicalRecordDetail();
        }

        if (!isApprovedByPatientToAddNewRecord[_patientId][_doctorAddress]) {
            revert AccessNotGranted();
        }
        patients[_patientId].patientMedicalRecordCount++;
        uint256 medicalRecordId = patients[_patientId]
            .patientMedicalRecordCount;

        MedicalRecord memory record = MedicalRecord({
            medicalRecordId: medicalRecordId,
            patientId: _patientId,
            duration: 0 seconds,
            expiration: 0 seconds,
            patient: _patientAddress,
            approvedDoctor: address(0),
            diagnosis: _diagnosis,
            recordDetailsUri: _recordDetailsUri,
            recordImageUri: _recordImageUri
        });
        patientMedicalRecords[_patientId][medicalRecordId] = record;

        patients[_patientId].approvalCount--;
        isApprovedByPatientToAddNewRecord[_patientId][_doctorAddress] = false;
        emit MedicalRecordAdded(
            _doctorAddress,
            _patientAddress,
            medicalRecordId
        );
    }

    function addMedicalRecordForFamilyMember(
        address _doctorAddress,
        uint256 _principalPatientId,
        uint256 _familyMemberId,
        bytes32 _diagnosis,
        bytes32 _recordDetailsUri,
        bytes32 _recordImageUri
    )
        external
        patientIdCompliance(_principalPatientId)
        doctorCompliance(_doctorAddress)
    {
        if (_diagnosis == bytes32(0) || _recordDetailsUri == bytes32(0)) {
            revert InvalidMedicalRecordDetail();
        }

        if (
            !isApprovedByPatientToAddNewRecordForFamilyMember[
                _principalPatientId
            ][_familyMemberId][_doctorAddress]
        ) {
            revert AccessNotGranted();
        }
        patientFamilyMembers[_principalPatientId][_familyMemberId]
            .familyMemberMedicalRecordCount++;
        uint256 medicalRecordId = patientFamilyMembers[_principalPatientId][
            _familyMemberId
        ].familyMemberMedicalRecordCount;
        PatientFamilyMedicalRecord memory record = PatientFamilyMedicalRecord({
            medicalRecordId: medicalRecordId,
            principalPatientId: _principalPatientId,
            patientId: _familyMemberId,
            duration: 0 seconds,
            expiration: 0 seconds,
            approvedDoctor: address(0),
            diagnosis: _diagnosis,
            recordDetailsUri: _recordDetailsUri,
            recordImageUri: _recordImageUri
        });

        patientFamilyMedicalRecord[_principalPatientId][_familyMemberId][
            medicalRecordId
        ] = record;
        patientFamilyMembers[_principalPatientId][_familyMemberId]
            .approvalCount--;
        isApprovedByPatientToAddNewRecordForFamilyMember[_principalPatientId][
            _familyMemberId
        ][_doctorAddress] = false;

        emit FamilyMemberMedicalRecordAdded(
            _doctorAddress,
            patients[_principalPatientId].walletAddress,
            _familyMemberId,
            medicalRecordId
        );
    }

    /**
     * View Functions
     */

    function patientHasRecords(
        uint256 _patientId
    ) internal view returns (bool) {
        return patients[_patientId].patientMedicalRecordCount > 0;
    }

    function patientFamilyMemberHasRecords(
        uint256 _principalPatientId,
        uint256 _familyMemberId
    ) internal view returns (bool) {
        return
            patientFamilyMembers[_principalPatientId][_familyMemberId]
                .familyMemberMedicalRecordCount > 0;
    }

    function viewerHasAccessToMedicalRecord(
        address _viewer,
        uint256 _patientId,
        uint256 _recordId
    ) internal view returns (bool) {
        MedicalRecord memory record = patientMedicalRecords[_patientId][
            _recordId
        ];
        bool accessValid = false;

        if (
            isPatientApprovedDoctors[_patientId][_recordId][_viewer] &&
            record.approvedDoctor == _viewer &&
            block.timestamp < record.expiration
        ) {
            accessValid = true;
        }

        return accessValid;
    }

    function viewerHasAccessToPatientFamilyMemberMedicalRecord(
        address _viewer,
        uint256 _principalPatientId,
        uint256 _familyMemberId,
        uint256 _recordId
    ) internal view returns (bool) {
        PatientFamilyMedicalRecord memory record = patientFamilyMedicalRecord[
            _principalPatientId
        ][_familyMemberId][_recordId];

        bool accessValid = false;

        if (
            isPatientApprovedDoctorForFamilyMember[_principalPatientId][
                _familyMemberId
            ][_recordId][_viewer] && block.timestamp < record.expiration
        ) {
            accessValid = true;
        }

        return accessValid;
    }
}