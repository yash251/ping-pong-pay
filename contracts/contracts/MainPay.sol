// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract MainPay is Ownable {
    uint256 public nextOrgIdCounter;
    uint256 public totalWorkforce;

    event OrganizationRegistered(uint256 indexed orgId, address indexed orgAddress, string orgName);
    event OrganizationFunded(uint256 indexed orgId, uint256 amount);
    event WorkerAdded(address indexed workerAddress, address indexed orgAddress, uint256 dailyPayRate, string role, uint256 startDate);
    event WorkerVerified(address indexed workerAddress, address indexed orgAddress);
    event WorkerPaid(address indexed workerAddress, uint256 amount, uint256 lastPaymentTimestamp);
    event PaymentTimestampAdjusted(address indexed workerAddress, uint256 hoursReversed);

    constructor() Ownable(msg.sender) {
        nextOrgIdCounter = 1;
        totalWorkforce = 0;
    }

    struct Organization {
        address admin;
        uint256 orgId;
        string name;
        uint256 treasury;
        uint256 workforceCount;
        address[] workers;
    }

    struct Worker {
        address account;
        address organization;
        string orgName;
        uint8 verificationStatus;
        uint256 dailyPay;
        string role;
        uint256 joinDate;
        uint256 lastPaymentTime;
        uint256[] paymentRecords;
    }

    mapping(uint256 => Organization) public organizationRegistry;
    mapping(address => Worker) public workerRegistry;
    mapping(address => uint256) public orgIdMapping;

    // Accept Ether directly
    receive() external payable {}

    fallback() external payable {}

    function registerOrganization(address admin, string memory name) external {
        require(orgIdMapping[admin] == 0, "Organization already exists");

        organizationRegistry[nextOrgIdCounter] = Organization({
            admin: admin,
            orgId: nextOrgIdCounter,
            name: name,
            treasury: 0,
            workforceCount: 0,
            workers: new address[](0)
        });

        orgIdMapping[admin] = nextOrgIdCounter;
        emit OrganizationRegistered(nextOrgIdCounter, admin, name);
        nextOrgIdCounter++;
    }

    function getOrganization(address admin) external view returns (Organization memory) {
        uint256 orgId = orgIdMapping[admin];
        require(orgId != 0, "Organization does not exist");
        return organizationRegistry[orgId];
    }

    function fundTreasury(uint256 orgId) external payable {
        Organization storage org = organizationRegistry[orgId];
        require(org.admin != address(0), "Invalid organization");
        org.treasury += msg.value;
        emit OrganizationFunded(orgId, msg.value);
    }

    function onboardWorker(
        address workerAddress,
        uint256 dailyPayRate,
        string memory role,
        uint256 joinDate
    ) external {
        uint256 orgId = orgIdMapping[msg.sender];
        Organization storage org = organizationRegistry[orgId];

        workerRegistry[workerAddress] = Worker({
            account: workerAddress,
            organization: msg.sender,
            orgName: org.name,
            verificationStatus: 0,
            dailyPay: dailyPayRate,
            role: role,
            joinDate: joinDate,
            lastPaymentTime: joinDate,
            paymentRecords: new uint256[](0)
   });

        org.workers.push(workerAddress);
        org.workforceCount++;
        totalWorkforce++;
        emit WorkerAdded(workerAddress, msg.sender, dailyPayRate, role, joinDate);
    }

    function getWorker(address workerAddress)
        external
        view
        returns (
            address account,
            address organization,
            string memory orgName,
            uint8 verificationStatus,
            uint256 dailyPay,
            string memory role,
            uint256 joinDate,
            uint256 lastPaymentTime,
            uint256 pendingPayment
        )
    {
        Worker memory worker = workerRegistry[workerAddress];
        require(worker.account != address(0), "Worker not found");

        uint256 pendingAmount = calculatePendingPayment(workerAddress);

        return (
            worker.account,
            worker.organization,
            worker.orgName,
            worker.verificationStatus,
            worker.dailyPay,
            worker.role,
            worker.joinDate,
            worker.lastPaymentTime,
            pendingAmount
        );
    }

    function calculatePendingPayment(address workerAddress) public view returns (uint256) {
        Worker memory worker = workerRegistry[workerAddress];
        require(worker.account != address(0), "Worker not found");

        uint256 currentTime = block.timestamp;
        if (currentTime <= worker.lastPaymentTime) return 0;

        uint256 elapsedDays = (currentTime - worker.lastPaymentTime) / 1 days;
        return elapsedDays * worker.dailyPay;
    }

    function disbursePayment(address workerAddress) external {
        Worker storage worker = workerRegistry[workerAddress];
        require(worker.account != address(0), "Worker not found");

        uint256 pendingAmount = calculatePendingPayment(workerAddress);
        uint256 orgId = orgIdMapping[worker.organization];
        Organization storage org = organizationRegistry[orgId];

        require(address(this).balance >= pendingAmount, "Insufficient contract balance");
        require(org.treasury >= pendingAmount, "Insufficient organization balance");

        (bool sent, ) = worker.account.call{value: pendingAmount}("");
        require(sent, "Payment failed");

        worker.lastPaymentTime = block.timestamp;
        worker.paymentRecords.push(block.timestamp);
        org.treasury -= pendingAmount;

        emit WorkerPaid(workerAddress, pendingAmount, worker.lastPaymentTime);
    }

    function adjustPaymentTimestamp(address workerAddress, uint256 hoursToReverse) external {
        Worker storage worker = workerRegistry[workerAddress];
        require(worker.account != address(0), "Worker not found");

        uint256 secondsToReverse = hoursToReverse * 1 hours;
        worker.lastPaymentTime -= secondsToReverse;

        emit PaymentTimestampAdjusted(workerAddress, hoursToReverse);
    }
}
