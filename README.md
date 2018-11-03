# DNS SWITCH
DNS Switch允许您使用终端以systemlessly的方式更改DNS。在终端输入su然后再输入`dns_switch`进入菜单, 选择自定义DNS后输入您要使用的DNS。
输入`dns_switch -h`或`dns_switch --help`以获取帮助

## 兼容性
* 所有设备
* 所有Android版本
* Selinux enforcing(执行)模式
* 所有根解决方案 (如果不使用magisk或supersu, 则需要init.d支持。尝试 [Init.d Injector](https://forum.xda-developers.com/android/software-hacking/mod-universal-init-d-injector-wip-t3692105))

## 更新日志
### v2 - 11.02.2018
* 添加了开机时设置支持
* 添加了查看自定义DNS的功能
* 添加了帮助选项。运行dns_switch -h或--help来查看它
* 即将推出的功能是dnscrypt支持/dns over https支持以及更多惊喜

### v1 - 10.26.2018
* 初始发布


## 源代码
* 模块 [GitHub](https://github.com/JohnFawkes/DNSSwitch)
