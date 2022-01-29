//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Vanity
contract Vanity is Ownable {

    /// @dev safemath library
    using SafeMath for uint256;

    string[] public names;
    
    /// @dev specified mappings of this contract
    mapping (string => address) public nameOwner;
    mapping (string => uint) public startTime;
    mapping (address => string[]) public namelist;

    /// @notice name's lock time
    uint public lockTime;

    /// @notice nameFee related to name length
    uint public nameFeeRate;

    /// @notice locking amount value
    uint public lockAmount;
    
    /// @dev Contract events
    event registered(string name, uint nameFee);
    event unregistered(string name);

    // Set ownership of the name
    modifier ownerOf(string memory _name) {
        require(nameOwner[_name] == msg.sender, "You don't have ownership of this name.");
        _;
    }

    /// @notice this contract constructor
    /// @param _locktime is name's lock time
    /// @param _nameFeeRate is platform fee related to name length
    constructor(uint _locktime, uint _nameFeeRate) {
         lockTime = _locktime;
         nameFeeRate = _nameFeeRate;
    }

    /**
    @notice function to register name
    @param _name is user's unique vanity name
    */
    function register(string memory _name) public payable {
        require(nameOwner[_name] == address(0), "Duplicate names.");
        uint256 nameFee = bytes(_name).length.mul(nameFeeRate);

        require(msg.sender.balance > nameFee, "Insufficient name fee.");
        (bool sent, bytes memory data) = address(this).call{value: msg.value + nameFee}("");
        require(sent, "Failed to send Ether");
        lockAmount = msg.value;

        names.push(_name);
        nameOwner[_name] = msg.sender;
        startTime[_name] = block.timestamp;
        namelist[msg.sender].push(_name);

        // emit registered event
        emit registered(_name, nameFee);
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}

    /**
    @notice function to unregister name
    @param _name is user's unique vanity name
    */
    function unregister(string memory _name) public ownerOf(_name) {
        require(startTime[_name].add(lockTime) >= block.timestamp, "It's not expired time.");

        (bool sent, bytes memory data) = msg.sender.call{value: lockAmount}("");
        require(sent, "Failed to send Ether");

        uint namesMatched;
        for (uint id = 0; id < names.length; id++) {
            if (keccak256(bytes(names[id])) == keccak256(bytes(_name))) {
                _removeName(id);
                namesMatched = namesMatched.add(1);
            }
        }
        require(namesMatched == 1, "There are no matches.");

        uint namelistMatched;
        for (uint id = 0; id < namelist[msg.sender].length; id++) {
            if (keccak256(bytes(namelist[msg.sender][id])) == keccak256(bytes(_name))) {
                _removeName(id);
                namelistMatched = namelistMatched.add(1);
            }
        }
        require(namelistMatched == 1, "There are no matches.");

        nameOwner[_name] = address(0);

        // emit unregistered event
        emit unregistered(_name);
    }

    /**
    @notice function to remove name
    @param _id is index of names array
    */
    function _removeName(uint _id) internal {
        for (uint i = _id; i < names.length - 1; i++) {
            names[i] = names[i+1];
        }

        names.pop();
    }

    /// @notice function to modify lock time and name fee rate
    /// @param _locktime is name's lock time
    /// @param _nameFeeRate is platform fee related to name length
    function _modifyFeature(uint _locktime, uint _nameFeeRate) internal onlyOwner {
        lockTime = _locktime;
        nameFeeRate = _nameFeeRate;
    }

    /// @notice function to get this contract balance
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    /// @notice function to get total of name number
    function getTotalNameNum() public view returns (uint) {
        return names.length;
    }

    /// @notice function to get name number of address
    /// @param _owner is name owner's address
    function getNameNum(address _owner) public view returns (uint) {
        return namelist[_owner].length;
    }

}
