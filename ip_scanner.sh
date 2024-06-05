#!/bin/bash

#######################################
#运行前，一定要安装依赖                   #
#yum install -y libpcap-devel         #
#yum install -y screen                #
#######################################

# 检查 masscan 是否可执行，如果不可执行则添加执行权限
if [ ! -x "./masscan" ]; then
    chmod +x "./masscan"
fi

# 默认参数
target=""          # 存储目标 IP
prefix_array=()    # 存储前缀数组
port=808           # 默认端口
rate=1000          # 默认速率
num_threads=100    # 默认线程数

# 处理命令行参数
while [[ $# -gt 0 ]]; do
    key="$1"

    case $key in
        -pre|--prefix)  # 如果参数是 -pre 或 --prefix
            shift  # 移除已处理的参数
            if [ -n "$target" ]; then
                echo "警告：$target 和 -pre 参数不能同时存在，已忽略 -pre 参数。"
            else
                # 使用逗号分隔的列表来分割前缀值，并添加到数组中
                IFS=',' read -ra prefix_values <<< "$1"
                for prefix_value in "${prefix_values[@]}"; do
                    # 如果前缀值包含"-"，表示前缀范围
                    if [[ "$prefix_value" == *-* ]]; then
                        IFS='-' read -ra range <<< "$prefix_value"
                        for i in $(seq ${range[0]} ${range[1]}); do
                            prefix_array+=("$i")
                        done
                    else
                        prefix_array+=("$prefix_value")
                    fi
                done
            fi
            shift  # 移除前缀列表参数
            ;;
        -t|--num_threads)  # 如果参数是 -t 或 --num_threads（代表线程数）
            shift  # 移除已处理的参数
            num_threads="$1"  # 获取线程数
            shift  # 移除线程数参数
            ;;
        -p|--port)  # 如果参数是 -p 或 --port（代表端口）
            shift  # 移除已处理的参数
            port="$1"  # 获取端口号
            shift  # 移除端口参数
            ;;
        -r|--rate)  # 如果参数是 -r 或 --rate（代表速率）
            shift  # 移除已处理的参数
            rate="$1"  # 获取速率
            shift  # 移除速率参数
            ;;
        *)  # 如果参数不匹配任何预定义的参数
            if [ -z "$target" ]; then
                target="$1"  # 如果目标 IP 未设置，则设置目标 IP
            else
                echo "未知参数: $1"
                exit 1
            fi
            shift  # 移除未知参数
            ;;
    esac
done

# 显示说明，仅当用户未输入任何参数时
if [ -z "$target" ] && [ ${#prefix_array[@]} -eq 0 ]; then
    echo "使用范例1：./ip_scan.sh 211.65.0.0/16 -p 808,9901"
    echo "使用范例2：./ip_scan.sh 211.65.0.100-211.65.0.200 -p 808,9901 -r 100"
    echo "使用范例3：./ip_scan.sh -pre 182-183 -p 808,9901 -r 10000"
    echo "参数说明："
    echo "-pre 或 --prefix：设置要扫描的 IP 前缀，支持多个前缀以逗号分隔，也支持前缀范围表示，例如：124,128-130,177,180-183,202,210,211,218-219"
    echo "-p 或 --port：设置要扫描的端口号，默认为 808，支持多个多个端口以逗号分隔，也支持端口范围表示。酒店源常用端口：88,808,8081-8800,9901,8181"
    echo "-r 或 --rate：设置扫描速率（每秒扫描的IP数量），默认为 1000"
    echo "-t 或 --num_threads：设置处理扫描结果的线程数，默认为 100"
    exit 0
fi

# 创建函数，用于执行 masscan 扫描并等待
function perform_masscan() {
    local pre="$1"

    if [ -n "$target" ]; then
        ./masscan -Pn $target -p$port --rate "$rate" > scan_results.txt
    else
        ./masscan -Pn $pre.0.0.0/8 -p$port --rate "$rate" > scan_results.txt
    fi
}

# 根据是否存在 target 判断使用哪种扫描模式
if [ -n "$target" ]; then
    perform_masscan
else
    # 遍历前缀值数组，并为每个前缀值启动一个后台任务
    for pre in "${prefix_array[@]}"; do
        if [ "$pre" = "${prefix_array[-1]}" ]; then
            # 如果是最后一个前缀，让其显示在前台
            perform_masscan "$pre"
        else
            # 否则，重定向输出到 scan_results.txt 文件，不输出终端信息
            perform_masscan "$pre" 2>/dev/null &
        fi
    done
fi

# 等待所有后台任务完成
wait

# 扫描结果文件
scan_results_file="scan_results.txt"

# 输出文件，用于保存返回码为 200 的 src 地址
output_file="myip.txt"

# 超时时间（秒）
timeout=1

# 清空输出文件
> "$output_file"

echo "正在检测源..."

# 遍历输入文件的每一行
while IFS= read -r line; do
    ip=$(echo "$line" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+')
    port=$(echo "$line" | grep -oE 'port [0-9]+' | awk '{print $2}')

    # 根据不同的端口设置不同的 path
    if [ "$port" = "808" ] || [ "$port" = "8800" ] || [ "$port" = "8081" ]; then
        path="/ZHGXTV/Public/json/live_interface.txt"
    elif [ "$port" = "9901" ] || [ "$port" = "8181" ]; then
        path="/iptv/live/1000.json"
    else
        path=""
    fi

    src="$ip:$port"
    address="$ip:$port$path"

    # 使用 curl 发送 GET 请求并设置超时时间，获取 HTTP 返回码
    (
        http_code=$(curl -o /dev/null -I -s -w "%{http_code}" --max-time "$timeout" "$address")
        # 检查返回码是否为 200，如果是则在终端中显示 address 地址并追加到输出文件
        if [ "$http_code" = "200" ]; then
            # 发送GET请求，获取响应内容
            response=$(curl -s $address --max-time "$timeout")
            cctv=$(echo "$response" | grep -iE "CCTV")
            if [ -n "$cctv" ]; then
                echo "检测到可用源：$address"  # 在终端中显示 address 地址
                # 使用 grep 检查 src 地址是否已存在于输出文件中
                if ! grep -q "^$src$" "$output_file"; then
                    echo "$src" >> "$output_file"  # 将 src 地址追加到输出文件
                fi
            fi
        fi
    ) &  # 后台运行任务

    # 控制并发线程数，等待直到当前线程数小于 num_threads
    while [ $(jobs | wc -l) -ge "$num_threads" ]; do
        sleep 1
    done

done < "$scan_results_file"

# 等待所有后台任务完成
wait

# 检查 myip.txt 文件是否为空
if [ -s "$output_file" ]; then
    echo "已检测并保存 IP 地址到 $output_file 文件。"
else
    echo "未找到符合条件的 IP 地址"
fi
