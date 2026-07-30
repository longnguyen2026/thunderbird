#!/bin/bash
set -e

# Script: Thunderbird BizFly Installer
# Version: 2.0
# Description: Tự động cấu hình Thunderbird cho email BizFly

# Màu sắc cho terminal
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Biến toàn cục
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TB_BASE="$HOME/.thunderbird"
PROFILE_NAME="bizfly"
CONFIG_DIR="$SCRIPT_DIR/config"

# Hàm hiển thị banner
show_banner() {
    clear
    echo -e "${BLUE}=========================================================${NC}"
    echo -e "${BLUE}          THUNDERBIRD BIZFLY INSTALLER${NC}"
    echo -e "${BLUE}                  Version 2.0${NC}"
    echo -e "${BLUE}=========================================================${NC}"
    echo -e "${YELLOW}  Tự động cấu hình email BizFly trên Thunderbird${NC}"
    echo -e "${BLUE}=========================================================${NC}\n"
}

# Hàm kiểm tra môi trường
check_environment() {
    echo -e "${BLUE}[1/5] Kiểm tra môi trường...${NC}"
    
    # Kiểm tra Thunderbird
    if command -v thunderbird &> /dev/null; then
        echo -e "  ${GREEN}✓${NC} Thunderbird: Đã cài đặt"
        TB_VERSION=$(thunderbird --version 2>/dev/null | head -n1 || echo "Unknown")
        echo -e "  ${GREEN}✓${NC} Phiên bản: $TB_VERSION"
    else
        echo -e "  ${YELLOW}⚠${NC} Thunderbird: Chưa cài đặt"
        echo -e "  ${YELLOW}⏳${NC} Đang cài đặt Thunderbird..."
        sudo apt update -qq
        sudo apt install -y thunderbird > /dev/null 2>&1
        echo -e "  ${GREEN}✓${NC} Thunderbird: Đã cài đặt xong"
    fi

    # Kiểm tra kết nối Internet
    if ping -c 1 -W 2 mail.bizflycloud.vn &> /dev/null; then
        echo -e "  ${GREEN}✓${NC} Internet: Kết nối OK"
    else
        echo -e "  ${RED}✗${NC} Internet: Không có kết nối"
        echo -e "  ${RED}✗${NC} Vui lòng kiểm tra kết nối mạng và thử lại"
        exit 1
    fi
    echo ""
}

# Hàm nhập thông tin người dùng
get_user_input() {
    echo -e "${BLUE}[2/5] Nhập thông tin cấu hình${NC}"
    
    # Chọn giao thức
    echo -e "\n  Chọn giao thức email:"
    echo -e "    ${GREEN}1${NC}. IMAP ${GREEN}(Khuyến nghị)${NC} - Đồng bộ tất cả thiết bị"
    echo -e "    ${YELLOW}2${NC}. POP3 - Tải email về máy tính"
    echo ""
    read -p "  Nhập lựa chọn [1/2] (Mặc định: 1): " PROTO_CHOICE
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
            echo -e "  ${RED}✗${NC} Vui lòng nhập tên hiển thị"
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

    # Hiển thị thông tin đã nhập
    echo -e "\n  ${GREEN}✓${NC} Thông tin đã nhập:"
    echo -e "    • Giao thức: ${SERVER_TYPE^^}"
    echo -e "    • Tên hiển thị: $FULL_NAME"
    echo -e "    • Email: $USER_EMAIL"
    echo ""
    
    read -p "  Xác nhận cấu hình? [Y/n]: " CONFIRM
    if [[ "$CONFIRM" =~ ^[Nn]$ ]]; then
        echo -e "  ${YELLOW}⚠${NC} Hủy bỏ cài đặt"
        exit 0
    fi
    echo ""
}

