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


;; Define storage for scheduled tips
(define-map scheduled-tips 
    {user: principal, schedule-id: uint} 
    {amount: uint, frequency: (string-ascii 10), active: bool})

(define-data-var schedule-counter uint u0)

;; Create a scheduled tip
(define-public (create-tip-schedule (amount uint) (frequency (string-ascii 10)))
    (begin
        (asserts! (> amount u0) (err u100))
        (var-set schedule-counter (+ (var-get schedule-counter) u1))
        (map-set scheduled-tips
            {user: tx-sender, schedule-id: (var-get schedule-counter)}
            {amount: amount, frequency: frequency, active: true})
        (ok (var-get schedule-counter))))


;; Define storage for tip categories
(define-map tip-categories
    {tip-id: uint}
    {category: (string-ascii 20)})

;; Send tip with category
(define-public (send-categorized-tip (amount uint) (category (string-ascii 20)))
    (begin
        (asserts! (> amount u0) (err u100))
        (var-set tip-counter (+ (var-get tip-counter) u1))
        (map-set tip-categories
            {tip-id: (var-get tip-counter)}
            {category: category})
        (send-tip amount)))


;; Define storage for referrals
(define-map referrals
    {referrer: principal}
    {total-referrals: uint, bonus-earned: uint})

;; Register a referral
(define-public (register-referral (referrer principal))
    (begin
        (asserts! (not (is-eq tx-sender referrer)) (err u105))
        (map-set referrals
            {referrer: referrer}
            {total-referrals: (+ u1 
                (default-to u0 
                    (get total-referrals 
                        (map-get? referrals {referrer: referrer})))),
             bonus-earned: u0})
        (ok true)))



;; Define storage for tip goals
(define-map user-goals
    {user: principal}
    {target: uint, current: uint, deadline: uint})

;; Set a tipping goal
(define-public (set-tip-goal (target uint) (deadline uint))
    (begin
        (asserts! (> target u0) (err u100))
        (map-set user-goals
            {user: tx-sender}
            {target: target,
             current: u0,
             deadline: deadline})
        (ok true)))



;; Define storage for rankings
(define-map tipper-ranks
    {rank: uint}
    {user: principal, amount: uint})

(define-data-var total-ranked-tippers uint u0)

;; Update tipper ranking
(define-public (update-ranking (user principal) (amount uint))
    (begin
        (var-set total-ranked-tippers (+ (var-get total-ranked-tippers) u1))
        (map-set tipper-ranks
            {rank: (var-get total-ranked-tippers)}
            {user: user, amount: amount})
        (ok true)))





;; Define storage for group tips
(define-map group-tips
    {group-id: uint}
    {members: (list 10 principal), target: uint, collected: uint})

(define-data-var group-counter uint u0)

;; Create a group tip
(define-public (create-group-tip (members (list 10 principal)) (target uint))
    (begin
        (var-set group-counter (+ (var-get group-counter) u1))
        (map-set group-tips
            {group-id: (var-get group-counter)}
            {members: members,
             target: target,
             collected: u0})
        (ok (var-get group-counter))))



;; Define storage for achievements
(define-map user-achievements
    {user: principal}
    {badges: (list 10 (string-ascii 20)), points: uint})

;; Award achievement
(define-public (award-achievement (user principal) (badge (string-ascii 20)))
    (let ((current-achievements (default-to 
            {badges: (list), points: u0}
            (map-get? user-achievements {user: user}))))
        (map-set user-achievements
            {user: user}
            {badges: (unwrap-panic (as-max-len? 
                (append (get badges current-achievements) badge) u10)),
             points: (+ (get points current-achievements) u10)})
        (ok true)))




;; Define vote storage
(define-map tip-votes
    {tip-id: uint}
    {upvotes: uint, downvotes: uint})

(define-map user-votes
    {user: principal, tip-id: uint}
    {voted: bool})

(define-public (vote-on-tip (tip-id uint) (is-upvote bool))
    (let ((current-votes (default-to
            {upvotes: u0, downvotes: u0}
            (map-get? tip-votes {tip-id: tip-id}))))
    (begin
        (asserts! (not (default-to false 
            (get voted (map-get? user-votes 
                {user: tx-sender, tip-id: tip-id})))) (err u106))
        (map-set tip-votes {tip-id: tip-id}
            {upvotes: (if is-upvote 
                         (+ (get upvotes current-votes) u1)
                         (get upvotes current-votes)),
             downvotes: (if is-upvote
                           (get downvotes current-votes)
                           (+ (get downvotes current-votes) u1))})
        (map-set user-votes 
            {user: tx-sender, tip-id: tip-id}
            {voted: true})
        (ok true))))



;; Define tag storage
(define-map tip-tags
    {tip-id: uint}
    {tags: (list 5 (string-ascii 20))})

(define-map tag-index
    {tag: (string-ascii 20)}
    {tip-count: uint, last-tip-id: uint})

(define-public (add-tip-tags (tip-id uint) (tags (list 5 (string-ascii 20))))
    (begin
        (map-set tip-tags
            {tip-id: tip-id}
            {tags: tags})
        (ok true)))


;; Define reputation storage
(define-map tipper-reputation
    {user: principal}
    {score: uint, level: uint, total-tips-sent: uint})

(define-public (update-reputation (user principal) (tip-amount uint))
    (let ((current-rep (default-to
            {score: u0, level: u1, total-tips-sent: u0}
            (map-get? tipper-reputation {user: user}))))
        (begin
            (map-set tipper-reputation {user: user}
                {score: (+ (get score current-rep) 
                          (/ tip-amount u100)),
                 level: (+ (get level current-rep)
                          (if (>= (+ (get score current-rep) 
                                    (/ tip-amount u100)) 
                              (* (get level current-rep) u1000))
                              u1 u0)),
                 total-tips-sent: (+ (get total-tips-sent current-rep) tip-amount)})
            (ok true))))


;; Define conditional tips storage
(define-map conditional-tips
    {tip-id: uint}
    {amount: uint, 
     condition: (string-ascii 100),
     completed: bool,
     recipient: principal})

(define-data-var conditional-tip-counter uint u0)

(define-public (create-conditional-tip 
    (amount uint) 
    (condition (string-ascii 100))
    (recipient principal))
    (begin
        (asserts! (> amount u0) (err u100))
        (var-set conditional-tip-counter (+ (var-get conditional-tip-counter) u1))
        (map-set conditional-tips
            {tip-id: (var-get conditional-tip-counter)}
            {amount: amount,
             condition: condition,
             completed: false,
             recipient: recipient})
        (ok (var-get conditional-tip-counter))))



;; Define subscription storage
(define-map tip-subscriptions
    {subscription-id: uint}
    {subscriber: principal,
     recipient: principal,
     amount: uint,
     period: uint,
     active: bool})

(define-data-var subscription-counter uint u0)

(define-public (create-subscription 
    (recipient principal)
    (amount uint)
    (period uint))
    (begin
        (asserts! (> amount u0) (err u100))
        (var-set subscription-counter (+ (var-get subscription-counter) u1))
        (map-set tip-subscriptions
            {subscription-id: (var-get subscription-counter)}
            {subscriber: tx-sender,
             recipient: recipient,
             amount: amount,
             period: period,
             active: true})
        (ok (var-get subscription-counter))))