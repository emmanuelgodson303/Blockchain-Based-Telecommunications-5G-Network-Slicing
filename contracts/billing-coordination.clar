;; Billing Coordination Contract
;; Manages billing for 5G network slices

(define-constant ERR_UNAUTHORIZED (err u500))
(define-constant ERR_INSUFFICIENT_BALANCE (err u501))
(define-constant ERR_BILLING_NOT_FOUND (err u502))

;; Data structures
(define-map billing-accounts
  { operator-id: uint }
  {
    balance: uint,
    total-usage: uint,
    last-billing: uint
  }
)

(define-map usage-records
  { slice-id: uint, period: uint }
  {
    bandwidth-consumed: uint,
    duration: uint,
    cost: uint
  }
)

(define-data-var billing-rate uint u10) ;; Cost per unit

;; Initialize billing account
(define-public (initialize-billing-account (operator-id uint) (initial-balance uint))
  (begin
    (map-set billing-accounts
      { operator-id: operator-id }
      {
        balance: initial-balance,
        total-usage: u0,
        last-billing: block-height
      }
    )
    (ok true)
  )
)

;; Record usage and calculate billing
(define-public (record-usage (slice-id uint) (operator-id uint) (bandwidth-consumed uint) (duration uint))
  (let ((cost (* bandwidth-consumed (var-get billing-rate)))
        (account (unwrap! (map-get? billing-accounts { operator-id: operator-id }) ERR_BILLING_NOT_FOUND)))

    (asserts! (>= (get balance account) cost) ERR_INSUFFICIENT_BALANCE)

    ;; Record usage
    (map-set usage-records
      { slice-id: slice-id, period: block-height }
      {
        bandwidth-consumed: bandwidth-consumed,
        duration: duration,
        cost: cost
      }
    )

    ;; Update billing account
    (map-set billing-accounts
      { operator-id: operator-id }
      {
        balance: (- (get balance account) cost),
        total-usage: (+ (get total-usage account) bandwidth-consumed),
        last-billing: block-height
      }
    )

    (ok cost)
  )
)

;; Add funds to billing account
(define-public (add-funds (operator-id uint) (amount uint))
  (let ((account (unwrap! (map-get? billing-accounts { operator-id: operator-id }) ERR_BILLING_NOT_FOUND)))

    (map-set billing-accounts
      { operator-id: operator-id }
      (merge account { balance: (+ (get balance account) amount) })
    )
    (ok true)
  )
)

;; Get billing account details
(define-read-only (get-billing-account (operator-id uint))
  (map-get? billing-accounts { operator-id: operator-id })
)

;; Get usage record
(define-read-only (get-usage-record (slice-id uint) (period uint))
  (map-get? usage-records { slice-id: slice-id, period: period })
)
