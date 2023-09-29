// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./SemiFungibleCollection.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract CollectionFactory is Initializable, OwnableUpgradeable {
    address private semiFungibleBeacon;
    address[] public collections;
    address public ommi;
    // Here 100 = 1%
    uint256 public platformFee;
    address public platformFeeReceiver;
    mapping(address => address) public collectionDetails;

    // Event for new collection
    event NewCollectionCreated(
        uint256 colletionIndex,
        address indexed collectionAddress,
        string _name,
        string _symbol
    );

    function initialize(
        address _semiFungibleBeacon,
        uint256 _platformFee,
        address _ommi,
        address _platformFeeReceiver
    ) external initializer {
        semiFungibleBeacon = _semiFungibleBeacon;
        ommi = _ommi;
        platformFee = _platformFee;
        platformFeeReceiver = _platformFeeReceiver;
        __Ownable_init();
    }

    function createCollection(
        string memory _name,
        string memory _symbol
    ) external {
        address newCollection = address(
            new BeaconProxy(
                semiFungibleBeacon,
                abi.encodeWithSelector(
                    SemiFungibleCollection.initialize.selector,
                    _name,
                    _symbol,
                    ommi,
                    platformFee,
                    platformFeeReceiver
                )
            )
        );
        SemiFungibleCollection(newCollection).transferOwnership(msg.sender);
        collectionDetails[newCollection] = msg.sender;
        collections.push(newCollection);
        emit NewCollectionCreated(
            collections.length - 1,
            newCollection,
            _name,
            _symbol
        );
    }

    function updateFee(uint256 _newfee) public onlyOwner {
        platformFee = _newfee;
    }

    function getAllCollections() public view returns (address[] memory) {
        return collections;
    }
}
