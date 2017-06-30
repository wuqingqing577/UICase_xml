file_location=$(cd `dirname $0`; pwd)
pre_file_location=${file_location%/*}
log_location="${pre_file_location}/log"
report_location="${pre_file_location}/report"
time1=$(date +%Y-%m-%d_%H-%M-%S)
log_name="${log_location}/${time1}.log"
report_name="${report_location}/${time1}.log"

# sh /Users/wuxian/Documents/UICase_Shell/cases/ershouche.sh | tee -a $log_name
#echo "==============================================================" | tee -a $log_name
# sh /Users/wuxian/Documents/UICase_Shell/cases/daleisou.sh  | tee -a $log_name
#echo "==============================================================" | tee -a $log_name

count=$#
echo "本次一共执行 $count 条case。" | tee -a $log_name

###解析log文件，生成report
deal_with_log(){
   log=$1
   report=$2
   
   echo "generate report ......"
  
   #统计行数
   file_line=`sed -n '$=' $log`
   case_count=0
   error_count=0
   case_name_pre="运行脚本: "
   error_case_pre=" X"

   while read line; do
   	   if [[ $line =~ "本次一共执行 " ]]; then
           case_count=${line#* }
           case_count=${case_count% *}
           echo "本次一共执行 $case_count 条case。" >> $report
           echo "其中运行失败case有以下几个：" >> $report
	   elif [[ $line =~ $case_name_pre ]]; then
		   let case_count+=1
		   case_name=${line#*:}
		elif [[ $line =~ $error_case_pre ]]; then
		   	let error_count+=1
		   	echo "$case_name" >> $report
	   fi
   done < $log

   echo "运行错误case共 $error_count 条" >> $report
   echo "具体出错原因参见：$log" >> $report

   echo "Done !"


}


for i in $*
do 
   echo "运行脚本: $i"  | tee -a $log_name
   sh $i | tee -a $log_name
   echo "==============================================================" | tee -a $log_name
done

deal_with_log $log_name $report_name

