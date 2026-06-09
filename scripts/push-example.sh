#!/bin/bash
set -e

# Usage:
# 1. Create a public repository on GitHub, for example:
#    qp-git/engineer-portfolio
# 2. Run this script from the repository root after confirming contents.

git init
git branch -M main
git add .
git commit -m "Add public engineer portfolio docs"
git remote add origin git@github.com:qp-git/engineer-portfolio.git
git push -u origin main
