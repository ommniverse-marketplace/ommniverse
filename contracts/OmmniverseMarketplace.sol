// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract OmmniverseMarketplace is ERC721Holder, ERC1155Holder, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    uint256 public platformFee;
    uint256 public listingId;
    address public platformFeeRecipient;
    uint256 constant MAX_ROYALTY_PERCENT = 50;
    IERC20 public OmmiToken;

    enum TokenStandard {
        ERC721,
        ERC1155
    }

    struct Collection {
        bool isEligibile;
        TokenStandard nftType;
        uint256 royalty;
        address royaltyReceiver;
    }

    struct NftListing {
        address contractAddress;
        TokenStandard nftType;
        uint256 tokenId;
        uint256 quantity;
        address seller;
        uint256 price;
        bool isActive;
        bool sold;
        uint256 listingId;
    }

    mapping(address => Collection) public approvedCollections;
    mapping(uint256 => NftListing) public listings;

    modifier validRoyalty(uint256 _royalty) {
        require(_royalty <= MAX_ROYALTY_PERCENT, "Royalty too high");
        _;
    }

    constructor(
        address _platformFeeRecipient,
        uint256 _platformFeePercent,
        address _ommi
    ) {
        platformFeeRecipient = _platformFeeRecipient;
        platformFee = _platformFeePercent;
        OmmiToken = IERC20(_ommi);
    }

    event NFTListed(
        address indexed contractAddress,
        address indexed seller,
        uint256 indexed listingId,
        uint256 tokenId,
        uint256 quantity,
        uint256 price
    );
    event NFTSold(
        uint256 indexed listingId,
        address indexed seller,
        address indexed buyer,
        address contractAddress,
        uint256 tokenId,
        uint256 quantity,
        uint256 price
    );

    event UpdatedApprovedCollections(
        address indexed collection,
        address indexed royaltyReceiver,
        bool indexed eligibility,
        uint256 royalty
    );

    event ListingCancelled(
        uint256 indexed listingId,
        address indexed nftContract,
        uint256 indexed tokenId
    );

    event ListingPriceChanged(
        uint256 indexed listingId,
        uint256 indexed oldPrice,
        uint256 indexed newPrice
    );

    event PlatformFeePercentageUpdated(
        uint256 oldPercentage,
        uint256 newPercentage
    );

    event PlatformFeeRecipientUpdated(
        address oldRecipient,
        address newRecipient
    );

    function updateListingPrice(uint256 _listingId, uint256 _price) public {
        require(_listingId > 0, "Invalid listingId");
        NftListing storage listing = listings[_listingId];
        require(msg.sender == listing.seller, "not seller");
        require(!listing.sold, "already sold");
        require(listing.isActive, "listing is not active");
        uint256 oldPrice = listing.price;
        listing.price = _price;
        emit ListingPriceChanged(listing.listingId, oldPrice, _price);
    }

    function cancelListing(uint256 _listingId) public {
        require(listings[_listingId].seller == msg.sender, "not owner");
        require(listings[_listingId].isActive, "listing not active");

        listings[_listingId].isActive = false;

        if (
            approvedCollections[listings[_listingId].contractAddress].nftType ==
            TokenStandard.ERC721
        ) {
            IERC721(listings[_listingId].contractAddress).safeTransferFrom(
                address(this),
                msg.sender,
                listings[_listingId].tokenId
            );
        } else if (
            approvedCollections[listings[_listingId].contractAddress].nftType ==
            TokenStandard.ERC1155
        ) {
            IERC1155(listings[_listingId].contractAddress).safeTransferFrom(
                address(this),
                msg.sender,
                listings[_listingId].tokenId,
                listings[_listingId].quantity,
                ""
            );
        }

        emit ListingCancelled(
            _listingId,
            listings[_listingId].contractAddress,
            listings[_listingId].tokenId
        );
    }

    function buyNFT(uint256 _listingId) public {
        require(listings[_listingId].isActive, "listing not active");
        require(!listings[_listingId].sold, "already sold");
        require(
            msg.sender != listings[_listingId].seller,
            "can't buy your own NFT"
        );
        uint256 nftPrice = listings[_listingId].price;
        require(
            OmmiToken.balanceOf(msg.sender) >= nftPrice,
            "insuffecient balance"
        );
        OmmiToken.safeTransferFrom(msg.sender, address(this), nftPrice);

        address seller = listings[_listingId].seller;
        uint256 royalty = nftPrice
            .mul(
                approvedCollections[listings[_listingId].contractAddress]
                    .royalty
            )
            .div(100);
        uint256 platformFeeToken = nftPrice.mul(platformFee).div(100);
        uint256 sellerPayout = nftPrice.sub(royalty).sub(platformFeeToken);

        listings[_listingId].isActive = false;
        listings[_listingId].sold = true;
        if (
            approvedCollections[listings[_listingId].contractAddress].nftType ==
            TokenStandard.ERC721
        ) {
            IERC721(listings[_listingId].contractAddress).safeTransferFrom(
                address(this),
                msg.sender,
                listings[_listingId].tokenId
            );
        } else if (
            approvedCollections[listings[_listingId].contractAddress].nftType ==
            TokenStandard.ERC1155
        ) {
            IERC1155(listings[_listingId].contractAddress).safeTransferFrom(
                address(this),
                msg.sender,
                listings[_listingId].tokenId,
                listings[_listingId].quantity,
                ""
            );
        } else {
            revert("wrong address");
        }
        OmmiToken.safeTransfer(
            approvedCollections[listings[_listingId].contractAddress]
                .royaltyReceiver,
            royalty
        );
        OmmiToken.safeTransfer(platformFeeRecipient, platformFeeToken);
        OmmiToken.safeTransfer(seller, sellerPayout);

        emit NFTSold(
            _listingId,
            seller,
            msg.sender,
            listings[_listingId].contractAddress,
            listings[_listingId].tokenId,
            listings[_listingId].quantity,
            listings[_listingId].price
        );
    }

    function listNFT(
        address _contractAddress,
        uint256 _tokenId,
        uint256 _quantity,
        uint256 _price
    ) public {
        require(
            approvedCollections[_contractAddress].isEligibile,
            "Collection not eligible"
        );
        require(_price > 0, "Price must be > 0");
        uint256 listingQuantity;
        if (
            approvedCollections[_contractAddress].nftType ==
            TokenStandard.ERC721
        ) {
            require(
                IERC721(_contractAddress).ownerOf(_tokenId) == msg.sender,
                "Not owner"
            );
            require(
                IERC721(_contractAddress).getApproved(_tokenId) ==
                    address(this),
                "Marketplace not approved"
            );
            listingQuantity = 1;

            IERC721(_contractAddress).safeTransferFrom(
                msg.sender,
                address(this),
                _tokenId
            );
        } else if (
            approvedCollections[_contractAddress].nftType ==
            TokenStandard.ERC1155
        ) {
            require(
                IERC1155(_contractAddress).balanceOf(msg.sender, _tokenId) >=
                    _quantity,
                "Not enough tokens"
            );
            require(
                IERC1155(_contractAddress).isApprovedForAll(
                    msg.sender,
                    address(this)
                ),
                "Marketplace not approved"
            );
            listingQuantity = _quantity;
            IERC1155(_contractAddress).safeTransferFrom(
                msg.sender,
                address(this),
                _tokenId,
                _quantity,
                ""
            );
        } else {
            revert("wrong address");
        }
        listingId += 1;

        listings[listingId] = NftListing({
            contractAddress: _contractAddress,
            nftType: approvedCollections[_contractAddress].nftType,
            tokenId: _tokenId,
            quantity: listingQuantity,
            seller: msg.sender,
            price: _price,
            isActive: true,
            sold: false,
            listingId: listingId
        });
        emit NFTListed(
            _contractAddress,
            msg.sender,
            listingId,
            _tokenId,
            _quantity,
            _price
        );
    }

    function updateApprovedCollections(
        address _collectionAddress,
        bool _eligibility,
        uint256 _royalty,
        address _royaltyReceiver
    ) public onlyOwner validRoyalty(_royalty) {
        require(_collectionAddress != address(0), "Invalid collection address");
        require(isContract(_collectionAddress), "wrong address");
        if (
            IERC165(_collectionAddress).supportsInterface(
                type(IERC721).interfaceId
            )
        ) {
            approvedCollections[_collectionAddress] = Collection({
                isEligibile: _eligibility,
                nftType: TokenStandard.ERC721,
                royalty: _royalty,
                royaltyReceiver: _royaltyReceiver
            });
        } else if (
            IERC165(_collectionAddress).supportsInterface(
                type(IERC1155).interfaceId
            )
        ) {
            approvedCollections[_collectionAddress] = Collection({
                isEligibile: _eligibility,
                nftType: TokenStandard.ERC1155,
                royalty: _royalty,
                royaltyReceiver: _royaltyReceiver
            });
        } else {
            revert("wrong address");
        }

        emit UpdatedApprovedCollections(
            _collectionAddress,
            _royaltyReceiver,
            _eligibility,
            _royalty
        );
    }

    function updatePlatformFeePercentage(
        uint256 _newPlatformFeePercentage
    ) public onlyOwner {
        uint256 oldPercentage = platformFee;
        platformFee = _newPlatformFeePercentage;
        emit PlatformFeePercentageUpdated(
            oldPercentage,
            _newPlatformFeePercentage
        );
    }

    function updatePlatformFeeRecepient(
        address _newPlatformFeeRecepient
    ) public onlyOwner {
        address oldRecipient = platformFeeRecipient;
        platformFeeRecipient = _newPlatformFeeRecepient;
        emit PlatformFeeRecipientUpdated(
            oldRecipient,
            _newPlatformFeeRecepient
        );
    }

    function isContract(address _address) public view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_address)
        }
        return size > 0;
    }

    function withdrawStuckTokens(
        address _token,
        uint256 _amount
    ) public onlyOwner {
        IERC20(_token).safeTransfer(msg.sender, _amount);
    }
}
