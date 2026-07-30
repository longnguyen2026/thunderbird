#!/bin/bash
set -e

# Tự động bắt TTY nếu chạy curl | bash
if [ ! -t 0 ]; then
    TMP_SCRIPT=$(mktemp /tmp/tb_install.XXXXXX.sh)
    cat > "$TMP_SCRIPT"
    exec bash "$TMP_SCRIPT" "$@" < /dev/tty
    rm -f "$TMP_SCRIPT"
    exit 0
fi

clear
echo "========================================================="
echo "          THUNDERBIRD BIZFLY INSTALLER"
echo "                  Version 1.0"
echo "========================================================="

# 1. Tắt Thunderbird nếu đang chạy
pkill -x thunderbird || true
sleep 1

# Check Thunderbird
if ! command -v thunderbird &> /dev/null; then
    echo -e "⚠️ Thunderbird: Not installed (Đang cài đặt...)"
    sudo apt update -qq && sudo apt install -y thunderbird > /dev/null 2>&1
fi
echo -e "✓ Thunderbird: Installed"

# Check Internet
if ping -c 1 mail.bizflycloud.vn &> /dev/null; then
    echo -e "✓ Internet: OK"
else
    echo -e "❌ Internet: No Connection"
    exit 1
fi

# 2. Nhập thông tin
echo -e "\nChọn giao thức\n"
echo " 1. IMAP (Khuyến nghị)"
echo " 2. POP3"
echo -e "\n-----------------------------------------\n"

read -p "Chọn [1/2] (Mặc định 1): " PROTO_CHOICE
PROTO_CHOICE=${PROTO_CHOICE:-1}

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
FULL_NAME=""
while [ -z "$FULL_NAME" ]; do
    read -p "Tên hiển thị: " FULL_NAME
done

USER_EMAIL=""
while [[ ! "$USER_EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; do
    read -p "Email: " USER_EMAIL
    if [[ ! "$USER_EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        echo -e "❌ Email không hợp lệ, vui lòng nhập lại!\n"
    fi
done

echo -e "\nĐang cấu hình..."

# 3. Xác định đúng thư mục root của Thunderbird
TB_BASE="$HOME/.thunderbird"
if [ -d "$HOME/.var/app/org.mozilla.Thunderbird/.thunderbird" ]; then
    TB_BASE="$HOME/.var/app/org.mozilla.Thunderbird/.thunderbird"
fi

PROFILE_DIR="$TB_BASE/auto.profile"
mkdir -p "$PROFILE_DIR"

# 4. Ghi file user.js chuẩn
cat <<EOF > "$PROFILE_DIR/user.js"
user_pref("mail.account.account1.identities", "id1");
user_pref("mail.account.account1.server", "server1");
user_pref("mail.accountmanager.accounts", "account1");
user_pref("mail.accountmanager.defaultaccount", "account1");
user_pref("mail.identity.id1.fullName", "$FULL_NAME");
user_pref("mail.identity.id1.useremail", "$USER_EMAIL");
user_pref("mail.identity.id1.valid", true);
user_pref("mail.identity.id1.smtpServer", "smtp1");
user_pref("mail.server.server1.authMethod", 3);
user_pref("mail.server.server1.hostname", "$IN_HOST");
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
EOF

# 5. Ghi file profiles.ini
cat <<EOF > "$TB_BASE/profiles.ini"
[Profile0]
Name=default
IsRelative=1
Path=auto.profile
Default=1

[General]
StartWithLastProfile=1
Version=2
EOF

# Xóa bớt cache profile cũ nếu có
rm -rf "$TB_BASE/installs.ini"

sleep 1
echo -e "\n✓ Hoàn tất."

# 6. Khởi động Thunderbird
echo ""
read -p "Nhấn Enter để mở Thunderbird..."
nohup thunderbird > /dev/null 2>&1 &
disown
