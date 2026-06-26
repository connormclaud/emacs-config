;; -*- lexical-binding: t; -*-

;; Disable package.el — Elpaca replaces it
(setq package-enable-at-startup nil)

;; Disable the toolbar
(when (fboundp 'tool-bar-mode)
  (tool-bar-mode -1))

;; Disable the scrollbar
(when (fboundp 'scroll-bar-mode)
  (scroll-bar-mode -1))

;; Disable the menu bar
(when (fboundp 'menu-bar-mode)
  (menu-bar-mode -1))

;; Disable the startup screen
(setq inhibit-startup-screen t)

;; Disable the startup message
(setq inhibit-startup-message t)

;; fullscreen
(add-to-list 'default-frame-alist '(fullscreen . maximized))

;; Prefer loading newer .el files
(setq load-prefer-newer t)

;; Silence native-compiler warnings
(setq native-comp-async-report-warnings-errors 'silent)

;; macOS: native-comp's libgccjit invokes the gcc driver, whose link step needs
;; gcc's runtime archives (libemutls_w.a, libgcc.a, crt*.o). Homebrew tucks those
;; in a version/arch-specific subdir the linker doesn't search by default, so
;; native compilation fails with "ld: library 'emutls_w' not found" → "error
;; invoking gcc driver". Point LIBRARY_PATH at the dir gcc itself reports. NB: bare
;; `gcc` is Apple clang (wrong dir), so use Homebrew's gcc-N. Requires `brew install gcc`.
(when (eq system-type 'darwin)
  (let ((gcc (car (last (or (file-expand-wildcards "/opt/homebrew/bin/gcc-[0-9]*")
                            '("gcc-16"))))))
    (when (executable-find gcc)
      (setenv "LIBRARY_PATH"
              (directory-file-name
               (file-name-directory
                (string-trim
                 (shell-command-to-string
                  (concat gcc " -print-libgcc-file-name")))))))))

;; Improve startup performance
(setq gc-cons-threshold (* 50 1000 1000))
(setq read-process-output-max (* 1024 1024)) ;; 1mb
