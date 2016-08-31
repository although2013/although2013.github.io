`jekyll server`



```
Using Interactive Rebase

You could do

git rebase -i -p <some HEAD before all of your bad commits>


git commit --amend --author "Ge Hao <althoughghgh@gmail.com>" 
git rebase --continue


You could skip opening the editor altogether here by appending --no-edit so that the command will be:

git commit --amend --author "Ge Hao <althoughghgh@gmail.com>" --no-edit && \
git rebase --continue

```