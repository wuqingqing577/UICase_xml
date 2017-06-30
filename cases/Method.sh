file_location=$(cd `dirname $0`; pwd)
#工程UICase_Shell绝对路径
pre_file_location=${file_location%/*}
#log文件夹绝对路径
log_location="${pre_file_location}/log"
#window_dump.xml绝对路径
dump_name="${file_location}/window_dump.xml"  

time1=$(date +%Y-%m-%d_%H-%M-%S)
#日志文件路径
log_name="${log_location}/${time1}.log"



devices=`adb devices | grep device$ | awk '{print $1}'`
echo "运行设备：$devices" 
size_cmd=`adb shell wm size | awk '{print $3}' | tr -d "\r"`
window_height=${size_cmd#*x}
window_width=${size_cmd%x*}
total=10   ###页面响应耗时小于10s#######可设置



adb -s $devices shell am force-stop com.wuba
sleep 2
echo "启动app首页" 
adb -s $devices shell am start -n com.wuba/.home.activity.HomeActivity
sleep 5

grep_bounds='bounds="\[[[:digit:]]{1,4},[[:digit:]]{1,4}]\[[[:digit:]]{1,4},[[:digit:]]{1,4}]"'
grep_location='\[[0-9]\{1,\},[0-9]\{1,\}]\[[0-9]\{1,\},[0-9]\{1,\}\]'


dump_window(){

    # res1=`adb shell uiautomator dump`
    # res2=`adb pull /sdcard/window_dump.xml ./`
    adb shell uiautomator dump
    adb pull /sdcard/window_dump.xml $file_location
}

sleep_and_dumpwindow(){
    
    wait_time=$1
    sleep $wait_time
    adb shell uiautomator dump
    adb pull /sdcard/window_dump.xml $file_location
}

screencap_error(){
    pic_time=$(date +%Y-%m-%d_%H-%M-%S)
    picture_name="/sdcard/${pic_time}.png"
    adb shell screencap -p $picture_name
    sleep 1
    adb pull $picture_name $log_location
    sleep 1
    adb shell rm -f $picture_name
    echo "\033[33m错误信息截图路径： $log_location/$picture_name\033[0m"
}


#返回0代表无验证元素
#返回1代表存在验证元素
verify_element_bytext(){
    verify_element_text=$1
    element="xml sel -t -m \"//node[contains(@text,'$verify_element_text')]\" -c . $dump_name"
    if [[ ! -n `eval $element` ]];then
        echo 0;
    else
        echo 1;
    fi
}

verify_element_bydesc(){
    verify_element_desc=$1
    element="xml sel -t -m \"//node[contains(@content-desc,'$verify_element_desc')]\" -c . $dump_name"
    if [[ ! -n `eval $element` ]];then
        echo 0;
    else
        echo 1;
    fi
}

verify_element_byid(){
    verify_element_id=$1
    element="xml sel -t -m \"//node[contains(@resource-id,'$verify_element_id')]\" -c . $dump_name"
    if [[ ! -n `eval $element` ]];then
        echo 0;
    else
        echo 1;
    fi
}


##判断页面是否存在某元素
#两个参数：参数1：元素类型  参数2：元素名称
#返回0代表无验证元素
#返回1代表存在验证元素
is_exist(){
    exist_element_type=$1
    exist_verify_element=$2


    case $exist_element_type in
    "text" )
        is_exist_verify=`verify_element_bytext $exist_verify_element` ;;
    "content-desc" )
        is_exist_verify=`verify_element_bydesc $exist_verify_element` ;;
    "id" )
        is_exist_verify=`verify_element_byid $exist_verify_element` ;;
    esac
       
    if [[ $is_exist_verify -eq 1 ]]; then
        echo 1
    else
        echo 0
    fi

}

#页面不应该存在某元素
#两个参数：参数1：元素类型  参数2：元素名称
should_not_exist(){
    noexist_element_type=$1
    noexist_verify_element=$2

    i=0
    while [[ $i -lt $total ]]; do
       dump_window

        case $noexist_element_type in
        "text" )
           noexist_verify=`verify_element_bytext $noexist_verify_element` ;;
        "content-desc" )
           noexist_verify=`verify_element_bydesc $noexist_verify_element` ;;
        "id" )
           noexist_verify=`verify_element_byid $noexist_verify_element` ;;
        esac

       if [[ $noexist_verify -eq 1 ]]; then
            echo "\033[33m页面元素:$noexist_verify_element 仍然存在\033[0m"
            return 1       ##函数返回状态码
        else
          sleep 1
          let i+=1
        fi
    done

}

##等待直到出现XX元素,每1s查询一次
##单个元素验证
##两个参数：参数1：元素类型  参数2：元素名称
check_element_by(){
    check_element_type=$1
    check_verify_element=$2  ###去掉行首空格

    echo "\033[32m--验证元素：$check_verify_element \033[0m"

    if [[ ${check_verify_element:0:1} = '!' ]]; then
        check_verify_element=${check_verify_element#*!}  ##去掉开头的！
        should_not_exist $check_element_type $check_verify_element
    else
        i=0

        while [[ $i -lt $total ]]; do
           dump_window

           case $check_element_type in
           "text" )
              verify=`verify_element_bytext $check_verify_element` ;;
            "content-desc" )
              verify=`verify_element_bydesc $check_verify_element` ;;
            "id" )
              verify=`verify_element_byid $check_verify_element` ;;
            esac

            if [[ $verify -eq 0 ]]; then
               sleep 1
               let i+=1
            else
               break
            fi
        done

        if [[ $i -ge $total ]]; then
            echo "\033[33m页面待验证元素:$check_verify_element 查找超时\033[0m"
            return 1  ##返回错误码
        fi
    fi

}

##多个元素验证
##两个参数：参数1：元素类型  参数2：元素名称
check_elements_by(){
    check_elements_type=$1
    check_verify_elements=$2

    echo "\033[32m需验证页面元素：$check_verify_elements \033[0m"

    if [[ $check_verify_elements =~ "&" ]]; then

        IFS='&'
        arr=$check_verify_elements
        for element in ${arr[@]}; do
           element1=$element    
           check_element_by $check_elements_type $element1
           if [[ $? = 0 ]]; then
              echo "\033[31m页面元素:$check_verify_elements 验证失败 X\033[0m"
              screencap_error
              exit 1
           fi
        done

        echo "\033[32m页面元素:$check_verify_elements 验证成功\033[0m"
        return 0   ##验证成功

    elif [[ $check_verify_elements =~ "|" ]]; then
                
        IFS='|'
        arr=$check_verify_elements
        for element in ${arr[@]}; do
           element1=$element  
           check_element_by $check_elements_type $element1
           if [[ $? != 1 ]]; then
               echo "\033[32m页面元素:$check_verify_elements 验证成功\033[0m"
               return 0   ##验证成功
           fi
        done
                      
        echo "\033[31m页面元素:$check_verify_elements 验证失败 X\033[0m"
        screencap_error
        exit 1
    
    else    ##单个元素验证
        check_element_by $check_elements_type $check_verify_elements
        if [[ $? != 1 ]]; then
            echo "\033[32m页面元素:$check_verify_elements 验证成功\033[0m"
            return 0   ##验证成功
        else
            echo "\033[31m页面元素:$check_verify_elements 验证失败 X\033[0m"
            screencap_error
            exit 1
        fi

    fi
   
}


## 滑动页面
## 两种情况：web页面dump整个页面，native页面只dump当前屏的元素
## native情况
## 三个参数
## 参数一：滑动方向："up"、"down"
## 参数二：定位元素类型："text"、"content-desc"、"id"
## 参数三：定位的元素
scroll_to_element_native(){
  
    direction=$1
    scroll_native_element_type=$2
    scroll_native_verify_element=$3

    echo "\033[32mScroll $direction Until finding element : $scroll_native_verify_element\033[0m"

    case $scroll_native_element_type in
        "text" )
           scroll_native_jump_button="xml sel -t -m \"//node[contains(@text,'$scroll_native_verify_element')]\" -c . $dump_name" ;;
        "content-desc" )
           scroll_native_jump_button="xml sel -t -m \"//node[contains(@content-desc,'$scroll_native_verify_element')]\" -c . $dump_name" ;;
        "id" )
           scroll_native_jump_button="xml sel -t -m \"//node[contains(@resource-id,'$scroll_native_verify_element')]\" -c . $dump_name" ;;
    esac

    ##两种情况：web页面dump整个页面，native页面只dump当前屏的元素
    ##第一种情况，待查找元素不在当前dump内容内，循环向上滑动，dump，查找元素
    i=0
    case $direction in
        "up" )
           width_start=`expr $window_width / 2`
           width_end=`expr $window_width / 2`
           height_start=`expr $window_height / 2`
           height_end1=`expr $window_height / 2 - $window_height / 8`
           height_end2=`expr $window_height / 2 - $window_height / 6` ;;
        "down" )
           width_start=`expr $window_width / 2`
           width_end=`expr $window_width / 2`
           height_start=`expr $window_height / 2`
           height_end1=`expr $window_height / 2 + $window_height / 8`
           height_end2=`expr $window_height / 2 + $window_height / 6` ;;
        "left" )
            ;;
        "right" )
            ;;
    esac

    while [[ $i -lt $total ]]; do
        dump_window
        if [[ -n `eval $scroll_native_jump_button` ]];then
           adb shell input swipe $width_start $height_start $width_end $height_end1  ##微滑，为了让目标元素更中心一点
           break
        else
           adb shell input swipe $width_start $height_start $width_start $height_end2
        fi
    done    
 
}


##滑动页面
##两种情况：web页面dump整个页面，native页面只dump当前屏的元素
##web情况
##两个参数
##参数一：定位元素类型："text"、"content-desc"、"id"
##参数二：定位的元素
scroll_to_element_web(){

    scroll_web_element_type=$1
    scroll_web_verify_element=$2
    echo "\033[32mScroll  Until finding element : $scroll_web_verify_element\033[0m"

    case $scroll_web_element_type in
        "text" )
           scroll_web_jump_button="xml sel -t -m \"//node[contains(@text,'$scroll_web_verify_element')]\" -c . $dump_name" ;;
        "content-desc" )
           scroll_web_jump_button="xml sel -t -m \"//node[contains(@content-desc,'$scroll_web_verify_element')]\" -c . $dump_name" ;;
        "id" )
           scroll_web_jump_button="xml sel -t -m \"//node[contains(@resource-id,'$scroll_web_verify_element')]\" -c . $dump_name" ;;
    esac
    
    i=0
    dump_window
    if [[ -n `eval $scroll_web_jump_button` ]]; then
        
        while [[ $i -lt $total ]]; do
            dump_window
            scroll_web_button_location=`eval $scroll_web_jump_button | egrep -o $grep_bounds | grep -o $grep_location `
            scroll_web_button_location0=`echo $scroll_web_button_location | awk '{print $1}'`
            start=${scroll_web_button_location0#[}
            start=${start%][*}
            end=${scroll_web_button_location0#*][}
            end=${end%]*}
            ##元素的x坐标范围
            x0=${start%\,*} 
            x1=${end%\,*} 
            ##元素的y坐标范围
            y0=${start#*\,}
            y1=${end#*\,}
         
            if [[ $x0 -gt 0 && $x1 -lt $window_width && $y0 -gt 0 && $y1 -lt window_height ]]; then
                break
            fi
            
            ##下滑
            if [[ $y0 -le 0 ]]; then
                width_start=`expr $window_width / 2`
                width_end=`expr $window_width / 2`
                height_start=`expr $window_height / 2`
                height_end=`expr $window_height / 2 + $window_height / 6`
                adb shell input swipe $width_start $height_start $width_end $height_end ##下滑
            fi
            
            ##上滑
            if [[ $y1 -ge $window_height ]]; then
                width_start=`expr $window_width / 2`
                width_end=`expr $window_width / 2`
                height_start=`expr $window_height / 2`
                height_end=`expr $window_height / 2 - $window_height / 6`
                adb shell input swipe $width_start $height_start $width_end $height_end ##下滑
            fi
            let i+=1

        done


    else
        echo "\033[31m页面不存在元素:$scroll_web_verify_element X\033[0m"
        screencap_error
        exit 1
        
    fi

    

}

##点击页面元素
##参数一：定位元素类型："text"、"content-desc"、"id"
##参数二：待点击的元素
click_element_by(){
     
    click_element_type=$1
    click_jump_element=$2
    echo "\033[32mClick elemnet : $click_jump_element \033[0m"

    case $click_element_type in
        "text" )
           click_jump_button="xml sel -t -m \"//node[contains(@text,'$click_jump_element')]\" -c . $dump_name" ;;
        "content-desc" )
           click_jump_button="xml sel -t -m \"//node[contains(@content-desc,'$click_jump_element')]\" -c . $dump_name" ;;
        "id" )
           click_jump_button="xml sel -t -m \"//node[contains(@resource-id,'$click_jump_element')]\" -c . $dump_name" ;;
    esac

    if [[ -n `eval $click_jump_button` ]];then
    click_button_location0=`eval $click_jump_button | egrep -o $grep_bounds | grep -o $grep_location `
    # click_button_location0=`echo $click_button_location | awk '{print $1}'`
    echo "控件位置：$click_button_location0"
    start0=${click_button_location0#[}
    start=${start0%%][*}
    end0=${click_button_location0#*][}
    end=${end0%%]*}
    x=`expr ${start%\,*} + ${end%\,*} `
    y=`expr ${start#*\,} + ${end#*\,} `
    x=`expr $x / 2`
    y=`expr $y / 2`
    echo "点击页面坐标：($x,$y)"
    adb shell input tap $x $y
    else
        echo "\033[31m待点击元素:$click_jump_element 不存在 X\033[0m"
        screencap_error
        exit 1

    fi

}


##输入文字
##参数一：定位元素类型："text"、"content-desc"、"id"
##参数二：待输入文字的元素
##参数三：要输入的文字
send_text(){
    
    send_element_type=$1
    send_jump_element=$2
    send_text=$3
    echo "\033[32m在 $send_jump_element 中输入：$send_text \033[0m"

    case $send_element_type in
        "text" )
           send_jump_button="xml sel -t -m \"//node[contains(@text,'$send_jump_element')]\" -c . $dump_name" ;;
        "content-desc" )
           send_jump_button="xml sel -t -m \"//node[contains(@content-desc,'$send_jump_element')]\" -c . $dump_name" ;;
        "id" )
           send_jump_button="xml sel -t -m \"//node[contains(@resource-id,'$send_jump_element')]\" -c . $dump_name" ;;

    esac

    if [[ -n `eval $send_jump_button` ]];then
    send_button_location0=`eval $send_jump_button | egrep -o $grep_bounds | grep -o $grep_location `
    # send_button_location0=`echo $send_button_location | awk '{print $1}'`
    start=${send_button_location0#[}
    start=${start%%][*}
    end=${send_button_location0#*][}
    end=${end%%]*}
    x=`expr ${start%\,*} + ${end%\,*} `
    y=`expr ${start#*\,} + ${end#*\,} `
    x=`expr $x / 2`
    y=`expr $y / 2`
    adb shell input tap $x $y
    adb shell am broadcast -a ADB_INPUT_TEXT --es msg $send_text
    else
        echo "\033[31m页面待键入内容元素:$send_jump_element 不存在 X\033[0m"
        screencap_error
        exit 1
    fi
}

###返回
back(){
    adb shell input keyevent 4
    echo "\033[32mBack\033[0m"
    sleep 2
}


