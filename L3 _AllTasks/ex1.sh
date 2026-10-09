# Q : 

mkdir ex1
cd ex1
# touch app.log # echo will create itself
echo "1st Content" > app.log
txt=$(cat app.log) # variable to store the previous content
echo "2nd Content" > app.log
echo txt
cat app.log