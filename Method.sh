devices=`adb devices | grep device$ | awk '{print $1}'`
echo $devices
size_cmd=`adb shell wm size | awk '{print $3}' | tr -d "\r"`
window_height=${size_cmd#*x}
window_width=${size_cmd%x*}

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
    adb pull /sdcard/window_dump.xml ./
}


#返回0代表无验证元素
#返回1代表存在验证元素
verify_element_bytext(){
    verify_element=$1
    element="xml sel -t -m \"//node[contains(@text,'$verify_element')]\" -c . window_dump.xml"
    if [[ ! -n `eval $element` ]];then
        echo 0;
    else
        echo 1;
    fi
}

verify_element_bydesc(){
    verify_element=$1
    element="xml sel -t -m \"//node[contains(@content-desc,'$verify_element')]\" -c . window_dump.xml"
    if [[ ! -n `eval $element` ]];then
        echo 0;
    else
        echo 1;
    fi
}

verify_element_byid(){
    verify_element=$1
    element="xml sel -t -m \"//node[contains(@resource-id,'$verify_element')]\" -c . window_dump.xml"
    if [[ ! -n `eval $element` ]];then
        echo 0;
    else
        echo 1;
    fi
}

#页面不应该存在某元素
#两个参数：参数1：元素类型  参数2：元素名称
should_not_exist(){
    element_type=$1
    verify_element3=$2

    i=0
    total=10   ###页面响应耗时小于5s
    while [[ $i -lt $total ]]; do
       dump_window

        case $element_type in
        "text" )
           verify=`verify_element_bytext $verify_element3` ;;
        "content-desc" )
           verify=`verify_element_bydesc $verify_element3` ;;
        "id" )
           verify=`verify_element_byid $verify_element3` ;;
        esac

       if [[ $verify -eq 1 ]]; then
            echo "\033[33m页面元素:$verify_element3 仍然存在\033[0m"
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
    element_type=$1
    verify_element1=$2  ###去掉行首空格

    echo "\033[32m--验证元素：$verify_element1 \033[0m"

    if [[ ${verify_element1:0:1} = '!' ]]; then
        verify_element1=${verify_element1#*!}  ##去掉开头的！
        should_not_exist $element_type $verify_element1
    else
        i=0
        total=10   ###页面响应耗时小于10s
        while [[ $i -lt $total ]]; do
           dump_window

           case $element_type in
           "text" )
              verify=`verify_element_bytext $verify_element1` ;;
            "content-desc" )
              verify=`verify_element_bydesc $verify_element1` ;;
            "id" )
              verify=`verify_element_byid $verify_element1` ;;
            esac

            if [[ $verify -eq 0 ]]; then
               sleep 1
               let i+=1
            else
               break
            fi
        done

        if [[ $i -ge $total ]]; then
            echo "\033[33m页面待验证元素:$verify_element1 查找超时\033[0m"
            return 1
        fi
    fi

}

