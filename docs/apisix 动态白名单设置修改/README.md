1. 将 apisix:apisix:plugins 里的 dynmic-ip-restrict.lua 拷贝到 /usr/local/apisix/apisix/plugins/ 下

2. 修改 /usr/local/apisix/conf/config-default.yaml 在 ``- cors`` 下新增

```yaml
  - cors                           # priority: 4000
  - dynmic-ip-restrict             # priority: 3001
```



3. 修改 /usr/local/apisix/dashboard/conf/conf.yaml 在文件最后新增 ``- dynmic-ip-restrict``

   ```yaml
     - traffic-split
     - dynmic-ip-restrict
   ```

4. 修改/usr/local/apisix/dashboard/conf/conf.yaml 在 ``api-breaker``插件前新增  ``dynmic-ip-restrict``插件配置元信息说明

   ```json
       "dynmic-ip-restrict": {
         "priority": 3001,
         "schema": {
           "properties": {
             "redis_host": {
               "type": "string",
               "minLength": 2
             },
             "redis_port": {
               "type": "integer",
               "minimum": 1,
               "default": 6379
             },
             "redis_username": {
               "type": "string",
               "minLength": 1
             },
             "redis_password": {
               "type": "string",
               "minLength": 0
             },
             "redis_database": {
               "type": "integer",
               "minimum": 0,
               "default": 0
             },
             "redis_timeout": {
               "type": "integer",
               "minimum": 1,
               "default": 1000
             },
             "redis_ssl": {
               "type": "boolean",
               "default": false
             },
             "redis_ssl_verify": {
               "type": "boolean",
               "default": false
             },
             "message": {
               "type": "string",
               "default": "IP restriction"
             }
           }
         },
         "version": 0.1
       },
   ```

   