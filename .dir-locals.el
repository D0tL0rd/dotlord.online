((nil . (
         (eval . (let ((project-root (locate-dominating-file default-directory ".dir-locals.el")))
                   ;; Set org-roam-directory to the 'roam' subdirectory of project-root
                   (setq org-roam-directory (expand-file-name "roam" project-root))
                   ;; Set org-roam-db-location inside org-roam-directory
                   (setq org-roam-db-location (expand-file-name "org-roam.db" org-roam-directory))
                   ;; Set org-hugo-base-dir to the 'content' sibling directory
                   (setq org-hugo-base-dir (expand-file-name "." project-root))
                   ;; Do not nest them, I use tags to identify blog
                   ;; posts. I tried using sub directories, and it
                   ;; started to fail on finding links
                   (setq org-hugo-section "")
                   ;; Ensure ox-hugo exports yaml FrontMatter
                   (setq org-hugo-front-matter-format "yaml")
                   ;; Re-initialize org-roam to pick up new settings
                   (when (fboundp 'org-roam-db-autosync-enable)
                     (org-roam-db-autosync-enable))
                   ;; Automatically invoke ox-hugo
                   (org-hugo-auto-export-mode)
                   )))
      ))
