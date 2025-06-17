git filter-branch --force --index-filter \
    "git rm --cached --ignore-unmatch subdir/<secretFilename>" \
    --prune-empty --tag-name-filter cat -- --all
git push --force --all

# Final step
git reflog expire --expire=now --all
git gc --prune=now --aggressive
git push origin --force --all