##多个元素验证
##两个参数：参数1：元素类型  参数2：元素名称
check_elements_by(){
    element_type=$1
    verify_element0=$2

    echo "\033[32m需验证页面元素：$verify_element0 \033[0m"

    if [[ $verify_element0 =~ "&" ]]; then

        IFS='&'
        arr=$verify_element0
        for element in ${arr[@]}; do
           element1=$element    
           check_element_by $element_type $element1
           if [[ $? = 1 ]]; then
              echo "\033[31m页面元素:$verify_element0 验证失败\033[0m"
              exit 1
           fi
        done

        echo "\033[32m页面元素:$verify_element0 验证成功\033[0m"
        return 0   ##验证成功

    elif [[ $verify_element0 =~ "|" ]]; then
                
        IFS='|'
        arr=$verify_element0
        for element in ${arr[@]}; do
           element1=$element  
           check_element_by $element_type $element1
           if [[ $? != 1 ]]; then
               echo "\033[32m页面元素:$verify_element0 验证成功\033[0m"
               return 0   ##验证成功
           fi
        done
                      
        echo "\033[31m页面元素:$verify_element0 验证失败\033[0m"
        exit 1
    
    else    ##单个元素验证
        check_element_by $element_type $verify_element0
        if [[ $? != 1 ]]; then
            echo "\033[32m页面元素:$verify_element0 验证成功\033[0m"
            return 0   ##验证成功
        else
            echo "\033[31m页面元素:$verify_element0 验证失败\033[0m"
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
    element_type=$2
    jump_element=$3

    echo "\033[32mScroll $direction Until finding element : $jump_element\033[0m"

    case $element_type in
        "text" )
           jump_button="xml sel -t -m \"//node[contains(@text,'$jump_element')]\" -c . window_dump.xml" ;;
        "content-desc" )
           jump_button="xml sel -t -m \"//node[contains(@content-desc,'$jump_element')]\" -c . window_dump.xml" ;;
        "id" )
           jump_button="xml sel -t -m \"//node[contains(@resource-id,'$jump_element')]\" -c . window_dump.xml" ;;
    esac

    ##两种情况：web页面dump整个页面，native页面只dump当前屏的元素
    ##第一种情况，待查找元素不在当前dump内容内，循环向上滑动，dump，查找元素
    i=0
    total=10   ###页面响应耗时小于10s
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
        if [[ -n `eval $jump_button` ]];then
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

    element_type=$1
    jump_element=$2
    echo "\033[32mScroll  Until finding element : $jump_element\033[0m"

    case $element_type in
        "text" )
           jump_button="xml sel -t -m \"//node[contains(@text,'$jump_element')]\" -c . window_dump.xml" ;;
        "content-desc" )
           jump_button="xml sel -t -m \"//node[contains(@content-desc,'$jump_element')]\" -c . window_dump.xml" ;;
        "id" )
           jump_button="xml sel -t -m \"//node[contains(@resource-id,'$jump_element')]\" -c . window_dump.xml" ;;
    esac
    
    i=0
    total=10   ###页面响应耗时小于10s
    dump_window
    if [[ -n `eval $jump_button` ]]; then
        
        while [[ $i -lt $total ]]; do
            dump_window
            button_location=`eval $jump_button | egrep -o $grep_bounds | grep -o $grep_location `
            button_location0=`echo $button_location | awk '{print $1}'`
            start=${button_location0#[}
            start=${start%][*}
            end=${button_location0#*][}
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
        echo "\033[31m页面不存在元素:$jump_element\033[0m"
        exit 1
        
    fi

    

}

##点击页面元素
##参数一：定位元素类型："text"、"content-desc"、"id"
##参数二：待点击的元素
click_element_by(){
     
    element_type=$1
    jump_element=$2
    echo "\033[32mClick elemnet : $jump_element \033[0m"

    case $element_type in
        "text" )
           jump_button="xml sel -t -m \"//node[contains(@text,'$jump_element')]\" -c . window_dump.xml" ;;
        "content-desc" )
           jump_button="xml sel -t -m \"//node[contains(@content-desc,'$jump_element')]\" -c . window_dump.xml" ;;
        "id" )
           jump_button="xml sel -t -m \"//node[contains(@resource-id,'$jump_element')]\" -c . window_dump.xml" ;;
    esac

    if [[ -n `eval $jump_button` ]];then
    button_location=`eval $jump_button | egrep -o $grep_bounds | grep -o $grep_location `
    button_location0=`echo $button_location | awk '{print $1}'`
    echo "控件位置：$button_location0"
    start0=${button_location0#[}
    start=${start0%%][*}
    end0=${button_location0#*][}
    end=${end0%%]*}
    x=`expr ${start%\,*} + ${end%\,*} `
    y=`expr ${start#*\,} + ${end#*\,} `
    x=`expr $x / 2`
    y=`expr $y / 2`
    echo "点击页面坐标：($x,$y)"
    adb shell input tap $x $y
    else
        echo "\033[33m待点击元素:$jump_element 不存在\033[0m"
        exit 1

    fi

}


##输入文字
##参数一：定位元素类型："text"、"content-desc"、"id"
##参数二：待输入文字的元素
##参数三：要输入的文字
send_text(){
    
    element_type=$1
    jump_element=$2
    send_text=$3
    echo "\033[32m在 $jump_element 中输入：$send_text \033[0m"

    case $element_type in
        "text" )
           jump_button="xml sel -t -m \"//node[contains(@text,'$jump_element')]\" -c . window_dump.xml" ;;
        "content-desc" )
           jump_button="xml sel -t -m \"//node[contains(@content-desc,'$jump_element')]\" -c . window_dump.xml" ;;
        "id" )
           jump_button="xml sel -t -m \"//node[contains(@resource-id,'$jump_element')]\" -c . window_dump.xml" ;;

    esac

    if [[ -n `eval $jump_button` ]];then
    button_location=`eval $jump_button | egrep -o $grep_bounds | grep -o $grep_location `
    button_location0=`echo $button_location | awk '{print $1}'`
    start=${button_location0#[}
    start=${start%][*}
    end=${button_location0#*][}
    end=${end%]*}
    x=`expr ${start%\,*} + ${end%\,*} `
    y=`expr ${start#*\,} + ${end#*\,} `
    x=`expr $x / 2`
    y=`expr $y / 2`
    adb shell input tap $x $y
    adb shell am broadcast -a ADB_INPUT_TEXT --es msg $send_text
    else
        echo "\033[31m页面待键入内容元素:$jump_element 不存在\033[0m"
        exit 1
    fi
}

###返回
back(){
    adb shell input keyevent 4
    echo "\033[32mBack\033[0m"
    sleep 2
}


