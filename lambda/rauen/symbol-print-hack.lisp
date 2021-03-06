;;; -*- Mode:LISP; Package:SI; Cold-Load:T; Base:8; Readtable:ZL -*-

(defun print-symbol (symbol stream &optional (rdtbl (current-readtable)))
  (let ((cp (current-package t))
        (sym-pkg (symbol-package symbol))
        (sym-name (symbol-name symbol))
        tem)
    (when *print-escape*
      (flet ((pp (pkg internal &aux tem PACKAGE-NAME PREFIX-NAME)
               (IF (PACKAGES::PACKAGE-REP-P PKG)
                   (SETQ PACKAGE-NAME (PACKAGES::PACKAGE-REP-NAME PKG)
                         PREFIX-NAME  (PACKAGES::PACKAGE-REP-NAME PKG))
                   (SETQ PACKAGE-NAME (PKG-NAME PKG)
                         PREFIX-NAME  (PKG-PREFIX-PRINT-NAME PKG)))
               (setq internal (if (memq internal '(:external :inherited))
                                  (pttbl-package-prefix rdtbl)
                                  (pttbl-package-internal-prefix rdtbl)))
               (block pp
                 (when (setq tem PREFIX-NAME)
                   (setq tem (assoc-equal tem (si:pkg-refname-alist cp)))
                   (when (or (null tem)
                             (eq (cdr tem) pkg))
                     (print-symbol-name PREFIX-NAME stream rdtbl)
                     (send stream :string-out internal)
                     (return-from pp)))
                 (setq tem (assoc-equal PACKAGE-NAME (si:pkg-refname-alist cp)))
                 (when (or (null tem)
                           (eq (cdr tem) pkg))
                   (print-symbol-name PACKAGE-NAME stream rdtbl)
                   (send stream :string-out internal)
                   (return-from pp))
                 ;; what a horrible piece of design that there is not pkg-name-and-nicknames
                 (dolist (n (pkg-nicknames pkg))
                   (setq tem (assoc-equal n (si:pkg-refname-alist cp)))
                   (when (or (null tem)
                             (eq (cdr tem) pkg))
                     (print-symbol-name n stream rdtbl)
                     (send stream :string-out internal)
                     (return-from pp)))
                 (print-symbol-name PACKAGE-NAME stream rdtbl)
                 (send stream :string-out "#:"))
               nil)
             (pg ()
                (and *print-gensym*
                     (send stream :string-out (pttbl-uninterned-symbol-prefix rdtbl)))))
        (cond ((null sym-pkg)
               (if (or (null cp)
                       (multiple-value-bind (found foundp)
                           (find-symbol sym-name cp)
                         (or (not foundp)
                             (not (eq found symbol)))))
                   (pg)))
              ((eq sym-pkg pkg-keyword-package)
               (send stream :tyo #/:))
              ;; people bind *package* nil expecting to have symbol home package printed
              ((null cp)
               (multiple-value-bind (nil foundp xp)
                   (find-symbol sym-name sym-pkg)
                 (if (null xp)
                     (pg)
                   (print-symbol-name (or (pkg-prefix-print-name xp) (pkg-name xp))
                                      stream rdtbl)
                   (send stream :string-out (if (memq foundp '(:external :inherited))
                                                (pttbl-package-prefix rdtbl)
                                              (pttbl-package-internal-prefix rdtbl))))))
              ((PACKAGES::PACKAGE-REP-P SYM-PKG)
               (PP SYM-PKG T))
              (t
               (multiple-value-bind (found foundp xp)
                   (find-symbol sym-name cp)
                 (cond ((not foundp)
                        (multiple-value-setq (nil foundp)
                          (find-symbol sym-name sym-pkg))
                        (pp sym-pkg foundp))
                       ((eq found symbol)
                        (when (assq symbol (rdtbl-symbol-substitutions rdtbl))
                          (pp xp foundp)))
                       (t
                        (unless (and (setq tem (assq found (rdtbl-symbol-substitutions rdtbl)))
                                     (eq (cdr tem) symbol))
                          (multiple-value-setq (nil foundp)
                            (find-symbol sym-name sym-pkg))
                          (pp sym-pkg foundp)))))))))
    (print-symbol-name sym-name stream rdtbl)))
