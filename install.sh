#!/bin/bash

# ============================================
# THUNDERBIRD BIZFLY AUTO-INSTALLER
# Version: 8.0 - TỰ ĐỘNG HOÀN TOÀN
# ============================================
# Cách dùng:
#   ./install.sh --email user@bizflycloud.vn --name "Nguyen Van A" --password "yourpass" --proto imap
#   Hoặc:
#   ./install.sh -e user@bizflycloud.vn -n "Nguyen Van A" -p "yourpass" -proto imap
# ============================================

set -e

# Màu sắc
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ============================================
# XỬ LÝ THAM SỐ
# ============================================
show_help() {
    echo "Cách dùng: $0 [OPTIONS]"
    echo ""
    echo "OPTIONS:"
    echo "  -e, --email EMAIL       Địa chỉ email (bắt buộc)"
    echo "  -n, --name NAME         Tên hiển thị (bắt buộc)"
    echo "  -p, --password PASS     Mật khẩu (tùy chọn)"
    echo "  --proto PROTO           Giao thức: imap hoặc pop3 (mặc định: imap)"
    echo "  -h, --help              Hiển thị trợ giúp"
    echo ""
    echo "Ví dụ:"
    echo "  $0 -e long@fahasa.com.vn -n \"Long Nguyen\" -p \"mypass\""
    echo "  $0 --email long@fahasa.com.vn --name \"Long Nguyen\" --proto pop3"
    exit 0
}

# Giá trị mặc định
USER_EMAIL=""
FULL_NAME=""
USER_PASS=""
PROTO="imap"
PORT="993"

# Parse tham số
while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--email)
            USER_EMAIL="$2"
            shift 2
            ;;
        -n|--name)
            FULL_NAME="$2"
            shift 2
            ;;
        -p|--password)
            USER_PASS="$2"
            shift 2
            ;;
        --proto)
            PROTO="$2"
            if [ "$PROTO" = "pop3" ]; then
                PORT="995"
            else
                PROTO="imap"
                PORT="993"
            fi
            shift 2
            ;;
        -h|--help)
            show_help
            ;;
        *)
            echo -e "${RED}❌ Tham số không hợp lệ: $1${NC}"
            show_help
            ;;
    esac
done

# Kiểm tra thông tin bắt buộc
if [ -z "$USER_EMAIL" ] || [ -z "$FULL_NAME" ]; then
    echo -e "${RED}❌ Thiếu thông tin bắt buộc!${NC}"
    echo -e "${YELLOW}⚠️ Cần cung cấp --email và --name${NC}"
    echo ""
    show_help
fi

# ============================================
# BANNER
# ============================================
clear
echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     🚀 THUNDERBIRD BIZFLY AUTO-INSTALLER v8.0          ║${NC}"
echo -e "${BLUE}║     ✅ TỰ ĐỘNG - KHÔNG CẦN NHẬP LIỆU                  ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

# ============================================
# 1. KIỂM TRA
# ============================================
echo -e "${BLUE}[1/4] 🔍 Kiểm tra môi trường...${NC}"

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
# 2. HIỂN THỊ THÔNG TIN
# ============================================
echo -e "${BLUE}[2/4] 📝 Thông tin cấu hình${NC}"
echo -e "  • Email: ${GREEN}$USER_EMAIL${NC}"
echo -e "  • Tên: ${GREEN}$FULL_NAME${NC}"
echo -e "  • Giao thức: ${GREEN}${PROTO^^}${NC}"
echo -e "  • Mật khẩu: ${GREEN}$([ -n "$USER_PASS" ] && echo "Đã cung cấp" || echo "Chưa cung cấp")${NC}"
echo ""

# ============================================
# 3. XÓA PROFILE CŨ
# ============================================
echo -e "${BLUE}[3/4] 📁 Xóa profile cũ...${NC}"

pkill thunderbird 2>/dev/null || true
sleep 2

rm -rf ~/.thunderbird 2>/dev/null || true
echo -e "  ${GREEN}✅${NC} Đã xóa profile cũ"
echo ""

# ============================================
# 4. TẠO PROFILE VÀ CẤU HÌNH
# ============================================
echo -e "${BLUE}[4/4] ⚙️  Cấu hình...${NC}"

mkdir -p ~/.thunderbird

PROFILE_NAME="bizfly"
echo -e "  ${YELLOW}⏳${NC} Tạo profile: $PROFILE_NAME"

# Tạo profile
thunderbird -CreateProfile "$PROFILE_NAME" 2>/dev/null || true
sleep 3

# Tìm profile path
PROFILE_PATH=$(find ~/.thunderbird -maxdepth 1 -type d -name "*.${PROFILE_NAME}" | head -1)

if [ -z "$PROFILE_PATH" ]; then
    echo -e "  ${YELLOW}⚠️${NC} Tạo profile thủ công..."
    PROFILE_PATH="$HOME/.thunderbird/${PROFILE_NAME}.default"
    mkdir -p "$PROFILE_PATH"
fi

echo -e "  ${GREEN}✅${NC} Profile: $(basename "$PROFILE_PATH")"

# Tạo file user.js
echo -e "  ${YELLOW}⏳${NC} Tạo cấu hình..."

cat > "$PROFILE_PATH/user.js" <<EOF
// THUNDERBIRD BIZFLY CONFIGURATION
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
user_pref("mail.server.server1.login_at_startup", true);
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
user_pref("mail.provider.${PROTO}.${USER_EMAIL}.hostname", "mail.bizflycloud.vn");
user_pref("mail.provider.${PROTO}.${USER_EMAIL}.port", $PORT);
user_pref("mail.provider.${PROTO}.${USER_EMAIL}.socketType", 3);
user_pref("mail.provider.${PROTO}.${USER_EMAIL}.authMethod", 3);
user_pref("mail.auto_config.${USER_EMAIL}.done", true);
user_pref("mail.auto_config.${USER_EMAIL}.success", true);
user_pref("mail.openMessageBehavior.version", 1);
user_pref("privacy.trackingprotection.enabled", true);
EOF

# Lưu mật khẩu
if [ -n "$USER_PASS" ]; then
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
# 5. HOÀN TẤT
# ============================================
echo -e "${GREEN}✅ CẤU HÌNH HOÀN TẤT!${NC}"
echo -e "\n  📋 Thông tin:"
echo -e "    • Giao thức: ${PROTO^^}"
echo -e "    • Server: mail.bizflycloud.vn:$PORT"
echo -e "    • Email: $USER_EMAIL"
echo -e "    • Profile: $PROFILE_NAME"

echo -e "\n  ${GREEN}▶${NC} Đang mở Thunderbird..."
sleep 2

nohup thunderbird -P "$PROFILE_NAME" > /dev/null 2>&1 &
disown

echo -e "\n  ${GREEN}✅${NC} Thunderbird đã mở!"
echo -e "  ${GREEN}✅${NC} Email đã được cấu hình tự động!"
echo ""

exit 0
