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



(define-map user-streaks 
    {user: principal} 
    {current-streak: uint, last-tip-date: uint, longest-streak: uint})

(define-public (update-streak)
    (let ((current-data (default-to 
            {current-streak: u0, last-tip-date: u0, longest-streak: u0}
            (map-get? user-streaks {user: tx-sender}))))
        (map-set user-streaks
            {user: tx-sender}
            {current-streak: (+ (get current-streak current-data) u1),
             last-tip-date: block-height,
             longest-streak: (get longest-streak current-data)})
        (ok true)))


(define-map tip-groups
    {group-id: uint}
    {name: (string-ascii 50), members: (list 10 principal), goal: uint})

(define-data-var group-id-counter uint u0)

(define-public (create-tip-group (name (string-ascii 50)) (goal uint))
    (begin
        (var-set group-id-counter (+ (var-get group-id-counter) u1))
        (map-set tip-groups
            {group-id: (var-get group-id-counter)}
            {name: name,
             members: (list tx-sender),
             goal: goal})
        (ok (var-get group-id-counter))))


(define-map reward-tiers
    {tier: uint}
    {name: (string-ascii 20), threshold: uint, bonus: uint})

(define-map user-rewards
    {user: principal}
    {current-tier: uint, points: uint})

(define-public (process-reward (user principal) (amount uint))
    (let ((current-data (default-to
            {current-tier: u0, points: u0}
            (map-get? user-rewards {user: user}))))
        (map-set user-rewards
            {user: user}
            {current-tier: (+ (get current-tier current-data) u1),
             points: (+ (get points current-data) amount)})
        (ok true)))


(define-data-var contract-paused bool false)
(define-data-var contract-admin principal tx-sender)

(define-public (toggle-contract-pause)
    (begin
        (asserts! (is-eq tx-sender (var-get contract-admin)) (err u401))
        (var-set contract-paused (not (var-get contract-paused)))
        (ok (var-get contract-paused))))



(define-map multiplier-events
    {event-id: uint}
    {multiplier: uint, start-block: uint, end-block: uint, active: bool})

(define-data-var event-counter uint u0)

(define-public (create-multiplier-event (multiplier uint) (duration uint))
    (begin
        (var-set event-counter (+ (var-get event-counter) u1))
        (map-set multiplier-events
            {event-id: (var-get event-counter)}
            {multiplier: multiplier,
             start-block: block-height,
             end-block: (+ block-height duration),
             active: true})
        (ok (var-get event-counter))))



(define-map pending-recoveries
    {recovery-id: uint}
    {user: principal, amount: uint, deadline: uint})

(define-data-var recovery-counter uint u0)

(define-public (request-tip-recovery (amount uint))
    (begin
        (var-set recovery-counter (+ (var-get recovery-counter) u1))
        (map-set pending-recoveries
            {recovery-id: (var-get recovery-counter)}
            {user: tx-sender,
             amount: amount,
             deadline: (+ block-height u144)})
        (ok (var-get recovery-counter))))


(define-map gift-cards
    {card-id: uint}
    {amount: uint, creator: principal, redeemed: bool, recipient: (optional principal)})

(define-data-var gift-card-counter uint u0)

(define-public (create-gift-card (amount uint))
    (begin
        (var-set gift-card-counter (+ (var-get gift-card-counter) u1))
        (map-set gift-cards
            {card-id: (var-get gift-card-counter)}
            {amount: amount,
             creator: tx-sender,
             redeemed: false,
             recipient: none})
        (ok (var-get gift-card-counter))))

(define-public (redeem-gift-card (card-id uint))
    (let ((card (unwrap! (map-get? gift-cards {card-id: card-id}) (err u300))))
        (asserts! (not (get redeemed card)) (err u301))
        (map-set gift-cards
            {card-id: card-id}
            {amount: (get amount card),
             creator: (get creator card),
             redeemed: true,
             recipient: (some tx-sender)})
        (ok (get amount card))))



(define-map lottery-pool
    {round: uint}
    {total-amount: uint, participants: (list 100 principal), winner: (optional principal)})

(define-data-var lottery-round uint u0)
(define-data-var min-lottery-entry uint u10)

