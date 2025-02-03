;; Define token for rewards
(define-fungible-token step-token)

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-invalid-route (err u101))
(define-constant err-already-completed (err u102))
(define-constant err-invalid-rating (err u103))

;; Data structures
(define-map routes
  { route-id: uint }
  {
    creator: principal,
    name: (string-utf8 100),
    description: (string-utf8 500),
    difficulty: uint,
    length: uint,
    rating: uint,
    total-ratings: uint
  }
)

(define-map completed-routes
  { user: principal, route-id: uint }
  { completed: bool }
)

;; Route creation
(define-public (create-route (name (string-utf8 100)) (description (string-utf8 500)) (difficulty uint) (length uint))
  (let ((route-id (var-get next-route-id)))
    (map-set routes
      { route-id: route-id }
      {
        creator: tx-sender,
        name: name,
        description: description,
        difficulty: difficulty,
        length: length,
        rating: u0,
        total-ratings: u0
      }
    )
    (var-set next-route-id (+ route-id u1))
    (ok route-id)))

;; Complete route
(define-public (complete-route (route-id uint))
  (let ((route (unwrap! (map-get? routes { route-id: route-id }) (err err-invalid-route))))
    (if (is-some (map-get? completed-routes { user: tx-sender, route-id: route-id }))
      (err err-already-completed)
      (begin
        (map-set completed-routes { user: tx-sender, route-id: route-id } { completed: true })
        (try! (ft-mint? step-token u10 tx-sender))
        (ok true)))))

;; Rate route
(define-public (rate-route (route-id uint) (rating uint))
  (let (
    (route (unwrap! (map-get? routes { route-id: route-id }) (err err-invalid-route)))
    (completed (unwrap! (map-get? completed-routes { user: tx-sender, route-id: route-id }) (err err-invalid-route)))
  )
    (if (and (>= rating u1) (<= rating u5))
      (begin
        (map-set routes
          { route-id: route-id }
          (merge route {
            rating: (+ (* route "rating") rating),
            total-ratings: (+ (get total-ratings route) u1)
          })
        )
        (ok true))
      (err err-invalid-rating))))
