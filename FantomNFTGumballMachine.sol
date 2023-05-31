// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./MyToken.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


contract FantomNFTGumballMachine is ERC721, Pausable, ReentrancyGuard,Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    string public baseTokenURI;

    // Immutable variables
    address  _tokenAddress;
    uint256  _price;
    uint256  _maxSupply;
    MyToken token; 

    // Withdrawal period in seconds
    uint256 public withdrawalPeriod = 60 days;

    event GumballBought(address User,uint TokenID);
    event Withdrawal(address Owner,uint256 Balance);
    event PriceChanged(uint256 NewPrice);
    event TokenAddressChanged(address TokenAdd);

    constructor(address tokenAddress, uint256 price, uint256 maxSupply) ERC721("Fantom NFT Gumball Machine", "FNGM") {
        _tokenAddress = tokenAddress;
        _price = price;
        _maxSupply = maxSupply;
        token = MyToken(tokenAddress);
    }

    function buyGumball() external payable  whenNotPaused nonReentrant {
        require(token.balanceOf(msg.sender) >= _price, "Not enough tokens to buy a gumball");
        token.transferFrom(msg.sender, address(this), _price);
        _mint(msg.sender, _tokenIdCounter.current());
        _tokenIdCounter.increment();
        emit GumballBought(msg.sender, _tokenIdCounter.current());
    }

    function MyToken_approve(address _spender) public {
        token.approve(_spender, _price);
    }

    function withdraw() external onlyOwner nonReentrant {
        require(block.timestamp > withdrawalPeriod, "Withdrawal not allowed yet");
        uint256 balance =token.balanceOf(address(this));
        token.transfer(owner(), balance);
        emit Withdrawal(owner(), balance);
    }

    function setBaseTokenURI(string memory _baseTokenURI1) public {
        baseTokenURI = _baseTokenURI1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    // function _baseURI() internal view virtual override returns (string memory) {
    //     return 'https://api.example.com/nft/';
    // }

    function setPrice(uint256 newPrice) external onlyOwner {
        _price = newPrice;
        emit PriceChanged(newPrice);
    }

    function setTokenAddress(address newTokenAddress) external onlyOwner {
        _tokenAddress = newTokenAddress;
        emit TokenAddressChanged(newTokenAddress);
    }

    function togglePause() external onlyOwner {
        if (paused()) {
            _unpause();
            emit Unpaused(msg.sender);
        } else {
            _pause();
            emit Paused(msg.sender);
        }
    }

    function mintGumball() external onlyOwner {
        require(_tokenIdCounter.current() < _maxSupply, "Max supply reached");
        _mint(msg.sender, _tokenIdCounter.current());
        _tokenIdCounter.increment();
    }
}
