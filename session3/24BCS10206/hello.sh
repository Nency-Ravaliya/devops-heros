# Overriding file contents

mkdir hello
cd hello
touch app.log

echo "This is initial content" > app.log
cat app.log

echo "This is overriden content" > app.log
cat app.log