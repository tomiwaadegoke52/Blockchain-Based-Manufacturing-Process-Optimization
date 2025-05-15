;; Equipment Registration Contract
;; Records manufacturing assets and their specifications

(define-data-var admin principal tx-sender)

;; Data structure for equipment
(define-map equipment
  { equipment-id: (string-ascii 32) }
  {
    name: (string-ascii 100),
    facility-id: (string-ascii 32),
    type: (string-ascii 50),
    installation-date: uint,
    last-maintenance: uint,
    operational-status: bool,
    specifications: (list 10 {
      key: (string-ascii 50),
      value: (string-ascii 50)
    })
  }
)

;; Register new equipment
(define-public (register-equipment
    (equipment-id (string-ascii 32))
    (name (string-ascii 100))
    (facility-id (string-ascii 32))
    (type (string-ascii 50))
    (specifications (list 10 {
      key: (string-ascii 50),
      value: (string-ascii 50)
    })))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (asserts! (is-none (map-get? equipment { equipment-id: equipment-id })) (err u100))
    (ok (map-set equipment
      { equipment-id: equipment-id }
      {
        name: name,
        facility-id: facility-id,
        type: type,
        installation-date: block-height,
        last-maintenance: block-height,
        operational-status: true,
        specifications: specifications
      }
    ))
  )
)

;; Update equipment maintenance status
(define-public (update-maintenance (equipment-id (string-ascii 32)))
  (let ((equip (unwrap! (map-get? equipment { equipment-id: equipment-id }) (err u404))))
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (ok (map-set equipment
      { equipment-id: equipment-id }
      (merge equip {
        last-maintenance: block-height
      })
    ))
  )
)

;; Update operational status
(define-public (update-operational-status (equipment-id (string-ascii 32)) (status bool))
  (let ((equip (unwrap! (map-get? equipment { equipment-id: equipment-id }) (err u404))))
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (ok (map-set equipment
      { equipment-id: equipment-id }
      (merge equip {
        operational-status: status
      })
    ))
  )
)

;; Get equipment details
(define-read-only (get-equipment (equipment-id (string-ascii 32)))
  (map-get? equipment { equipment-id: equipment-id })
)

;; Check if equipment is operational
(define-read-only (is-equipment-operational (equipment-id (string-ascii 32)))
  (default-to false (get operational-status (map-get? equipment { equipment-id: equipment-id })))
)

;; Transfer admin rights
(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u403))
    (ok (var-set admin new-admin))
  )
)
