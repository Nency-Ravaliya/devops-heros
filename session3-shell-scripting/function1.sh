#!/bin/bash

show_uptime(){
    echo "---System Uptime---"
    uptime
    echo ""
}

greet_user(){
    local name=$1
    echo "Hello, $name! Welcome to the system."
    echo ""
}

show_uptime
greet_user "John Doe"