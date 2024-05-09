// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ConfirmationLetter is ERC721, Ownable(msg.sender) {
    
    struct Token {
        address auditee;
        address auditor;
        address confirmationRecipient;
        string auditeeInput;
        string auditorInput;
        string recipientResponse;
        bool confirmed;
    }

    uint256 public tokenIdCounter;
    mapping(uint256 => Token) private tokens;
    mapping(address => bool) private admins;
    mapping(address => bool) private auditors;
    mapping(address => bool) private auditees;
    mapping(address => bool) private confirmationRecipients;

    event ConfirmationDrafted(
        uint256 tokenId,
        address auditee
    );

    event ConfirmationRequested(
        uint256 tokenId,
        address auditor
    );
    event ConfirmationResponded(
        uint256 tokenId,
        address confirmationRecipient
    );

    constructor() ERC721("ConfirmationLetterToken", "CLT") {
        admins[msg.sender] = true;
    }

    modifier onlyAdmin() {
        require(admins[msg.sender], "Only admin can perform this operation");
        _;
    }

    modifier onlyAuditor() {
        require(
            auditors[msg.sender],
            "Only auditor can perform this operation"
        );
        _;
    }

    modifier onlyConfirmationRecipient() {
        require(
            confirmationRecipients[msg.sender],
            "Only confirmation recipient can perform this operation"
        );
        _;
    }

    function addAuditor(address auditor) external onlyAdmin {
        auditors[auditor] = true;
    }

    function addAuditee(address auditee) external onlyAuditor {
        auditees[auditee] = true;
    }

    function addConfirmationRecipient(address recipient) external {
        require(
            auditors[msg.sender] || admins[msg.sender],
            "Only admin or auditor can add confirmation recipient"
        );
        confirmationRecipients[recipient] = true;
    }

    function DraftConfirmation(
        address auditee,
        address auditor,
        address confirmationRecipient,
        string memory auditeeInput
    ) external {
        require(
            auditees[msg.sender],
            "Only auditees can mint tokens"
        );

        uint256 tokenId = tokenIdCounter;
        _safeMint(auditor, tokenId);
        tokenIdCounter++;

        tokens[tokenId] = Token(
            auditee,
            auditor,
            confirmationRecipient,
            auditeeInput,
            '',
            '',
            false
        );

        emit ConfirmationDrafted(tokenId, msg.sender);
    }

    function AuditorInput(
        uint256 tokenId,
        address confirmationRecipient,
        string memory auditorInput
    ) external onlyAuditor {
        require(ownerOf(tokenId) == msg.sender, "Only auditor as token owner can provide auditor signature");
        tokens[tokenId].auditorInput = auditorInput;
        emit ConfirmationRequested(tokenId, msg.sender);

        _transfer(ownerOf(tokenId), confirmationRecipient, tokenId);
    }

    function Response(uint256 tokenId, address auditor, string memory recipientResponse)
        external
        onlyConfirmationRecipient
    {
        require(ownerOf(tokenId) == msg.sender, "Only recipient as token owner can confirm");
        tokens[tokenId].recipientResponse = recipientResponse;
        tokens[tokenId].confirmed = true;

        emit ConfirmationResponded(tokenId, msg.sender);

        _transfer(ownerOf(tokenId), auditor, tokenId);
    }

    function getConfItem(uint256 tokenId)
        external
        view
        returns (string memory)
    {
        require(ownerOf(tokenId) == msg.sender, "Only token owner can get financial input of auditee");
        return tokens[tokenId].auditeeInput;
    }

    function getAuditorInput(uint256 tokenId)
        external
        onlyConfirmationRecipient
        view
        returns (string memory)
    {
        require(ownerOf(tokenId) == msg.sender, "Only designated recipient can get input of auditor");
        return tokens[tokenId].auditorInput;
    }

    function getRecipientResponse(uint256 tokenId)
        external
        onlyAuditor
        view
        returns (string memory)
    {
        require(ownerOf(tokenId) == msg.sender, "Only designated auditor can get response of confirmation recipient");
        return tokens[tokenId].recipientResponse;
    }
   
}