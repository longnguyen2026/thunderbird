#!/bin/bash
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/functions.sh"

# In Banner
clear
if [ -f "$SCRIPT_DIR/assets/banner.txt" ]; then
    cat "$SCRIPT_DIR/assets/banner.txt"
fi

# Thực thi các bước
check_environment
get_user_input
deploy_profile

# Nhấn Enter để mở phần mềm
echo ""
read -p "Nhấn Enter để mở Thunderbird..."
nohup thunderbird > /dev/null 2>&1 &
