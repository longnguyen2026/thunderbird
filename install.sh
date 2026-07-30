#!/bin/bash

# ============================================
# THUNDERBIRD BIZFLY INSTALLER - FUNCTIONS
# Version: 2.0
# ============================================

# Màu sắc
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ============================================
# KIỂM TRA MÔI TRƯỜNG
# ============================================
check_environment() {
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
}

# ============================================
# NHẬP THÔNG TIN
# ============================================
get_user_input() {
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
    
    export SERVER_TYPE IN_PORT FULL_NAME USER_EMAIL USER_PASS
}

# ============================================
# TẠO PROFILE
# ============================================
create_profile() {
    echo -e "${BLUE}[3/5] 📁 Tạo profile...${NC}"
    
    TB_BASE="$HOME/.thunderbird"
    if [ -d "$HOME/.var/app/org.mozilla.Thunderbird/.thunderbird" ]; then
        TB_BASE="$HOME/.var/app/org.mozilla.Thunderbird/.thunderbird"
        echo -e "  ${YELLOW}ℹ️${NC} Sử dụng Thunderbird Snap"
    fi
    
    pkill thunderbird 2>/dev/null || true
    sleep 2
    
    rm -rf "$TB_BASE"/*.bizfly* 2>/dev/null || true
    rm -f "$TB_BASE/profiles.ini" 2>/dev/null || true
    
    PROFILE_NAME="bizfly"
    echo -e "  ${YELLOW}⏳${NC} Tạo profile: $PROFILE_NAME"
    thunderbird -CreateProfile "$PROFILE_NAME" > /dev/null 2>&1
    sleep 3
    
    PROFILE_PATH=$(find "$TB_BASE" -maxdepth 1 -type d -name "*.${PROFILE_NAME}" | head -1)
    
    if [ -z "$PROFILE_PATH" ]; then
        echo -e "  ${RED}❌${NC} Không tìm thấy profile, tạo thủ công..."
        PROFILE_PATH="$TB_BASE/${PROFILE_NAME}.default"
        mkdir -p "$PROFILE_PATH"
    fi
    
    echo -e "  ${GREEN}✅${NC} Profile: $(basename "$PROFILE_PATH")"
    echo ""
    
    export TB_BASE PROFILE_NAME PROFILE_PATH
}

# ============================================
# CẤU HÌNH
# ============================================
deploy_config() {
    echo -e "${BLUE}[4/5] ⚙️  Cấu hình...${NC}"
    
    # Tạo defaults/profile
    mkdir -p "$TB_BASE/defaults/profile"
    
    # Tạo file cấu hình mặc định
    cat > "$TB_BASE/defaults/profile/user.js" <<EOF
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
    
    # Tạo prefs.js
    cat > "$PROFILE_PATH/prefs.js" <<EOF
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
    
    # profiles.ini
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
}

# ============================================
# HOÀN TẤT
# ============================================
finish() {
    echo -e "${BLUE}[5/5] 🎉 Hoàn tất${NC}"
    
    echo -e "\n  ${GREEN}✅ CẤU HÌNH HOÀN TẤT!${NC}"
    echo -e "\n  📋 Thông tin:"
    echo -e "    • Giao thức: ${SERVER_TYPE^^}"
    echo -e "    • Server: mail.bizflycloud.vn:$IN_PORT"
    echo -e "    • Email: $USER_EMAIL"
    echo -e "    • Profile: $PROFILE_NAME"
    
    echo -e "\n  ${GREEN}▶${NC} Đang mở Thunderbird..."
    sleep 2
    
    nohup thunderbird -P "$PROFILE_NAME" > /dev/null 2>&1 &
    disown
    
    echo -e "\n  ${GREEN}✅${NC} Thunderbird đã mở!"
    echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}\n"
}
