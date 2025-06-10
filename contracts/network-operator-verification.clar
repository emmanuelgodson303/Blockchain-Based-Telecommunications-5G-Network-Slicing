;; Network Operator Verification Contract
;; Manages verification and registration of 5G network operators

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_OPERATOR_EXISTS (err u101))
(define-constant ERR_OPERATOR_NOT_FOUND (err u102))
(define-constant ERR_INVALID_LICENSE (err u103))

;; Data structures
(define-map operators
  { operator-id: uint }
  {
    name: (string-ascii 50),
    license-number: (string-ascii 20),
    verified: bool,
    registration-block: uint
  }
)

(define-data-var next-operator-id uint u1)

;; Register a new network operator
(define-public (register-operator (name (string-ascii 50)) (license-number (string-ascii 20)))
  (let ((operator-id (var-get next-operator-id)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (is-none (map-get? operators { operator-id: operator-id })) ERR_OPERATOR_EXISTS)

    (map-set operators
      { operator-id: operator-id }
      {
        name: name,
        license-number: license-number,
        verified: false,
        registration-block: block-height
      }
    )

    (var-set next-operator-id (+ operator-id u1))
    (ok operator-id)
  )
)

;; Verify an operator
(define-public (verify-operator (operator-id uint))
  (let ((operator (unwrap! (map-get? operators { operator-id: operator-id }) ERR_OPERATOR_NOT_FOUND)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)

    (map-set operators
      { operator-id: operator-id }
      (merge operator { verified: true })
    )
    (ok true)
  )
)

;; Get operator details
(define-read-only (get-operator (operator-id uint))
  (map-get? operators { operator-id: operator-id })
)

;; Check if operator is verified
(define-read-only (is-operator-verified (operator-id uint))
  (match (map-get? operators { operator-id: operator-id })
    operator (get verified operator)
    false
  )
)
