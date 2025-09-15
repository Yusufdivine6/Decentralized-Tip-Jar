;; Smart Tip Matching System
;; Enables sponsors to create matching pools that automatically amplify user tips

;; Error constants
(define-constant ERR-NOT-AUTHORIZED (err u800))
(define-constant ERR-INVALID-AMOUNT (err u801))
(define-constant ERR-POOL-NOT-FOUND (err u802))
(define-constant ERR-POOL-DEPLETED (err u803))
(define-constant ERR-POOL-EXPIRED (err u804))
(define-constant ERR-INVALID-RATIO (err u805))

;; Data variables
(define-data-var pool-counter uint u0)
(define-data-var total-matched-amount uint u0)
(define-data-var active-pools-count uint u0)

;; Matching pool definitions
(define-map matching-pools
  { pool-id: uint }
  {
    sponsor: principal,
    pool-balance: uint,
    matching-ratio: uint, ;; 100 = 1:1, 200 = 2:1, 50 = 1:2
    min-tip-amount: uint,
    max-match-per-tip: uint,
    expiry-block: uint,
    recipient-filter: (optional principal),
    category-filter: (optional (string-ascii 20)),
    total-matched: uint,
    tips-matched: uint,
    is-active: bool
  }
)

;; Track individual tip matches
(define-map tip-matches
  { match-id: uint }
  {
    pool-id: uint,
    original-tipper: principal,
    tip-amount: uint,
    matched-amount: uint,
    recipient: principal,
    matched-at: uint
  }
)

;; Track sponsor statistics
(define-map sponsor-stats
  { sponsor: principal }
  {
    total-pools-created: uint,
    total-amount-sponsored: uint,
    total-tips-matched: uint,
    active-pools: uint,
    reputation-score: uint
  }
)

(define-data-var match-counter uint u0)

;; Create a new matching pool
(define-public (create-matching-pool 
  (pool-balance uint)
  (matching-ratio uint)
  (min-tip-amount uint)
  (max-match-per-tip uint)
  (duration uint)
  (recipient-filter (optional principal))
  (category-filter (optional (string-ascii 20))))
  (let
    (
      (pool-id (var-get pool-counter))
      (expiry (+ block-height duration))
    )
    
    ;; Validate inputs
    (asserts! (> pool-balance u0) ERR-INVALID-AMOUNT)
    (asserts! (and (>= matching-ratio u25) (<= matching-ratio u1000)) ERR-INVALID-RATIO)
    (asserts! (> duration u144) ERR-INVALID-AMOUNT) ;; Min 1 day
    
    ;; Create pool
    (map-set matching-pools
      { pool-id: pool-id }
      {
        sponsor: tx-sender,
        pool-balance: pool-balance,
        matching-ratio: matching-ratio,
        min-tip-amount: min-tip-amount,
        max-match-per-tip: max-match-per-tip,
        expiry-block: expiry,
        recipient-filter: recipient-filter,
        category-filter: category-filter,
        total-matched: u0,
        tips-matched: u0,
        is-active: true
      })
    
    ;; Update counters and stats
    (var-set pool-counter (+ pool-id u1))
    (var-set active-pools-count (+ (var-get active-pools-count) u1))
    (update-sponsor-stats tx-sender pool-balance)
    
    (ok pool-id)
  )
)

;; Process tip matching automatically
(define-public (process-tip-match 
  (tip-amount uint)
  (recipient principal)
  (category (optional (string-ascii 20))))
  (let
    (
      (best-pool (find-best-matching-pool tip-amount recipient category))
    )
    
    (asserts! (> tip-amount u0) ERR-INVALID-AMOUNT)
    
    (match best-pool
      pool-data (execute-tip-match pool-data tip-amount recipient)
      (ok { matched: false, amount: u0, pool-id: u0 }))
  )
)

