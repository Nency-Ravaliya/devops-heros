show_system_user(){
    echo "Hostname: $(hostname)"
    echo "Username: $(whoami)"
}

show_date(){
    date
}

show_system_user
show_date