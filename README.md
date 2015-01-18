# SendMIDIBySocket
通过蓝牙进行数据交换，再通过网络传输到另一台设备

本demo实现了经过蓝牙与网络传输数据至另一台设备。

大致流程如下：

外部硬件设备-----(BLE4.0)发送数据----->IOS设备<-----(Socket)数据交换----->服务器<-----(Socket)数据交换----->IOS设备<-----(BLE4.0)发送数据-----外部硬件设备

解释：
1.外部硬件通过蓝牙，IOS设备主要是通过BLE4.0来传输数据；
2.多台IOS设备之间使用Socket(本例使用PHP的workerman)网络通信；
3.IOS中使用的是AsyncSocket第三方Socket框架；

问题：
1.TCP传输的粘包与分包问题暂未解决；

交流：
QQ：451973176
Email：zhao_li_bo@163.com
