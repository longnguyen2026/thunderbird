#!/bin/bash
# install.sh - Script cài đặt và cấu hình Thunderbird cho BizflyCloud

PROFILE_DIR="$HOME/.thunderbird/bizfly.default"

# Cài đặt Thunderbird nếu chưa có
if ! command -v thunderbird &> /dev/null; then
    echo "Đang cài đặt Thunderbird..."
    sudo apt update && sudo apt install -y thunderbird
fi

# Tạo profile nếu chưa có
if [ ! -d "$PROFILE_DIR" ]; then
    thunderbird -CreateProfile "bizfly $PROFILE_DIR"
fi

echo "Chọn giao thức nhận mail:"
echo "1) IMAP (imap.bizflycloud.vn:993 SSL)"
echo "2) POP3 (pop3.bizflycloud.vn:995 SSL)"
read -p "Nhập lựa chọn [1-2]: " choice

if [ "$choice" == "1" ]; then
    PROTOCOL="imap"
    PORT=993
    SOCKET=2 # SSL/TLS
elif [ "$choice" == "2" ]; then
    PROTOCOL="pop3"
    PORT=995
    SOCKET=2 # SSL/TLS
else
    echo "Lựa chọn không hợp lệ."
    exit 1
fi

read -p "Nhập họ tên đầy đủ: " FULLNAME
read -p "Nhập địa chỉ email BizflyCloud: " EMAIL
read -p "Nhập tên đăng nhập (thường là email): " USERNAME

cat > "$PROFILE_DIR/user.js" <<EOF
// Thông tin người dùng
user_pref("mail.identity.id1.fullName", "${FULLNAME}");
user_pref("mail.identity.id1.useremail", "${EMAIL}");
user_pref("mail.identity.id1.smtpServer", "smtp1");

// Server nhận mail
user_pref("mail.server.server1.hostname", "${PROTOCOL}.bizflycloud.vn");
user_pref("mail.server.server1.type", "${PROTOCOL}");
user_pref("mail.server.server1.userName", "${USERNAME}");
user_pref("mail.server.server1.port", ${PORT});
user_pref("mail.server.server1.socketType", ${SOCKET});

// SMTP gửi mail
user_pref("mail.smtpserver.smtp1.hostname", "smtp.bizflycloud.vn");
user_pref("mail.smtpserver.smtp1.username", "${USERNAME}");
user_pref("mail.smtpserver.smtp1.port", 587);
user_pref("mail.smtpserver.smtp1.try_ssl", 2); // STARTTLS
EOF

echo "✅ Cấu hình Thunderbird cho BizflyCloud (${PROTOCOL}) đã được tạo."
echo "⚠️ Lần đầu mở Thunderbird, bạn sẽ được hỏi nhập mật khẩu để lưu vào kho bảo mật."

# Tự mở Thunderbird với profile vừa tạo
thunderbird -P bizfly &
