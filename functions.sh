#!/bin/bash

# ============================================
# Thunderbird BizFly Functions Library
# Version: 3.0
# ============================================

# Màu sắc
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Biến toàn cục
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/config"

# ============================================
# Kiểm tra môi trường
# ============================================
check_environment() {
    echo -e "${BLUE}[1/5] Kiểm tra môi trường...${NC}"
    
    if command -v thunderbird &> /dev/null; then
        echo -e "  ${GREEN}✓${NC} Thunderbird: Đã cài đặt"
        TB_VER=$(thunderbird --version 2>/dev/null | head -n1 || echo "Unknown")
        echo -e "  ${GREEN}✓${NC} Phiên bản: $TB_VER"
    else
        echo -e "  ${YELLOW}⚠${NC} Thunderbird chưa cài đặt..."
        sudo apt update -qq
        sudo apt install -y thunderbird > /dev/null 2>&1
        echo -e "  ${GREEN}✓${NC} Thunderbird đã được cài đặt"
    fi

    if ping -c 1 -W 2 mail.bizflycloud.vn &> /dev/null; then
        echo -e "  ${GREEN}✓${NC} Internet: OK"
    else
        echo -e "  ${RED}✗${NC} Internet: Không có kết nối"
        exit 1
    fi
    echo ""
}

