file_location=$(cd `dirname $0`; pwd)
pre_file_location=${file_location%/*}
log_location="${pre_file_location}/log"
time=$(date +%Y-%m-%d_%H-%M-%S)
log_name="${log_location}/${time}.log"

# sh /Users/wuxian/Documents/UICase_Shell/cases/ershouche.sh | tee -a $log_name
# sh /Users/wuxian/Documents/UICase_Shell/cases/daleisou.sh  | tee -a $log_name

count=$#
echo "本次一共需执行 $count 条case。" | tee -a $log_name
for i in $*
do 
   sh $i | tee -a $log_name
done