# IP 扫描脚本
[![libpcap-devel](https://img.shields.io/badge/-libpcap--devel-brightgreen)](https://rpmfind.net/linux/rpm2html/search.php?query=libpcap-devel) [![screen](https://img.shields.io/badge/-screen-brightgreen)](https://www.gnu.org/software/screen/)

使用 `masscan` 扫描指定 IP 范围内的开放端口，并检查 HTTP 的特定特征响应的有效IP源。

此脚本为初级单机扫描脚本，高级分布式UI版本请前往：[全王探测](https://isus.cc/frontend/about)（持续更新）

## 前置条件
### 系统环境要求
Centos7.9系统（如果是其他系统，请重新编译对应平台的 masscan 替换文件）

### 运行前，请先安装以下依赖：
```sh
yum install -y libpcap-devel screen
```

## Screen使用方法
1. 创建并进入一个新的 Screen 窗口
```sh
screen -S ip
```
2. 切换到脚本所在目录
```sh
cd xxx
```
3. 启动 IP 扫描脚本
```sh
./ip_scanner.sh 211.65.0.0/16 -p 808,9901
```
4. 退出 Screen 窗口
- 要退出当前的 screen 窗口而不终止其运行的会话，可以使用以下快捷键：
  - 按 Ctrl + A，然后按 D 键。这会将您带回到普通终端，而扫描脚本仍在 screen 会话中运行。
5. 重新进入 Screen 窗口
```sh
./ip_scanner.sh 211.65.0.0/16 -p 808,9901
```

### 扫描脚本使用示例
1. 使用单个目标运行脚本：
```sh
./ip_scanner.sh 211.65.0.0/16 -p 808,9901
```
2. 使用 IP 范围运行脚本：
```sh
./ip_scanner.sh 211.65.0.100-211.65.0.200 -p 808,9901 -r 100
```
3. 使用 IP 前缀运行脚本：
```sh
./ip_scanner.sh -pre 182-183 -p 808,9901 -r 10000
```
4. 扫描单个目标的多个端口：
```sh
./ip_scanner.sh 192.168.0.1 -p 80,443
```
5. 扫描指定速率和端口的 IP 范围：
```sh
./ip_scanner.sh 10.0.0.1-10.0.0.255 -p 22,80,443 -r 5000
```
6. 使用指定端口和线程数扫描多个 IP 前缀：
```sh
./ip_scanner.sh -pre 10-12,192.168 -p 808,9901 -r 2000 -t 50
```

### 参数说明
- -pre, --prefix： 设置要扫描的 IP 前缀，支持多个前缀以逗号分隔，也支持前缀范围表示（例如：124,128-130,177,180-183,202,210,211,218-219）。
- -p, --port： 设置要扫描的端口号，默认为 808，支持多个端口以逗号分隔，也支持端口范围表示（例如：88,808,8081-8800,9901,8181）。
- -r, --rate： 设置扫描速率（每秒扫描的 IP 数量），默认为 1000。
- -t, --num_threads： 设置处理扫描结果的线程数，默认为 100。

### 输出文件
- scan_results.txt： 包含 masscan 的原始扫描结果。
- myip.txt： 包含过滤后的 IP 地址，这些地址返回特定内容的 HTTP 200 响应。

### 脚本工作流程
1. 权限检查： 确保 masscan 可执行。
2. 参数处理： 处理输入参数并设置默认值。
3. 扫描： 使用 masscan 扫描指定的 IP 和端口。
4. 过滤： 向扫描到的 IP 和端口发送 HTTP 请求，检查特定响应。
5. 输出： 将有效源保存到 myip.txt。

### 注意事项
- 脚本根据提供的目标（单个目标或多个前缀）自动调整扫描方式。
- 通过管理线程数高效处理并发任务。

### 许可证
此项目根据 MIT 许可证授权 - 有关详细信息，请参见 LICENSE 文件。

### 致谢
特别感谢 [masscan](https://github.com/robertdavidgraham/masscan) 的贡献者和开源社区提供的宝贵工具和支持。
