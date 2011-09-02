;; evil-numbers -- increment/decrement numbers like in vim

;; Copyright (C) 2011 by Michael Markert
;; Author: 2011 Michael Markert <markert.michael@googlemail.com>
;; Created: 2011-09-02
;; Version: 0.
;; Keywords: numbers increment decrement octal hex binary

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;; Known Bugs:
;; See http://github.com/cofi/evil-numbers/issues

;; Install:

;; Usage:

;; Homepage: http://github.com/cofi/evil-numbers
;; Git-Repository: git://github.com/cofi/evil-numbers.git

(defun evil-numbers/inc-at-pt (amount)
  "Increment the number at point by `amount'"
  (interactive "p*")
  (save-match-data
    (if (not (or
              ;; numbers or format specifier in front
              (looking-back (rx (or (+? digit)
                                    (and "0" (or (and (in "bB") (*? (in "01")))
                                                 (and (in "oO") (*? (in "0-7")))
                                                 (and (in "xX") (*? (in "0-9A-Fa-f"))))))))
              ;; search for number in rest of line
              (re-search-forward (rx
                                  (or
                                   (and "0" (in "bB") (+? (in "01")))
                                   (and "0" (in "oO") (+? (in "0-7")))
                                   (and "0" (in "xX") (+? (in digit "a-fA-F")))
                                   (or (and "0" (not (in "bBoOxX"))) (+? digit))))
                                 (point-at-eol) t)))
        (error "No number at point or until end of line")
      (or
       ;; find binary literals
       (when (looking-back "0[bB][01]*")
         ;; already ensured there's only one -
         (skip-chars-backward "01")
         (search-forward-regexp "[01]*")
         (replace-match
          (evil-numbers/format-binary (+ amount (string-to-number (match-string 0) 2))
                                      (- (match-end 0) (match-beginning 0))))
         t)

       ;; find octal literals
       (when (looking-back "0[oO]-?[0-7]*")
         ;; already ensured there's only one -
         (skip-chars-backward "-01234567")
         (search-forward-regexp "-?\\([0-7]+\\)")
         (replace-match
          (format (format "%%0%do" (- (match-end 1) (match-beginning 1)))
                  (+ amount (string-to-number (match-string 0) 8))))
         t)

       ;; find hex literals
       (when (looking-back "0[xX]-?[0-9a-fA-F]*")
         ;; already ensured there's only one -
         (skip-chars-backward "-0123456789abcdefABCDEF")
         (search-forward-regexp "-?\\([0-9a-fA-F]+\\)")
         (replace-match
          (format (format "%%0%dX" (- (match-end 1) (match-beginning 1)))
                  (+ amount (string-to-number (match-string 0) 16))))
         t)

       ;; find decimal literals
       (progn
         (skip-chars-backward "0123456789")
         (skip-chars-backward "-")
         (when (looking-at "-?\\([0-9]+\\)")
           (replace-match
            (format (format "%%0%dd" (- (match-end 1) (match-beginning 1)))
                    (+ amount (string-to-number (match-string 0) 10))))
           t))
       (error "No number at point")))))

(defun evil-numbers/format-binary (number &optional width fillchar)
  "Format `NUMBER' as binary.
Fill up to `WIDTH' with `FILLCHAR' (defaults to ?0) if binary
representation of `NUMBER' is smaller."
  (let (nums
        (fillchar (or fillchar ?0)))
    (do ((num number (truncate num 2)))
        ((= num 0))
      (push (number-to-string (% num 2)) nums))
    (let ((len (length nums)))
      (apply #'concat
             (if (and width (< len width))
                 (make-string (- width len) fillchar)
               "")
             nums))))

(defun evil-numbers/dec-at-pt (amount)
  "Decrement the number at point by `amount'"
  (interactive "p*")
  (evil-numbers/inc-at-pt (- amount)))

(provide evil-numbers)
