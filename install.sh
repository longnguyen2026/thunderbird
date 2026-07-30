#!/bin/bash
set -e

# ============================================
# THUNDERBIRD BIZFLY INSTALLER v2.0
# GitHub: https://github.com/longnguyen2026/thunderrbird
# ============================================

# Màu sắc
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Banner
clear
cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║     🚀 THUNDERBIRD BIZFLY INSTALLER v2.0                 ║
║                                                           ║
║     Tự động cấu hình email BizFly trên Thunderbird        ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
echo ""

# ============================================
# KIỂM TRA MÔI TRƯỜNG
# ============================================
echo -e "${BLUE}[1/5] 🔍 Kiểm tra môi trường...${NC}"

if ! command -v thunderbird &> /dev/null; then
    echo -e "  ${YELLOW}⚠️${NC} Thunderbird chưa cài, đang cài đặt..."
    sudo apt update -qq
    sudo apt install -y thunderbird > /dev/null 2>&1
fi
echo -e "  ${GREEN}✅${NC} Thunderbird: Đã cài đặt"

if ping -c 1 -W 2 mail.bizflycloud.vn &> /dev/null; then
    echo -e "  ${GREEN}✅${NC} Internet: OK"
else
    echo -e "  ${RED}❌${NC} Internet: Không có kết nối"
    exit 1
fi
echo ""

# ============================================
# NHẬP THÔNG TIN
# ============================================
echo -e "${BLUE}[2/5] 📝 Nhập thông tin cấu hình${NC}"

echo -e "\n  Chọn giao thức email:"
echo -e "    ${GREEN}1${NC}. IMAP ${GREEN}(Khuyến nghị)${NC}"
echo -e "    ${YELLOW}2${NC}. POP3"
echo ""
read -p "  Lựa chọn [1/2] (Mặc định: 1): " PROTO_CHOICE
PROTO_CHOICE=${PROTO_CHOICE:-1}

if [ "$PROTO_CHOICE" = "2" ]; then
    SERVER_TYPE="pop3"
    IN_PORT="995"
else
    SERVER_TYPE="imap"
    IN_PORT="993"
fi

echo ""
read -p "  👤 Tên hiển thị: " FULL_NAME
while [ -z "$FULL_NAME" ]; do
    read -p "  👤 Tên hiển thị (không để trống): " FULL_NAME
done

