file_name=$(cd `dirname $0`; pwd)"/Method.sh"
source $file_name

check_elements_by "text" '二手物品'
click_element_by "text" '二手车'
check_elements_by 'content-desc' "大众 Link"
click_element_by 'content-desc' '大众 Link'
check_elements_by "id" "com.wuba.car:id/list_item_title"
click_element_by "id" "com.wuba.car:id/list_item_title"
check_elements_by "text" "查看新车报价"
click_element_by "text" "交谈"
check_elements_by "text" "你好，在吗?"
back
back
