file_name=$(cd `dirname $0`; pwd)"/Method.sh"
source $file_name

check_elements_by "text" '二手物品'
send_text "text" "找工作 找房子 找服务" "租房"
check_elements_by "text" "搜索"
click_element_by "text" "搜索"
check_elements_by "id" "com.wuba.house:id/new_version_title"
click_element_by "id" "com.wuba.house:id/new_version_title"
check_elements_by "text" "签约前切勿支付【订金、租金、押金】等一切费用！"
back
back
back