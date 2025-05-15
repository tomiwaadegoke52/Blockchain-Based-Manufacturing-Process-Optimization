;; Process Parameter Contract
;; Tracks production settings and parameters

(define-data-var admin principal tx-sender)

;; Data structure for process parameters
(define-map process-parameters
  { process-id: (string-ascii 32) }
  {
    name: (string-ascii 100),
    equipment-id: (string-ascii 32),
    created-at: uint,
    updated-at: uint,
    parameters: (list 20 {
      name: (string-ascii 50),
      value: (string-ascii 50),
      unit: (string-ascii 20),
      min-threshold: (string-ascii 20),
      max-threshold: (string-ascii 20)
    })
  }
)

;; Data structure for parameter history
(define-map parameter-history
  { process-id: (string-ascii 32), timestamp: uint }
  {
    parameters: (list 20 {
      name: (string-ascii 50),
      value: (string-ascii 50),
      unit: (string-ascii 20)
    }),
    changed-by: principal
  }
)

;; Create a new process
(define-public (create-process
    (process-id (string-ascii 32))
    (name (string-ascii 100))
    (equipment-id (string-ascii 32))
    (parameters (list 20 {
      name: (string-ascii 50),
      value: (string-ascii 50),
      unit: (string-ascii 20),
      min-threshold: (string-ascii 20),
      max-threshold: (string-ascii 20)
    })))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (is-none (map-get? process-parameters { process-id: process-id })) (err u100))
    (ok (map-set process-parameters
      { process-id: process-id }
      {
        name: name,
        equipment-id: equipment-id,
        created-at: block-height,
        updated-at: block-height,
        parameters: parameters
      }
    ))
  )
)

;; Update process parameters
(define-public (update-parameters
    (process-id (string-ascii 32))
    (parameters (list 20 {
      name: (string-ascii 50),
      value: (string-ascii 50),
      unit: (string-ascii 20),
      min-threshold: (string-ascii 20),
      max-threshold: (string-ascii 20)
    })))
  (let ((process (unwrap! (map-get? process-parameters { process-id: process-id }) (err u404))))
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))

    ;; Store history before updating
    (map-set parameter-history
      { process-id: process-id, timestamp: block-height }
      {
        parameters: (map extract-parameter-history (get parameters process)),
        changed-by: tx-sender
      }
    )

    ;; Update the parameters
    (ok (map-set process-parameters
      { process-id: process-id }
      (merge process {
        updated-at: block-height,
        parameters: parameters
      })
    ))
  )
)

;; Helper function to extract parameter history
(define-private (extract-parameter-history (param {
      name: (string-ascii 50),
      value: (string-ascii 50),
      unit: (string-ascii 20),
      min-threshold: (string-ascii 20),
      max-threshold: (string-ascii 20)
    }))
  {
    name: (get name param),
    value: (get value param),
    unit: (get unit param)
  }
)

;; Get process parameters
(define-read-only (get-process (process-id (string-ascii 32)))
  (map-get? process-parameters { process-id: process-id })
)

;; Get parameter history
(define-read-only (get-parameter-history (process-id (string-ascii 32)) (timestamp uint))
  (map-get? parameter-history { process-id: process-id, timestamp: timestamp })
)

;; Transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (ok (var-set admin new-admin))
  )
)
