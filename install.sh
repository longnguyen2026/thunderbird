#!/bin/bash
set -e

# Tự động bắt TTY nếu script được gọi qua luồng pipe curl | bash
if [ ! -t 0 ]; then
    TMP_SCRIPT=$(mktemp /tmp/tb_install.XXXXXX.sh)
    cat > "$TMP_SCRIPT"
    exec bash "$TMP_SCRIPT" "$@" < /dev/tty
    rm -f "$TMP_SCRIPT"
    exit 0
fi

# Xác định vị trí lưu file script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Load các hàm xử lý từ functions.sh
if [ -f "$SCRIPT_DIR/functions.sh" ]; then
    source "$SCRIPT_DIR/functions.sh"
else
    echo "❌ Lỗi: Không tìm thấy file functions.sh cùng thư mục!"
    exit 1
fi

# Clear màn hình và in Banner
clear
echo "========================================================="
echo "          THUNDERBIRD BIZFLY INSTALLER v9.0"
echo "========================================================="

# Thực thi các bước cấu hình
check_environment
get_user_input
deploy_profile
launch_thunderbird

echo -e "\n========================================================="
echo "✅ ĐÃ HOÀN TẤT. Nhập mật khẩu trên bảng Thunderbird để dùng!"
echo "========================================================="
