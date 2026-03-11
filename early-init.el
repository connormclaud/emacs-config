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

;; Improve startup performance
(setq gc-cons-threshold (* 50 1000 1000))
(setq read-process-output-max (* 1024 1024)) ;; 1mb
