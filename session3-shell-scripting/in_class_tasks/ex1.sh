# Q : 

mkdir ex1
cd ex1
# touch app.log # echo will create itself
echo "First Content" > app.log
txt=$(cat app.log) # variable to store the previous content
echo "Second Content" > app.log
echo txt
cat app.log