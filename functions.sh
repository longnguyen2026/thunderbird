#!/bin/bash

# ============================================
# Thunderbird BizFly Installer - Functions
# Version: 2.0
# ============================================

# Màu sắc
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# Biến toàn cục
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR/config"
TB_BASE="$HOME/.thunderbird"
PROFILE_NAME="bizfly"

# ============================================
# Kiểm tra môi trường
# ============================================
check_environment() {
    echo -e "${BLUE}📦 Kiểm tra môi trường...${NC}"
    
    # Kiểm tra Thunderbird
    if command -v thunderbird &> /dev/null; then
        echo -e "  ${GREEN}✓${NC} Thunderbird: Đã cài đặt"
        TB_VERSION=$(thunderbird --version 2>/dev/null | grep -oP '[\d.]+' | head -n1)
        echo -e "  ${GREEN}✓${NC} Phiên bản: $TB_VERSION"
    else
        echo -e "  ${YELLOW}⚠${NC} Thunderbird chưa cài đặt, đang tiến hành cài đặt..."
        sudo apt update -qq && sudo apt install -y thunderbird > /dev/null 2>&1
        echo -e "  ${GREEN}✓${NC} Thunderbird đã được cài đặt"
    fi

    # Kiểm tra kết nối Internet
    if ping -c 1 -W 2 mail.bizflycloud.vn &> /dev/null; then
        echo -e "  ${GREEN}✓${NC} Kết nối Internet: OK"
    else
        echo -e "  ${RED}✗${NC} Không có kết nối Internet"
        echo -e "  ${RED}✗${NC} Vui lòng kiểm tra mạng và thử lại"
        exit 1
    fi
    echo ""
}