# Hàm tạo profile
create_profile() {
    echo -e "${BLUE}[3/5] Tạo profile Thunderbird...${NC}"
    
    # Tìm Thunderbird base directory (cho cả Snap và native)
    if [ -d "$HOME/.var/app/org.mozilla.Thunderbird/.thunderbird" ]; then
        TB_BASE="$HOME/.var/app/org.mozilla.Thunderbird/.thunderbird"
        echo -e "  ${YELLOW}ℹ${NC} Phát hiện Thunderbird (Snap version)"
    fi

    # Đảm bảo thư mục tồn tại
    mkdir -p "$TB_BASE"

    # Đóng Thunderbird nếu đang chạy
    pkill -x thunderbird 2>/dev/null || true
    sleep 1

    # Tạo profile mới
    echo -e "  ${YELLOW}⏳${NC} Đang tạo profile mới..."
    
    # Xóa profile cũ nếu tồn tại
    find "$TB_BASE" -maxdepth 1 -type d -name "*.${PROFILE_NAME}" -exec rm -rf {} \; 2>/dev/null || true
    
    # Tạo profile mới
    thunderbird -CreateProfile "$PROFILE_NAME" > /dev/null 2>&1
    
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

# Hàm deploy cấu hình
deploy_config() {
    echo -e "${BLUE}[4/5] Cấu hình email...${NC}"
    
    # Tạo file user.js từ template
    TEMPLATE_FILE="$CONFIG_DIR/user.js.template"
    
    if [ ! -f "$TEMPLATE_FILE" ]; then
        echo -e "  ${RED}✗${NC} Không tìm thấy file template: $TEMPLATE_FILE"
        echo -e "  ${YELLOW}ℹ${NC} Sử dụng cấu hình mặc định..."
        
        # Tạo user.js trực tiếp
        cat <<EOF > "$PROFILE_PATH/user.js"
// ============================================
// Thunderbird BizFly Configuration
// Generated: $(date)
// ============================================

// Account Management
user_pref("mail.accountmanager.accounts", "account1");
user_pref("mail.accountmanager.defaultaccount", "account1");
user_pref("mail.account.account1.identities", "id1");
user_pref("mail.account.account1.server", "server1");

// Identity
user_pref("mail.identity.id1.fullName", "$FULL_NAME");
user_pref("mail.identity.id1.useremail", "$USER_EMAIL");
user_pref("mail.identity.id1.valid", true);
user_pref("mail.identity.id1.smtpServer", "smtp1");

// Incoming Server
user_pref("mail.server.server1.authMethod", 3);
user_pref("mail.server.server1.hostname", "$IN_HOST");
user_pref("mail.server.server1.name", "$USER_EMAIL");
user_pref("mail.server.server1.port", $IN_PORT);
user_pref("mail.server.server1.socketType", 3);
user_pref("mail.server.server1.type", "$SERVER_TYPE");
user_pref("mail.server.server1.userName", "$USER_EMAIL");
user_pref("mail.server.server1.login_at_startup", true);
user_pref("mail.server.server1.check_new_mail", true);

// Outgoing Server (SMTP)
user_pref("mail.smtpservers", "smtp1");
user_pref("mail.smtp.defaultserver", "smtp1");
user_pref("mail.smtpserver.smtp1.authMethod", 3);
user_pref("mail.smtpserver.smtp1.hostname", "mail.bizflycloud.vn");
user_pref("mail.smtpserver.smtp1.port", 465);
user_pref("mail.smtpserver.smtp1.try_ssl", 3);
user_pref("mail.smtpserver.smtp1.username", "$USER_EMAIL");

// Security & Privacy
user_pref("privacy.trackingprotection.enabled", true);
user_pref("privacy.trackingprotection.emailtracking.enabled", true);
user_pref("mail.server.server1.secure_connection", 1);

// UI Settings
user_pref("mail.startup.enabledMailCheckOnce", true);
user_pref("mail.openMessageBehavior.version", 1);
user_pref("mail.identity.id1.archive_enabled", true);
user_pref("mail.identity.id1.drafts_folder_picker_mode", 0);
user_pref("mail.identity.id1.sent_folder_picker_mode", 0);
user_pref("mail.identity.id1.template_folder_picker_mode", 0);

// Performance
user_pref("mail.imap.use_literal_plus", true);
user_pref("mail.imap.use_status_for_biff", true);
EOF
    else
        # Sử dụng template
        echo -e "  ${YELLOW}⏳${NC} Đang tạo cấu hình từ template..."
        
        sed -e "s/{{FULL_NAME}}/$(echo "$FULL_NAME" | sed 's/[\/&]/\\&/g')/g" \
            -e "s/{{USER_EMAIL}}/$(echo "$USER_EMAIL" | sed 's/[\/&]/\\&/g')/g" \
            -e "s/{{SERVER_TYPE}}/$SERVER_TYPE/g" \
            -e "s/{{IN_HOST}}/$IN_HOST/g" \
            -e "s/{{IN_PORT}}/$IN_PORT/g" \
            "$TEMPLATE_FILE" > "$PROFILE_PATH/user.js"
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

    echo -e "  ${GREEN}✓${NC} Cấu hình đã được tạo: $PROFILE_PATH/user.js"
    echo ""
}

# Hàm hoàn tất
finish() {
    echo -e "${BLUE}[5/5] Hoàn tất cài đặt${NC}"
    
    # Backup cấu hình cũ (nếu có)
    if [ -f "$PROFILE_PATH/user.js.bak" ]; then
        rm -f "$PROFILE_PATH/user.js.bak"
    fi
    
    echo -e "\n  ${GREEN}✓${NC} Cấu hình email đã hoàn tất!"
    echo -e "\n  ${BLUE}Thông tin cấu hình:${NC}"
    echo -e "    • Giao thức: ${SERVER_TYPE^^}"
    echo -e "    • Server đến: $IN_HOST:$IN_PORT (SSL/TLS)"
    echo -e "    • Server đi: mail.bizflycloud.vn:465 (SSL/TLS)"
    echo -e "    • Email: $USER_EMAIL"
    
    echo -e "\n  ${YELLOW}⚠${NC} Lưu ý:"
    echo -e "    • Lần đầu mở Thunderbird sẽ yêu cầu nhập mật khẩu"
    echo -e "    • Có thể thay đổi cấu hình trong Settings"
    
    echo -e "\n  ${GREEN}▶${NC} Khởi động Thunderbird..."
    sleep 2
    
    # Mở Thunderbird
    nohup thunderbird > /dev/null 2>&1 &
    disown
    
    echo -e "\n  ${GREEN}✓${NC} Thunderbird đã được mở!"
    echo -e "  ${BLUE}=========================================================${NC}\n"
}

# ============================================
# MAIN
# ============================================

main() {
    show_banner
    check_environment
    get_user_input
    create_profile
    deploy_config
    finish
}

# Bắt đầu script
main

exit 0
