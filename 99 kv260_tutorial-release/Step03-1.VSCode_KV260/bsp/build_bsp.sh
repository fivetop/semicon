#!/bin/bash

source /tools/Xilinx/Vitis/2021.2/settings64.sh

XSCT="/tools/Xilinx/Vitis/2021.2/bin/xsct"
XSA_PATH="/home/woody/SoGang/2026-03/kv260_vivado_tutorial/Step03-1.VSCode_KV260/image/gpio_led_rtl.xsa"
BSP_DIR="/home/woody/SoGang/2026-03/kv260_vivado_tutorial/Step03-1.VSCode_KV260/bsp"
BSP_NAME="psu_cortexa53_0"
TEMP_DIR="$BSP_DIR/${BSP_NAME}_temp"

echo "=== XSCT BSP Generation ==="
echo "XSA: $XSA_PATH"
echo "Output: $BSP_DIR/$BSP_NAME"
echo ""

cd $BSP_DIR
rm -rf $BSP_NAME $TEMP_DIR

$XSCT -interactive << 'EOF'

hsi open_hw_design /home/woody/SoGang/2026-03/kv260_vivado_tutorial/Step03-1.VSCode_KV260/image/gpio_led_rtl.xsa

hsi create_sw_design -os standalone -proc psu_cortexa53_0 psu_cortexa53_0

hsi generate_target -dir /home/woody/SoGang/2026-03/kv260_vivado_tutorial/Step03-1.VSCode_KV260/bsp/psu_cortexa53_0_temp -compile bsp

exit

EOF

if [ -d "$TEMP_DIR" ]; then
    if [ -d "$TEMP_DIR/psu_cortexa53_0" ]; then
        mv $TEMP_DIR/psu_cortexa53_0/* $TEMP_DIR/
        rmdir $TEMP_DIR/psu_cortexa53_0
    fi
    mv $TEMP_DIR $BSP_DIR/$BSP_NAME
    echo ""
    echo "=== Directory structure fixed ==="
fi

echo ""
echo "=== Done! ==="
ls -la $BSP_DIR/$BSP_NAME/lib/libxil.a