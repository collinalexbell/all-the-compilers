cat README.md | grep -o "https://github.com/.*)" | sed "s/)/.git/" > urls
sbcl
rm -rf `find -type d -name *.git`
