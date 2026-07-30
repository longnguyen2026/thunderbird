#!/bin/bash

# Kiểm tra Thunderbird & Internet
check_environment() {
    # Check Thunderbird
    if command -v thunderbird &> /dev/null; then
        echo -e "✓ Thunderbird: Installed"
    else
        echo -e "⚠️ Thunderbird: Not installed (Đang cài đặt...)"
        sudo apt update -qq && sudo apt install -y thunderbird > /dev/null 2>&1
        echo -e "✓ Thunderbird: Installed"
    fi

    # Check Internet
    if ping -c 1 mail.bizflycloud.vn &> /dev/null; then
        echo -e "✓ Internet: OK"
    else
        echo -e "❌ Internet: No Connection"
        exit 1
    fi
}

# Thu thập thông tin tương tác
get_user_input() {
    echo -e "\nChọn giao thức\n"
    echo " 1. IMAP (Khuyến nghị)"
    echo " 2. POP3"
    echo -e "\n-----------------------------------------\n"

    read -p "Chọn [1/2] (Mặc định 1): " PROTO_CHOICE
    if [ "$PROTO_CHOICE" == "2" ]; then
        SERVER_TYPE="pop3"
        IN_HOST="mail.bizflycloud.vn"
        IN_PORT="995"
    else
        SERVER_TYPE="imap"
        IN_HOST="mail.bizflycloud.vn"
        IN_PORT="993"
    fi

    echo ""
    while [ -z "$FULL_NAME" ]; do
        read -p "Tên hiển thị: " FULL_NAME
    done

    while [[ ! "$USER_EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; do
        read -p "Email: " USER_EMAIL
        if [[ ! "$USER_EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
            echo -e "❌ Email không hợp lệ, vui lòng nhập lại!\n"
        fi
    done
}

# Tạo profile và áp dụng template user.js
deploy_profile() {
    echo -e "\nĐang cấu hình..."
    
    local PROFILE_DIR="$HOME/.thunderbird/auto.profile"
    mkdir -p "$PROFILE_DIR"

    # Thay thế biến vào file template
    sed -e "s/{{FULL_NAME}}/$FULL_NAME/g" \
        -e "s/{{USER_EMAIL}}/$USER_EMAIL/g" \
        -e "s/{{SERVER_TYPE}}/$SERVER_TYPE/g" \
        -e "s/{{IN_HOST}}/$IN_HOST/g" \
        -e "s/{{IN_PORT}}/$IN_PORT/g" \
        "$SCRIPT_DIR/config/user.js.template" > "$PROFILE_DIR/user.js"

    # Ghi file profiles.ini
    cat <<EOF > "$HOME/.thunderbird/profiles.ini"
[General]
StartWithLastProfile=1

[Profile0]
Name=default
IsRelative=1
Path=auto.profile
Default=1
EOF

    sleep 1
    echo -e "\n✓ Hoàn tất."
}
