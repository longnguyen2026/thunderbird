#!/bin/bash

# ============================================
# THUNDERBIRD BIZFLY INSTALLER
# Version: 7.0 - FIXED
# ============================================

set -e

# Màu sắc
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# --- Hàm để đảm bảo nhập từ bàn phím ---
force_tty_input() {
    if [ ! -t 0 ]; then
        # Chạy lại script với TTY
        exec bash -c "exec < /dev/tty; bash $0 $@"
        exit 0
    fi
}

# Gọi hàm ngay từ đầu
force_tty_input "$@"

clear
echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     🚀 THUNDERBIRD BIZFLY INSTALLER v7.0                ║${NC}"
echo -e "${BLUE}║     ✅ FIXED: NHẬP LIỆU & TẠO PROFILE                   ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

# ============================================
# 1. KIỂM TRA
# ============================================
echo -e "${BLUE}[1/5] 🔍 Kiểm tra môi trường...${NC}"

if ! command -v thunderbird &> /dev/null; then
    echo -e "  ${YELLOW}⚠️${NC} Đang cài Thunderbird..."
    sudo apt update -qq && sudo apt install -y thunderbird -qq
fi
echo -e "  ${GREEN}✅${NC} Thunderbird: OK"

if ping -c 1 -W 2 mail.bizflycloud.vn &> /dev/null; then
    echo -e "  ${GREEN}✅${NC} Internet: OK"
else
    echo -e "  ${RED}❌${NC} Không có kết nối"
    exit 1
fi
echo ""

# ============================================
# 2. NHẬP THÔNG TIN (ĐÃ SỬA)
# ============================================
echo -e "${BLUE}[2/5] 📝 Nhập thông tin${NC}"

echo -e "\n  Chọn giao thức:"
echo -e "    ${GREEN}1${NC}. IMAP"
echo -e "    ${YELLOW}2${NC}. POP3"
read -p "  Lựa chọn [1/2]: " CHOICE </dev/tty

if [ "$CHOICE" = "2" ]; then
    PROTO="pop3"; PORT="995"
else
    PROTO="imap"; PORT="993"
fi

echo ""
read -p "  Tên hiển thị: " FULL_NAME </dev/tty
while [ -z "$FULL_NAME" ]; do
    read -p "  Tên hiển thị (không để trống): " FULL_NAME </dev/tty
done

