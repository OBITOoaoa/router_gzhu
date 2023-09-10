# 转载

## 小米路由器4C刷openwrt

[2021-05-19](https://cloudflare.luhawxem.com/2021/05/19/Mi-Router-4C-flash-openwrt/)

前言：校园网环境需要经过锐捷认证才能正常上网，无法使用正常路由器自带的后台管理及网络分配那一套系统。比较现成完整的方案是刷入[openwrt](https://openwrt.org/)，然后通过可扩展的802.1x客户端[minieap](https://github.com/updateing/minieap)模拟锐捷认证以正常通过校园网认证。所以本文讲一下如何刷入openwrt，以小米路由器4C为例。

#### 路由器选择

实际上这个路由器选择的不太好，整体除了便宜就没有什么好处了，建议选择Redmi AC2100或竞斗云，及小米3系列路由器。不过在师兄的帮助下，总算是把这个路由器的坑踩完了，目前刷入的是openwrt官方的snapshot版本(小米4C也只有snapshot版本)，在此感谢[@ysc3839](https://github.com/ysc3839)师兄的帮助，祝师兄毕业快乐，前程似锦😃。

#### 刷机准备

本质上，各大厂商都是不允许用户刷机的。而openwrt官方的固件是对厂商官方的bootloader进行了支持的，但刷机是一个有风险的行为，官方的bootloader无法承担风险，所以一般刷机需要先刷入一个第三方bootloader以保证就算固件刷坏了，也能通过第三方的bootloader重刷固件而不至于变砖。此处使用了恩山论坛的breed：https://www.right.com.cn/forum/thread-161906-1-4.html ，但由于小米4C并没有专供的breed版本，此处使用通用版本breed-mt7688-reset38.bin。具体文件请去恩山论坛下载，避免转载侵权。

##### 漏洞提权

为了刷入bootloader，我们需要先拿到路由器后台的ssh权限和ftp权限，window下使用[R3GV3 patches](http://dwz.win/ansg)，运行0.start_main.bat，输入路由器后台管理员密码通过漏洞破解获取ssh权限和ftp权限，此方法可以在无网络(WAN口无网络)情况下实现漏洞破解，而openwrt官方推荐的[OpenWRTInvasion](https://github.com/acecilia/OpenWRTInvasion)除了0.0.1版本以外均需要WAN口有网络连接。

##### 备份

通过漏洞破解提权之后，就可以通过ssh和ftp连接进入路由器后台了，由于小米4C的ftp用户为guest无密码用户，可以直接在资源管理器通过ftp://192.168.31.1连接进入。ssh和ftp都连接上之后首先需要将重要分区备份。

![img](E:\课外资料\Linux\Router_minieap\xiaomi_4C\xiaomi4C刷入固件\proc-mtd-layout.png)

openwrt关于小米4C的介绍页中提供了原厂闪存的布局及openwrt固件的闪存布局，此处我们需要将原厂的mtd1:bootloader分区、mtd3:eeprom分区、以及mtd7:OS1分区备份起来，输入：`cat /proc/mtd`确认分区情况，然后通过`dd if = /dev/mtd0 of = /tmp/all.bin`将整个闪存分区备份到`/tmp`路径下，同理将bootloader、eeprom、OS1分区均备份成`.bin`二进制文件，然后通过ftp将其保存到本地备用，此处需要注意，eeprom为编程器驱动分区，是刷砖之后最后的救砖方案必须保留的分区，需要注意的是此分区大小一般为65536个字节即64KB，若备份时发现文件大小不对最好多尝试几次。

##### 刷入breed

将下载的breed.bin文件复制到远端`/tmp`目录下，通过ssh执行`mtd write /tmp/breed.bin Bootloader`刷入breed。刷入完成后，在按住复位键的同时给路由器通电，可以看到电源灯与网络灯闪烁一次之后连续闪烁几下，此时就进入了breed模式，可以通过浏览器访问192.168.1.1进入breed的图形界面。此处我们不使用图形界面进行刷机。我们使用`telnet 192.168.1.1`进入breed后台进行操作。

##### 刷机过程

前面提到了，openwrt实际上是针对原厂固件进行了适配的。通过阅读openwrt仓库里xiaomi-router-4c的dts文件(openwrt/target/linux/ramips/dts/mt7628an_xiaomi_mi_router-4c.dts)可以发现，firmware分区是从0x160000开始，大小为0xea0000的扇区。即kernel位于0x160000起始。但前面说到了，我们刷入的breed是通用breed，并没有针对此处进行适配，如果使用图形界面刷机，只能刷入0x60000等几个有限的位置。这就导致了虽然bootloader能在0x60000运行kernel，但由于kernel内隐含了dtb文件，dtb文件定义了文件系统所处的位置，如果将openwrt.bin刷入到0x60000位置，但由于整个文件向前移动了，导致文件系统也向前移动，所以dtb无法找到挂载文件系统的位置(magic:D0 0D FE ED)，所以整个系统启动过程会失败，导致不断重启。

为了解决这个问题，我们需要手动将openwrt.bin刷入到0x160000起始的闪存位置上，先通过计算器算出该文件真实大小对应的16进制数字。

![img](E:\课外资料\Linux\Router_minieap\xiaomi_4C\xiaomi4C刷入固件\openwrt-size.png)

此处需要计算的是大小所对应的数字，而非占用空间。此处算得大小为0x4C013A。

此处借用breed内置的wget命令将本地的文件上传到路由器内存中。先在存放openwrt.bin的目录下运行`py -m http.server`开启一个本地ftp服务器，一般默认端口为8000，然后通过浏览器打开breed同网段下的该ftp服务器，如http://192.168.1.2:8000 ；然后右键获取openwrt.bin的文件链接，`wget [link]`通过局域网下载本地文件。下载完成后注意看breed的提示，因为此时下载文件是存放在内存中的，需要记下存放的内存地址。

![img](E:\课外资料\Linux\Router_minieap\xiaomi_4C\xiaomi4C刷入固件\breed-flash-help.png)

然后先通过`flash erase 0x160000 0xea0000`擦除需要写入的系统分区位置，再通过`flash write 0x160000 src 0x4C013A`刷入openwrt.bin文件，此处的src即为wget时存放openwrt.bin文件的内存起始地址。

刷写完毕后，由于breed的autoboot命令默认从0x60000加载kernel，所以我们需要额外添加参数指定其从0x160000开始加载kernel内核。执行`boot flash 0x160000`从0x160000加载内核。至此已经可以正常启动openwrt固件，进入openwrt系统了。

但是，这种方法要求每次启动都要先telnet进breed后台手动启动，显然不现实。通过翻阅恩山论坛breed教程贴，发现可以使用环境变量解决，如图：

![img](E:\课外资料\Linux\Router_minieap\xiaomi_4C\xiaomi4C刷入固件\autoboot-command.png) ![img](E:\课外资料\Linux\Router_minieap\xiaomi_4C\xiaomi4C刷入固件\env-autoboot.png)

只需要通过图形界面打开breed内置的环境变量功能，新建如图所示的环境变量并保存重启即可，至此算是真正的完成了。最大的坑也算是踩进去并填上了。

再次感谢[@ysc3839](https://github.com/ysc3839)师兄的帮助，这个异常的启动位置所导致的“坑”大概填了有三个多小时吧，师兄带着我一步一步阅读dtsi、dtc、dtb并讲解其中过程，非常感谢。

#### 后记

路由器系统启动的过程分为：bootloader启动，bootloader加载kernel内核，kernel运行并挂载文件系统，kernel运行用户模式程序，kernel将权限交给用户模式程序使其继续运行下去。此处的用户模式程序即为我们所能见到的操作系统展示出来的东西。之前直接通过breed刷入会失败的原因就是因为文件系统无法挂载，没有办法进入用户态执行。而常见的x86平台由于UEFI(bootloader)能够实现挂载文件系统的功能，若文件系统挂载失败则在UEFI-BIOS中即可发现(磁盘掉盘)，一般很少注意到其实kernel这里也挂载了一次文件系统。此次经历使我再次学到了部分有关操作系统的知识，算是一次“还不赖”的踩坑吧😄

**本文作者：** BBSD丿草丶帽
**发布时间：** 2021-05-19
**最后更新：** 2022-09-13
**本文标题：** [小米路由器4C刷openwrt](https://cloudflare.luhawxem.com/2021/05/19/Mi-Router-4C-flash-openwrt/)
**本文链接：** https://cloudflare.luhawxem.com/2021/05/19/Mi-Router-4C-flash-openwrt/
**版权声明：** 本作品采用 [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/) 许可协议进行许可。转载请注明出处！