mkdir hello
cd hello
# touch app.log
echo "This is my log file" > app.log
txt=$(cat app.log)
echo "New content added" > app.log
echo $txt
cat app.log