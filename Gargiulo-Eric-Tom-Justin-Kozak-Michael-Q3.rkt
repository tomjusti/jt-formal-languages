#lang racket
(require fsm)

(define B
  (make-ndfa '(Q0 Q1 Q2 Q3 Q4 Q5)
             '(a b)
             'Q0
             '(Q4)
             '((Q0 a Q1)
               (Q1 b Q2)
               (Q2 b Q3)
               (Q3 a Q4)
               (Q5 a Q4)
               (Q5 b Q4))))

(define C
  (make-ndfa '(Q0 Q1)
             '(a b)
             'Q0
             '(Q1)
             '((Q0 a Q1))))

(define D
  (make-ndfa '(Q0 Q1 Q2 Q3)
             '(a b)
             'Q0
             '(Q1)
             '((Q0 a Q1)
               (Q1 b Q3)
               (Q3 b Q3)
               ;(Q3 a Q1)
               (Q2 b Q0))))


;; member?: X, (list-of-X) -> boolean
;; Purpose: to return true if (eqv? X Y) where Y is an element of (listof X)
(define member?
  (lambda (element lst)
    (cond
      [(empty? lst) #f]
      [(eqv? element (car lst)) #t]
      [else (member? element (cdr lst))])))

;; reachable4: ndfa -> (list-of-sym)
;; Purpose: to return a list of all reachable states from the start state of ndfa
(define (reachable4 ndfa)
  (let*
      ((rules (sm-getrules ndfa)) ; list of rules of the ndfa
       (i (length (sm-getstates ndfa)))) ; used to limit recursion depth
    (local ((define (reach-aux r visited)
             (cond
               [(zero? i) visited]
               [(empty? r) (begin
                             (set! i (- i 1)) ;; whenever a pass is completed, i is decreased
                                              ;; at most, recursion can occur one time per state in the machine
                             (reach-aux rules visited))] ;; list of rules has been scanned, reset rules for another pass
               ;; found a member of visited pointing to a state not already visited
               [(and (member? (caar r) visited) (not (member? (caddar r) visited))) (reach-aux (cdr r) (cons (caddar r) visited))]
               [else ;; did not find member of visited
                (reach-aux (cdr r) visited)])))
      (reach-aux rules (list (sm-getstart ndfa)))))) ;; "visited" only contains the start state by default


;; path-to-final: sym, ndfa -> (list-of-sym)
;; Purpose: to return a list of all states in ndfa that are on a path to the final states of ndfa
;; these are made final states in the prefix ndfa, as any state not on a path to final would not be reached by a valid prefix
(define (path-to-final ndfa)
  (let*
      ((rules (sm-getrules ndfa)) ;; list of rules of the ndfa
       (i (length (sm-getstates ndfa))) ;; used to limit recursion depth
       (reachable (reachable4 ndfa)))
    (local ((define (reach-aux r visited)
              (cond
                [(zero? i) visited]
                [(empty? r) (begin
                              (set! i (- i 1))
                              (reach-aux rules visited))] ;; list of rules has been scanned, reset rules for another pass
                [(and (member? (caddar r) visited) (not (member? (caar r) visited)) (member? (caar r) reachable)) (reach-aux (cdr r) (cons (caar r) visited))] ; found a member of visited pointing to a state not already visited
                [else ;; did not find member of visited
                 (reach-aux (cdr r) visited)])))
      (reach-aux rules (sm-getfinals ndfa)))))


; ndfa -> listof sym
; return a list of rules of ndfa not containing "silly" rules
;(define (nonsilly ndfa)
;  (let*
;      ((silly (reachable4 ndfa))
;       (res '())
;       (rules (sm-getrules ndfa)))
;    (cond
;      [(empty? silly) res]
;      [(member? 

;(define (nonsilly-grammar ndfa)
;  (sm->grammar (make-ndfa (reachable4 ndfa)
;                          (sm-getalphabet ndfa)
;                          (sm-getstart ndfa)
;                          (sm-getfinals ndfa)
;                          (returnsilly ndfa))))

(define DFA1 (make-dfa '(S U V T D)
                       '(a b)
                       'S
                       '(S V T)
                       `((S a U)
                         (S b U)
                         (U a V)
                         (U b T)
                         (V a D)
                         (V b D)
                         (T a D)
                         (T b U)
                         (D a D)
                         (D b D))))

(define (in-reach? x fa)
  (not (member? x (path-to-final fa))))

(define (sillystates ndfa)
  (filter (in-reach? (sm-getstates ndfa) ndfa) (sm-getstates ndfa)))

sillystates

; listof sym listof sym -> bool
; return true if any element of the first list appears in the second
(define (member-aux? L1 L2)
  (cond
    [(empty? L1) #f]
    [(member? (car L1) L2) #t]
    [else (member-aux? (cdr L1) L2)]))

(define (remove-silly ndfa)
  (let*
      ((silly (filter (lambda (x) (not (member? x (path-to-final ndfa)))) (sm-getstates D)))
       (rules (sm-getrules ndfa))
       (newrules '()))
    (local
      [(define (remove-aux los lor)
         (cond
           [(empty? rules) newrules]
           [(not (member-aux? silly rules)) (cons (car rules) newrules)] ; nonsilly rule found, added to newrules
           [else (remove-aux los (cdr lor))]))]
      (remove-aux silly rules))))

(define new-rules
  (lambda (lor lou)
    (if (null? lor) lor
        (if (or (member? (caar lor) lou) (member? (caddar lor) lou)) (new-rules (cdr lor) lou)
            (cons (car lor) (new-rules (cdr lor) lou))))))
