// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

contract OmmniverseNonFungibleCollection is
    Initializable,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    ERC721BurnableUpgradeable,
    OwnableUpgradeable
{
    uint256 public currentTokenId;
    address public ommi;
    // Fee receivers
    address primaryReceiver;
    address secondaryReceiver;

    struct TokenInfo {
        string uri;
        uint256 price; // Price
        bool initialized; // Flag to check if tokenId has been initialized
    }
    mapping(uint256 => TokenInfo) public tokenInfos;

    event TokenInitialized(uint256 indexed tokenId, uint256 price, string uri);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        string memory name,
        string memory symbol,
        address _ommi,
        address _primaryReceiver,
        address _secondaryReceiver
    ) public initializer {
        __ERC721_init(name, symbol);
        ommi = _ommi;
        primaryReceiver = _primaryReceiver;
        secondaryReceiver = _secondaryReceiver;
        __ERC721Enumerable_init();
        __ERC721Burnable_init();
        __Ownable_init();
    }

    function initToken(uint256 _price, string memory _uri) public onlyOwner {
        currentTokenId++;
        require(
            !tokenInfos[currentTokenId].initialized,
            "Token already initialized"
        );

        // Store token info
        tokenInfos[currentTokenId] = TokenInfo({
            uri: _uri,
            price: _price,
            initialized: true
        });

        emit TokenInitialized(currentTokenId, _price, _uri);
    }

    function mint(uint256 _tokenId) public {
        require(tokenInfos[_tokenId].initialized, "Token not initialized");
        uint256 transferAmount = tokenInfos[_tokenId].price;
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
        _safeMint(msg.sender, _tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _burn(uint256 tokenId) internal override(ERC721Upgradeable) {
        super._burn(tokenId);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721Upgradeable) returns (string memory) {
        require(tokenInfos[tokenId].initialized, "Token not initialized");
        return tokenInfos[tokenId].uri;
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
