echo "运行脚本：$(basename $0)" 
file_name=$(cd `dirname $0`; pwd)"/Method.sh"
source $file_name

check_elements_by "text" '二手物品'
send_text "text" "找工作 找房子 找服务" "租房"
check_elements_by "text" "搜索"
click_element_by "text" "搜索"
check_elements_by "id" "com.wuba.house:id/new_version_title"
click_element_by "id" "com.wuba.house:id/new_version_title"

sleep_and_dumpwindow 3  ##先设定等待几秒，并dump页面
##判断是否存在弹框
if [[ `is_exist 'text' '租房骗子们都说'` -eq 1 ]]; then
	click_element_by "text" "我知道了"
fi

check_elements_by "text" "签约前切勿支付【订金、租金、押金】等一切费用！"
back
back
back