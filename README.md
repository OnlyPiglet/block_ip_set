
config.yaml与ip_set同目录下，内配置redis 相关配置
redis:
  addr: 127.0.0.1:6379
  password: xxx
  db: 0

ips 文件的内容如下

``112.23.224.121,121.40.117.18``

使用命令 ip名单存放在 ips, -c 指定 IP 文件，action 指定黑名单还是白名单
黑名单设置

``./ip_set -c ./ips -action black``

白名单设置

``./ip_set -c ./ips -action white``

