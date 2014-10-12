xslt-dependencies
=================

EMACS minor-mode to find dependencies in XSLT 1.0 xsl files and display them in a graph.

This was made with XSLT 1.0 in mind as I do not have much experience with
XSLT 2.0. It also assumes that you have graphviz installed, which is readily
available at http://www.graphviz.org. Recursive includes/imports generates an
error and you can review the dot file to see what happened.

Put xslt-dep.el in your load path and keep xslt-dep.sh in the same folder. 
Assuming you use nxml-mode for editing xsl:

```emacs
(add-hook 'nxml-mode-hook (lambda () 
  (require 'xslt-dep)
  (xslt-dep-mode)))
```

Visit an .xsl file that imports/includes other files and try C-c C-s d. This
generates a graphviz .dot file at `xd/deps-dot-output'. The graphviz dot
executable executes the dot file and outputs the graph.