echo ""
read -p "  Email: " USER_EMAIL </dev/tty
while [[ ! "$USER_EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; do
    read -p "  Email (hợp lệ): " USER_EMAIL </dev/tty
done

echo ""
read -s -p "  Mật khẩu (để trống nếu không lưu): " USER_PASS </dev/tty
echo ""
echo ""

# ============================================
# 3. XÓA PROFILE CŨ
# ============================================
echo -e "${BLUE}[3/5] 📁 Xóa profile cũ...${NC}"

pkill thunderbird 2>/dev/null || true
sleep 2

rm -rf ~/.thunderbird 2>/dev/null || true
echo -e "  ${GREEN}✅${NC} Đã xóa profile cũ"
echo ""

# ============================================
# 4. TẠO PROFILE MỚI (ĐÃ SỬA)
# ============================================
echo -e "${BLUE}[4/5] ⚙️  Tạo profile...${NC}"

mkdir -p ~/.thunderbird

PROFILE_NAME="bizfly"
echo -e "  ${YELLOW}⏳${NC} Tạo profile: $PROFILE_NAME"

# Tạo profile với đường dẫn tuyệt đối để tránh lỗi
thunderbird -CreateProfile "$PROFILE_NAME" 2>/dev/null || true
sleep 3

# Tìm profile path
PROFILE_PATH=$(find ~/.thunderbird -maxdepth 1 -type d -name "*.${PROFILE_NAME}" | head -1)

if [ -z "$PROFILE_PATH" ]; then
    echo -e "  ${YELLOW}⚠️${NC} Không tìm thấy profile. Tạo thủ công..."
    PROFILE_PATH="$HOME/.thunderbird/${PROFILE_NAME}.default"
    mkdir -p "$PROFILE_PATH"
    
    # Tạo file cần thiết cho profile
    touch "$PROFILE_PATH/prefs.js"
    touch "$PROFILE_PATH/user.js"
fi

echo -e "  ${GREEN}✅${NC} Profile: $(basename "$PROFILE_PATH")"
echo ""

# ============================================
# 5. CẤU HÌNH (ĐÃ SỬA)
# ============================================
echo -e "${BLUE}[5/5] ⚙️  Cấu hình email...${NC}"

# Tạo file user.js
echo -e "  ${YELLOW}⏳${NC} Tạo user.js..."

cat > "$PROFILE_PATH/user.js" <<EOF
// ============================================
// THUNDERBIRD BIZFLY CONFIGURATION
// ============================================

// ACCOUNT
user_pref("mail.accountmanager.accounts", "account1");
user_pref("mail.accountmanager.defaultaccount", "account1");
user_pref("mail.account.account1.identities", "id1");
user_pref("mail.account.account1.server", "server1");

// IDENTITY
user_pref("mail.identity.id1.fullName", "$FULL_NAME");
user_pref("mail.identity.id1.useremail", "$USER_EMAIL");
user_pref("mail.identity.id1.valid", true);
user_pref("mail.identity.id1.smtpServer", "smtp1");

// INCOMING SERVER
user_pref("mail.server.server1.type", "$PROTO");
user_pref("mail.server.server1.hostname", "mail.bizflycloud.vn");
user_pref("mail.server.server1.port", $PORT);
user_pref("mail.server.server1.userName", "$USER_EMAIL");
user_pref("mail.server.server1.authMethod", 3);
user_pref("mail.server.server1.socketType", 3);
user_pref("mail.server.server1.name", "$USER_EMAIL");
user_pref("mail.server.server1.login_at_startup", true);

// SMTP SERVER
user_pref("mail.smtpservers", "smtp1");
user_pref("mail.smtp.defaultserver", "smtp1");
user_pref("mail.smtpserver.smtp1.hostname", "mail.bizflycloud.vn");
user_pref("mail.smtpserver.smtp1.port", 465);
user_pref("mail.smtpserver.smtp1.try_ssl", 3);
user_pref("mail.smtpserver.smtp1.authMethod", 3);
user_pref("mail.smtpserver.smtp1.username", "$USER_EMAIL");

// DISABLE SETUP WIZARD
user_pref("mail.startup.enabledMailCheckOnce", true);
user_pref("mail.provider.${PROTO}.${USER_EMAIL}.configured", true);
user_pref("mail.provider.${PROTO}.${USER_EMAIL}.autoconfigured", true);
user_pref("mail.provider.${PROTO}.${USER_EMAIL}.hostname", "mail.bizflycloud.vn");
user_pref("mail.provider.${PROTO}.${USER_EMAIL}.port", $PORT);
user_pref("mail.provider.${PROTO}.${USER_EMAIL}.socketType", 3);
user_pref("mail.provider.${PROTO}.${USER_EMAIL}.authMethod", 3);
user_pref("mail.auto_config.${USER_EMAIL}.done", true);
user_pref("mail.auto_config.${USER_EMAIL}.success", true);

// UI
user_pref("mail.openMessageBehavior.version", 1);
user_pref("mail.identity.id1.draft_autosave", true);

// SECURITY
user_pref("privacy.trackingprotection.enabled", true);
EOF

# Tạo file prefs.js
cat > "$PROFILE_PATH/prefs.js" <<EOF
# Mozilla User Preferences
user_pref("mail.accountmanager.accounts", "account1");
user_pref("mail.accountmanager.defaultaccount", "account1");
user_pref("mail.account.account1.identities", "id1");
user_pref("mail.account.account1.server", "server1");
user_pref("mail.identity.id1.fullName", "$FULL_NAME");
user_pref("mail.identity.id1.useremail", "$USER_EMAIL");
user_pref("mail.identity.id1.valid", true);
user_pref("mail.identity.id1.smtpServer", "smtp1");
user_pref("mail.server.server1.type", "$PROTO");
user_pref("mail.server.server1.hostname", "mail.bizflycloud.vn");
user_pref("mail.server.server1.port", $PORT);
user_pref("mail.server.server1.userName", "$USER_EMAIL");
user_pref("mail.server.server1.authMethod", 3);
user_pref("mail.server.server1.socketType", 3);
user_pref("mail.server.server1.name", "$USER_EMAIL");
user_pref("mail.smtpservers", "smtp1");
user_pref("mail.smtp.defaultserver", "smtp1");
user_pref("mail.smtpserver.smtp1.hostname", "mail.bizflycloud.vn");
user_pref("mail.smtpserver.smtp1.port", 465);
user_pref("mail.smtpserver.smtp1.try_ssl", 3);
user_pref("mail.smtpserver.smtp1.authMethod", 3);
user_pref("mail.smtpserver.smtp1.username", "$USER_EMAIL");
user_pref("mail.startup.enabledMailCheckOnce", true);
user_pref("mail.provider.${PROTO}.${USER_EMAIL}.configured", true);
user_pref("mail.provider.${PROTO}.${USER_EMAIL}.autoconfigured", true);
user_pref("mail.auto_config.${USER_EMAIL}.done", true);
user_pref("mail.auto_config.${USER_EMAIL}.success", true);
EOF

# Lưu mật khẩu
if [ -n "$USER_PASS" ]; then
    echo -e "  ${YELLOW}⏳${NC} Lưu mật khẩu..."
    
    cat > "$PROFILE_PATH/logins.json" <<EOF
{
  "logins": [{
    "id": 1,
    "hostname": "mail.bizflycloud.vn",
    "username": "$USER_EMAIL",
    "password": "$USER_PASS"
  }],
  "version": 3
}
EOF
fi

# Tạo profiles.ini
cat > ~/.thunderbird/profiles.ini <<EOF
[General]
StartWithLastProfile=1

[Profile0]
Name=$PROFILE_NAME
IsRelative=1
Path=$(basename "$PROFILE_PATH")
Default=1
EOF

echo -e "  ${GREEN}✅${NC} Cấu hình hoàn tất"
echo ""

# ============================================
# 6. HOÀN TẤT
# ============================================
echo -e "${GREEN}✅ CẤU HÌNH HOÀN TẤT!${NC}"
echo -e "\n  📋 Thông tin:"
echo -e "    • Giao thức: ${PROTO^^}"
echo -e "    • Server: mail.bizflycloud.vn:$PORT"
echo -e "    • Email: $USER_EMAIL"
echo -e "    • Profile: $PROFILE_NAME"
echo -e "    • Mật khẩu: $([ -n "$USER_PASS" ] && echo "${GREEN}Đã lưu${NC}" || echo "${YELLOW}Chưa lưu${NC}")"

echo -e "\n  ${GREEN}▶${NC} Đang mở Thunderbird..."
sleep 2

nohup thunderbird -P "$PROFILE_NAME" > /dev/null 2>&1 &
disown

echo -e "\n  ${GREEN}✅${NC} Thunderbird đã mở!"
echo -e "  ${GREEN}✅${NC} Email đã được cấu hình!"
echo -e "  ${GREEN}✅${NC} KHÔNG hiện Setup Wizard!"
echo ""

exit 0