# ============================================
# Thu thập thông tin người dùng
# ============================================
get_user_input() {
    echo -e "${BLUE}📝 Nhập thông tin cấu hình${NC}"
    
    # Chọn giao thức
    echo -e "\n  Chọn giao thức email:"
    echo -e "    ${GREEN}1${NC}. IMAP ${GREEN}(Khuyến nghị)${NC}"
    echo -e "    ${YELLOW}2${NC}. POP3"
    echo -e "  ${YELLOW}ℹ${NC}  IMAP đồng bộ giữa các thiết bị, POP3 tải về máy"
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

    # Nhập tên hiển thị
    echo ""
    while [ -z "$FULL_NAME" ]; do
        read -p "  Tên hiển thị (Họ và tên): " FULL_NAME
        [ -z "$FULL_NAME" ] && echo -e "  ${RED}✗${NC} Không được để trống"
    done

    # Nhập email
    echo ""
    while [[ ! "$USER_EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; do
        read -p "  Địa chỉ email: " USER_EMAIL
        [[ ! "$USER_EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]] && \
            echo -e "  ${RED}✗${NC} Email không hợp lệ"
    done

    echo ""
    echo -e "  ${GREEN}✓${NC} Thông tin đã nhập:"
    echo -e "    • Giao thức: ${SERVER_TYPE^^}"
    echo -e "    • Tên: $FULL_NAME"
    echo -e "    • Email: $USER_EMAIL"
    echo ""
}

# ============================================
# Khởi tạo profile
# ============================================
init_profile() {
    echo -e "${BLUE}📁 Tạo profile...${NC}"
    
    # Xác định Thunderbird base
    if [ -d "$HOME/.var/app/org.mozilla.Thunderbird/.thunderbird" ]; then
        TB_BASE="$HOME/.var/app/org.mozilla.Thunderbird/.thunderbird"
        echo -e "  ${YELLOW}ℹ${NC} Sử dụng Thunderbird Snap"
    fi

    mkdir -p "$TB_BASE"
    
    # Đóng Thunderbird
    pkill -x thunderbird 2>/dev/null || true
    sleep 1

    # Xóa profile cũ
    find "$TB_BASE" -maxdepth 1 -type d -name "*.${PROFILE_NAME}" -exec rm -rf {} \; 2>/dev/null || true
    
    # Tạo profile mới
    thunderbird -CreateProfile "$PROFILE_NAME" > /dev/null 2>&1
    
    # Lấy đường dẫn profile
    PROFILE_PATH=$(find "$TB_BASE" -maxdepth 1 -type d -name "*.${PROFILE_NAME}" | head -n 1)
    
    if [ -z "$PROFILE_PATH" ]; then
        echo -e "  ${YELLOW}⚠${NC} Tạo profile thủ công..."
        PROFILE_PATH="$TB_BASE/${PROFILE_NAME}.default"
        mkdir -p "$PROFILE_PATH"
    fi
    
    echo -e "  ${GREEN}✓${NC} Profile: $(basename "$PROFILE_PATH")"
    echo ""
}

# ============================================
# Deploy cấu hình
# ============================================
deploy_config() {
    echo -e "${BLUE}⚙️  Cấu hình email...${NC}"
    
    TEMPLATE_FILE="$CONFIG_DIR/user.js.template"
    
    # Tạo user.js
    if [ -f "$TEMPLATE_FILE" ]; then
        echo -e "  ${YELLOW}⏳${NC} Đang tạo cấu hình từ template..."
        
        sed -e "s/{{FULL_NAME}}/$(echo "$FULL_NAME" | sed 's/[\/&]/\\&/g')/g" \
            -e "s/{{USER_EMAIL}}/$(echo "$USER_EMAIL" | sed 's/[\/&]/\\&/g')/g" \
            -e "s/{{SERVER_TYPE}}/$SERVER_TYPE/g" \
            -e "s/{{IN_HOST}}/$IN_HOST/g" \
            -e "s/{{IN_PORT}}/$IN_PORT/g" \
            "$TEMPLATE_FILE" > "$PROFILE_PATH/user.js"
    else
        echo -e "  ${YELLOW}⚠${NC} Không tìm thấy template, sử dụng cấu hình mặc định"
        generate_default_config
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

    echo -e "  ${GREEN}✓${NC} Cấu hình đã được tạo"
    echo ""
}

# ============================================
# Tạo cấu hình mặc định
# ============================================
generate_default_config() {
    cat <<EOF > "$PROFILE_PATH/user.js"
// ============================================
// Thunderbird BizFly Configuration
// Generated: $(date '+%Y-%m-%d %H:%M:%S')
// ============================================

// --- Account Settings ---
user_pref("mail.accountmanager.accounts", "account1");
user_pref("mail.accountmanager.defaultaccount", "account1");
user_pref("mail.account.account1.identities", "id1");
user_pref("mail.account.account1.server", "server1");

// --- Identity ---
user_pref("mail.identity.id1.fullName", "$FULL_NAME");
user_pref("mail.identity.id1.useremail", "$USER_EMAIL");
user_pref("mail.identity.id1.valid", true);
user_pref("mail.identity.id1.smtpServer", "smtp1");

// --- Incoming Server ---
user_pref("mail.server.server1.authMethod", 3);
user_pref("mail.server.server1.hostname", "$IN_HOST");
user_pref("mail.server.server1.name", "$USER_EMAIL");
user_pref("mail.server.server1.port", $IN_PORT);
user_pref("mail.server.server1.socketType", 3);
user_pref("mail.server.server1.type", "$SERVER_TYPE");
user_pref("mail.server.server1.userName", "$USER_EMAIL");
user_pref("mail.server.server1.login_at_startup", true);
user_pref("mail.server.server1.check_new_mail", true);

// --- SMTP Server ---
user_pref("mail.smtpservers", "smtp1");
user_pref("mail.smtp.defaultserver", "smtp1");
user_pref("mail.smtpserver.smtp1.authMethod", 3);
user_pref("mail.smtpserver.smtp1.hostname", "mail.bizflycloud.vn");
user_pref("mail.smtpserver.smtp1.port", 465);
user_pref("mail.smtpserver.smtp1.try_ssl", 3);
user_pref("mail.smtpserver.smtp1.username", "$USER_EMAIL");

// --- Security ---
user_pref("privacy.trackingprotection.enabled", true);
user_pref("privacy.trackingprotection.emailtracking.enabled", true);
user_pref("mail.server.server1.secure_connection", 1);

// --- UI ---
user_pref("mail.startup.enabledMailCheckOnce", true);
user_pref("mail.openMessageBehavior.version", 1);
user_pref("mail.identity.id1.archive_enabled", true);

// --- Performance ---
user_pref("mail.imap.use_literal_plus", true);
user_pref("mail.imap.use_status_for_biff", true);
EOF
}

# ============================================
# Hoàn tất và khởi động
# ============================================
finish_installation() {
    echo -e "${BLUE}✅ Hoàn tất cài đặt${NC}"
    
    echo -e "\n  ${GREEN}✓${NC} Cấu hình đã được áp dụng thành công!"
    echo -e "\n  ${BLUE}📋 Thông tin cấu hình:${NC}"
    echo -e "    • Giao thức: ${SERVER_TYPE^^}"
    echo -e "    • Server đến: $IN_HOST:$IN_PORT"
    echo -e "    • Server đi: mail.bizflycloud.vn:465"
    echo -e "    • Email: $USER_EMAIL"
    echo -e "    • Profile: $PROFILE_NAME"
    
    echo -e "\n  ${YELLOW}ℹ${NC} Lưu ý:"
    echo -e "    • Nhập mật khẩu khi Thunderbird yêu cầu"
    echo -e "    • Có thể thay đổi cấu hình trong Settings"
    
    echo -e "\n  ${GREEN}▶${NC} Đang khởi động Thunderbird..."
    sleep 2
    
    nohup thunderbird > /dev/null 2>&1 &
    disown
    
    echo -e "\n  ${GREEN}✓${NC} Hoàn tất! Thunderbird đã được mở."
    echo -e "${BLUE}=========================================================${NC}\n"
}

# ============================================
# Export functions
# ============================================
export -f check_environment
export -f get_user_input
export -f init_profile
export -f deploy_config
export -f finish_installation
