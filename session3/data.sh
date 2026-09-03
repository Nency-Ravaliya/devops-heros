mkdir data1
cd data1
echo "This is a sample data file." > app.log
echo "This is the overwritten line." > app.log
echo "This is the appended line." >> app.log
cat app.log