echo ""
read -p "  📧 Email: " USER_EMAIL
while [[ ! "$USER_EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; do
    read -p "  📧 Email (hợp lệ): " USER_EMAIL
done

echo ""
read -s -p "  🔑 Mật khẩu (để trống nếu không lưu): " USER_PASS
echo ""
echo ""

# ============================================
# TẠO PROFILE
# ============================================
echo -e "${BLUE}[3/5] 📁 Tạo profile...${NC}"

# Xác định thư mục Thunderbird
TB_BASE="$HOME/.thunderbird"
if [ -d "$HOME/.var/app/org.mozilla.Thunderbird/.thunderbird" ]; then
    TB_BASE="$HOME/.var/app/org.mozilla.Thunderbird/.thunderbird"
    echo -e "  ${YELLOW}ℹ️${NC} Sử dụng Thunderbird Snap"
fi

# Đóng Thunderbird
pkill thunderbird 2>/dev/null || true
sleep 2

# Xóa profile cũ
rm -rf "$TB_BASE"/*.bizfly* 2>/dev/null || true
rm -f "$TB_BASE/profiles.ini" 2>/dev/null || true

# Tạo profile mới
PROFILE_NAME="bizfly"
echo -e "  ${YELLOW}⏳${NC} Tạo profile: $PROFILE_NAME"
thunderbird -CreateProfile "$PROFILE_NAME" > /dev/null 2>&1
sleep 3

# Tìm profile path
PROFILE_PATH=$(find "$TB_BASE" -maxdepth 1 -type d -name "*.${PROFILE_NAME}" | head -1)

if [ -z "$PROFILE_PATH" ]; then
    echo -e "  ${RED}❌${NC} Không tìm thấy profile, tạo thủ công..."
    PROFILE_PATH="$TB_BASE/${PROFILE_NAME}.default"
    mkdir -p "$PROFILE_PATH"
fi

echo -e "  ${GREEN}✅${NC} Profile: $(basename "$PROFILE_PATH")"
echo ""

# ============================================
# CẤU HÌNH - PHƯƠNG PHÁP MỚI
# ============================================
echo -e "${BLUE}[4/5] ⚙️  Cấu hình...${NC}"

# Tạo thư mục defaults/profile (QUAN TRỌNG)
mkdir -p "$TB_BASE/defaults/profile"

# Tạo file user.js trong defaults/profile
echo -e "  ${YELLOW}⏳${NC} Tạo cấu hình trong defaults/profile..."

cat > "$TB_BASE/defaults/profile/user.js" <<EOF
// ============================================
// Thunderbird BizFly Default Configuration
// This will be applied to ALL new profiles
// ============================================

// Account Management
user_pref("mail.accountmanager.accounts", "account1");
user_pref("mail.accountmanager.defaultaccount", "account1");
user_pref("mail.accountmanager.locallyStoredAccounts", "account1");
user_pref("mail.account.account1.identities", "id1");
user_pref("mail.account.account1.server", "server1");

// Identity
user_pref("mail.identity.id1.fullName", "$FULL_NAME");
user_pref("mail.identity.id1.useremail", "$USER_EMAIL");
user_pref("mail.identity.id1.valid", true);
user_pref("mail.identity.id1.smtpServer", "smtp1");
user_pref("mail.identity.id1.reply_to", "$USER_EMAIL");

// Incoming Server
user_pref("mail.server.server1.type", "$SERVER_TYPE");
user_pref("mail.server.server1.hostname", "mail.bizflycloud.vn");
user_pref("mail.server.server1.port", $IN_PORT);
user_pref("mail.server.server1.userName", "$USER_EMAIL");
user_pref("mail.server.server1.authMethod", 3);
user_pref("mail.server.server1.socketType", 3);
user_pref("mail.server.server1.name", "$USER_EMAIL");
user_pref("mail.server.server1.login_at_startup", true);

// SMTP Server
user_pref("mail.smtpservers", "smtp1");
user_pref("mail.smtp.defaultserver", "smtp1");
user_pref("mail.smtpserver.smtp1.hostname", "mail.bizflycloud.vn");
user_pref("mail.smtpserver.smtp1.port", 465);
user_pref("mail.smtpserver.smtp1.try_ssl", 3);
user_pref("mail.smtpserver.smtp1.authMethod", 3);
user_pref("mail.smtpserver.smtp1.username", "$USER_EMAIL");

// Bỏ qua Setup Wizard
user_pref("mail.startup.enabledMailCheckOnce", true);
user_pref("mail.provider.${SERVER_TYPE}.${USER_EMAIL}.configured", true);
user_pref("mail.provider.${SERVER_TYPE}.${USER_EMAIL}.autoconfigured", true);
user_pref("mail.provider.${SERVER_TYPE}.${USER_EMAIL}.hostname", "mail.bizflycloud.vn");
user_pref("mail.provider.${SERVER_TYPE}.${USER_EMAIL}.port", $IN_PORT);
user_pref("mail.provider.${SERVER_TYPE}.${USER_EMAIL}.socketType", 3);
user_pref("mail.provider.${SERVER_TYPE}.${USER_EMAIL}.authMethod", 3);
user_pref("mail.auto_config.${USER_EMAIL}.done", true);
user_pref("mail.auto_config.${USER_EMAIL}.success", true);

// UI Settings
user_pref("mail.openMessageBehavior.version", 1);
user_pref("mail.identity.id1.draft_autosave", true);
user_pref("mail.identity.id1.archive_enabled", true);

// Security
user_pref("privacy.trackingprotection.enabled", true);
user_pref("privacy.trackingprotection.emailtracking.enabled", true);

// Performance
user_pref("mail.imap.use_literal_plus", true);
user_pref("mail.imap.use_status_for_biff", true);
EOF

# Tạo file cấu hình trong profile
echo -e "  ${YELLOW}⏳${NC} Tạo cấu hình trong profile..."

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
user_pref("mail.server.server1.type", "$SERVER_TYPE");
user_pref("mail.server.server1.hostname", "mail.bizflycloud.vn");
user_pref("mail.server.server1.port", $IN_PORT);
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
user_pref("mail.provider.${SERVER_TYPE}.${USER_EMAIL}.configured", true);
user_pref("mail.provider.${SERVER_TYPE}.${USER_EMAIL}.autoconfigured", true);
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

# Cập nhật profiles.ini
cat > "$TB_BASE/profiles.ini" <<EOF
[General]
StartWithLastProfile=1
Version=2

[Profile0]
Name=$PROFILE_NAME
IsRelative=1
Path=$(basename "$PROFILE_PATH")
Default=1
EOF

echo -e "  ${GREEN}✅${NC} Cấu hình hoàn tất"
echo ""

# ============================================
# HOÀN TẤT
# ============================================
echo -e "${BLUE}[5/5] 🎉 Hoàn tất${NC}"

echo -e "\n  ${GREEN}✅ CẤU HÌNH HOÀN TẤT!${NC}"
echo -e "\n  📋 Thông tin:"
echo -e "    • Giao thức: ${SERVER_TYPE^^}"
echo -e "    • Server: mail.bizflycloud.vn:$IN_PORT"
echo -e "    • SMTP: mail.bizflycloud.vn:465"
echo -e "    • Email: $USER_EMAIL"
echo -e "    • Profile: $PROFILE_NAME"
echo -e "    • Mật khẩu: $([ -n "$USER_PASS" ] && echo "${GREEN}Đã lưu${NC}" || echo "${YELLOW}Chưa lưu${NC}")"

echo -e "\n  ${GREEN}▶${NC} Đang mở Thunderbird..."
sleep 2

nohup thunderbird -P "$PROFILE_NAME" > /dev/null 2>&1 &
disown

echo -e "\n  ${GREEN}✅${NC} Thunderbird đã mở!"
echo -e "  ${GREEN}✅${NC} Email đã được cấu hình sẵn!"
echo -e "  ${GREEN}✅${NC} KHÔNG hiện Setup Wizard!"
echo -e "\n${BLUE}════════════════════════════════════════════════════════════${NC}\n"

exit 0
