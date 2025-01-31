(load "unit-test.scm")
(define ie (interaction-environment))
(define (str<->symb s)
  (if (symbol? s)
      (symbol->string s)
      (string->symbol s)))

;#1
(display "#1\n")
(define memoized-factorial
  (let loop ((memo '()))
    (lambda (x)
      (if (<= x 1)
          1
          (let ((memo-val (assoc x memo)))
            (if memo-val
                  (cadr memo-val)
                (let ((res (* x (memoized-factorial (- x 1)))))
                  (set! memo (cons (list x res) memo))
                  res)))))))

(define fact-tests
  (list
   (test (memoized-factorial 4) 24)
   (test (memoized-factorial 0) 1)
   (test (memoized-factorial 3) 6)
   (test (memoized-factorial 5) 120)
   (test (memoized-factorial 1) 1)))
(run-tests fact-tests)

;#2
(display "\n#2\n")

(define-syntax lazy-cons
  (syntax-rules ()
    ((lazy-cons head tail)
     (cons head (delay tail)))))

(define (lazy-car p)
  (if (pair? p)
  (car p)
  p))

(define (lazy-cdr p)
  (if (pair? p)
  (force (cdr p))))

(define (lazy-head xs k)
  (if (= k 0)
      (list)
      (cons (lazy-car xs) (lazy-head (lazy-cdr xs) (- k 1)))))

(define (lazy-ref xs n)
  (if (= n 0)
      (lazy-car xs)
      (lazy-ref (lazy-cdr xs) (- n 1))))


(lazy-ref '(1 2 3 4) 0)
  

(define (naturals n)
  (lazy-cons n (naturals (+ n 1))))

(define (factorials)
  (let loop ((p 1) (n 1))
    (lazy-cons (* p n) (loop (* p n) (+ n 1)))))

(define (lazy-factorial n)
  (list-ref (lazy-head (factorials) n)
            (- n 1)))

;test of natural numbers
(display "Naturals:\n")
(display (lazy-head (naturals 10) 12)) (newline)

;test of lazy-factorial
(display "\nFactorial:\n")
(begin
  (display (lazy-factorial 10)) (newline)
  (display (lazy-factorial 50)) (newline))

;#3
(display "\n#3\n")

(define (read-words)
  (let loop ((words '()) (word ""))
    (if (eof-object? (peek-char))
        (reverse (if (> (string-length word) 0)
                     (cons word words)
                     words))
        (let ((char (read-char)))
          (if (or (equal? char #\space)
                  (equal? char #\newline)
                  (equal? char #\tab))
              (if (> (string-length word) 0)
                  (loop (cons word words) "")
                  (loop words ""))
              (loop words (string-append word (string char))))))))


;#4
(display "\n#4\n")

(define-syntax define-struct
  (syntax-rules ()
    ((define-struct name (field1 ...))
     (begin
       (eval (list 'define
                      (str<->symb (string-append "make-" (str<->symb 'name)))
                      (lambda (field1 ...)
                        (list (list 'type 'name) (list 'field1 field1) ...))) ie)
       (eval (list 'define
                      (str<->symb (string-append (str<->symb 'name) "?"))
                      (lambda (x)
                        (and (list? x) (not (null? x))
                             (let ((ares (assoc 'type x)))
                               (and ares (equal? (cadr ares) 'name)))))) ie)
       (eval (list 'define
                       (str<->symb (string-append (str<->symb 'name) "-" (str<->symb 'field1)))
                       (lambda (x)
                         (cadr (assoc 'field1 (cdr x))))) ie) ...
       (eval (list 'define
                       (str<->symb (string-append "set-" (str<->symb 'name) "-" (str<->symb 'field1) "!"))
                       (lambda (x val)
                         (set-car! (cdr (assoc 'field1 (cdr x))) val))) ie) ... ))))



(define-struct pos (row col)) ; Объявление типа pos
(define p (make-pos 1 2))     ; Создание значения типа pos

(define struct-tests
  (list
   (test (pos? p) #t)
   (test (pos-row p) 1)
   (test (pos-col p) 2)))
(run-tests struct-tests)

(set-pos-row! p 3) ; Изменение значения в поле row
(set-pos-col! p 4) ; Изменение значения в поле col

(define struct-tests2
  (list
   (test (pos-row p) 3)
   (test (pos-col p) 4)))

(run-tests struct-tests2)

;#5
(display "\n#5\n")

(define-syntax define-data
  (syntax-rules ()
    ((_ data-name ((name field1 ...) ...))
     (begin
       (eval (list 'define
                      'name
                      (lambda (field1 ...)
                        (list (list 'd-name 'data-name) (list 't-name 'name)
                              (list 'field1 field1) ...))) ie) ...
       (eval (list 'define
                      (str<->symb (string-append (str<->symb 'data-name) "?"))
                      (lambda (x)
                        (and (list? x) (>= (length x) 2)
                             (let ((data-res (assoc 'd-name x)))
                               (and data-res (equal? (cadr data-res) 'data-name)))))) ie)))))

(define-syntax match
  (syntax-rules ()
    ((_ x ((name field1 ...) expr) ...)
       (cond
         ((equal? (cadadr x) 'name)
           (let ((field1 (cadr (assoc 'field1 x))) ...)
             expr))
          ...
          (else x)))))


; Определяем тип
;
(define-data figure ((square a)
                     (rectangle a b)
                     (triangle a b c)
                     (circle r)))

; Определяем значения типа
;
(define s (square 10))
(define r (rectangle 10 20))
(define t (triangle 10 20 30))
(define c (circle 10))

; Пусть определение алгебраического типа вводит
; не только конструкторы, но и предикат этого типа:
;
(display (and (figure? s)
              (figure? r)
              (figure? t)
              (figure? c))) (newline)

(define pi (acos -1)) ; Для окружности
  
(define (perim f)
  (match f 
    ((square a)       (* 4 a))
    ((rectangle a b)  (* 2 (+ a b)))
    ((triangle a b c) (+ a b c))
    ((circle r)       (* 2 pi r))))
  
(display (perim s)) (newline)
(display (perim r)) (newline)
(display (perim t)) (newline)
(display (perim c)) (newline)