(define-public (enter-lottery)
    (let ((current-round (var-get lottery-round))
          (current-pool (default-to 
            {total-amount: u0, 
             participants: (list), 
             winner: none}
            (map-get? lottery-pool {round: current-round}))))
        (begin
            (asserts! (>= (var-get total-tips) (var-get min-lottery-entry)) (err u200))
            (map-set lottery-pool
                {round: current-round}
                {total-amount: (+ (get total-amount current-pool) u1),
                 participants: (unwrap-panic (as-max-len? 
                    (append (get participants current-pool) tx-sender) u100)),
                 winner: none})
            (ok true))))

(define-public (draw-lottery-winner)
    (let ((current-round (var-get lottery-round)))
        (begin
            (var-set lottery-round (+ current-round u1))
            (ok current-round))))




(define-map tip-delegates
    {delegator: principal}
    {delegate: principal, allowance: uint, expiry: uint})

(define-public (set-tip-delegate (delegate principal) (allowance uint) (duration uint))
    (begin
        (map-set tip-delegates
            {delegator: tx-sender}
            {delegate: delegate,
             allowance: allowance,
             expiry: (+ block-height duration)})
        (ok true)))

(define-public (tip-through-delegate (amount uint) (delegator principal))
    (let ((delegation (unwrap! (map-get? tip-delegates {delegator: delegator}) (err u400))))
        (begin
            (asserts! (is-eq tx-sender (get delegate delegation)) (err u401))
            (asserts! (>= (get allowance delegation) amount) (err u402))
            (asserts! (>= (get expiry delegation) block-height) (err u403))
            (map-set tip-delegates
                {delegator: delegator}
                {delegate: (get delegate delegation),
                 allowance: (- (get allowance delegation) amount),
                 expiry: (get expiry delegation)})
            (send-tip amount))))



(define-map tip-challenges 
    {challenge-id: uint}
    {creator: principal,
     description: (string-ascii 200),
     reward: uint,
     completed: bool,
     winner: (optional principal)})

(define-data-var challenge-counter uint u0)

(define-public (create-challenge (description (string-ascii 200)) (reward uint))
    (begin
        (asserts! (> reward u0) (err u500))
        (var-set challenge-counter (+ (var-get challenge-counter) u1))
        (map-set tip-challenges
            {challenge-id: (var-get challenge-counter)}
            {creator: tx-sender,
             description: description,
             reward: reward,
             completed: false,
             winner: none})
        (ok (var-get challenge-counter))))

(define-public (complete-challenge (challenge-id uint) (winner principal))
    (let ((challenge (unwrap! (map-get? tip-challenges {challenge-id: challenge-id}) (err u501))))
        (begin
            (asserts! (is-eq tx-sender (get creator challenge)) (err u502))
            (asserts! (not (get completed challenge)) (err u503))
            (map-set tip-challenges
                {challenge-id: challenge-id}
                {creator: (get creator challenge),
                 description: (get description challenge),
                 reward: (get reward challenge),
                 completed: true,
                 winner: (some winner)})
            (send-tip (get reward challenge)))))


(define-map split-configurations
    {config-id: uint}
    {recipients: (list 5 {recipient: principal, percentage: uint})})

(define-data-var split-config-counter uint u0)

(define-public (create-split-config (recipients (list 5 {recipient: principal, percentage: uint})))
    (begin
        (asserts! (is-eq u100 (fold + (map get-percentage recipients) u0)) (err u600))
        (var-set split-config-counter (+ (var-get split-config-counter) u1))
        (map-set split-configurations
            {config-id: (var-get split-config-counter)}
            {recipients: recipients})
        (ok (var-get split-config-counter))))

(define-public (send-split-tip (config-id uint) (total-amount uint))
    (let ((config (unwrap! (map-get? split-configurations {config-id: config-id}) (err u601))))
        (begin
            (asserts! (> total-amount u0) (err u602))
            (map process-split-payment 
                (get recipients config))
            (ok total-amount))))

(define-private (get-percentage (split {recipient: principal, percentage: uint}))
    (get percentage split))

(define-private (process-split-payment (split {recipient: principal, percentage: uint}))
    (send-tip-to-recipient (get recipient split) (get percentage split)))


(define-map escrow-agreements
    {escrow-id: uint}
    {tipper: principal,
     recipient: principal,
     amount: uint,
     description: (string-ascii 200),
     status: (string-ascii 20),
     tipper-approved: bool,
     recipient-approved: bool,
     created-at: uint,
     expires-at: uint})