# ============================================
# Nhập thông tin người dùng
# ============================================
get_user_input() {
    echo -e "${BLUE}[2/5] Nhập thông tin cấu hình${NC}"
    
    echo -e "\n  Chọn giao thức:"
    echo -e "    ${GREEN}1${NC}. IMAP (Khuyến nghị)"
    echo -e "    ${YELLOW}2${NC}. POP3"
    echo ""
    read -p "  Lựa chọn [1/2] (Mặc định: 1): " PROTO_CHOICE
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
    while [ -z "$FULL_NAME" ]; do
        read -p "  Tên hiển thị: " FULL_NAME
        [ -z "$FULL_NAME" ] && echo -e "  ${RED}✗${NC} Không được để trống"
    done

    echo ""
    while [[ ! "$USER_EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; do
        read -p "  Địa chỉ email: " USER_EMAIL
        [[ ! "$USER_EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]] && \
            echo -e "  ${RED}✗${NC} Email không hợp lệ"
    done

    echo ""
    read -s -p "  Mật khẩu (để trống nếu không lưu): " USER_PASSWORD
    echo ""
    
    echo -e "\n  ${GREEN}✓${NC} Thông tin đã nhập:"
    echo -e "    • Giao thức: ${SERVER_TYPE^^}"
    echo -e "    • Tên: $FULL_NAME"
    echo -e "    • Email: $USER_EMAIL"
    echo ""
}

# ============================================
# Tạo profile
# ============================================
create_profile() {
    echo -e "${BLUE}[3/5] Tạo profile...${NC}"
    
    TB_BASE="$HOME/.thunderbird"
    [ -d "$HOME/.var/app/org.mozilla.Thunderbird/.thunderbird" ] && \
        TB_BASE="$HOME/.var/app/org.mozilla.Thunderbird/.thunderbird"

    mkdir -p "$TB_BASE"
    pkill -x thunderbird 2>/dev/null || true
    sleep 1

    PROFILE_NAME="bizfly_$(date +%s)"
    thunderbird -CreateProfile "$PROFILE_NAME" > /dev/null 2>&1
    sleep 2

    PROFILE_PATH=$(find "$TB_BASE" -maxdepth 1 -type d -name "*.${PROFILE_NAME}" | head -n 1)
    [ -z "$PROFILE_PATH" ] && {
        PROFILE_PATH="$TB_BASE/${PROFILE_NAME}.default"
        mkdir -p "$PROFILE_PATH"
    }
    
    echo -e "  ${GREEN}✓${NC} Profile: $(basename "$PROFILE_PATH")"
    echo ""
}

# ============================================
# Deploy cấu hình
# ============================================
deploy_config() {
    echo -e "${BLUE}[4/5] Cấu hình email...${NC}"
    
    # Tạo user.js
    cat <<EOF > "$PROFILE_PATH/user.js"
// Account
user_pref("mail.accountmanager.accounts", "account1");
user_pref("mail.accountmanager.defaultaccount", "account1");
user_pref("mail.account.account1.identities", "id1");
user_pref("mail.account.account1.server", "server1");

// Identity
user_pref("mail.identity.id1.fullName", "$FULL_NAME");
user_pref("mail.identity.id1.useremail", "$USER_EMAIL");
user_pref("mail.identity.id1.valid", true);
user_pref("mail.identity.id1.smtpServer", "smtp1");

// Incoming
user_pref("mail.server.server1.type", "$SERVER_TYPE");
user_pref("mail.server.server1.hostname", "$IN_HOST");
user_pref("mail.server.server1.port", $IN_PORT);
user_pref("mail.server.server1.userName", "$USER_EMAIL");
user_pref("mail.server.server1.authMethod", 3);
user_pref("mail.server.server1.socketType", 3);
user_pref("mail.server.server1.name", "$USER_EMAIL");

// SMTP
user_pref("mail.smtpservers", "smtp1");
user_pref("mail.smtp.defaultserver", "smtp1");
user_pref("mail.smtpserver.smtp1.hostname", "mail.bizflycloud.vn");
user_pref("mail.smtpserver.smtp1.port", 465);
user_pref("mail.smtpserver.smtp1.try_ssl", 3);
user_pref("mail.smtpserver.smtp1.authMethod", 3);
user_pref("mail.smtpserver.smtp1.username", "$USER_EMAIL");

// Bỏ qua Setup Wizard
user_pref("mail.provider.${SERVER_TYPE}.${USER_EMAIL}.configured", true);
user_pref("mail.provider.${SERVER_TYPE}.${USER_EMAIL}.autoconfigured", true);
user_pref("mail.provider.${SERVER_TYPE}.${USER_EMAIL}.hostname", "$IN_HOST");
user_pref("mail.provider.${SERVER_TYPE}.${USER_EMAIL}.port", $IN_PORT);
user_pref("mail.provider.${SERVER_TYPE}.${USER_EMAIL}.socketType", 3);
user_pref("mail.provider.${SERVER_TYPE}.${USER_EMAIL}.authMethod", 3);
user_pref("mail.auto_config.${USER_EMAIL}.done", true);
user_pref("mail.auto_config.${USER_EMAIL}.success", true);

// UI
user_pref("mail.startup.enabledMailCheckOnce", true);
user_pref("mail.openMessageBehavior.version", 1);
EOF

    # Lưu mật khẩu
    if [ -n "$USER_PASSWORD" ]; then
        cat <<EOF > "$PROFILE_PATH/logins.json"
{
  "logins": [{
    "id": 1,
    "hostname": "mail.bizflycloud.vn",
    "username": "$USER_EMAIL",
    "password": "$USER_PASSWORD"
  }],
  "version": 3
}
EOF
    fi

    # Cập nhật profiles.ini
    cat <<EOF > "$TB_BASE/profiles.ini"
[General]
StartWithLastProfile=1

[Profile0]
Name=$PROFILE_NAME
IsRelative=1
Path=$(basename "$PROFILE_PATH")
Default=1
EOF

    echo -e "  ${GREEN}✓${NC} Cấu hình hoàn tất"
    echo ""
}

# ============================================
# Hoàn tất
# ============================================
finish() {
    echo -e "${BLUE}[5/5] Hoàn tất${NC}"
    echo -e "\n  ${GREEN}✅ Cấu hình hoàn tất!${NC}"
    echo -e "\n  📋 Thông tin:"
    echo -e "    • Giao thức: ${SERVER_TYPE^^}"
    echo -e "    • Server: $IN_HOST:$IN_PORT"
    echo -e "    • Email: $USER_EMAIL"
    
    [ -n "$USER_PASSWORD" ] && echo -e "    • Mật khẩu: ${GREEN}Đã lưu${NC}" || \
        echo -e "    • Mật khẩu: ${YELLOW}Chưa lưu${NC}"

    echo -e "\n  ${GREEN}▶${NC} Đang mở Thunderbird..."
    sleep 2
    
    nohup thunderbird -P "$PROFILE_NAME" > /dev/null 2>&1 &
    disown
    
    echo -e "\n  ${GREEN}✓${NC} Hoàn tất!"
    echo -e "${BLUE}=========================================================${NC}\n"
}

# Export functions
export -f check_environment
export -f get_user_input
export -f create_profile
export -f deploy_config
export -f finish
