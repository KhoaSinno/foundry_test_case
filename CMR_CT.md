## Note code with CRM onchain MPAY

``` solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title CRM Payroll and Treasury Service
/// @notice A Solidity implementation of the Aptos Move CRM::PayrollAndTreasury module
contract PayrollTreasury {
    // --- Events ---
    event Deposit(address indexed from, uint256 amount);
    event Withdraw(address indexed to, uint256 amount, uint256 timestamp);
    event EmployeeRegistered(address indexed emp, uint256 rate, uint256 timestamp);
    event PayrollRun(address indexed admin, uint256 timestamp);
    event Payment(address indexed to, uint256 amount, uint256 timestamp);

    // --- Treasury State ---
    address public treasuryManager;
    uint256 public dailyLimit;
    uint256 public lastWithdrawalDay;
    uint256 public dailyWithdrawn;

    // --- Employee State ---
    struct Employee {
        bool exists;
        uint256 rate;        // salary per 30-day period (in wei)
        uint256 lastPaid;    // UNIX timestamp
        uint256 totalPaid;   // cumulative salary paid
    }
    mapping(address => Employee) private employees;
    address[] private employeeList;

    /// @dev Restrict functions to treasury manager
    modifier onlyManager() {
        require(msg.sender == treasuryManager, "Not authorized");
        _;
    }

    /// @dev Initialize the contract, setting treasury manager and daily limit
    /// @param _manager Address that can withdraw and run payroll
    /// @param _dailyLimit Maximum withdrawal per day (in wei)
    constructor(address _manager, uint256 _dailyLimit) {
        require(_manager != address(0), "Invalid manager");
        treasuryManager = _manager;
        dailyLimit = _dailyLimit;
        lastWithdrawalDay = block.timestamp / 86400;
        dailyWithdrawn = 0;
    }

    // --- Treasury Functions ---

    /// @notice Deposit ether into the treasury
    function deposit() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    /// @notice Withdraw funds to a staff address, respecting daily cap
    /// @param to Recipient address
    /// @param amount Amount in wei
    function withdraw(address payable to, uint256 amount) public {
        uint256 currentDay = block.timestamp / 86400;
        if (currentDay != lastWithdrawalDay) {
            dailyWithdrawn = 0;
            lastWithdrawalDay = currentDay;
        }
        require(dailyWithdrawn + amount <= dailyLimit, "Daily withdrawal limit exceeded");
        dailyWithdrawn += amount;
        require(address(this).balance >= amount, "Insufficient balance");
        to.transfer(amount);
        emit Withdraw(to, amount, block.timestamp);
    }

    // --- Payroll Functions ---

    /// @notice Register a new employee
    /// @param emp Address of the employee
    /// @param rate Fixed salary for each 30-day period (in wei)
    function registerEmployee(address emp, uint256 rate) public  {
        require(emp != address(0), "Invalid employee");
        Employee storage e = employees[emp];
        require(!e.exists, "Employee already registered");
        e.exists = true;
        e.rate = rate;
        e.lastPaid = block.timestamp;
        e.totalPaid = 0;
        employeeList.push(emp);
        emit EmployeeRegistered(emp, rate, block.timestamp);
    }

    /// @notice Compute salary due since last paid
    /// @param rate Salary per 30-day period
    /// @param lastPaid Timestamp of last payment
    /// @return Amount due in wei
    function computeDue(uint256 rate, uint256 lastPaid) public view returns (uint256) {
        uint256 period = 30 days;
        uint256 nowTs = block.timestamp;
        if (nowTs > lastPaid) {
            return rate * ((nowTs - lastPaid) / period);
        }
        return 0;
    }

    /// @notice Run payroll for all registered employees
    function runPayroll() public onlyManager {
        uint256 nowTs = block.timestamp;
        for (uint256 i = 0; i < employeeList.length; i++) {
            address empAddr = employeeList[i];
            Employee storage e = employees[empAddr];
            uint256 due = computeDue(e.rate, e.lastPaid);
            if (due > 0) {
                withdraw(payable(empAddr), due);
                e.lastPaid = nowTs;
                e.totalPaid += due;
                emit Payment(empAddr, due, nowTs);
            }
        }
        emit PayrollRun(msg.sender, nowTs);
    }

    // --- View Functions ---

    /// @notice Get basic info for an employee
    /// @param emp Address of the employee
    /// @return exists Whether registered
    /// @return rate Salary per 30-day period
    /// @return lastPaid Timestamp of last payment
    /// @return totalPaid Cumulative salary paid
    function getEmployeeInfo(address emp) public view returns (
        bool exists,
        uint256 rate,
        uint256 lastPaid,
        uint256 totalPaid
    ) {
        Employee memory e = employees[emp];
        return (e.exists, e.rate, e.lastPaid, e.totalPaid);
    }

    /// @notice List all registered employees
    /// @return Array of employee addresses
    function listEmployees() public view returns (address[] memory) {
        return employeeList;
    }
}

```

## Note from Senior

- thống nhất các đặt tên field

- lưu ý thứ tự cột nào nên để đầu và cột nào để cuối: status nên để cuối và để cuối với những field không quan trọng

- e-wallet phải hash

- password phải thêm salt

- 500 employee thì bao lâu họ nhận dc tiền

- nếu có sẵn hệ thống ql nhân viên rồi, h a sẽ tích hợp hệ thống e ntn

- nếu có sai xót trong quá trình phát lương thì tụi e có giải pháp gì ko => do blockchain là không thay đổi => câu này tụi e tìm hiểu thêm các công ty web3 hay DAO
