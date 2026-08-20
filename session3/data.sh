mkdir data1

cd data1

touch app.log
echo "This is a log file." > app.log
echo "This is the overwritten content." > app.log

cat app.log