(define-data-var escrow-counter uint u0)

(define-public (create-escrow (recipient principal) (amount uint) (description (string-ascii 200)) (duration uint))
    (begin
        (asserts! (> amount u0) (err u700))
        (asserts! (not (is-eq tx-sender recipient)) (err u701))
        (asserts! (> duration u0) (err u702))
        (var-set escrow-counter (+ (var-get escrow-counter) u1))
        (map-set escrow-agreements
            {escrow-id: (var-get escrow-counter)}
            {tipper: tx-sender,
             recipient: recipient,
             amount: amount,
             description: description,
             status: "pending",
             tipper-approved: false,
             recipient-approved: false,
             created-at: block-height,
             expires-at: (+ block-height duration)})
        (var-set total-tips (+ (var-get total-tips) amount))
        (ok (var-get escrow-counter))))

(define-public (approve-escrow (escrow-id uint))
    (let ((agreement (unwrap! (map-get? escrow-agreements {escrow-id: escrow-id}) (err u703))))
        (begin
            (asserts! (is-eq (get status agreement) "pending") (err u704))
            (asserts! (< block-height (get expires-at agreement)) (err u705))
            (asserts! (or (is-eq tx-sender (get tipper agreement)) 
                         (is-eq tx-sender (get recipient agreement))) (err u706))
            (let ((new-tipper-approved (if (is-eq tx-sender (get tipper agreement)) 
                                         true 
                                         (get tipper-approved agreement)))
                  (new-recipient-approved (if (is-eq tx-sender (get recipient agreement)) 
                                            true 
                                            (get recipient-approved agreement))))
                (map-set escrow-agreements
                    {escrow-id: escrow-id}
                    {tipper: (get tipper agreement),
                     recipient: (get recipient agreement),
                     amount: (get amount agreement),
                     description: (get description agreement),
                     status: (if (and new-tipper-approved new-recipient-approved) 
                               "completed" 
                               "pending"),
                     tipper-approved: new-tipper-approved,
                     recipient-approved: new-recipient-approved,
                     created-at: (get created-at agreement),
                     expires-at: (get expires-at agreement)})
                (if (and new-tipper-approved new-recipient-approved)
                    (begin
                        (map-set user-tips
                            {user: (get recipient agreement)}
                            {amount: (+ (get amount agreement) 
                                      (default-to u0 
                                        (get amount (map-get? user-tips {user: (get recipient agreement)}))))})
                        (ok "released"))
                    (ok "approved"))))))

(define-public (cancel-escrow (escrow-id uint))
    (let ((agreement (unwrap! (map-get? escrow-agreements {escrow-id: escrow-id}) (err u707))))
        (begin
            (asserts! (is-eq tx-sender (get tipper agreement)) (err u708))
            (asserts! (is-eq (get status agreement) "pending") (err u709))
            (asserts! (not (get recipient-approved agreement)) (err u710))
            (map-set escrow-agreements
                {escrow-id: escrow-id}
                {tipper: (get tipper agreement),
                 recipient: (get recipient agreement),
                 amount: (get amount agreement),
                 description: (get description agreement),
                 status: "cancelled",
                 tipper-approved: (get tipper-approved agreement),
                 recipient-approved: (get recipient-approved agreement),
                 created-at: (get created-at agreement),
                 expires-at: (get expires-at agreement)})
            (var-set total-tips (- (var-get total-tips) (get amount agreement)))
            (ok "cancelled"))))

(define-public (expire-escrow (escrow-id uint))
    (let ((agreement (unwrap! (map-get? escrow-agreements {escrow-id: escrow-id}) (err u711))))
        (begin
            (asserts! (>= block-height (get expires-at agreement)) (err u712))
            (asserts! (is-eq (get status agreement) "pending") (err u713))
            (map-set escrow-agreements
                {escrow-id: escrow-id}
                {tipper: (get tipper agreement),
                 recipient: (get recipient agreement),
                 amount: (get amount agreement),
                 description: (get description agreement),
                 status: "expired",
                 tipper-approved: (get tipper-approved agreement),
                 recipient-approved: (get recipient-approved agreement),
                 created-at: (get created-at agreement),
                 expires-at: (get expires-at agreement)})
            (var-set total-tips (- (var-get total-tips) (get amount agreement)))
            (ok "expired"))))

