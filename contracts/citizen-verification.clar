;; Citizen Verification Contract
;; Validates public service users and manages citizen identity

;; Constants
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-CITIZEN-EXISTS (err u101))
(define-constant ERR-CITIZEN-NOT-FOUND (err u102))
(define-constant ERR-INVALID-DATA (err u103))

;; Data Variables
(define-data-var contract-owner principal tx-sender)

;; Data Maps
(define-map citizens
  { citizen-id: principal }
  {
    verified: bool,
    registration-date: uint,
    verification-level: uint,
    status: (string-ascii 20)
  }
)

(define-map citizen-profiles
  { citizen-id: principal }
  {
    name: (string-ascii 50),
    contact-method: (string-ascii 100),
    service-preferences: (list 10 (string-ascii 30))
  }
)

;; Private Functions
(define-private (is-contract-owner)
  (is-eq tx-sender (var-get contract-owner))
)

;; Public Functions
(define-public (register-citizen (citizen-id principal) (name (string-ascii 50)) (contact (string-ascii 100)))
  (begin
    (asserts! (is-none (map-get? citizens { citizen-id: citizen-id })) ERR-CITIZEN-EXISTS)
    (asserts! (> (len name) u0) ERR-INVALID-DATA)

    (map-set citizens
      { citizen-id: citizen-id }
      {
        verified: false,
        registration-date: block-height,
        verification-level: u1,
        status: "registered"
      }
    )

    (map-set citizen-profiles
      { citizen-id: citizen-id }
      {
        name: name,
        contact-method: contact,
        service-preferences: (list)
      }
    )

    (ok true)
  )
)

(define-public (verify-citizen (citizen-id principal) (verification-level uint))
  (begin
    (asserts! (is-contract-owner) ERR-NOT-AUTHORIZED)
    (asserts! (is-some (map-get? citizens { citizen-id: citizen-id })) ERR-CITIZEN-NOT-FOUND)
    (asserts! (<= verification-level u5) ERR-INVALID-DATA)

    (map-set citizens
      { citizen-id: citizen-id }
      (merge
        (unwrap! (map-get? citizens { citizen-id: citizen-id }) ERR-CITIZEN-NOT-FOUND)
        {
          verified: true,
          verification-level: verification-level,
          status: "verified"
        }
      )
    )

    (ok true)
  )
)

(define-public (update-service-preferences (preferences (list 10 (string-ascii 30))))
  (begin
    (asserts! (is-some (map-get? citizens { citizen-id: tx-sender })) ERR-CITIZEN-NOT-FOUND)

    (map-set citizen-profiles
      { citizen-id: tx-sender }
      (merge
        (unwrap! (map-get? citizen-profiles { citizen-id: tx-sender }) ERR-CITIZEN-NOT-FOUND)
        { service-preferences: preferences }
      )
    )

    (ok true)
  )
)

;; Read-only Functions
(define-read-only (get-citizen-info (citizen-id principal))
  (map-get? citizens { citizen-id: citizen-id })
)

(define-read-only (get-citizen-profile (citizen-id principal))
  (map-get? citizen-profiles { citizen-id: citizen-id })
)

(define-read-only (is-citizen-verified (citizen-id principal))
  (match (map-get? citizens { citizen-id: citizen-id })
    citizen-data (get verified citizen-data)
    false
  )
)

(define-read-only (get-verification-level (citizen-id principal))
  (match (map-get? citizens { citizen-id: citizen-id })
    citizen-data (get verification-level citizen-data)
    u0
  )
)
