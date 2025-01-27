# Vesta Insurance Smart Contract

A decentralized peer-to-peer insurance platform built on the Stacks blockchain using Clarity smart contracts.

## Overview

Vesta is a trustless insurance protocol that enables:
- Decentralized insurance pools with automated premium collection
- Transparent claim filing and processing
- Emergency control mechanisms for risk management
- Comprehensive event tracking and reporting

## Features

### Core Insurance Features
- Premium payments and fund pooling
- Claim filing and processing
- Automated claim validation
- Fund withdrawal mechanisms
- Event tracking and reporting

### Administrative Controls
- Contract pause/unpause functionality
- Individual function pause mechanisms
- Premium rate management
- Claim threshold updates
- Admin rights transfer

### Security Features
- Function-level pause controls
- Admin-only privileged operations
- Balance and claim amount validations
- Emergency shutdown capability

## Smart Contract Functions

### User Operations

#### Premium Management
```clarity
(define-public (pay-premium))
```
Allows users to pay their insurance premium and join the pool. The premium rate is configurable by the admin.

#### Claims
```clarity
(define-public (file-claim (amount uint)))
```
Enables users to file insurance claims. Claims must meet the minimum threshold and cannot exceed the user's balance.

#### Fund Management
```clarity
(define-public (withdraw-funds (amount uint)))
```
Permits users to withdraw available funds from their balance in the insurance pool.

### Administrative Functions

#### Contract Control
```clarity
(define-public (pause-contract))
(define-public (unpause-contract))
```
Emergency controls to pause/unpause the entire contract.

#### Function Control
```clarity
(define-public (pause-function (function-name (string-ascii 24))))
(define-public (unpause-function (function-name (string-ascii 24))))
```
Granular control over individual contract functions.

#### Claim Processing
```clarity
(define-public (approve-claim (user principal)))
(define-public (reject-claim (user principal)))
```
Admin functions for processing insurance claims.

#### Configuration
```clarity
(define-public (update-premium-rate (new-rate uint)))
(define-public (update-claim-threshold (new-threshold uint)))
```
Functions to update premium rates and claim thresholds.

### Read-Only Functions

```clarity
(define-read-only (get-balance (user principal)))
(define-read-only (get-total-funds))
(define-read-only (get-event (user principal)))
(define-read-only (get-premium-rate))
(define-read-only (get-claim-threshold))
(define-read-only (get-admin-address))
(define-read-only (is-user-registered (user principal)))
(define-read-only (is-contract-paused))
(define-read-only (is-function-paused (function-name (string-ascii 24))))
```

## Data Structures

### State Variables
```clarity
(define-data-var total-funds uint u0)
(define-data-var premium-rate uint u100)
(define-data-var claim-threshold uint u500)
(define-data-var admin-address principal 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
(define-data-var contract-paused bool false)
```

### Maps
```clarity
(define-map balances principal uint)
(define-map claims principal uint)
(define-map user-registry principal bool)
(define-map events principal (tuple (event-type (string-ascii 24)) (amount uint)))
(define-map paused-functions (string-ascii 24) bool)
```

## Event System

The contract includes a comprehensive event tracking system that logs:
- Premium payments
- Claim filing
- Claim approvals/rejections
- Fund withdrawals
- Administrative actions
- Contract state changes

## Security Considerations

### Access Control
- Admin-only functions are protected with principal checks
- Function-level pause mechanisms
- Contract-wide pause capability

### Validation
- Amount validation for all financial operations
- Balance checks before withdrawals
- Claim threshold enforcement
- Admin address validation

## Development Setup

1. Install the Clarity CLI:
```bash
npm install -g @stacks/cli
```

2. Clone the repository:
```bash
git clone https://github.com/your-org/vesta-insurance
cd vesta-insurance
```

3. Deploy the contract:
```bash
clarinet contract-deploy vesta-insurance.clar
```

## Testing

The contract can be tested using Clarinet:
```bash
clarinet test
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request


