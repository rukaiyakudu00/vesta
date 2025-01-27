;; Vesta Insurance Smart Contract
;; A decentralized peer-to-peer insurance platform

;; Define data structures
(define-data-var total-funds uint u0) ;; Total funds in the insurance pool
(define-data-var premium-rate uint u100) ;; Premium rate (e.g., 100 microSTX per coverage)
(define-data-var claim-threshold uint u500) ;; Minimum claim amount
(define-data-var admin-address principal 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM) ;; Admin address

;; Emergency control variables
(define-data-var contract-paused bool false) ;; Global pause switch
(define-map paused-functions (string-ascii 24) bool) ;; Individual function pause states

;; Define user balances and tracking
(define-map balances principal uint) ;; User balances in the pool
(define-map claims principal uint) ;; User claims
(define-map user-registry principal bool) ;; Registry to track users instead of a list

;; Define events using a map
(define-map events principal (tuple (event-type (string-ascii 24)) (amount uint)))

;; Helper function to check if operation is allowed
(define-private (can-operate (function-name (string-ascii 24)))
  (and 
    (not (var-get contract-paused))
    (not (default-to false (map-get? paused-functions function-name)))
  )
)

;; Helper function to validate function names
(define-private (is-valid-function (function-name (string-ascii 24)))
  (or 
    (is-eq function-name "pay-premium")
    (is-eq function-name "file-claim")
    (is-eq function-name "approve-claim")
    (is-eq function-name "reject-claim")
    (is-eq function-name "withdraw-funds")
    (is-eq function-name "update-premium")
    (is-eq function-name "update-threshold")
    (is-eq function-name "transfer-admin")
  )
)

;; Emergency pause/unpause functions
(define-public (pause-contract)
  (begin
    (asserts! (is-eq tx-sender (var-get admin-address)) (err "Only admin can pause contract"))
    (var-set contract-paused true)
    (map-set events tx-sender (tuple (event-type "ContractPaused") (amount u0)))
    (ok true)
  )
)

(define-public (unpause-contract)
  (begin
    (asserts! (is-eq tx-sender (var-get admin-address)) (err "Only admin can unpause contract"))
    (var-set contract-paused false)
    (map-set events tx-sender (tuple (event-type "ContractUnpaused") (amount u0)))
    (ok true)
  )
)

(define-public (pause-function (function-name (string-ascii 24)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin-address)) (err "Only admin can pause functions"))
    (asserts! (is-valid-function function-name) (err "Invalid function name"))
    (map-set paused-functions function-name true)
    (map-set events tx-sender (tuple (event-type "FunctionPaused") (amount u0)))
    (ok true)
  )
)

(define-public (unpause-function (function-name (string-ascii 24)))
  (begin
    (asserts! (is-eq tx-sender (var-get admin-address)) (err "Only admin can unpause functions"))
    (asserts! (is-valid-function function-name) (err "Invalid function name"))
    (map-set paused-functions function-name false)
    (map-set events tx-sender (tuple (event-type "FunctionUnpaused") (amount u0)))
    (ok true)
  )
)

;; Add funds to the insurance pool
(define-public (pay-premium)
  (begin
    (asserts! (can-operate "pay-premium") (err "Operation is paused"))
    (let ((amount (var-get premium-rate)))
      (asserts! (> amount u0) (err "Amount must be greater than 0"))
      (map-set balances tx-sender (+ (default-to u0 (map-get? balances tx-sender)) amount))
      (var-set total-funds (+ (var-get total-funds) amount))
      (map-set events tx-sender (tuple (event-type "PremiumPaid") (amount amount)))
      ;; Register user
      (map-set user-registry tx-sender true)
      (ok true)
    )
  )
)

;; File a claim
(define-public (file-claim (amount uint))
  (begin
    (asserts! (can-operate "file-claim") (err "Operation is paused"))
    (asserts! (>= amount (var-get claim-threshold)) (err "Claim amount below threshold"))
    (asserts! (<= amount (default-to u0 (map-get? balances tx-sender))) (err "Insufficient balance"))
    (map-set claims tx-sender amount)
    (map-set events tx-sender (tuple (event-type "ClaimFiled") (amount amount)))
    (ok true)
  )
)

