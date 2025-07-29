#!/system/bin/sh

# === [1] Kiểm tra quyền root ===
[ "$(id -u)" -ne 0 ] && echo "❌ Vui lòng chạy script với quyền root!" && exit 1

# === [2] Cấu hình cơ bản ===
APP="com.garena.game.kgvn"
TMP="/data/local/tmp"
DIR="Meow"
BOT_TOKEN="7788263103:AAE0bzNSwiwS-yIzaS53heFha-psGLbPmuY"
CHAT_ID="8081396229"

# === [3] Xóa log đầu ===
clear



# === [5] Xác định kiến trúc CPU (ABI) ===
ABI=$(dumpsys package "$APP" | grep primaryCpuAbi | cut -d= -f2 | tr -d ' ')
[ "$ABI" != "arm64-v8a" ] && [ "$ABI" != "armeabi-v7a" ] && {
    echo "❌ Không hỗ trợ kiến trúc CPU: $ABI"
    exit 1
}

# === [6] Đường dẫn file loader và .so ===
J="$DIR/$ABI/loader"
L="$DIR/$ABI/libmainn.so"

# === [7] Kiểm tra file tồn tại ===
[ ! -f "$J" ] && echo "❌ Thiếu file loader: $J" && exit 1
[ ! -f "$L" ] && echo "❌ Thiếu file libmainn.so: $L" && exit 1

# === [8] Thông tin thiết bị ===
BRAND=$(getprop ro.product.brand)
MODEL=$(getprop ro.product.model)
ANDROID=$(getprop ro.build.version.release)
TIME=$(date "+%H:%M:%S %d/%m/%Y")
BRAND_UP=$(echo "$BRAND" | tr '[:lower:]' '[:upper:]')

# === [9] Gửi thông báo Telegram trước khi inject ===
MESSAGE=$(cat <<EOF
🚀 *Đã bắt đầu inject!*

📱 *Thiết bị:* $BRAND_UP $MODEL  
📦 *Android:* $ANDROID  
🎮 *Game:* Garena Liên Quân  
🕒 *Thời gian:* $TIME

🔄 Đang thực hiện inject...
EOF
)
curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
     -d chat_id="$CHAT_ID" \
     -d text="$MESSAGE" \
     -d parse_mode="Markdown" >/dev/null 2>&1 &

# === [10] Copy và cấp quyền loader & .so ===
cp -f "$J" "$TMP/loader" && chmod 777 "$TMP/loader"
cp -f "$L" "$TMP/libmainn.so" && chmod 777 "$TMP/libmainn.so"

# === [11] Inject vào game ===
echo "📦 Injecting vào package: $APP..."
su -c "$TMP/loader" -pkg "$APP" -lib "$TMP/libmainn.so" -dl_memfd -hide_maps -hide_solist

clear

# === [12] Dọn dẹp ===
rm -f "$TMP/loader" "$TMP/libmainn.so"

# === [13] Hiển thị lịch tháng với ngày hiện tại màu đỏ ===
DAY=$(date +%d)
echo -e "\n📅 \033[1mLỊCH THÁNG $(date +%m/%Y)\033[0m"
for d in $(seq 1 31); do
    if [ "$d" -eq "$DAY" ]; then
        printf " \033[1;41;97m%2d\033[0m" "$d"
    else
        printf " %2d" "$d"
    fi
    [ $((d % 7)) -eq 0 ] && echo
done
echo ""

# === [14] Đếm ngược khởi động game ===
echo -e "\n\n✅ Inject thành công, chuẩn bị mở game..."
for i in 3 2 1; do
    echo "⏳ Mở game sau... $i"
    sleep 1
done

# === [15] Gửi thông báo hoàn tất ===
MESSAGE_DONE=$(cat <<EOF
✅ *Inject hoàn tất!*

📱 *Thiết bị:* $BRAND_UP $MODEL  
📦 *Android:* $ANDROID  
🎮 *Game:* Garena Liên Quân  
🕒 *Thời gian:* $(date "+%H:%M:%S %d/%m/%Y")

🔥 *Game sẽ khởi động ngay bây giờ!*
EOF
)
curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
     -d chat_id="$CHAT_ID" \
     -d text="$MESSAGE_DONE" \
     -d parse_mode="Markdown" >/dev/null 2>&1 &

# === [16] Khởi động game ===
monkey -p "$APP" -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1

exit 0
.l