(define-read-only (get-escrow-details (escrow-id uint))
    (ok (map-get? escrow-agreements {escrow-id: escrow-id})))

(define-read-only (get-user-escrows (user principal))
    (ok user))

(define-map flash-auctions
    {auction-id: uint}
    {creator: principal,
     description: (string-ascii 200),
     min-bid: uint,
     highest-bid: uint,
     highest-bidder: (optional principal),
     end-block: uint,
     status: (string-ascii 20),
     total-bidders: uint})

(define-map auction-bids
    {auction-id: uint, bidder: principal}
    {amount: uint})

(define-data-var auction-counter uint u0)

(define-public (create-flash-auction (description (string-ascii 200)) (min-bid uint) (duration uint))
    (begin
        (asserts! (> min-bid u0) (err u800))
        (asserts! (> duration u0) (err u801))
        (var-set auction-counter (+ (var-get auction-counter) u1))
        (map-set flash-auctions
            {auction-id: (var-get auction-counter)}
            {creator: tx-sender,
             description: description,
             min-bid: min-bid,
             highest-bid: u0,
             highest-bidder: none,
             end-block: (+ block-height duration),
             status: "active",
             total-bidders: u0})
        (ok (var-get auction-counter))))

(define-public (place-bid (auction-id uint) (bid-amount uint))
    (let ((auction (unwrap! (map-get? flash-auctions {auction-id: auction-id}) (err u802)))
          (existing-bid (default-to u0 
              (get amount (map-get? auction-bids {auction-id: auction-id, bidder: tx-sender})))))
        (begin
            (asserts! (is-eq (get status auction) "active") (err u803))
            (asserts! (< block-height (get end-block auction)) (err u804))
            (asserts! (> bid-amount (get highest-bid auction)) (err u805))
            (asserts! (>= bid-amount (get min-bid auction)) (err u806))
            (map-set auction-bids
                {auction-id: auction-id, bidder: tx-sender}
                {amount: bid-amount})
            (map-set flash-auctions
                {auction-id: auction-id}
                {creator: (get creator auction),
                 description: (get description auction),
                 min-bid: (get min-bid auction),
                 highest-bid: bid-amount,
                 highest-bidder: (some tx-sender),
                 end-block: (get end-block auction),
                 status: "active",
                 total-bidders: (if (is-eq existing-bid u0) 
                                  (+ (get total-bidders auction) u1)
                                  (get total-bidders auction))})
            (ok bid-amount))))

(define-public (finalize-auction (auction-id uint))
    (let ((auction (unwrap! (map-get? flash-auctions {auction-id: auction-id}) (err u807))))
        (begin
            (asserts! (>= block-height (get end-block auction)) (err u808))
            (asserts! (is-eq (get status auction) "active") (err u809))
            (map-set flash-auctions
                {auction-id: auction-id}
                {creator: (get creator auction),
                 description: (get description auction),
                 min-bid: (get min-bid auction),
                 highest-bid: (get highest-bid auction),
                 highest-bidder: (get highest-bidder auction),
                 end-block: (get end-block auction),
                 status: "finalized",
                 total-bidders: (get total-bidders auction)})
            (match (get highest-bidder auction)
                winner (begin
                    (map-set user-tips
                        {user: (get creator auction)}
                        {amount: (+ (get highest-bid auction) 
                                  (default-to u0 
                                    (get amount (map-get? user-tips {user: (get creator auction)}))))})
                    (ok "winner-paid"))
                (ok "no-winner")))))

(define-public (claim-refund (auction-id uint))
    (let ((auction (unwrap! (map-get? flash-auctions {auction-id: auction-id}) (err u810)))
          (user-bid (unwrap! (map-get? auction-bids {auction-id: auction-id, bidder: tx-sender}) (err u811))))
        (begin
            (asserts! (is-eq (get status auction) "finalized") (err u812))
            (asserts! (not (is-eq (some tx-sender) (get highest-bidder auction))) (err u813))
            (map-delete auction-bids {auction-id: auction-id, bidder: tx-sender})
            (ok (get amount user-bid)))))

(define-read-only (get-auction-details (auction-id uint))
    (ok (map-get? flash-auctions {auction-id: auction-id})))

(define-read-only (get-user-bid (auction-id uint) (bidder principal))
    (ok (map-get? auction-bids {auction-id: auction-id, bidder: bidder})))