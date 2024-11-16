// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract OptimizedPayroll {
    struct Organization {
        address admin;
        string name;
        uint256 balance;
    }

    struct Staff {
        address staffAddress;
        address organization;
        uint256 dailyPay;
        uint256 daysWorkedCount;
        uint8 isVerified;
        string role;
    }

    mapping(address => Organization) public organizations;
    mapping(address => Staff) public staffMembers;

    event OrganizationRegistered(address indexed admin, string name);
    event OrganizationFunded(address indexed admin, uint256 amount);
    event StaffRegistered(address indexed staffAddress, address indexed organization, uint256 dailyPay, string role);
    event WorkDaysUpdated(address indexed staffAddress, uint256 daysWorkedCount);
    event PaymentProcessed(address indexed staffAddress, uint256 amount);
    event StaffVerified(address indexed staffAddress);

    function registerOrganization(string memory organizationName) external {
        organizations[msg.sender] = Organization({
            admin: msg.sender,
            name: organizationName,
            balance: 0
        });
        emit OrganizationRegistered(msg.sender, organizationName);
    }

    function depositFunds() external payable {
        Organization storage org = organizations[msg.sender];
        org.balance += msg.value;
        emit OrganizationFunded(msg.sender, msg.value);
    }

    function registerStaff(
        address staffAddress,
        uint256 dailyPayRate,
        string memory staffRole
    ) external {
        staffMembers[staffAddress] = Staff({
            staffAddress: staffAddress,
            organization: msg.sender,
            dailyPay: dailyPayRate,
            daysWorkedCount: 0,
            isVerified: 0,
            role: staffRole
        });
        emit StaffRegistered(staffAddress, msg.sender, dailyPayRate, staffRole);
    }

    function logWorkDays(address staffAddress, uint256 daysCount) external {
        Staff storage staff = staffMembers[staffAddress];
        staff.daysWorkedCount = daysCount;
        emit WorkDaysUpdated(staffAddress, daysCount);
    }

    function processPayment(address staffAddress) external {
        Staff storage staff = staffMembers[staffAddress];
        Organization storage org = organizations[staff.organization];

        uint256 totalPayment = staff.daysWorkedCount * staff.dailyPay;

        require(org.balance >= totalPayment, "Organization balance insufficient");
        require(address(this).balance >= totalPayment, "Contract balance insufficient");

        staff.daysWorkedCount = 0;
        org.balance -= totalPayment;
        payable(staff.staffAddress).transfer(totalPayment);

        emit PaymentProcessed(staffAddress, totalPayment);
    }

    function approveStaff(address staffAddress) external {
        Staff storage staff = staffMembers[staffAddress];
        require(staff.staffAddress != address(0), "Staff does not exist");

        staff.isVerified = 1;
        emit StaffVerified(staffAddress);
    }

    // Function to accept ETH
    receive() external payable {}

    // Retrieve organization details
    function fetchOrganization(address orgAddress) external view returns (Organization memory) {
        return organizations[orgAddress];
    }

    // Retrieve staff details
    function fetchStaff(address staffAddress) external view returns (Staff memory) {
        return staffMembers[staffAddress];
    }
}
