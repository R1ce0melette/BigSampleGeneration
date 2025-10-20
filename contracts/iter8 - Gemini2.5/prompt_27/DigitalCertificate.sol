// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IERC721Receiver
 * @dev Interface for any contract that wants to support safeTransfers from ERC721 asset contracts.
 */
interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

/**
 * @title DigitalCertificate
 * @dev A self-contained ERC721-like contract for minting digital certificates.
 * This implementation includes core ERC721 functionalities for demonstration purposes.
 */
contract DigitalCertificate {
    // State variables
    string public name;
    string public symbol;
    address public owner;

    uint256 private _tokenIdCounter;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Mapping from token ID to metadata URI
    mapping(uint256 => string) private _tokenURIs;

    // Events
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function.");
        _;
    }

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
        owner = msg.sender;
    }

    /**
     * @dev Mints a new digital certificate and assigns it to a recipient.
     * @param _recipient The address that will receive the minted certificate.
     * @param _tokenURI The URI for the certificate's metadata.
     * @return The ID of the newly minted token.
     */
    function mintCertificate(address _recipient, string memory _tokenURI) external onlyOwner returns (uint256) {
        require(_recipient != address(0), "ERC721: mint to the zero address");

        _tokenIdCounter++;
        uint256 newTokenId = _tokenIdCounter;

        _owners[newTokenId] = _recipient;
        _balances[_recipient]++;
        _tokenURIs[newTokenId] = _tokenURI;

        emit Transfer(address(0), _recipient, newTokenId);
        return newTokenId;
    }

    function tokenURI(uint256 _tokenId) public view returns (string memory) {
        require(_exists(_tokenId), "ERC721: URI query for nonexistent token");
        return _tokenURIs[_tokenId];
    }

    function ownerOf(uint256 _tokenId) public view returns (address) {
        address ownerAddress = _owners[_tokenId];
        require(ownerAddress != address(0), "ERC721: owner query for nonexistent token");
        return ownerAddress;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        require(_owner != address(0), "ERC721: balance query for the zero address");
        return _balances[_owner];
    }

    function approve(address _to, uint256 _tokenId) public {
        address ownerAddress = ownerOf(_tokenId);
        require(_to != ownerAddress, "ERC721: approval to current owner");
        require(msg.sender == ownerAddress || isApprovedForAll(ownerAddress, msg.sender), "ERC721: approve caller is not owner nor approved for all");
        _tokenApprovals[_tokenId] = _to;
        emit Approval(ownerAddress, _to, _tokenId);
    }

    function getApproved(uint256 _tokenId) public view returns (address) {
        require(_exists(_tokenId), "ERC721: approved query for nonexistent token");
        return _tokenApprovals[_tokenId];
    }

    function setApprovalForAll(address _operator, bool _approved) public {
        require(_operator != msg.sender, "ERC721: approve to caller");
        _operatorApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
        return _operatorApprovals[_owner][_operator];
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) public {
        require(isApprovedOrOwner(msg.sender, _tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(_from, _to, _tokenId);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public {
        safeTransferFrom(_from, _to, _tokenId, "");
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) public {
        require(isApprovedOrOwner(msg.sender, _tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(_from, _to, _tokenId, _data);
    }

    // Internal functions
    function _exists(uint256 _tokenId) internal view returns (bool) {
        return _owners[_tokenId] != address(0);
    }

    function isApprovedOrOwner(address _spender, uint256 _tokenId) internal view returns (bool) {
        address ownerAddress = ownerOf(_tokenId);
        return (_spender == ownerAddress || getApproved(_tokenId) == _spender || isApprovedForAll(ownerAddress, _spender));
    }

    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        require(ownerOf(_tokenId) == _from, "ERC721: transfer of token that is not own");
        require(_to != address(0), "ERC721: transfer to the zero address");

        // Clear approvals from the previous owner
        if (getApproved(_tokenId) != address(0)) {
            _tokenApprovals[_tokenId] = address(0);
        }

        _balances[_from]--;
        _balances[_to]++;
        _owners[_tokenId] = _to;

        emit Transfer(_from, _to, _tokenId);
    }

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non-ERC721Receiver implementer");
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) private returns (bool) {
        if (to.code.length > 0) { // Is a contract
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non-ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else { // Is a regular address
            return true;
        }
    }
}
