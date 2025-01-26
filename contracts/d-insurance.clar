;; Vesta Insurance Smart Contract
;; A decentralized peer-to-peer insurance platform

;; Define data structures
(define-data-var total-funds uint u0) ;; Total funds in the insurance pool
(define-data-var premium-rate uint u100) ;; Premium rate (e.g., 100 microSTX per coverage)
(define-data-var claim-threshold uint u500) ;; Minimum claim amount

;; Define user balances
(define-map balances principal uint) ;; User balances in the pool
(define-map claims principal uint) ;; User claims

;; Define events using a map
(define-map events principal (tuple (event-type (string-ascii 20)) (amount uint)))

;; Add funds to the insurance pool
(define-public (pay-premium)
  (let ((amount (var-get premium-rate)))
    (asserts! (> amount u0) (err "Amount must be greater than 0"))
    (map-set balances tx-sender (+ (default-to u0 (map-get? balances tx-sender)) amount))
    (var-set total-funds (+ (var-get total-funds) amount))
    (map-set events tx-sender (tuple (event-type "PremiumPaid") (amount amount)))
    (ok true)
  )
)

;; File a claim
(define-public (file-claim (amount uint))
  (begin
    (asserts! (>= amount (var-get claim-threshold)) (err "Claim amount below threshold"))
    (asserts! (<= amount (default-to u0 (map-get? balances tx-sender))) (err "Insufficient balance"))
    (map-set claims tx-sender amount)
    (map-set events tx-sender (tuple (event-type "ClaimFiled") (amount amount)))
    (ok true)
  )
)

;; Approve a claim (only an admin or oracle can call this)
(define-public (approve-claim (user principal))
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

;; Reject a claim (only an admin or oracle can call this)
(define-public (reject-claim (user principal))
  (let ((amount (default-to u0 (map-get? claims user))))
    (asserts! (> amount u0) (err "No claim found for this user"))
    (map-delete claims user)
    (map-set events user (tuple (event-type "ClaimRejected") (amount amount)))
    (ok true)
  )
)

;; Get user balance
(define-read-only (get-balance (user principal))
  (ok (default-to u0 (map-get? balances user)))
)

;; Get total funds in the pool
(define-read-only (get-total-funds)
  (ok (var-get total-funds))
)

;; Get event for a user
(define-read-only (get-event (user principal))
  (ok (map-get? events user))
)