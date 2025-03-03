;; Define token for rewards
(define-fungible-token step-token)

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-invalid-route (err u101))
(define-constant err-already-completed (err u102))
(define-constant err-invalid-rating (err u103))
(define-constant err-not-completed (err u104))
(define-constant err-invalid-params (err u105))
(define-constant err-already-rated (err u106))

;; Data variables
(define-data-var next-route-id uint u1)

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

(define-map user-ratings
  { user: principal, route-id: uint }
  { rating: uint }
)

;; Events
(define-public (print-route-created (route-id uint))
  (ok (print { event: "route-created", route-id: route-id, creator: tx-sender })))

;; Read-only functions
(define-read-only (get-route (route-id uint))
  (map-get? routes { route-id: route-id }))

;; Route creation
(define-public (create-route (name (string-utf8 100)) (description (string-utf8 500)) (difficulty uint) (length uint))
  (begin
    (asserts! (and (> difficulty u0) (<= difficulty u5)) (err err-invalid-params))
    (asserts! (> length u0) (err err-invalid-params))
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
      (try! (print-route-created route-id))
      (ok route-id))))

;; Complete route
(define-public (complete-route (route-id uint))
  (let ((route (unwrap! (map-get? routes { route-id: route-id }) (err err-invalid-route))))
    (asserts! (is-none (map-get? completed-routes { user: tx-sender, route-id: route-id }))
      (err err-already-completed))
    (map-set completed-routes { user: tx-sender, route-id: route-id } { completed: true })
    (try! (ft-mint? step-token u10 tx-sender))
    (ok true)))

;; Rate route
(define-public (rate-route (route-id uint) (rating uint))
  (let (
    (route (unwrap! (map-get? routes { route-id: route-id }) (err err-invalid-route)))
    (completed (unwrap! (map-get? completed-routes { user: tx-sender, route-id: route-id }) 
      (err err-not-completed)))
  )
    (asserts! (is-none (map-get? user-ratings { user: tx-sender, route-id: route-id }))
      (err err-already-rated))
    (asserts! (and (>= rating u1) (<= rating u5)) (err err-invalid-rating))
    (asserts! completed (err err-not-completed))
    (let (
      (current-total (* (get rating route) (get total-ratings route)))
      (new-total-ratings (+ (get total-ratings route) u1))
      (new-rating (/ (+ current-total (* rating u100)) (* new-total-ratings u100)))
    )
      (map-set routes
        { route-id: route-id }
        (merge route {
          rating: new-rating,
          total-ratings: new-total-ratings
        })
      )
      (map-set user-ratings
        { user: tx-sender, route-id: route-id }
        { rating: rating }
      )
      (ok true))))
