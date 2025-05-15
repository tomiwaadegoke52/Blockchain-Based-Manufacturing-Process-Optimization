;; Optimization Contract
;; Manages continuous improvement initiatives

(define-data-var admin principal tx-sender)

;; Data structure for optimization initiatives
(define-map optimization-initiatives
  { initiative-id: (string-ascii 32) }
  {
    name: (string-ascii 100),
    process-id: (string-ascii 32),
    created-at: uint,
    status: (string-ascii 20), ;; "proposed", "in-progress", "completed", "cancelled"
    target-metrics: (list 10 {
      name: (string-ascii 50),
      current-value: (string-ascii 50),
      target-value: (string-ascii 50),
      unit: (string-ascii 20)
    }),
    description: (string-utf8 500),
    proposer: principal
  }
)

;; Data structure for optimization results
(define-map optimization-results
  { initiative-id: (string-ascii 32) }
  {
    completed-at: uint,
    actual-metrics: (list 10 {
      name: (string-ascii 50),
      achieved-value: (string-ascii 50),
      unit: (string-ascii 20)
    }),
    success-rating: uint, ;; 1-10 scale
    notes: (string-utf8 500)
  }
)

;; Propose a new optimization initiative
(define-public (propose-initiative
    (initiative-id (string-ascii 32))
    (name (string-ascii 100))
    (process-id (string-ascii 32))
    (target-metrics (list 10 {
      name: (string-ascii 50),
      current-value: (string-ascii 50),
      target-value: (string-ascii 50),
      unit: (string-ascii 20)
    }))
    (description (string-utf8 500)))
  (begin
    (asserts! (is-none (map-get? optimization-initiatives { initiative-id: initiative-id })) (err u100))
    (ok (map-set optimization-initiatives
      { initiative-id: initiative-id }
      {
        name: name,
        process-id: process-id,
        created-at: block-height,
        status: "proposed",
        target-metrics: target-metrics,
        description: description,
        proposer: tx-sender
      }
    ))
  )
)

;; Update initiative status
(define-public (update-initiative-status (initiative-id (string-ascii 32)) (new-status (string-ascii 20)))
  (let ((initiative (unwrap! (map-get? optimization-initiatives { initiative-id: initiative-id }) (err u404))))
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (or (is-eq new-status "proposed") (is-eq new-status "in-progress") (is-eq new-status "completed") (is-eq new-status "cancelled")) (err u400))
    (ok (map-set optimization-initiatives
      { initiative-id: initiative-id }
      (merge initiative {
        status: new-status
      })
    ))
  )
)

;; Record optimization results
(define-public (record-results
    (initiative-id (string-ascii 32))
    (actual-metrics (list 10 {
      name: (string-ascii 50),
      achieved-value: (string-ascii 50),
      unit: (string-ascii 20)
    }))
    (success-rating uint)
    (notes (string-utf8 500)))
  (let ((initiative (unwrap! (map-get? optimization-initiatives { initiative-id: initiative-id }) (err u404))))
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (<= success-rating u10) (err u400))

    ;; Update initiative status to completed
    (map-set optimization-initiatives
      { initiative-id: initiative-id }
      (merge initiative {
        status: "completed"
      })
    )

    ;; Record the results
    (ok (map-set optimization-results
      { initiative-id: initiative-id }
      {
        completed-at: block-height,
        actual-metrics: actual-metrics,
        success-rating: success-rating,
        notes: notes
      }
    ))
  )
)

;; Get initiative details
(define-read-only (get-initiative (initiative-id (string-ascii 32)))
  (map-get? optimization-initiatives { initiative-id: initiative-id })
)

;; Get initiative results
(define-read-only (get-results (initiative-id (string-ascii 32)))
  (map-get? optimization-results { initiative-id: initiative-id })
)

;; Transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (ok (var-set admin new-admin))
  )
)
