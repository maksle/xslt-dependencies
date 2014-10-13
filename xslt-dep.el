;; xslt-dep.el --- Find XSLT dependencies and display them
;; in a graph.

;; Copyright (C) 2014 Maksim Grinman

;; Author: Maksim Grinman <maxchgr@gmail.com>
;; Keywords: xslt

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;; 
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.
;; 
;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <http://www.gnu.org/licenses/>.

;; Commentary:

;; This was made with XSLT 1.0 in mind as I do not have much experience with
;; XSLT 2.0. It also assumes that you have graphviz installed, which is readily
;; available at http://www.graphviz.org. Recursive includes/imports generates an
;; error and you can review the dot file to see what happened.
;; 
;; Put xslt-dep.el in your load path and keep xslt-dep.sh in the same folder.
;; 
;; (add-hook 'nxml-mode-hook (lambda () 
;;   (require 'xslt-dep)
;;   (xslt-dep-mode)))
;;
;; Visit an .xsl file that imports/includes other files and try C-c C-s d. This
;; generates a graphviz .dot file at `xd/deps-dot-output'. The graphviz dot
;; executable executes the dot file and outputs the graph.
;; 
;; I was able to use this in a Windows cygwin environment by using something
;; like this in the shell script:
;; 
;;   #!/bin/bash
;;   
;;   /cygdrive/c/location/of/dot.exe -Tpng $(cygpath -w $1) -o $(cygpath -w $2);
;;   /cygdrive/c/location/of/Foxit\ Reader.exe $(cygpath -w $2);


(defvar xd/deps-dot-shell-file (concat (file-name-directory (locate-library "xslt-dep")) "xslt-dep.sh")
  "Location of shell file to run graphviz executable dot and
  display the result. The default tries to get the source
  location of this package and use the shell file there. It is
  better to define your own that suits your needs.")

(defvar xd/deps-dot-file "/tmp/xslt-deps.dot"
  "Temp dot file to write to.")

(defvar xd/deps-dot-output "/tmp/xslt-deps.ps"
  "Output file of dot command")

(defvar xd/deps-replacements
  '(("/home/maks/Documents/learn/xslt/" . "$xls/docs/"))
  "Assoc list of file name replacements to make the graph smaller.")

(defun xd/dep-replace (dep)
  "Reduce file names for graph using `deps-replacement'"
  (if (find-if (lambda (replacement)
                 (string-match (car replacement) dep))
               xd/deps-replacements)
      (substring dep (match-end 0))
    dep))

(defun xd/find-deps-in-file (file)
  "Finds import/include dependencies in FILE. Returns list like
'(FILE . '(dep1 dep2)) or '(FILE . nil)"
  (interactive)
  (let (deps)
    (save-excursion
      (set-buffer (find-file-noselect file))
      (goto-char (point-min))
      (while (re-search-forward "<xsl:\\(include\\|import\\) href=\"\\(.*\\)\"" nil t)
        (let* ((match (match-string-no-properties 2))
               (dep (if (fboundp 'cygwin-convert-file-name-from-windows)
                       (cygwin-convert-file-name-from-windows match t)
                     (expand-file-name match))))
          (if (file-readable-p dep)
              (setq deps (cons dep deps))
            (error "Error: %s referenced in %s is not real file or unreadable" dep file))))
      (cons file (list (nreverse deps))))))

(defun xd/write-dot-notation-for-node (deps-node)
  "Subroutine of `xd/write-dot-notation-recursive.' Writes dot notation for
single node and its dependencies."
  (unless (eq nil (cadr deps-node))
    (mapc (lambda (dep)
            (insert (format "\"%s\" -> \"%s\";\n"
                            (xd/dep-replace (car deps-node))
                            (xd/dep-replace dep))))
          (cadr deps-node))))

(defun xd/write-dot-notation-recursive (file &optional deps-processed)
  "Subroutine of `xd/write-dot-buffer.' Write dot notation inside
the digraph block of FILE and its dependencies into dot file
`xd/deps-dot-file'"
  (let ((deps-node (xd/find-deps-in-file file)))
    (if (member (car deps-node) deps-processed)
        (error "%s duplicate reference" (car deps-node))
      (xd/write-dot-notation-for-node deps-node)
      (setq deps-processed (cons (car deps-node) deps-processed))
      (mapc (lambda (dep)
              (xd/write-dot-notation-recursive dep deps-processed))
            (cadr deps-node)))))

(defun xd/write-dot-buffer (file)
  "Writes entire dot file to file `xd/deps-dot-file'."
  (with-temp-file xd/deps-dot-file
    (and (fboundp 'graphviz-dot-mode)
         (graphviz-dot-mode))
    (erase-buffer)
    (insert "digraph XSLT_dependencies {")
    (newline)
    (xd/write-dot-notation-recursive file)
    (insert "}")
    (indent-region (point-min) (point-max)))
  (view-file-other-window xd/deps-dot-file))

(defun xd/execute-dot-file ()
  "Executes dot file `xd/deps-dot-file'."
  (message "calling %s" xd/deps-dot-shell-file)
  (call-process xd/deps-dot-shell-file
                nil 0 nil xd/deps-dot-file xd/deps-dot-output)
  (message "Viewing %s" xd/deps-dot-file))

(defun xd/show-dependencies ()
  "Entry public function that finds the xslt 1.0 file
dependencies of current `buffer-file-name' and shows a graph."
  (interactive)
  (xd/write-dot-buffer (buffer-file-name))
  (when (file-exists-p xd/deps-dot-output)
    (delete-file xd/deps-dot-output t))
  (xd/execute-dot-file))

(define-minor-mode xslt-dep-mode
  "Find xslt 1.0 files\' dependencies and display graph."
  :keymap (let ((map (make-sparse-keymap)))
            (define-key map (kbd "C-c C-s d") 'xd/show-dependencies)
            map))

(provide 'xslt-dep)
