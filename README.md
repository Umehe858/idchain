# IdentityChain - Decentralized Identity Verification Platform

IdentityChain is a blockchain-based identity verification system that enables secure, decentralized management of user identity status on the Stacks blockchain.

## Features

- **Decentralized Identity Verification**: Submit identity verification requests directly on-chain
- **Multi-Status Management**: Track verification through pending, approved, and rejected states
- **Secure Access Control**: Only authorized verifiers can approve or reject submissions
- **Transparent Process**: All verification events are recorded on the blockchain
- **Ownership Transfer**: Secure transfer of verification authority

## Contract Overview

The IdentityChain smart contract manages identity verification status for blockchain addresses with the following key components:

### Verification States
- `0`: Unverified (default state)
- `1`: Pending verification
- `2`: Verified and approved
- `3`: Rejected

### Core Functions

#### Public Functions
- `submit-identity-request(identity-info)`: Submit identity verification request
- `approve-identity(address)`: Approve pending identity verification (verifier-only)
- `reject-identity(address)`: Reject pending identity verification (verifier-only)
- `revoke-identity(address)`: Revoke existing verification (verifier-only)
- `change-verifier(new-verifier)`: Transfer verification authority (owner-only)

#### Read-Only Functions
- `get-identity-status(address)`: Get complete identity verification status
- `is-verifier-authority(address)`: Check if address has verification authority

## Usage

### For Users
1. Call `submit-identity-request` with your identity information
2. Wait for verifier to process your request
3. Check status using `get-identity-status`

### For Verifiers
1. Review pending identity requests
2. Use `approve-identity` or `reject-identity` to process requests
3. Use `revoke-identity` to revoke previously approved identities

## Security Features

- Input validation for all user-provided data
- Authorization checks for verifier-only functions
- Prevention of self-verification
- Secure ownership transfer mechanisms

## Deployment

Deploy the contract to Stacks blockchain using Clarinet or your preferred deployment tool.

## Error Codes

- `u100`: Unauthorized access
- `u101`: Identity already has verification status
- `u102`: Identity not found or not verified
- `u103`: Invalid verification state
- `u104`: Invalid input parameters
- `u105`: Invalid new verifier address