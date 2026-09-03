mkdir -p test
cd test 
echo "First line" > log.txt
cat log.txt
echo "Second line" > log.txt
cat log.txt
echo "Third Line" > log.txt
cat log.txt

# if want to append
# mkdir -p test
# cd test
# echo "Appended First line" > log.txt
# echo "Appended Second line" >> log.txt
# echo "Appended Third line" >> log.txt
# cat log.txt