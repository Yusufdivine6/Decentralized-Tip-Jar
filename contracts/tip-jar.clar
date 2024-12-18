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
