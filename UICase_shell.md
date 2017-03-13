# 安装配置

1. 安装android sdk ,不赘述。
2. 安装[xmlstarlet](https://github.com/fishjam/xmlstarlet)

下载地址：[http://xmlstar.sourceforge.net/](http://xmlstar.sourceforge.net/)

下载zip包，解压后，进入目录

~~~shell
sudo ./configure
sudo make
sudo make install
~~~

xmlstarlet用法可参考：[https://www.ibm.com/developerworks/cn/xml/x-starlet.html#resources](https://www.ibm.com/developerworks/cn/xml/x-starlet.html#resources)

# 原理

基于adb adb shell uiautomator dump页面，找到待操作页面元素，并利用正则匹配找到元素坐标，进行操作。

# 实现

1. 对常见的控件操作方式进行封装，简化编写case的复杂度。
2. 脱离appium等测试框架，减少环境维护成本以及搭建环境的成本，避免appium自身的不稳定性，只要电脑安装android sdk 即可使用

## 方法封装

#### check_elements_by

 元素验证，参数1：元素类型  参数2：元素名称

支持 与或非 逻辑运算

A: 预期控件A存在；

!A: 预期控件A不存在；

A|B: 预期控件A或控件B至少存在一个；

A&B: 预期控件A和控件B同时存在；

A&!B: 预期控件A存在，但控件B不存在；

!A&!B: 预期控件A和控件B都不存在

~~~shell
check_elements_by "text" '二手物品&二手车'
check_elements_by "text" "二手物品"
~~~

#### scroll_to_element_native

滑动页面

两种情况：web页面dump整个页面，native页面只dump当前屏的元素

native情况

三个参数

参数一：滑动方向："up"、"down"

参数二：定位元素类型："text"、"content-desc"、"id"

参数三：定位的元素

~~~shell
scroll_to_element_native "up" "text" "违章查询"
~~~

#### scroll_to_element_web

滑动页面

两种情况：web页面dump整个页面，native页面只dump当前屏的元素

web情况

两个参数

参数一：定位元素类型："text"、"content-desc"、"id"

参数二：定位的元素

#### send_text

输入文字

参数一：定位元素类型："text"、"content-desc"、"id"

参数二：待输入文字的元素

参数三：要输入的文字

~~~shell
send_text "text" "找工作 找房子 找服务" "租房"
~~~

输入中文问题解决考：[http://blog.csdn.net/slimboy123/article/details/54140029](http://blog.csdn.net/slimboy123/article/details/54140029)

#### back

返回

无参数

#### is_exist  

判断页面是否存在某元素

两个参数：参数1：元素类型  参数2：元素名称

返回0代表无验证元素，返回1代表存在验证元素

#### sleep_and_dumpwindow

等待几秒，并dump页面元素

一个参数：等待的时间，单位s

与is_exist一起用于处理页面弹框

## 有弹框case示例

​    ![QQ20170310-0@2x](/Users/wuxian/Downloads/QQ20170310-0@2x.png)

如上图所示，对于有弹框的页面，先等待页面加载几秒，再判断页面是否存在弹框元素，点掉弹框。利用方法：sleep_and_dumpwindow、is_exist。case编写示例如下：

~~~shell
echo "运行脚本："$(basename $0)
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
~~~

## case示例

~~~shell
echo "运行脚本："$(basename $0)
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
~~~







