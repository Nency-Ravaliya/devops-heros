# Overriding file contents

mkdir override
cd override

echo "This is initial content" > app.log
cat app.log

echo "This is overriden content" > app.log
cat app.log