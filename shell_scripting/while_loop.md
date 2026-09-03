# `while_loop.sh`

- `while true` runs an infinite loop that only exits via `break`.
- `read -p` prints the line and stores what the user types in `input`.
- If the input is `q`, it prints "Exiting the loop." and `break`s out.
- If the input isn't all digits (`^[0-9]+$`), it prints an error and `continue`s to the next prompt.
- Otherwise it echoes the number back and loops again.