;; Approve a claim (only an admin or oracle can call this)
(define-public (approve-claim (user principal))
  (begin
    (asserts! (can-operate "approve-claim") (err "Operation is paused"))
    (asserts! (is-eq tx-sender (var-get admin-address)) (err "Only admin can approve claims"))
    (let ((amount (default-to u0 (map-get? claims user))))
      (asserts! (> amount u0) (err "No claim found for this user"))
      (asserts! (<= amount (var-get total-funds)) (err "Insufficient funds in the pool"))
      (map-delete claims user)
      (var-set total-funds (- (var-get total-funds) amount))
      (map-set balances user (- (default-to u0 (map-get? balances user)) amount))
      (map-set events user (tuple (event-type "ClaimApproved") (amount amount)))
      (ok true)
    )
  )
)

;; Reject a claim (only an admin or oracle can call this)
(define-public (reject-claim (user principal))
  (begin
    (asserts! (can-operate "reject-claim") (err "Operation is paused"))
    (asserts! (is-eq tx-sender (var-get admin-address)) (err "Only admin can reject claims"))
    (let ((amount (default-to u0 (map-get? claims user))))
      (asserts! (> amount u0) (err "No claim found for this user"))
      (map-delete claims user)
      (map-set events user (tuple (event-type "ClaimRejected") (amount amount)))
      (ok true)
    )
  )
)

;; Withdraw funds from the insurance pool
(define-public (withdraw-funds (amount uint))
  (begin
    (asserts! (can-operate "withdraw-funds") (err "Operation is paused"))
    (let ((user-balance (default-to u0 (map-get? balances tx-sender))))
      (asserts! (> amount u0) (err "Amount must be greater than 0"))
      (asserts! (<= amount user-balance) (err "Insufficient balance"))
      (map-set balances tx-sender (- user-balance amount))
      (var-set total-funds (- (var-get total-funds) amount))
      (map-set events tx-sender (tuple (event-type "WithdrawFunds") (amount amount)))
      (ok true)
    )
  )
)

;; Update premium rate (only admin can call this)
(define-public (update-premium-rate (new-rate uint))
  (begin
    (asserts! (can-operate "update-premium") (err "Operation is paused"))
    (asserts! (is-eq tx-sender (var-get admin-address)) (err "Only admin can update premium rate"))
    (asserts! (> new-rate u0) (err "Premium rate must be greater than 0"))
    (var-set premium-rate new-rate)
    (map-set events tx-sender (tuple (event-type "PremiumRateUpdated") (amount new-rate)))
    (ok true)
  )
)

;; Update claim threshold (only admin can call this)
(define-public (update-claim-threshold (new-threshold uint))
  (begin
    (asserts! (can-operate "update-threshold") (err "Operation is paused"))
    (asserts! (is-eq tx-sender (var-get admin-address)) (err "Only admin can update claim threshold"))
    (asserts! (> new-threshold u0) (err "Claim threshold must be greater than 0"))
    (var-set claim-threshold new-threshold)
    (map-set events tx-sender (tuple (event-type "ThresholdUpdated") (amount new-threshold)))
    (ok true)
  )
)

;; Transfer admin rights (only admin can call this)
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (can-operate "transfer-admin") (err "Operation is paused"))
    (asserts! (is-eq tx-sender (var-get admin-address)) (err "Only admin can transfer admin rights"))
    ;; Add validation for new admin address
    (asserts! (not (is-eq new-admin tx-sender)) (err "Cannot transfer admin to current admin"))
    (asserts! (not (is-eq new-admin (var-get admin-address))) (err "New admin cannot be current admin"))
    (asserts! (not (is-eq new-admin 'SP000000000000000000002Q6VF78)) (err "Cannot transfer to zero address"))
    ;; Perform the transfer
    (var-set admin-address new-admin)
    (map-set events tx-sender (tuple (event-type "AdminTransferred") (amount u0)))
    (ok true)
  )
)

;; Read-only functions
(define-read-only (get-balance (user principal))
  (ok (default-to u0 (map-get? balances user)))
)

(define-read-only (get-total-funds)
  (ok (var-get total-funds))
)

(define-read-only (get-event (user principal))
  (ok (map-get? events user))
)

(define-read-only (get-premium-rate)
  (ok (var-get premium-rate))
)

(define-read-only (get-claim-threshold)
  (ok (var-get claim-threshold))
)

(define-read-only (get-admin-address)
  (ok (var-get admin-address))
)

(define-read-only (is-user-registered (user principal))
  (ok (is-some (map-get? user-registry user)))
)

;; Read-only functions for pause status
(define-read-only (is-contract-paused)
  (ok (var-get contract-paused))
)

(define-read-only (is-function-paused (function-name (string-ascii 24)))
  (ok (default-to false (map-get? paused-functions function-name)))
)