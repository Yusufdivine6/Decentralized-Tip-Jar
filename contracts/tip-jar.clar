(define-data-var total-tips uint u0)

(define-map user-tips {user: principal} {amount: uint})

(define-public (send-tip (amount uint))
    (begin
        (asserts! (> amount u0) (err u100)) ;; Ensure the tip amount is greater than zero
        (map-set user-tips
            {user: tx-sender}
            {amount: (match (map-get? user-tips {user: tx-sender})
                tips-data (+
                    (get amount tips-data)
                    amount)
                amount)})
        (var-set total-tips (+ (var-get total-tips) amount))
        (ok amount)))

(define-read-only (get-total-tips)
    (ok (var-get total-tips)))

(define-read-only (get-user-tips (user principal))
    (ok (match (map-get? user-tips {user: user})
        tips-data (get amount tips-data)
        u0)))


;; Add these at the top with other definitions
(define-data-var contract-owner principal tx-sender)
(define-data-var withdrawable-balance uint u0)

(define-public (withdraw-tips (amount uint))
    (begin
        (asserts! (is-eq tx-sender (var-get contract-owner)) (err u101))
        (asserts! (<= amount (var-get withdrawable-balance)) (err u102))
        (var-set withdrawable-balance (- (var-get withdrawable-balance) amount))
        (ok amount)))


(define-map milestone-rewards 
    {threshold: uint} 
    {reward-name: (string-ascii 50)})

(define-public (check-milestone (user principal))
    (let ((user-total (unwrap-panic (get-user-tips user))))
        (if (>= user-total u1000)
            (ok "Gold Tipper")
            (if (>= user-total u500)
                (ok "Silver Tipper")
                (if (>= user-total u100)
                    (ok "Bronze Tipper")
                    (ok "New Tipper"))))))



(define-map tip-messages 
    {tipper: principal, tip-id: uint} 
    {message: (string-ascii 280)})

(define-data-var tip-counter uint u0)

(define-public (send-tip-with-message (amount uint) (message (string-ascii 280)))
    (begin
        (asserts! (> amount u0) (err u100))
        (var-set tip-counter (+ (var-get tip-counter) u1))
        (map-set tip-messages 
            {tipper: tx-sender, tip-id: (var-get tip-counter)}
            {message: message})
        (send-tip amount)))



(define-map monthly-tips 
    {user: principal, month: uint, year: uint} 
    {amount: uint})

(define-public (record-monthly-tip (amount uint) (month uint) (year uint))
    (begin
        (asserts! (and (> month u0) (<= month u12)) (err u103))
        (map-set monthly-tips
            {user: tx-sender, month: month, year: year}
            {amount: (+ amount (default-to u0 
                (get amount (map-get? monthly-tips 
                    {user: tx-sender, month: month, year: year}))))})
        (ok amount)))



(define-public (split-tip (recipients (list 10 principal)) (amount uint))
    (let ((split-amount (/ amount (len recipients))))
        (begin
            (asserts! (> amount u0) (err u100))
            (asserts! (> (len recipients) u0) (err u104))
            (ok amount))))

(define-private (send-tip-to-recipient (recipient principal) (amount uint))
    (map-set user-tips
        {user: recipient}
        {amount: (+ amount (default-to u0 
            (get amount (map-get? user-tips {user: recipient}))))}))
