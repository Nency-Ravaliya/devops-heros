# Appending file contents

mkdir append
cd append

echo "This is initial content" > app.log
echo "This is appended content" >> app.log
cat app.log