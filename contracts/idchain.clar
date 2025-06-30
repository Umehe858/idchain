;; IdentityChain - Decentralized Identity Verification Platform
;; Manages identity verification status for addresses

;; Error codes
(define-constant ERROR_UNAUTHORIZED u100)
(define-constant ERROR_ALREADY_HAS_STATUS u101)
(define-constant ERROR_IDENTITY_NOT_FOUND u102)
(define-constant ERROR_INVALID_STATE u103)
(define-constant ERROR_INVALID_PARAMETERS u104)
(define-constant ERROR_INVALID_VERIFIER u105)

;; Data variables
(define-data-var verifier-authority principal tx-sender)

;; Identity verification map
(define-map identity-records 
    principal 
    {
        state: uint,  ;; 0: unverified, 1: pending, 2: verified, 3: rejected
        timestamp: uint,
        identity-info: (string-utf8 500),
        authority: principal
    }
)

;; Read-only functions
(define-read-only (get-identity-status (address principal))
    (default-to 
        {
            state: u0, 
            timestamp: u0, 
            identity-info: u"", 
            authority: tx-sender
        }
        (map-get? identity-records address)
    )
)

(define-read-only (is-verifier-authority (address principal))
    (is-eq address (var-get verifier-authority))
)

;; Helper function for input validation
(define-private (is-valid-address (address principal))
    (and 
        (not (is-eq address (as-contract tx-sender)))  ;; Prevent contract self-interaction
        (not (is-eq address tx-sender))  ;; Prevent sender from manipulating other addresses
    )
)

;; Helper function for identity info validation
(define-private (is-valid-identity-info (info (string-utf8 500)))
    (and 
        (> (len info) u0)  ;; Ensure non-empty
        (<= (len info) u500)  ;; Ensure within max length
    )
)

;; Helper function for state validation
(define-private (validate-state-transition 
    (current-state uint) 
    (allowed-states (list 10 uint)))
    (is-some (index-of allowed-states current-state))
)

;; Helper function for additional new verifier validation
(define-private (is-valid-verifier (new-verifier principal))
    (and
        (is-valid-address new-verifier)  ;; Use existing address validation
        (not (is-eq new-verifier (var-get verifier-authority)))  ;; Prevent setting same verifier
    )
)

;; Public functions
(define-public (submit-identity-request (identity-info (string-utf8 500)))
    (begin
        ;; Validate identity info input
        (asserts! (is-valid-identity-info identity-info) (err ERROR_INVALID_PARAMETERS))
        (let 
            ((current-state (get state (get-identity-status tx-sender))))
            (asserts! (is-eq current-state u0) (err ERROR_ALREADY_HAS_STATUS))
            (map-set identity-records tx-sender
                {
                    state: u1,
                    timestamp: block-height,
                    identity-info: identity-info,
                    authority: tx-sender
                }
            )
            (ok true)
        )
    )
)

(define-public (approve-identity (address principal))
    (begin
        ;; Validate input address
        (try! (validate-target-address address))
        
        ;; Ensure only verifier authority can approve
        (try! (validate-authority-only))
        
        ;; Get current identity status
        (let ((current-state (get state (get-identity-status address))))
            ;; Validate state for approval
            (asserts! (validate-state-transition current-state (list u1)) (err ERROR_INVALID_STATE))
            (map-set identity-records address
                {
                    state: u2,
                    timestamp: block-height,
                    identity-info: (get identity-info (get-identity-status address)),
                    authority: tx-sender
                }
            )
            (ok true)
        )
    )
)

(define-public (reject-identity (address principal))
    (begin
        ;; Validate input address
        (try! (validate-target-address address))
        
        ;; Ensure only verifier authority can reject
        (try! (validate-authority-only))
        
        ;; Get current identity status
        (let ((current-state (get state (get-identity-status address))))
            ;; Validate state for rejection
            (asserts! (validate-state-transition current-state (list u1)) (err ERROR_INVALID_STATE))
            (map-set identity-records address
                {
                    state: u3,
                    timestamp: block-height,
                    identity-info: (get identity-info (get-identity-status address)),
                    authority: tx-sender
                }
            )
            (ok true)
        )
    )
)

(define-public (revoke-identity (address principal))
    (begin
        ;; Validate input address
        (try! (validate-target-address address))
        
        ;; Ensure only verifier authority can revoke
        (try! (validate-authority-only))
        
        ;; Get current identity status
        (let ((current-state (get state (get-identity-status address))))
            ;; Validate state for revocation
            (asserts! (validate-state-transition current-state (list u1 u2)) (err ERROR_INVALID_STATE))
            (map-set identity-records address
                {
                    state: u0,
                    timestamp: block-height,
                    identity-info: (get identity-info (get-identity-status address)),
                    authority: tx-sender
                }
            )
            (ok true)
        )
    )
)

;; Private function to validate target address
(define-private (validate-target-address (address principal))
    (ok (asserts! (is-valid-address address) (err ERROR_INVALID_PARAMETERS)))
)

;; Private function to validate authority-only operations
(define-private (validate-authority-only)
    (ok (asserts! (is-verifier-authority tx-sender) (err ERROR_UNAUTHORIZED)))
)

(define-public (change-verifier (new-verifier principal))
    (begin
        ;; Validate new verifier address with additional checks
        (asserts! (is-valid-verifier new-verifier) (err ERROR_INVALID_VERIFIER))
        
        ;; Ensure only current authority can transfer
        (try! (validate-authority-only))
        
        ;; Update verifier authority
        (var-set verifier-authority new-verifier)
        
        ;; Optional: Initialize new verifier's identity status
        (map-set identity-records new-verifier
            {
                state: u0,
                timestamp: block-height,
                identity-info: u"",
                authority: tx-sender
            }
        )
        
        (ok true)
    )
)

;; Initialize the contract with deployer's address
(map-set identity-records tx-sender
    {
        state: u0,
        timestamp: block-height,
        identity-info: u"",
        authority: tx-sender
    })