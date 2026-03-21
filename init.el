;; -*- lexical-binding: t; -*-

;;; Elpaca bootstrap
(defvar elpaca-installer-version 0.12)
(defvar elpaca-directory (expand-file-name "elpaca/" user-emacs-directory))
(defvar elpaca-builds-directory (expand-file-name "builds/" elpaca-directory))
(defvar elpaca-sources-directory (expand-file-name "sources/" elpaca-directory))
(defvar elpaca-order '(elpaca :repo "https://github.com/progfolio/elpaca.git"
                              :ref nil :depth 1 :inherit ignore
                              :files (:defaults "elpaca-test.el" (:exclude "extensions"))
                              :build (:not elpaca-activate)))
(let* ((repo  (expand-file-name "elpaca/" elpaca-sources-directory))
       (build (expand-file-name "elpaca/" elpaca-builds-directory))
       (order (cdr elpaca-order))
       (default-directory repo))
  (add-to-list 'load-path (if (file-exists-p build) build repo))
  (unless (file-exists-p repo)
    (make-directory repo t)
    (when (<= emacs-major-version 28) (require 'subr-x))
    (condition-case-unless-debug err
        (if-let* ((buffer (pop-to-buffer-same-window "*elpaca-bootstrap*"))
                  ((zerop (apply #'call-process `("git" nil ,buffer t "clone"
                                                  ,@(when-let* ((depth (plist-get order :depth)))
                                                      (list (format "--depth=%d" depth) "--no-single-branch"))
                                                  ,(plist-get order :repo) ,repo))))
                  ((zerop (call-process "git" nil buffer t "checkout"
                                        (or (plist-get order :ref) "--"))))
                  (emacs (concat invocation-directory invocation-name))
                  ((zerop (call-process emacs nil buffer nil "-Q" "-L" "." "--batch"
                                        "--eval" "(byte-recompile-directory \".\" 0 'force)")))
                  ((require 'elpaca))
                  ((elpaca-generate-autoloads "elpaca" repo)))
            (progn (message "%s" (buffer-string)) (kill-buffer buffer))
          (error "%s" (with-current-buffer buffer (buffer-string))))
      ((error) (warn "%s" err) (delete-directory repo 'recursive))))
  (unless (require 'elpaca-autoloads nil t)
    (require 'elpaca)
    (elpaca-generate-autoloads "elpaca" repo)
    (let ((load-source-file-function nil)) (load "./elpaca-autoloads"))))
(add-hook 'after-init-hook #'elpaca-process-queues)
(elpaca `(,@elpaca-order))

;;; use-package integration
(elpaca elpaca-use-package
  (elpaca-use-package-mode))

(use-package org
  ;; :ensure (:wait t)
  :ensure t
  :demand t
  :bind (("C-c a" . org-agenda))
  :init
  (setq org-modules nil)
  :custom
  (org-agenda-files
   '("~/org/index.org" "~/org/personal.org" "~/org/work.org" "~/org/habits.org"))
  (org-refile-allow-creating-parent-nodes 'confirm)
  (org-adapt-indentation t)
  (org-agenda-start-on-weekday 0)
  (org-clock-idle-time 10)
  (org-directory "~/org")
  (org-log-done nil)
  (org-log-repeat nil)
  (org-stuck-projects
   '("+project-maybe-TODO=\"DONE\"-TODO=\"SKIP\""
     ("TODO" "NEXT" "WAIT")
     nil ""))
  (org-tags-exclude-from-inheritance '("project"))
  (org-agenda-custom-commands
   '(("n" "Agenda and all TODO's"
      ((agenda "" nil)
       (todo "NEXT"
			 ((org-agenda-overriding-header
			   (concat "Next Actions "
					   (my/org-agenda-wip-count
						'("NEXT"))))
			  (org-tags-match-list-sublevels 'indented))))
      nil)
     ("K" "Kanban"
      ((todo "TODO"
			 ((org-agenda-overriding-header
			   (concat "To Do "
					   (my/org-agenda-wip-count
						'("TODO"))))
			  (org-tags-match-list-sublevels 'indented)))
       (todo "NEXT"
			 ((org-agenda-overriding-header
			   (concat "Next Actions "
					   (my/org-agenda-wip-count
						'("NEXT"))))
			  (org-tags-match-list-sublevels 'indented)))
       (todo "WAIT"
			 ((org-agenda-overriding-header
			   (concat "Waiting "
					   (my/org-agenda-wip-count
						'("WAIT"))))
			  (org-tags-match-list-sublevels 'indented)))
       (todo "DONE|SKIP"
			 ((org-agenda-overriding-header
			   (concat "Done & Cancelled "
					   (my/org-agenda-wip-count
						'("DONE" "SKIP"))))
			  (org-tags-match-list-sublevels 'indented)))))
     ("1" "Q1 - Important & Urgent" tags-todo "+important+urgent")
     ("2" "Q2 - Important & Not Urgent" tags-todo "+important-urgent")
     ("3" "Q3 - Not Important & Urgent" tags-todo "-important+urgent")
     ("4" "Q4 - Not Important & Not Urgent" tags-todo "-important-urgent")
     ("E" "Eisenhower Matrix"
      ((tags-todo "+important+urgent"
				  ((org-agenda-overriding-header "Do First")
				   (org-agenda-sorting-strategy
					'(priority-down))))
       (tags-todo "+important-urgent"
				  ((org-agenda-overriding-header "Schedule")
				   (org-agenda-sorting-strategy
					'(priority-down))))
       (tags-todo "-important+urgent"
				  ((org-agenda-overriding-header "Delegate")
				   (org-agenda-sorting-strategy
					'(priority-down))))
       (tags-todo "-important-urgent"
				  ((org-agenda-overriding-header "Eliminate or Do later")
				   (org-agenda-sorting-strategy
					'(priority-down))))))
     ("p" "List of all projects" tags "+project-maybe-TODO=\"DONE\"" nil)
     ("x" "Unscheduled TODOs" tags "-SCHEDULED={.+}-DEADLINE={.+}/!+TODO" nil)))
  :config
  (setq org-refile-targets
        '((nil :maxlevel . 7)
          (org-agenda-files :maxlevel . 7))
        org-refile-use-outline-path 'file
        org-outline-path-complete-in-steps nil)
  (setq org-agenda-show-future-repeats nil)
  (setq org-list-allow-alphabetical t)
  )
(cl-pushnew 'org elpaca-ignored-dependencies)

;;; Redirect Custom writes to separate file
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(when (file-exists-p custom-file)
  (load custom-file))

;;;; ============================================================
;;;; Built-in packages
;;;; ============================================================

(use-package emacs
  :ensure nil
  :bind (("C-c b" . my/create-scratch-buffer)
         ("<f5>" . revert-buffer))
  :hook (emacs-startup . (lambda () (select-frame-set-input-focus (selected-frame))))
  :custom
  (default-input-method "russian-computer")
  (font-use-system-font t)
  (scroll-conservatively 5)
  :config
  (pixel-scroll-precision-mode 1)
  (defun my/create-scratch-buffer (&optional mode)
    "Create a new scratch buffer.
    MODE allows specifying the mode the buffer should start in."
    (interactive
     (list (completing-read "Mode (leave blank for default): "
                            (let (modes)
                              (mapatoms (lambda (sym)
                                          (when (and (string-suffix-p "-mode" (symbol-name sym))
                                                     (commandp sym)
                                                     (not (memq sym minor-mode-list)))
                                            (push (symbol-name sym) modes))))
                              (sort modes 'string<))
                            nil t)))
    (let ((buffer (generate-new-buffer (if mode
                                           (format "*scratch-%s*" mode)
                                         "*scratch*"))))
      (switch-to-buffer buffer)
      (when mode
        (funcall (intern mode)))
      (setq default-directory "/tmp/")
      (message "Created a scratch buffer in %s mode." (or mode "default")))))

(use-package exec-path-from-shell
  :ensure t
  :if (memq window-system '(mac ns))
  :config
  (exec-path-from-shell-initialize))

(use-package frame
  :ensure nil
  :config
  (undelete-frame-mode 1))

(use-package autorevert
  :ensure nil
  :config
  (global-auto-revert-mode +1)
  (setq auto-revert-interval 2
        global-auto-revert-non-file-buffers t
        auto-revert-verbose t))

(use-package savehist
  :ensure nil
  :init (savehist-mode))

(use-package recentf
  :ensure nil
  :config (recentf-mode 1)
  :custom (recentf-max-saved-items 200))

(use-package saveplace
  :ensure nil
  :init (save-place-mode 1))

(use-package holidays
  :ensure nil
  :custom
  (calendar-holidays
   `(
	 ;; Berlin public holidays
	 (holiday-fixed 1 1 "New Year's Day")
	 (holiday-fixed 3 8 "International Women's Day")
	 ;; Easter-related holidays calculation
	 (holiday-easter-etc -2 "Good Friday")
	 (holiday-easter-etc 1 "Easter Monday")
	 (holiday-easter-etc 39 "Ascension Day")
	 (holiday-easter-etc 50 "Whit Monday")
	 (holiday-fixed 5 1 "Labour Day")
	 (holiday-fixed 10 3 "Day of German Unity")
	 (holiday-fixed 12 25 "Christmas Day")
	 (holiday-fixed 12 26 "2nd Day of Christmas")
	 ))
  )

(use-package diminish :ensure t)

;; SYNC POINT: diminish must be available for :diminish in later blocks
(elpaca-wait)

;;;; ============================================================
;;;; Completion framework (vertico + orderless + marginalia + embark)
;;;; ============================================================

(use-package avy
  :ensure t
  :bind (("M-j" . avy-goto-char-2)
         ("C-c j c" . avy-goto-char)
         ("C-c j w" . avy-goto-word-1)
         ("C-c j e" . avy-goto-word-0)
         ("C-c j l" . avy-goto-line)
         ("C-c j t" . avy-goto-char-timer)
         ("C-c j r" . avy-resume))
  :init
  (avy-setup-default))

(use-package jinx
  :ensure t
  :diminish "jx"
  :hook (emacs-startup . global-jinx-mode)
  :bind (("M-$" . jinx-correct))
  :custom
  (jinx-languages "en_US de_DE ru_RU")
  (jinx-delay 1.0)
  :init
  ;; Workaround for https://github.com/alexmurray/emacs-snap/issues/71
  (when (getenv "EMACS_SNAP_USER_COMMON")
    (define-advice jinx--load-module (:around (orig-fun &rest args) snap-jinx-rpath)
      "Add rpath to host libs so snap Emacs loads the host libenchant."
      (let ((jinx--compile-flags (append jinx--compile-flags
                                         '("-Wl,-rpath,/usr/lib/x86_64-linux-gnu"))))
        (apply orig-fun args))))
  )

(use-package ace-window
  :ensure t
  :bind ("M-o" . my/ace-window)
  :custom
  (aw-keys '(?f ?j ?d ?k ?s ?l ?g ?h ?a))
  :config
  (defun my/ace-window (arg)
    "Ace-window: no prefix switches, C-u swaps, C-u C-u dispatches."
    (interactive "p")
    (if (= arg 16)  ; C-u C-u
        (let ((aw-dispatch-always t))
          (ace-window 0))
      (ace-window arg))))

(use-package biblio
  :commands biblio-lookup
  :ensure t
  )

(use-package vertico
  :ensure t
  :init
  (vertico-mode))

(use-package marginalia
  :ensure t
  :init
  (marginalia-mode))

(use-package orderless
  :ensure t
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles basic partial-completion)))))

(use-package embark
  :ensure t
  :bind
  (("C-." . embark-act)
   ("C-;" . embark-dwim)
   ("C-:" . embark-act-all)
   ("C-h B" . embark-bindings))
  :init
  (setq prefix-help-command #'embark-prefix-help-command)
  :config
  (add-to-list 'display-buffer-alist
               '("\\`\\*Embark Collect \\(Live\\|Completions\\)\\*"
                 nil
                 (window-parameters (mode-line-format . none)))))

(use-package consult
  :ensure t
  :bind (("C-x b"   . consult-buffer)
         ("C-x r b" . consult-bookmark)
         ("M-y"     . consult-yank-pop)
         ("M-g g"   . consult-goto-line)
         ("M-g M-g" . consult-goto-line)
         ("M-g i"   . consult-imenu)
         ("M-g o"   . consult-outline)
         ("M-g m"   . consult-mark)
         ("M-g M"   . consult-global-mark)
         ("M-g r"   . consult-register)
         ("M-s r"   . consult-ripgrep)
         ("M-s l"   . consult-line)
         ("M-s L"   . consult-line-multi)
         ("<f6>"    . consult-ripgrep)
         ("C-c r"   . consult-org-heading)
         :map minibuffer-local-map
         ("M-r"     . consult-history))
  :custom
  (consult-narrow-key "<")
  :config
  (consult-customize
   consult-ripgrep consult-git-grep consult-grep
   :preview-key '("M-." :debounce 0.3 any)))

(use-package embark-consult
  :ensure t
  :hook (embark-collect-mode . consult-preview-at-point-mode))

(use-package wgrep :ensure t)

(use-package consult-notes
  :ensure t
  :commands (consult-notes consult-notes-search-in-all-notes)
  :bind (("<f8>" . consult-notes)
         ("S-<f8>" . consult-notes-search-in-all-notes))
  :custom
  (consult-notes-file-dir-sources
   '(("Org Roam" ?r "~/org/roam/")))
  :config
  (when (fboundp 'consult-notes-org-roam-mode)
    (consult-notes-org-roam-mode)))

;;;; ============================================================
;;;; Helm (deferred, used only for specific commands)
;;;; ============================================================

(use-package helm :ensure t :defer t)
(use-package helm-bibtex
  :ensure t
  :commands (helm-bibtex)
  :config
  (setq bibtex-completion-bibliography '("~/org/roam/references.bib")
        bibtex-completion-pdf-field "file"
        bibtex-completion-pdf-symbol "⌘"
        bibtex-completion-notes-symbol "✎"
        bibtex-completion-pdf-open-function
		(lambda (fpath)
		  (call-process (if (eq system-type 'darwin) "open" "xdg-open")
						nil 0 nil fpath))
        bibtex-completion-notes-path "~/org/bibnotes.org"
        bibtex-completion-additional-search-fields '(tags)))

;;;; ============================================================
;;;; Org-mode dependent packages
;;;; ============================================================

;; SYNC POINT: flush the queue so org (and all other queued packages)
;; are fully installed before packages that depend on org >= 9.8
;;(elpaca-wait)

(use-package org-habit
  :ensure nil
  :after org
  :custom
  (org-habit-graph-column 50))

(use-package anki-editor
  :ensure (:host github :repo "anki-editor/anki-editor")
  :defer t
  :config
  (defun anki-editor-set-zettelkasten-properties ()
    "Set ANKI properties for the current Org entry."
    (interactive)
    (let ((anki-deck "Zettelkasten")
          (anki-note-type "Zettelkasten"))
      (org-set-property "ANKI_DECK" anki-deck)
      (org-set-property "ANKI_NOTE_TYPE" anki-note-type)))
  )

(use-package org-modern
  :ensure t
  :after org
  :hook (org-agenda-finalize . org-modern-agenda)
  :config
  (set-face-attribute 'org-modern-symbol nil :family "Iosevka")
  (setq org-modern-hide-stars nil)
  (setq org-agenda-block-separator 9472)
  (setq org-agenda-include-diary nil)
  (defun my/org-agenda-add-holidays ()
    "Show `calendar-holidays' in agenda without diary machinery."
    (let ((inhibit-read-only t))
      (save-excursion
        (goto-char (point-min))
        (while (not (eobp))
          (let ((day (get-text-property (point) 'day)))
            (when (and day (get-text-property (point) 'org-date-line))
              (let* ((date (calendar-gregorian-from-absolute day))
                     (holidays (calendar-check-holidays date)))
                (when holidays
                  (end-of-line)
                  (insert "  " (propertize (string-join holidays ", ")
                                           'face 'org-agenda-calendar-event))))))
          (forward-line 1)))))
  (add-hook 'org-agenda-finalize-hook #'my/org-agenda-add-holidays)
  (setq org-extend-today-until 4)
  (define-advice org-modern-agenda (:after (&rest _) progress-bars)
    "Also style progress bars in agenda buffers."
    (when (integerp org-modern-progress)
      (save-excursion
        (save-match-data
          (goto-char (point-min))
          (while (re-search-forward
                  " \\(\\[\\(?:\\([0-9]+\\)%\\|\\([0-9]+\\)/\\([0-9]+\\)\\)]\\)"
                  nil 'noerror)
            (org-modern--progress))))))
  )

(use-package org-modern-right-justify
  :ensure (:host github :repo "connormclaud/org-modern-right-justify")
  :after (org-modern org-habit)
  :config
  (org-modern-right-justify-activate))

(use-package org-ref
  :ensure t
  :commands (org-ref-insert-link)
  :bind (("C-c ]" . org-ref-insert-link)
         ("s-[" . org-ref-insert-link-hydra/body))
  :config
  (require 'bibtex)
  (setq bibtex-autokey-year-length 4
		bibtex-autokey-name-year-separator "-"
		bibtex-autokey-year-title-separator "-"
		bibtex-autokey-titleword-separator "-"
		bibtex-autokey-titlewords 2
		bibtex-autokey-titlewords-stretch 1
		bibtex-autokey-titleword-length 5)
  (require 'org-ref-arxiv)
  (require 'org-ref-scopus)
  (require 'org-ref-wos))

(use-package org-ref-helm
  :ensure nil
  :after org-ref
  :init (setq org-ref-insert-link-function 'org-ref-insert-link-hydra/body
			  org-ref-insert-cite-function 'org-ref-cite-insert-helm
			  org-ref-insert-label-function 'org-ref-insert-label-link
			  org-ref-insert-ref-function 'org-ref-insert-ref-link
			  org-ref-cite-onclick-function (lambda (_) (org-ref-citation-hydra/body))))

(use-package hydra :ensure t)

(use-package citar
  :ensure t
  :custom
  (citar-bibliography '("~/org/roam/references.bib"))
  :hook
  (LaTeX-mode . citar-capf-setup)
  (org-mode . citar-capf-setup))

(use-package citar-embark
  :ensure t
  :diminish citar-embark-mode
  :after (citar embark)
  :no-require
  :config (citar-embark-mode))

(use-package org-download
  :ensure t
  :after org
  :commands (org-download-enable
             org-download-yank
             org-download-screenshot
             org-download-clipboard)
  :custom
  (org-image-actual-width 1100)
  )

;;;; ============================================================
;;;; Org-roam
;;;; ============================================================

(use-package org-roam
  :ensure t
  :after org
  :custom
  (org-roam-directory (file-truename "~/org/roam/"))
  (org-roam-node-display-template
   (concat "${title:65} "
           (propertize "${tags:*}" 'face 'org-tag)))
  (org-roam-completion-everywhere t)
  (org-roam-dailies-directory "daily/")
  (org-roam-mode-sections
   `(orb-section-reference
     org-roam-backlinks-section
     org-roam-reflinks-section))
  (org-roam-capture-templates
   '(("d" "default" plain
      "%?"
      :target
      (file+head
       "%<%Y%m%d%H%M%S>-${slug}.org"
       "#+title: ${title}\n")
      :unnarrowed t)
     ("n" "literature note" plain
      "%?"
      :target
      (file+head
       "%(expand-file-name (or citar-org-roam-subdir \"\") org-roam-directory)/${citar-citekey}.org"
       "#+title: ${citar-citekey} (${citar-date}). ${title}.\n#+created: %U\n#+last_modified: %U\n\n")
      :unnarrowed t)))
  (org-roam-dailies-capture-templates
   '(("d" "default" entry
      "* %?"
      :target (file+head "%<%Y-%m-%d>.org"
                         ":PROPERTIES:\n:LINK: [[id:41ace651-2c8b-4fa3-b92c-b8e2f0297630][dairy parent]]\n:END:\n#+title: Daily: %<%A, %Y-%m-%d>\n"))
     ("j" "journal" plain
      "* Morning Gratitude\n  - I am grateful for...\n    1. %?\n    2. \n    3. \n* Daily Affirmation\n  - Something positive about myself...\n    \n* Evening Reflection\n  - 3 Amazing things today...\n    1. \n    2. \n    3. \n  - How could I have made today better?\n    1."
      :target (file+head "%<%Y-%m-%d>-journal.org"
                         ":PROPERTIES:\n:LINK: [[id:ec6f965e-fc1d-474a-b867-e2c959bf0b33][journal parent]]\n:END:\n#+title: Journal: %<%A, %B %d, %Y>\n"))

     ("m" "meeting" plain
      "* %<%I:%M %p> - %^{Title}  :meeting:\n** Date: %<%Y-%m-%d %H:%M>\n** Attendees: \n** Location: \n\n** Agenda:\n- %?\n\n** Meeting Notes\n\n** Key Points\n-\n\n** Action Items\n- [ ]\n\n** Follow up"
      :target (file+head "%<%Y-%m-%d>-meetings.org"
                         ":PROPERTIES:\n:LINK: [[id:177ee0d9-632e-4391-bb6d-be19c699fae8][meetings parent]]\n:END:\n#+title: Meetings: %<%Y-%m-%d>\n"))
     ("p" "practice journal" entry
      "* Meditation practice %<%Y-%m-%d> %<%A, %B %d, %Y>\n\n** Meditation type\n   - %?\n** Place and location\n   - \n** Self assessment before practice (thoughts, feelings)\n   - \n** Self reflection during practice\n   - \n** Self assessment after the practice?\n   - \n** Special notes\n   - "
      :target (file+head "%<%Y-%m-%d>-meditation.org"
                         ":PROPERTIES:\n:LINK: [[id:95d1a25f-602d-4b68-9236-33a16e0b6ed7][meditation parent]]\n:END:\n#+title: meditation diary: %<%Y-%m-%d> %<%A, %B %d, %Y>\n#+filetags: :meditation:\n"))
     ))
  :bind (
         ("C-c n f" . org-roam-node-find)
         ("C-c f" . org-roam-node-find)
         ("C-c n r" . org-roam-node-random)
         ("C-c n l" . org-roam-buffer-toggle)
         ("C-c n d" . org-roam-dailies-capture-today)
         ("C-c d" . org-roam-dailies-capture-today)		 
         ("C-c n ." . org-roam-dailies-goto-today)
         ("C-c n <" . org-roam-dailies-goto-yesterday)
         ("C-c n ," . org-roam-dailies-goto-date)
         (:map org-mode-map
               ("C-c n t" . org-roam-tag-add)
               ("C-c n a" . org-roam-alias-add)
               ("C-c n i" . org-roam-node-insert)))
  :config
  (org-roam-db-autosync-mode)
  (add-hook 'org-roam-mode-hook #'turn-on-visual-line-mode)
  (add-to-list 'display-buffer-alist
               '("\\*org-roam\\*"
				 (display-buffer-in-side-window)
				 (side . right)
				 (slot . 0)
				 (window-width . 0.33)
				 (window-parameters . ((no-other-window . t)
                                       (no-delete-other-windows . t)))))
  )

(use-package citar-org-roam
  :ensure t
  :after (citar org-roam)
  :config (citar-org-roam-mode)
  :init
  (setq citar-notes-source 'orb-citar-source)
  (setq org-roam-db-node-include-function
		(lambda ()
          (not (member "fc" (org-get-tags)))))
  (setq org-startup-folded 'nofold)
  )

(use-package org-roam-calendar
  :ensure (:host github :repo "connormclaud/emacs_org_roam_calendar")
  :commands org-roam-calendar-open
  :bind ("C-c n o" . org-roam-calendar-open))

(use-package org-roam-bibtex
  :ensure t
  :after (helm-bibtex org-roam)
  :config
  (require 'org-ref)
  (org-roam-bibtex-mode)
  )

(use-package org-roam-ui
  :ensure t
  :commands org-roam-ui-mode
  :after org-roam)

;;;; ============================================================
;;;; Git
;;;; ============================================================

;; Emacs 30 built-in transient is too old for magit
(use-package transient :ensure t)

(use-package magit
  :ensure t
  :commands (magit-status magit-blame magit-log)
  ;; :bind (("C-c m" . magit-status))
  :custom
  (magit-diff-use-overlays nil))

(use-package magit-delta
  :ensure t
  :after magit
  :config
  (magit-delta-mode))

(use-package diff-hl
  :ensure t
  :hook ((prog-mode . diff-hl-flydiff-mode)
         (dired-mode . diff-hl-dired-mode)
         (magit-post-refresh . diff-hl-magit-post-refresh))
  :custom
  (diff-hl-draw-borders nil)
  :config
  (global-diff-hl-mode +1)
  )

(use-package yaml-mode :ensure t)
(use-package json-mode :ensure t :defer t)

;;;; ============================================================
;;;; Development tools
;;;; ============================================================

;; Workaround https://github.com/flycheck/flycheck/issues/1762
(defvar-local my/flycheck-local-cache nil)
(use-package flycheck
  :ensure t
  :init (global-flycheck-mode)
  :custom
  (flycheck-temp-prefix ".flycheck")
  :config
  (defun my/flycheck-checker-get (fn checker property)
    (or (alist-get property (alist-get checker my/flycheck-local-cache))
		(funcall fn checker property)))

  (advice-add 'flycheck-checker-get :around 'my/flycheck-checker-get)

  (add-hook 'lsp-managed-mode-hook
            (lambda ()
              (when (derived-mode-p 'python-base-mode)
				(setq my/flycheck-local-cache '((lsp . ((next-checkers . (python-ruff)))))))))

  ;; Workaround https://github.com/flycheck/flycheck/issues/2083
  (add-hook 'org-mode-hook
            (lambda ()
              (setq-local flycheck-disabled-checkers '(org-lint)))))

(use-package yasnippet
  :ensure t
  :defer t)

(use-package project
  :ensure nil
  :bind-keymap ("C-c p" . project-prefix-map))

;; Tree-sitter: enable all available ts modes + prompt to install missing grammars
(setq treesit-enabled-modes t)
(setq treesit-auto-install-grammar 'ask)

(electric-pair-mode 1)
(add-hook 'prog-mode-hook #'display-line-numbers-mode)

(use-package combobulate
  :ensure (:host github :repo "mickeynp/combobulate")
  :hook ((python-ts-mode . combobulate-mode)
         (js-ts-mode . combobulate-mode)
         (yaml-ts-mode . combobulate-mode)))

(use-package corfu
  :ensure t
  :custom
  (corfu-auto t)
  (corfu-cycle t)
  :init (global-corfu-mode))

(use-package cape
  :ensure t
  :init
  (add-hook 'completion-at-point-functions #'cape-dabbrev)
  (add-hook 'completion-at-point-functions #'cape-file))

(use-package vundo
  :ensure t
  :bind ("C-x u" . vundo))

(use-package multiple-cursors
  :ensure t
  :bind (("C-S-c C-S-c" . mc/edit-lines)
         ("C->" . mc/mark-next-like-this)
         ("C-<" . mc/mark-previous-like-this)))

(use-package envrc
  :ensure t
  :config (envrc-global-mode))

(use-package editorconfig
  :ensure nil
  :config (editorconfig-mode 1))

(use-package apheleia
  :ensure t
  :config
  (setf (alist-get 'python-mode apheleia-mode-alist) '(ruff-isort ruff))
  (setf (alist-get 'python-ts-mode apheleia-mode-alist) '(ruff-isort ruff))
  (apheleia-global-mode))

(use-package treemacs
  :ensure t
  :bind
  (:map global-map
        ("M-0"   . treemacs-select-window)
        )
  )

;;;; ============================================================
;;;; Python
;;;; ============================================================

(use-package python-pytest
  :ensure t
  :defer t)

(use-package python-coverage
  :after (python-pytest magit)
  :ensure t)


(use-package pet
  :ensure t
  :after python)

(use-package lsp-mode
  :ensure t
  :commands (lsp lsp-deferred)
  :diminish lsp-mode
  :init
  (setq lsp-keymap-prefix "C-c l")
  (setq lsp-completion-provider :none)
  :hook (python-ts-mode . lsp)
  :custom
  (lsp-file-watch-threshold 15000)
  :config
  (lsp-enable-which-key-integration t)
  )

(use-package lsp-pyright
  :ensure t
  :after lsp-mode
  :demand t)

(use-package lsp-ui
  :ensure t
  :after lsp-mode
  :init
  (setq lsp-ui-sideline-show-code-actions t)
  (setq lsp-ui-sideline-show-diagnostics t))


(use-package dap-mode
  :ensure t
  :after lsp-mode)

(use-package dap-python
  :ensure nil
  :after dap-mode
  :demand
  :custom
  (dap-python-debugger 'debugpy))

(use-package expand-region
  :ensure t
  :bind ("C-=" . er/expand-region))

(use-package goto-chg
  :ensure (:host github :repo "emacs-evil/goto-chg")
  :bind (("M-g ;" . goto-last-change)
         ("M-g :" . goto-last-change-reverse))
  :config
  (defvar-keymap goto-chg-repeat-map
    :repeat t
    ";" #'goto-last-change
    ":" #'goto-last-change-reverse)
  (put 'goto-last-change 'repeat-map 'goto-chg-repeat-map)
  (put 'goto-last-change-reverse 'repeat-map 'goto-chg-repeat-map))

;;;; ============================================================
;;;; Misc settings and utilities
;;;; ============================================================

(setq-default tab-width 4)

;; prevent silly initial splash screen
(setq inhibit-startup-screen t)

(use-package server
  :ensure nil
  :defer 1
  :config
  (setq server-socket-dir (expand-file-name "server" user-emacs-directory)))

(repeat-mode 1)

(use-package winner
  :ensure nil
  :init (winner-mode 1)
  :config
  (defvar-keymap winner-repeat-map
    :repeat t
    "<left>"  #'winner-undo
    "<right>" #'winner-redo)
  (put 'winner-undo 'repeat-map 'winner-repeat-map)
  (put 'winner-redo 'repeat-map 'winner-repeat-map))

(use-package delsel
  :ensure nil
  :init (delete-selection-mode 1))

;; Save automatically (focus loss, idle, buffer/window switch)
(use-package super-save
  :ensure t
  :diminish
  :custom
  (super-save-auto-save-when-idle t)
  (super-save-all-buffers t)
  (super-save-remote-files nil)
  ;; (super-save-silent t)
  :config
  (super-save-mode 1))

(use-package tramp
  :ensure nil
  :defer t
  :config
  (setq tramp-default-method "ssh"))

(use-package toolbox-tramp
  :ensure (:host github :repo "fejfighter/toolbox-tramp")
  :if (eq system-type 'gnu/linux)
  :defer t)

;;; org mode minor modes
(defun my-org-mode-hook ()
  (visual-line-mode 1)
  (org-modern-mode 1))
(add-hook 'org-mode-hook 'my-org-mode-hook)

(use-package nerd-icons
  :ensure t
  :if (display-graphic-p)
  :after org
  :config
  (setq org-agenda-category-icon-alist
        `(("work" ,(list (nerd-icons-mdicon "nf-md-laptop")) nil nil :ascent center)
          ("habit" ,(list (nerd-icons-mdicon "nf-md-repeat")) nil nil :ascent center)
          ("@home" ,(list (nerd-icons-mdicon "nf-md-home")) nil nil :ascent center)
          ("personal" ,(list (nerd-icons-faicon "nf-fa-fort_awesome")) nil nil :ascent center))))

(use-package org-habit-stats
  :ensure t
  :after org
  :bind ((:map org-mode-map
               ("C-c h" . org-habit-stats-view-habit-at-point))
         (:map org-agenda-mode-map
               ("h" . org-habit-stats-view-habit-at-point-agenda))))

(defun browse-url-chrome-incognito (url &optional _new-window)
  "Browse URL in Google Chrome incognito mode."
  (interactive (browse-url-interactive-arg "URL: "))
  (if (eq system-type 'darwin)
      (start-process "chrome" nil "open" "-a" "Google Chrome" "--args" "--incognito" url)
    (start-process "chrome" nil "flatpak" "run" "com.google.Chrome" "--incognito" url)))

(setq browse-url-browser-function 'browse-url-chrome-incognito)


(use-package which-key
  :ensure nil
  :init
  (which-key-mode)
  :config
  (setq which-key-idle-delay 0.3)
  )

(use-package helpful
  :ensure t
  :bind (("C-h f" . helpful-callable)
         ("C-h v" . helpful-variable)
         ("C-h k" . helpful-key)
         ("C-h x" . helpful-command)))

(defun my/toggle-org-habit-today-only ()
  "Toggle the org-habit-show-habits-only-for-today and org-agenda-show-future-repeats variables."
  (interactive)
  (setq org-habit-show-habits-only-for-today (not org-habit-show-habits-only-for-today))
  (org-agenda-redo)
  (message "Showing future habits is now %s"
           (if org-habit-show-habits-only-for-today "disabled" "enabled"))
  )


(with-eval-after-load 'org-agenda
  (define-key org-agenda-mode-map (kbd "C-c h") 'my/toggle-org-habit-today-only))

(defun my/org-agenda-wip-count (states)
  (let ((counter 0))
    (org-map-entries
     (lambda ()
       (when (member (org-get-todo-state) states)
         (setq counter (1+ counter))))
     nil 'agenda)
    (format "[%d]" counter)))

(use-package grep
  :ensure nil
  :defer t
  :custom
  (grep-files-aliases
   '(("all" . "\\*")
     ("el" . "*.el")
     ("ch" . "\\*.[ch]")
     ("c" . "\\*.c")
     ("pl" . "\\*.pl")
     ("py" . "\\*.py")
     ("cc" . "*.cc *.cxx *.cpp *.C *.CC *.c++")
     ("cchh" . "*.cc *.[ch]xx *.[ch]pp *.[CHh] *.CC *.HH *.[ch]++")
     ("hh" . "*.hxx *.hpp *.[Hh] *.HH *.h++")
     ("h" . "\\*.h")
     ("l" . "[Cc]hange[Ll]og*")
     ("m" . "\\*[Mm]akefile*")
     ("tex" . "*.tex")
     ("xml" . "\\*.xml")
     ("texi" . "*.texi")
     ("asm" . "*.[sS]")))
  (grep-template "git grep -n -e <R> -- <F>"))

(use-package midnight
  :ensure nil
  :custom
  (clean-buffer-list-delay-general 1)
  :config
  (midnight-mode 1))

;;;; ============================================================
;;;; Startup
;;;; ============================================================

(defun my/display-org-agenda-on-startup ()
  (let ((org-agenda-window-setup 'only-window))
    (org-agenda nil "n")))
(add-hook 'elpaca-after-init-hook 'my/display-org-agenda-on-startup)

;;;; ============================================================
;;;; Theme and appearance
;;;; ============================================================

(use-package modus-themes
  :ensure t
  :config
  (modus-themes-load-theme 'modus-vivendi)
  (setq modus-themes-to-toggle '(modus-vivendi modus-operandi-tinted))
  (define-key global-map (kbd "<f10>") #'modus-themes-toggle)
  )

(use-package pulsar
  :ensure t
  :config
  (dolist (fn '(avy-goto-char avy-goto-char-2 avy-goto-char-timer avy-goto-line
							  avy-goto-word-1 consult-line consult-goto-line
							  consult-imenu xref-find-definitions xref-find-references
							  isearch-repeat-forward isearch-repeat-backward))
    (add-to-list 'pulsar-pulse-functions fn))
  (pulsar-global-mode 1))

(use-package doom-modeline
  :ensure t
  :hook (elpaca-after-init . doom-modeline-mode)
  :custom
  (doom-modeline-icon t)
  (doom-modeline-buffer-file-name-style 'truncate-upto-project)
  (doom-modeline-lsp t)
  (doom-modeline-vcs-max-length 20)
  (doom-modeline-window-width-limit 0.55)
  (doom-modeline-env-version nil)
  (doom-modeline-buffer-encoding 'nondefault)
  (doom-modeline-total-line-number t)
  (doom-modeline-enable-word-count t)
  (doom-modeline-column-zero-based nil))

(use-package ligature
  :ensure t
  :config
  (ligature-set-ligatures 'prog-mode
                          '("-<<" "-<" "-<-" "<--" "<---" "<<-" "<-" "->" "->>" "-->" "--->" "->-" ">-" ">>-"
                            "=<<" "=<" "=<=" "<==" "<===" "<<=" "<=" "=>" "=>>" "==>" "===>" "=>=" ">=" ">>="
                            "<->" "<-->" "<--->" "<---->" "<=>" "<==>" "<===>" "<====>" "::" ":::" "__"
                            "<~~" "</" "</>" "/>" "~~>" "==" "!=" "/=" "~=" "<>" "===" "!==" "!===" "=/=" "=!="
                            "<:" ":=" "*=" "*+" "<*" "<*>" "*>" "<|" "<|>" "|>" "<." "<.>" ".>" "+*" "=*" "=:" ":>"
                            "(*" "*)" "/*" "*/" "[|" "|]" "{|" "|}" "++" "+++" "\\/" "/\\" "|-" "-|" "<!--" "<!---"))
  (global-ligature-mode t))

(set-face-attribute 'default nil :family "Iosevka" :height 150)

