#!/bin/bash

# ============================================
# THUNDERBIRD BIZFLY INSTALLER - FUNCTIONS
# ============================================

# 1. Kiểm tra môi trường và đóng ứng dụng cũ
check_environment() {
    # Tắt Thunderbird nếu đang chạy ngầm để tránh khóa file cấu hình
    pkill -x thunderbird 2>/dev/null || true
    sleep 1

    # Check & Cài đặt Thunderbird nếu chưa có
    if command -v thunderbird &> /dev/null; then
        echo -e "✓ Thunderbird: Đã cài đặt"
    else
        echo -e "⚠️ Thunderbird: Chưa cài đặt (Đang tiến hành cài...)"
        sudo apt update -qq && sudo apt install -y thunderbird > /dev/null 2>&1
        echo -e "✓ Thunderbird: Đã cài đặt"
    fi

    # Check kết nối tới Server Mail Bizfly
    if ping -c 1 mail.bizflycloud.vn &> /dev/null; then
        echo -e "✓ Kết nối mạng: Tốt"
    else
        echo -e "❌ Kết nối mạng: Lỗi (Không ping được server mail)"
        exit 1
    fi
}

# 2. Thu thập thông tin người dùng từ TTY
get_user_input() {
    echo -e "\nChọn giao thức nhận thư:"
    echo " 1. IMAP (Khuyến nghị - Đồng bộ với server)"
    echo " 2. POP3 (Tải thư về lưu local)"
    echo -e "\n-----------------------------------------\n"

    read -p "Chọn [1/2] (Mặc định 1): " PROTO_CHOICE
    PROTO_CHOICE=${PROTO_CHOICE:-1}

    if [ "$PROTO_CHOICE" = "2" ]; then
        SERVER_TYPE="pop3"
        IN_PORT="995"
        DIR_NAME="Mail"
    else
        SERVER_TYPE="imap"
        IN_PORT="993"
        DIR_NAME="ImapMail"
    fi

    echo ""
    FULL_NAME=""
    while [ -z "$FULL_NAME" ]; do
        read -p "👉 Tên hiển thị (VD: Nguyen Van A): " FULL_NAME
    done

    USER_EMAIL=""
    while [[ ! "$USER_EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; do
        read -p "👉 Email công ty (VD: user@domain.com): " USER_EMAIL
        if [[ ! "$USER_EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
            echo -e "❌ Email không đúng định dạng, vui lòng nhập lại!\n"
        fi
    done
}

# 3. Làm sạch và deploy Profile
deploy_profile() {
    echo -e "\n⏳ Đang tiến hành làm sạch và khởi tạo cấu hình Profile..."

    # Xác định thư mục root của Thunderbird (Apt hoặc Snap/Flatpak)
    TB_BASE="$HOME/.thunderbird"
    if [ -d "$HOME/.var/app/org.mozilla.Thunderbird/.thunderbird" ]; then
        TB_BASE="$HOME/.var/app/org.mozilla.Thunderbird/.thunderbird"
    fi

    # Xóa sạch cấu hình rác cũ để tránh bị lỗi profile cũ đè
    rm -rf "$TB_BASE"
    mkdir -p "$TB_BASE/bizfly.default"
    PROFILE_PATH="$TB_BASE/bizfly.default"

    # Ghi trực tiếp các preference CORE vào prefs.js
    cat > "$PROFILE_PATH/prefs.js" <<EOF
user_pref("mail.account.account1.identities", "id1");
user_pref("mail.account.account1.server", "server1");
user_pref("mail.accountmanager.accounts", "account1");
user_pref("mail.accountmanager.defaultaccount", "account1");

user_pref("mail.identity.id1.fullName", "$FULL_NAME");
user_pref("mail.identity.id1.useremail", "$USER_EMAIL");
user_pref("mail.identity.id1.valid", true);
user_pref("mail.identity.id1.smtpServer", "smtp1");

user_pref("mail.server.server1.authMethod", 3);
user_pref("mail.server.server1.directory-rel", "[profD]$DIR_NAME/mail.bizflycloud.vn");
user_pref("mail.server.server1.hostname", "mail.bizflycloud.vn");
user_pref("mail.server.server1.name", "$USER_EMAIL");
user_pref("mail.server.server1.port", $IN_PORT);
user_pref("mail.server.server1.socketType", 3);
user_pref("mail.server.server1.type", "$SERVER_TYPE");
user_pref("mail.server.server1.userName", "$USER_EMAIL");

user_pref("mail.smtp.defaultserver", "smtp1");
user_pref("mail.smtpserver.smtp1.authMethod", 3);
user_pref("mail.smtpserver.smtp1.hostname", "mail.bizflycloud.vn");
user_pref("mail.smtpserver.smtp1.port", 465);
user_pref("mail.smtpserver.smtp1.try_ssl", 3);
user_pref("mail.smtpserver.smtp1.username", "$USER_EMAIL");
user_pref("mail.smtpservers", "smtp1");

user_pref("mail.rights.version", 1);
user_pref("toolkit.telemetry.prompted", 2);
EOF

    # Copy sang user.js để duy trì thiết lập ổn định
    cp "$PROFILE_PATH/prefs.js" "$PROFILE_PATH/user.js"

    # Ghi profiles.ini và installs.ini định dạng v2 ép nhận profile
    cat > "$TB_BASE/profiles.ini" <<EOF
[Profile0]
Name=bizfly
IsRelative=1
Path=bizfly.default
Default=1

[General]
StartWithLastProfile=1
Version=2
EOF

    cat > "$TB_BASE/installs.ini" <<EOF
[default]
Default=bizfly.default
Locked=1
EOF

    sleep 1
    echo -e "✓ Cấu hình hoàn tất thành công!"
}

# 4. Mở Thunderbird
launch_thunderbird() {
    echo -e "\n🚀 Đang khởi chạy Thunderbird..."
    sleep 1
    nohup thunderbird > /dev/null 2>&1 &
    disown
}
