;;; org-discuss.el --- Discuss with org-mode -*- lexical-binding: t -*-

;; Copyright (C) 2022  Free Software Foundation, Inc.

;; Author: Payard Clément <clement020302@gmail.com>
;; Maintainer: Payard Clément
;; URL: https://github.com/Cletip/org-discuss
;; Version: 0.0.1
;; Package-Requires: ((emacs "27.2") (org "9.4.4") (org-roam "2.0.0"))

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Here commentary

;;; Code:

(require 'subr-x)
(require 'org-roam)

(defvar org-discuss-pseudo ""
  "Set the tag to a heading/answer.")

(defvar org-discuss-discussion-directory ""
 "Set the tag to a heading/answer.")

(defvar org-discuss-capture-key ""
 "Where is map the capture for the new subject")

(defvar org-discuss-directory ""
"Directory where org-roam notes to subject are.")

(defvar org-discuss-propertie-creator "CREATOR"
"Name of the propertie for the creator of the message")

(defvar org-discuss-title
  (concat (format-time-string "%Y-%m-%d %T") " " ":" org-discuss-pseudo ":")
  "When inserting a answer, what is the format of the title")

(defvar org-discuss-db-location (if (string= org-roam-directory org-discuss-directory)
				    org-roam-db-location
				  (concat org-roam-directory "roam.db"))
  "Where is the db location")



(defun org-discuss--with-org-roam (func &rest args)
  "Evaluate FUNC with ARGS org-roam set for working as personnal questionning."
  (let* ((org-roam-directory org-discuss-directory)
         (org-roam-db-location org-discuss-db-location))
    (apply func args)))

(defun org-discuss-db-sync ()
  (interactive)
  (org-discuss--with-org-roam #'org-roam-db-sync))

(defun org-discuss-find-subject ()
  (interactive)
  (org-discuss--with-org-roam #'org-roam-node-find))

(defun org-discuss-insert-subject ()
  (interactive)
  (org-discuss--with-org-roam #'org-roam-node-insert))

(defun org-discuss-function-to-quote-a-message ()
  "Function to quote a part of a message in an aswer"
  (interactive)
  (if-let ((region-active-p (region-active-p))
           (text (string-trim (buffer-substring-no-properties (region-beginning) (region-end)))))
      (progn
	(deactivate-mark)
	(org-discuss-answer-current-heading)

        ;; insérer la quote
        (outline-next-heading)
        (open-line 5)
	(next-line 1)
        (org-insert-structure-template "quote")
        ;; (open-line 1)
        (insert text)
	(newline)
        (next-line 2))
    (message "Region is not active")))

(defun org-discuss-answer-current-heading ()
  "Create a new sub-heading to answer. If heading exist (with the good pseude), the cursor is under
  this heading"
  (interactive)
  (let ((position nil)
	(position-of-answer (progn (ignore-errors (outline-up-heading 0)) (point))))
    (goto-char position-of-answer)
    (if (not (save-excursion (org-goto-first-child)))
	(progn
	  (message "test")
	  (goto-char (org-element-property :end (org-element-at-point)))
	  (org-insert-subheading 1)
	  (org-discuss-set-properties))
      (progn
	;;cas 1, je suis pas encore sur le sous heading 1. J'y vais, je le fais
	;;et je fais tourner la boucle
	(org-goto-first-child)
	(when (org-discuss-answer-by-p org-discuss-pseudo)
	  (setq position (point)))
	(while (or
		;; si le titre suivant à un heading de même level
		(condition-case nil
		    (progn
		      (save-excursion (outline-forward-same-level 1))
		      (outline-forward-same-level 1)
		      t)
		  (error nil))
		(not position) ;; si jamais j'ai déjà trouvé ma réponse
		)
	  (when (org-discuss-answer-by-p org-discuss-pseudo)
	    (setq position (point))))
	(if position
	    (goto-char position)
	  ;; when the message doesn't exist yet
	  (progn
	    (ignore-errors (outline-up-heading 0))
	    (goto-char (org-element-property :end (org-element-at-point)))
	    (org-insert-subheading 1)
	    (org-discuss-set-properties)))))))

(defun org-discuss-answer-by-p (pseudo)
  "Return t if the answer at point is write by pseudo"
  ;; (string= (org-entry-get (point) org-discuss-propertie-creator) pseudo)
  (member pseudo (org-get-tags))
  )

(defun org-discuss-set-properties ()
  "Set correct properties for a message at point"
  (org-edit-headline org-discuss-title)
  (org-entry-put (point) org-discuss-propertie-creator org-discuss-pseudo))

(defun org-discuss-go-to-last-answer-of-subtree ()
  "Move to the last answer of the subtree"
  (interactive)
  (org-end-of-subtree)
  (outline-previous-heading)
  )

(with-eval-after-load 'org-roam
  (add-to-list 'org-roam-capture-templates
               `(,org-discuss-capture-key
		 "Org-discuss new subject" plain ,(concat (format "* %s"
								  org-discuss-title) "\n%?")
		 :target (file+head ,(format "%s/%s/${slug}.org" org-discuss-directory org-discuss-discussion-directory)
				    "#+title: ${title}\n")
		 :unnarrowed t)))

(provide 'org-discuss)