;; Execute the actual tip matching
(define-private (execute-tip-match 
  (pool-data (tuple (pool-id uint) (sponsor principal) (pool-balance uint) 
                     (matching-ratio uint) (max-match-per-tip uint)))
  (tip-amount uint)
  (recipient principal))
  (let
    (
      (pool-id (get pool-id pool-data))
      (match-amount (calculate-match-amount tip-amount (get matching-ratio pool-data) 
                                          (get max-match-per-tip pool-data)))
      (match-id (var-get match-counter))
      (pool-info (unwrap-panic (map-get? matching-pools { pool-id: pool-id })))
    )
    
    ;; Validate pool has sufficient balance
    (asserts! (<= match-amount (get pool-balance pool-info)) ERR-POOL-DEPLETED)
    
    ;; Record the match
    (map-set tip-matches
      { match-id: match-id }
      {
        pool-id: pool-id,
        original-tipper: tx-sender,
        tip-amount: tip-amount,
        matched-amount: match-amount,
        recipient: recipient,
        matched-at: block-height
      })
    
    ;; Update pool balance and statistics
    (map-set matching-pools
      { pool-id: pool-id }
      (merge pool-info {
        pool-balance: (- (get pool-balance pool-info) match-amount),
        total-matched: (+ (get total-matched pool-info) match-amount),
        tips-matched: (+ (get tips-matched pool-info) u1)
      }))
    
    ;; Update global counters
    (var-set match-counter (+ match-id u1))
    (var-set total-matched-amount (+ (var-get total-matched-amount) match-amount))
    
    (ok { matched: true, amount: match-amount, pool-id: pool-id })
  )
)

;; Find the best matching pool for a tip
(define-private (find-best-matching-pool 
  (tip-amount uint)
  (recipient principal)
  (category (optional (string-ascii 20))))
  (let
    (
      ;; For simplicity, return pool 1 if it exists and is valid
      (pool-candidate (map-get? matching-pools { pool-id: u1 }))
    )
    
    (match pool-candidate
      pool (if (and 
                 (get is-active pool)
                 (>= tip-amount (get min-tip-amount pool))
                 (> (get pool-balance pool) u0)
                 (< block-height (get expiry-block pool))
                 (match (get recipient-filter pool)
                   filter-recipient (is-eq recipient filter-recipient)
                   true))
             (some { 
               pool-id: u1,
               sponsor: (get sponsor pool),
               pool-balance: (get pool-balance pool),
               matching-ratio: (get matching-ratio pool),
               max-match-per-tip: (get max-match-per-tip pool)
             })
             none)
      none)
  )
)

;; Calculate matching amount based on ratio and limits
(define-private (calculate-match-amount 
  (tip-amount uint)
  (ratio uint)
  (max-match uint))
  (let
    (
      (calculated-match (/ (* tip-amount ratio) u100))
    )
    
    (if (> max-match u0)
        (if (> calculated-match max-match)
            max-match
            calculated-match)
        calculated-match)
  )
)

;; Update sponsor statistics
(define-private (update-sponsor-stats (sponsor principal) (amount uint))
  (let
    (
      (current-stats (default-to
        { total-pools-created: u0, total-amount-sponsored: u0, 
          total-tips-matched: u0, active-pools: u0, reputation-score: u0 }
        (map-get? sponsor-stats { sponsor: sponsor })))
    )
    
    (map-set sponsor-stats
      { sponsor: sponsor }
      {
        total-pools-created: (+ (get total-pools-created current-stats) u1),
        total-amount-sponsored: (+ (get total-amount-sponsored current-stats) amount),
        total-tips-matched: (get total-tips-matched current-stats),
        active-pools: (+ (get active-pools current-stats) u1),
        reputation-score: (+ (get reputation-score current-stats) u5)
      })
  )
)

;; Deactivate expired pools
(define-public (deactivate-expired-pool (pool-id uint))
  (let
    (
      (pool-data (unwrap! (map-get? matching-pools { pool-id: pool-id }) ERR-POOL-NOT-FOUND))
    )
    
    ;; Check if pool is expired
    (asserts! (>= block-height (get expiry-block pool-data)) ERR-POOL-EXPIRED)
    
    ;; Deactivate pool
    (map-set matching-pools
      { pool-id: pool-id }
      (merge pool-data { is-active: false }))
    
    ;; Update active pools count
    (var-set active-pools-count (- (var-get active-pools-count) u1))
    
    (ok true)
  )
)

;; Read-only functions
(define-read-only (get-matching-pool (pool-id uint))
  (map-get? matching-pools { pool-id: pool-id })
)

(define-read-only (get-tip-match (match-id uint))
  (map-get? tip-matches { match-id: match-id })
)

(define-read-only (get-sponsor-stats (sponsor principal))
  (map-get? sponsor-stats { sponsor: sponsor })
)

(define-read-only (get-system-stats)
  (ok {
    total-pools: (var-get pool-counter),
    active-pools: (var-get active-pools-count),
    total-matched: (var-get total-matched-amount),
    total-matches: (var-get match-counter)
  })
)
