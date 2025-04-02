;; Producer Registration Contract
;; Records details of energy generation sources

(define-data-var next-producer-id uint u0)

;; Producer data structure
(define-map producers
  { producer-id: uint }
  {
    owner: principal,
    name: (string-ascii 50),
    energy-type: (string-ascii 20),
    capacity: uint,
    location: (string-ascii 100),
    active: bool
  }
)

;; Producer ID to principal mapping
(define-map producer-by-principal
  { owner: principal }
  { producer-id: uint }
)

;; Error codes
(define-constant ERR-NOT-AUTHORIZED u1)
(define-constant ERR-ALREADY-REGISTERED u2)
(define-constant ERR-INVALID-PRODUCER u3)

;; Register a new producer
(define-public (register-producer
    (name (string-ascii 50))
    (energy-type (string-ascii 20))
    (capacity uint)
    (location (string-ascii 100)))
  (let ((producer-id (var-get next-producer-id))
        (caller tx-sender))
    (asserts! (is-none (map-get? producer-by-principal { owner: caller })) (err ERR-ALREADY-REGISTERED))

    ;; Update producer ID counter
    (var-set next-producer-id (+ producer-id u1))

    ;; Add producer to maps
    (map-set producers
      { producer-id: producer-id }
      {
        owner: caller,
        name: name,
        energy-type: energy-type,
        capacity: capacity,
        location: location,
        active: true
      }
    )

    (map-set producer-by-principal
      { owner: caller }
      { producer-id: producer-id }
    )

    (ok producer-id)
  )
)

;; Update producer details
(define-public (update-producer
    (producer-id uint)
    (name (string-ascii 50))
    (energy-type (string-ascii 20))
    (capacity uint)
    (location (string-ascii 100)))
  (let ((producer-data (unwrap! (map-get? producers { producer-id: producer-id }) (err ERR-INVALID-PRODUCER)))
        (caller tx-sender))

    ;; Check if caller is the owner
    (asserts! (is-eq (get owner producer-data) caller) (err ERR-NOT-AUTHORIZED))

    ;; Update producer data
    (map-set producers
      { producer-id: producer-id }
      {
        owner: caller,
        name: name,
        energy-type: energy-type,
        capacity: capacity,
        location: location,
        active: (get active producer-data)
      }
    )

    (ok true)
  )
)

;; Deactivate a producer
(define-public (deactivate-producer (producer-id uint))
  (let ((producer-data (unwrap! (map-get? producers { producer-id: producer-id }) (err ERR-INVALID-PRODUCER)))
        (caller tx-sender))

    ;; Check if caller is the owner
    (asserts! (is-eq (get owner producer-data) caller) (err ERR-NOT-AUTHORIZED))

    ;; Update producer active status
    (map-set producers
      { producer-id: producer-id }
      {
        owner: (get owner producer-data),
        name: (get name producer-data),
        energy-type: (get energy-type producer-data),
        capacity: (get capacity producer-data),
        location: (get location producer-data),
        active: false
      }
    )

    (ok true)
  )
)

;; Reactivate a producer
(define-public (reactivate-producer (producer-id uint))
  (let ((producer-data (unwrap! (map-get? producers { producer-id: producer-id }) (err ERR-INVALID-PRODUCER)))
        (caller tx-sender))

    ;; Check if caller is the owner
    (asserts! (is-eq (get owner producer-data) caller) (err ERR-NOT-AUTHORIZED))

    ;; Update producer active status
    (map-set producers
      { producer-id: producer-id }
      {
        owner: (get owner producer-data),
        name: (get name producer-data),
        energy-type: (get energy-type producer-data),
        capacity: (get capacity producer-data),
        location: (get location producer-data),
        active: true
      }
    )

    (ok true)
  )
)

;; Read-only function to get producer details
(define-read-only (get-producer (producer-id uint))
  (map-get? producers { producer-id: producer-id })
)

;; Read-only function to get producer ID by principal
(define-read-only (get-producer-id-by-principal (owner principal))
  (map-get? producer-by-principal { owner: owner })
)

;; Read-only function to check if a producer is active
(define-read-only (is-producer-active (producer-id uint))
  (match (map-get? producers { producer-id: producer-id })
    producer-data (get active producer-data)
    false
  )
)

