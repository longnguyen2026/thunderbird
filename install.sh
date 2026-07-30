#!/bin/bash
set -e

# Clear màn hình và in Banner
clear
echo "========================================================="
echo "          THUNDERBIRD BIZFLY INSTALLER"
echo "                  Version 1.0"
echo "========================================================="

# 1. Kiểm tra Thunderbird & Internet
if command -v thunderbird &> /dev/null; then
    echo -e "✓ Thunderbird: Installed"
else
    echo -e "⚠️ Thunderbird: Not installed (Đang cài đặt...)"
    sudo apt update -qq && sudo apt install -y thunderbird > /dev/null 2>&1
    echo -e "✓ Thunderbird: Installed"
fi

if ping -c 1 mail.bizflycloud.vn &> /dev/null; then
    echo -e "✓ Internet: OK"
else
    echo -e "❌ Internet: No Connection"
    exit 1
fi

# 2. Thu thập thông tin từ người dùng
echo -e "\nChọn giao thức\n"
echo " 1. IMAP (Khuyến nghị)"
echo " 2. POP3"
echo -e "\n-----------------------------------------\n"

read -p "Chọn [1/2] (Mặc định 1): " PROTO_CHOICE

if [ "$PROTO_CHOICE" = "2" ]; then
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

# 3. Tạo Profile và ghi cấu hình user.js
echo -e "\nĐang cấu hình..."

PROFILE_DIR="$HOME/.thunderbird/auto.profile"
mkdir -p "$PROFILE_DIR"

cat <<EOF > "$PROFILE_DIR/user.js"
// Account Management
user_pref("mail.account.account1.server", "server1");
user_pref("mail.account.account1.identities", "id1");
user_pref("mail.accountmanager.accounts", "account1");
user_pref("mail.accountmanager.defaultaccount", "account1");

// Incoming Server (IMAP/POP3) - BizFly Cloud
user_pref("mail.server.server1.type", "$SERVER_TYPE");
user_pref("mail.server.server1.hostname", "$IN_HOST");
user_pref("mail.server.server1.userlogintypes", 0);
user_pref("mail.server.server1.username", "$USER_EMAIL");
user_pref("mail.server.server1.port", $IN_PORT);
user_pref("mail.server.server1.socketType", 3); // SSL/TLS
user_pref("mail.server.server1.authMethod", 3); // Normal password

// Identity Config
user_pref("mail.identity.id1.useremail", "$USER_EMAIL");
user_pref("mail.identity.id1.fullName", "$FULL_NAME");
user_pref("mail.identity.id1.valid", true);
user_pref("mail.identity.id1.smtpServer", "smtp1");

// Outgoing Server (SMTP) - BizFly Cloud
user_pref("mail.smtp.defaultserver", "smtp1");
user_pref("mail.smtpserver.smtp1.hostname", "mail.bizflycloud.vn");
user_pref("mail.smtpserver.smtp1.port", 465);
user_pref("mail.smtpserver.smtp1.username", "$USER_EMAIL");
user_pref("mail.smtpserver.smtp1.authMethod", 3); // Normal password
user_pref("mail.smtpserver.smtp1.try_ssl", 3); // SSL/TLS
user_pref("mail.smtpservers", "smtp1");
EOF

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

# 4. Mở Thunderbird
echo ""
read -p "Nhấn Enter để mở Thunderbird..."
nohup thunderbird > /dev/null 2>&1 &
