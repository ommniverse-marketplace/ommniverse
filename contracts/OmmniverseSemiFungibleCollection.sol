// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract OmmniverseSemiFungibleCollection is
    Initializable,
    ERC1155Upgradeable,
    OwnableUpgradeable,
    ERC1155BurnableUpgradeable,
    ERC1155SupplyUpgradeable
{
    uint256 public currentTokenId;
    string public name;
    string public symbol;
    address public ommi;
    // Fee receivers
    address primaryReceiver;
    address secondaryReceiver;

    struct TokenInfo {
        uint256 maxSupply; // Maximum supply
        string uri; // URI
        uint256 price; // Price
        bool initialized; // Flag to check if tokenId has been initialized
    }

    mapping(uint256 => TokenInfo) public tokenInfos;
    mapping(uint256 => uint256) private totalSupplies;

    event TokenInitialized(
        uint256 indexed tokenId,
        uint256 maxSupply,
        uint256 price,
        string uri
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        string memory _name,
        string memory _symbol,
        address _ommi,
        address _primaryReceiver,
        address _secondaryReceiver
    ) public initializer {
        name = _name;
        symbol = _symbol;
        ommi = _ommi;
        primaryReceiver = _primaryReceiver;
        secondaryReceiver = _secondaryReceiver;
        __ERC1155_init("");
        __Ownable_init();
        __ERC1155Burnable_init();
        __ERC1155Supply_init();
    }

    function initToken(
        uint256 _maxSupply,
        uint256 _price,
        string memory _uri
    ) public onlyOwner {
        currentTokenId++;
        require(
            !tokenInfos[currentTokenId].initialized,
            "Token already initialized"
        );

        // Store token info
        tokenInfos[currentTokenId] = TokenInfo({
            maxSupply: _maxSupply,
            uri: _uri,
            price: _price,
            initialized: true
        });
        emit TokenInitialized(currentTokenId, _maxSupply, _price, _uri);
    }

    function mint(uint256 _tokenId, uint256 _amount) public {
        require(tokenInfos[_tokenId].initialized, "Token not initialized");
        require(
            totalSupplies[_tokenId] + _amount <= tokenInfos[_tokenId].maxSupply,
            "Exceeds max supply"
        );
        uint256 transferAmount = tokenInfos[_tokenId].price * _amount;
        uint256 primaryAmount = (transferAmount * 90) / 100;
        uint256 secondaryAmount = transferAmount - primaryAmount;
        IERC20Upgradeable(ommi).transferFrom(
            msg.sender,
            address(this),
            transferAmount
        );
        // Send token to primary receiver addresses
        IERC20Upgradeable(ommi).transfer(primaryReceiver, primaryAmount);
        // Send token to secondary receiver addresses
        IERC20Upgradeable(ommi).transfer(secondaryReceiver, secondaryAmount);
        totalSupplies[_tokenId] += _amount;
        _mint(msg.sender, _tokenId, _amount, "");
    }

    function updateTokenUri(
        uint256 _tokenId,
        string memory _uri
    ) public onlyOwner {
        require(tokenInfos[_tokenId].initialized, "Token not initialized");
        // Set the URI for the specified token ID
        tokenInfos[_tokenId].uri = _uri;
        // Emit an event to indicate that the URI has been updated for the specified token ID
        emit URI(_uri, _tokenId);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155Upgradeable, ERC1155SupplyUpgradeable) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function uri(
        uint256 _tokenId
    ) public view override returns (string memory) {
        require(tokenInfos[_tokenId].initialized, "Token not initialized");
        return tokenInfos[_tokenId].uri;
    }
}
