
# 1. Create the directory and navigate into it
mkdir -p test
cd test

# 2. Initialize the file with baseline text
echo "This is my logfile" > app.log
echo "Initial content set: $(cat app.log)"

# 3. Take input from the user
echo "Enter new text to OVERWRITE the log file:"
read -r user_input

# 4. Overwrite the file using the '>' operator
echo "$user_input" > app.log

# 5. Display the final result
echo -e "\n--- Current app.log Content ---"
cat app.log 
