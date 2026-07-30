#!/bin/bash
set -e

# ============================================
# Thunderbird BizFly Auto-Config Installer
# Version: 3.0
# ============================================

# Màu sắc
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Banner
clear
echo -e "${BLUE}=========================================================${NC}"
echo -e "${BLUE}     THUNDERBIRD BIZFLY AUTO-CONFIG INSTALLER${NC}"
echo -e "${BLUE}                  Version 3.0${NC}"
echo -e "${BLUE}=========================================================${NC}"
echo -e "${YELLOW}  Tự động cấu hình email BizFly trên Thunderbird${NC}"
echo -e "${BLUE}=========================================================${NC}\n"

# ============================================
# HÀM KIỂM TRA MÔI TRƯỜNG
# ============================================
check_environment() {
    echo -e "${BLUE}[1/5] Kiểm tra môi trường...${NC}"
    
    # Kiểm tra Thunderbird
    if command -v thunderbird &> /dev/null; then
        echo -e "  ${GREEN}✓${NC} Thunderbird: Đã cài đặt"
        TB_VER=$(thunderbird --version 2>/dev/null | head -n1 || echo "Unknown")
        echo -e "  ${GREEN}✓${NC} Phiên bản: $TB_VER"
    else
        echo -e "  ${YELLOW}⚠${NC} Thunderbird chưa cài đặt, đang tiến hành cài đặt..."
        sudo apt update -qq
        sudo apt install -y thunderbird > /dev/null 2>&1
        echo -e "  ${GREEN}✓${NC} Thunderbird đã được cài đặt"
    fi

    # Kiểm tra kết nối Internet
    if ping -c 1 -W 2 mail.bizflycloud.vn &> /dev/null; then
        echo -e "  ${GREEN}✓${NC} Internet: Kết nối OK"
    else
        echo -e "  ${RED}✗${NC} Internet: Không có kết nối"
        echo -e "  ${RED}✗${NC} Vui lòng kiểm tra mạng và thử lại"
        exit 1
    fi
    echo ""
}

