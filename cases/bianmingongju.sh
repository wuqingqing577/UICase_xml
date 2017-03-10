echo "运行脚本：$(basename $0)" 
file_name=$(cd `dirname $0`; pwd)"/Method.sh"
source $file_name

check_elements_by "text" '二手物品'
scroll_to_element_native "up" "text" "违章查询"
check_elements_by "text" " 便民工具"
click_element_by "text" "违章查询"
check_elements_by "content-desc" "查询地区&车牌号码"
back