;;; org-discuss.el --- Discuss with org-mode -*- lexical-binding: t -*-

;; Copyright (C) 2022  Free Software Foundation, Inc.

;; Author: Payard Clément <clement020302@gmail.com>
;; Maintainer: Payard Clément
;; URL: https://github.com/Cletip/org-discuss
;; Version: 0.0.1
;; Package-Requires: ((emacs "27.2"))

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


(defvar org-discuss-pseudo
""
"Variable to set the tag to a heading/answer.")

(defvar org-discuss-discussion-directory
 ""
 "Variable to set the tag to a heading/answer.")

(defvar org-discuss--org-roam-dir "/home/utilisateur/mesdocuments/personnel/discussionTheSystem/"
  "Directory where org-roam notes to subject are.")

(defun org-discuss--with-org-roam (func &rest args)
  "Evaluate FUNC with ARGS org-roam set for working as personnal questionning."
  (let* ((org-roam-directory org-discuss--org-roam-dir)
         (org-roam-db-location (concat org-roam-directory "/roam.db")))
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
           (text (buffer-substring-no-properties (point-min) (point-max)))
           )
      (progn
        (message "Region active")
        (beginning-of-buffer)
        (outline-next-heading)
        (when (not (member org-discuss-pseudo (org-get-tags))) ;;next heading is without the tag ?
          (previous-line)
          (org-insert-heading)
          (insert (format-time-string "%Y-%m-%d %T")))

        ;; insérer la quote
        (outline-next-heading)
        (open-line 3)
        (org-insert-structure-template "quote")
        (open-line 1)
        (insert text)
        (next-line 3)
        )
    (message "Region is not active")))

(add-to-list 'org-roam-capture-templates
             '("N" "Nouveau sujet" plain "%?"
               :target (file+head (format "%s/${slug}.org" org-discuss-discussion-directory)
                                  "#+title: ${title}\n")
               :unnarrowed t))

(provide 'org-discuss)