# ============================================
# HÀM NHẬP THÔNG TIN
# ============================================
get_user_input() {
    echo -e "${BLUE}[2/5] Nhập thông tin cấu hình${NC}"
    
    # Chọn giao thức
    echo -e "\n  Chọn giao thức email:"
    echo -e "    ${GREEN}1${NC}. IMAP ${GREEN}(Khuyến nghị)${NC} - Đồng bộ nhiều thiết bị"
    echo -e "    ${YELLOW}2${NC}. POP3 - Tải email về máy tính"
    echo ""
    read -p "  Lựa chọn [1/2] (Mặc định: 1): " PROTO_CHOICE
    PROTO_CHOICE=${PROTO_CHOICE:-1}

    if [ "$PROTO_CHOICE" = "2" ]; then
        SERVER_TYPE="pop3"
        IN_HOST="mail.bizflycloud.vn"
        IN_PORT="995"
        echo -e "  ${YELLOW}ℹ${NC} Đã chọn POP3 (Port: 995, SSL/TLS)"
    else
        SERVER_TYPE="imap"
        IN_HOST="mail.bizflycloud.vn"
        IN_PORT="993"
        echo -e "  ${GREEN}ℹ${NC} Đã chọn IMAP (Port: 993, SSL/TLS)"
    fi

    # Nhập tên hiển thị
    echo ""
    while [ -z "$FULL_NAME" ]; do
        read -p "  Tên hiển thị (Họ và tên): " FULL_NAME
        if [ -z "$FULL_NAME" ]; then
            echo -e "  ${RED}✗${NC} Không được để trống"
        fi
    done

    # Nhập email
    echo ""
    while [[ ! "$USER_EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; do
        read -p "  Địa chỉ email: " USER_EMAIL
        if [[ ! "$USER_EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
            echo -e "  ${RED}✗${NC} Email không hợp lệ, vui lòng nhập lại!"
        fi
    done

    # Nhập mật khẩu (tùy chọn)
    echo ""
    read -s -p "  Mật khẩu email (để trống nếu không muốn lưu): " USER_PASSWORD
    echo ""
    
    if [ -n "$USER_PASSWORD" ]; then
        echo -e "  ${GREEN}✓${NC} Mật khẩu đã được nhập (sẽ lưu để tự động đăng nhập)"
    else
        echo -e "  ${YELLOW}⚠${NC} Mật khẩu để trống - sẽ yêu cầu nhập khi mở Thunderbird"
    fi

    # Hiển thị thông tin đã nhập
    echo -e "\n  ${GREEN}✓${NC} Thông tin đã nhập:"
    echo -e "    • Giao thức: ${SERVER_TYPE^^}"
    echo -e "    • Tên hiển thị: $FULL_NAME"
    echo -e "    • Email: $USER_EMAIL"
    echo -e "    • Mật khẩu: $([ -n "$USER_PASSWORD" ] && echo "Đã nhập" || echo "Chưa nhập")"
    echo ""
    
    read -p "  Xác nhận cấu hình? [Y/n]: " CONFIRM
    if [[ "$CONFIRM" =~ ^[Nn]$ ]]; then
        echo -e "  ${YELLOW}⚠${NC} Hủy bỏ cài đặt"
        exit 0
    fi
    echo ""
}

# ============================================
# HÀM TẠO PROFILE
# ============================================
create_profile() {
    echo -e "${BLUE}[3/5] Tạo profile Thunderbird...${NC}"
    
    # Xác định thư mục Thunderbird
    TB_BASE="$HOME/.thunderbird"
    if [ -d "$HOME/.var/app/org.mozilla.Thunderbird/.thunderbird" ]; then
        TB_BASE="$HOME/.var/app/org.mozilla.Thunderbird/.thunderbird"
        echo -e "  ${YELLOW}ℹ${NC} Sử dụng Thunderbird Snap version"
    fi

    mkdir -p "$TB_BASE"

    # Đóng Thunderbird nếu đang chạy
    pkill -x thunderbird 2>/dev/null || true
    sleep 1

    # Tạo profile mới
    PROFILE_NAME="bizfly_$(date +%s)"
    echo -e "  ${YELLOW}⏳${NC} Đang tạo profile mới..."
    
    # Xóa profile cũ nếu tồn tại
    find "$TB_BASE" -maxdepth 1 -type d -name "*.bizfly_*" -exec rm -rf {} \; 2>/dev/null || true
    
    # Tạo profile
    thunderbird -CreateProfile "$PROFILE_NAME" > /dev/null 2>&1
    sleep 2

    # Tìm đường dẫn profile
    PROFILE_PATH=$(find "$TB_BASE" -maxdepth 1 -type d -name "*.${PROFILE_NAME}" | head -n 1)
    
    if [ -z "$PROFILE_PATH" ]; then
        echo -e "  ${YELLOW}⚠${NC} Không tìm thấy profile, tạo thủ công..."
        PROFILE_PATH="$TB_BASE/${PROFILE_NAME}.default"
        mkdir -p "$PROFILE_PATH"
    fi
    
    echo -e "  ${GREEN}✓${NC} Profile đã tạo: $(basename "$PROFILE_PATH")"
    echo ""
}

# ============================================
# HÀM DEPLOY CẤU HÌNH
# ============================================
deploy_config() {
    echo -e "${BLUE}[4/5] Cấu hình email...${NC}"
    
    # Tạo file user.js
    echo -e "  ${YELLOW}⏳${NC} Đang tạo file cấu hình..."
    
    cat <<EOF > "$PROFILE_PATH/user.js"
// ============================================
// Thunderbird BizFly Auto-Configuration
// Generated: $(date '+%Y-%m-%d %H:%M:%S')
// ============================================

// ---- ACCOUNT MANAGEMENT ----
user_pref("mail.accountmanager.accounts", "account1");
user_pref("mail.accountmanager.defaultaccount", "account1");
user_pref("mail.accountmanager.locallyStoredAccounts", "account1");

// ---- ACCOUNT ----
user_pref("mail.account.account1.identities", "id1");
user_pref("mail.account.account1.server", "server1");

// ---- IDENTITY ----
user_pref("mail.identity.id1.fullName", "$FULL_NAME");
user_pref("mail.identity.id1.useremail", "$USER_EMAIL");
user_pref("mail.identity.id1.valid", true);
user_pref("mail.identity.id1.smtpServer", "smtp1");
user_pref("mail.identity.id1.reply_to", "$USER_EMAIL");

// ---- INCOMING SERVER ----
user_pref("mail.server.server1.type", "$SERVER_TYPE");
user_pref("mail.server.server1.hostname", "$IN_HOST");
user_pref("mail.server.server1.port", $IN_PORT);
user_pref("mail.server.server1.userName", "$USER_EMAIL");
user_pref("mail.server.server1.authMethod", 3);
user_pref("mail.server.server1.socketType", 3);
user_pref("mail.server.server1.name", "$USER_EMAIL");
user_pref("mail.server.server1.login_at_startup", true);
user_pref("mail.server.server1.check_new_mail", true);

// ---- SMTP SERVER ----
user_pref("mail.smtpservers", "smtp1");
user_pref("mail.smtp.defaultserver", "smtp1");
user_pref("mail.smtpserver.smtp1.hostname", "mail.bizflycloud.vn");
user_pref("mail.smtpserver.smtp1.port", 465);
user_pref("mail.smtpserver.smtp1.try_ssl", 3);
user_pref("mail.smtpserver.smtp1.authMethod", 3);
user_pref("mail.smtpserver.smtp1.username", "$USER_EMAIL");

// ---- BỎ QUA SETUP WIZARD ----
user_pref("mail.provider.${SERVER_TYPE}.${USER_EMAIL}.configured", true);
user_pref("mail.provider.${SERVER_TYPE}.${USER_EMAIL}.autoconfigured", true);
user_pref("mail.provider.${SERVER_TYPE}.${USER_EMAIL}.hostname", "$IN_HOST");
user_pref("mail.provider.${SERVER_TYPE}.${USER_EMAIL}.port", $IN_PORT);
user_pref("mail.provider.${SERVER_TYPE}.${USER_EMAIL}.socketType", 3);
user_pref("mail.provider.${SERVER_TYPE}.${USER_EMAIL}.authMethod", 3);
user_pref("mail.auto_config.${USER_EMAIL}.done", true);
user_pref("mail.auto_config.${USER_EMAIL}.success", true);

// ---- UI SETTINGS ----
user_pref("mail.startup.enabledMailCheckOnce", true);
user_pref("mail.openMessageBehavior.version", 1);
user_pref("mail.identity.id1.draft_autosave", true);
user_pref("mail.identity.id1.draft_autosave_interval", 30);
user_pref("mail.identity.id1.archive_enabled", true);

// ---- SECURITY ----
user_pref("privacy.trackingprotection.enabled", true);
user_pref("privacy.trackingprotection.emailtracking.enabled", true);
user_pref("mail.server.server1.secure_connection", 1);

// ---- PERFORMANCE ----
user_pref("mail.imap.use_literal_plus", true);
user_pref("mail.imap.use_status_for_biff", true);
user_pref("mail.server.server1.max_cached_connections", 5);

// ---- DISABLE AUTO-CONFIG POPUP ----
user_pref("mail.auto_config.${USER_EMAIL}.url", "");
user_pref("mail.auto_config.${USER_EMAIL}.error", "");
EOF

    # Lưu mật khẩu nếu có
    if [ -n "$USER_PASSWORD" ]; then
        echo -e "  ${YELLOW}⏳${NC} Đang lưu mật khẩu..."
        
        cat <<EOF > "$PROFILE_PATH/logins.json"
{
  "logins": [
    {
      "id": 1,
      "hostname": "mail.bizflycloud.vn",
      "httpRealm": null,
      "formSubmitURL": null,
      "usernameField": "",
      "passwordField": "",
      "encryptedUsername": "",
      "encryptedPassword": "",
      "username": "$USER_EMAIL",
      "password": "$USER_PASSWORD",
      "timesUsed": 0
    }
  ],
  "disabledHosts": [],
  "version": 3
}
EOF
        echo -e "  ${GREEN}✓${NC} Mật khẩu đã được lưu"
    fi

    # Cập nhật profiles.ini
    cat <<EOF > "$TB_BASE/profiles.ini"
[General]
StartWithLastProfile=1
Version=2

[Profile0]
Name=$PROFILE_NAME
IsRelative=1
Path=$(basename "$PROFILE_PATH")
Default=1

[Install]
Default=Profiles/$PROFILE_NAME
EOF

    # Copy cho Snap nếu cần
    if [ -d "$HOME/.var/app/org.mozilla.Thunderbird/.thunderbird" ]; then
        cp "$TB_BASE/profiles.ini" "$TB_BASE/../profiles.ini" 2>/dev/null || true
    fi

    echo -e "  ${GREEN}✓${NC} Cấu hình đã hoàn tất"
    echo ""
}

# ============================================
# HÀM HOÀN TẤT
# ============================================
finish() {
    echo -e "${BLUE}[5/5] Hoàn tất cài đặt${NC}"
    
    echo -e "\n  ${GREEN}✅ CẤU HÌNH HOÀN TẤT!${NC}"
    echo -e "\n  📋 Thông tin cấu hình:"
    echo -e "    • Giao thức: ${SERVER_TYPE^^}"
    echo -e "    • Server đến: $IN_HOST:$IN_PORT"
    echo -e "    • Server đi: mail.bizflycloud.vn:465"
    echo -e "    • Email: $USER_EMAIL"
    echo -e "    • Profile: $PROFILE_NAME"
    
    if [ -n "$USER_PASSWORD" ]; then
        echo -e "    • Mật khẩu: ${GREEN}Đã lưu${NC} (tự động đăng nhập)"
    else
        echo -e "    • Mật khẩu: ${YELLOW}Chưa lưu${NC} (nhập khi mở Thunderbird)"
    fi

    echo -e "\n  ${YELLOW}ℹ${NC} Lưu ý:"
    echo -e "    • Thunderbird sẽ KHÔNG hiện màn hình Setup Wizard"
    echo -e "    • Tất cả cấu hình đã được áp dụng tự động"
    
    echo -e "\n  ${GREEN}▶${NC} Đang mở Thunderbird..."
    sleep 2
    
    # Khởi động Thunderbird
    nohup thunderbird -P "$PROFILE_NAME" > /dev/null 2>&1 &
    disown
    
    echo -e "\n  ${GREEN}✓${NC} Thunderbird đã được mở với profile: $PROFILE_NAME"
    echo -e "  ${GREEN}✓${NC} Email đã được cấu hình sẵn!"
    echo -e "\n${BLUE}=========================================================${NC}\n"
}

# ============================================
# MAIN
# ============================================
main() {
    check_environment
    get_user_input
    create_profile
    deploy_config
    finish
}

# Chạy script
main

exit 0
