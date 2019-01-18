# s -- 跳板机脚本

## 简介

用于快速跳转到目标服务器

支持自定义host别名配置，支持tab自动补齐

除了支持host别名外，s脚本也支持IP简化输入，请自行修改s脚本ip prefix的预设即可。

## 配置

#### 配置tab自动补齐

将addon.bash_profile文件中的内容添加到~/.bash_profile文件中，然后运行以下命令使之生效
```
~$ source ~/.bash_profile
```

#### 配置host列表

按照config.my_hosts的格式，根据自己需求配置host列表，将列表写入以下文件。

```
~$ vim ~/.my_hosts 
```
