# vscode-server-download-script


# 零、使用方法


1. 本脚本是在本地设备上执行的。使用本脚本前建议先把本地设备上的ssh公钥上传到服务器上，让本地设备能免密登录服务器(不传也可以，就是麻烦)；
2. 本脚本假设本地设备是能联网的，而服务器则不一定可以；
3. 如果本地设备的操作系统是某个Linux发行版(或者其他能直接运行shell脚本的系统)，那本脚本是可以直接运行的；如果是windows系统（或者其他不能直接运行shell脚本的系统），那你需要下载git和wget，在git提供的终端里面运行本脚本，亲测有效；
4. 给这个脚本赋予执行权限并执行它：chmod +x codeserver.sh && ./codeserver.sh,接下来根据提示操作即可；
5. 使用前一定要把远程服务器上.vscode-server/bin目录下的${commit id}文件夹删除掉，也就是说每次更新完vscode后，先不要打开vscode（不然的话vscode会自动在远程服务器上.vscode-server/bin目录下创建${commit id}文件夹），先运行完这个脚本再打开vscode。


# 一、vscode-server是如何工作的


1. 使用vscode远程连接到服务器上需要在服务器上下载vscode-server；
2. .vscode-server的内部目录结构如下：
```bash
  |-.vscode-server
    |-bin
      |-${commit id1}
      |-${commit id2}
      |-...
    |-data（不一定有）
    |-extensions（不一定有）
    |-...
```
3. 每个版本的vscode都对应一个commit id，当远程连接到服务器时，本地设备上vscode的commit id会被传上去；
4. 如果在.vscode-server/bin/目录下有与传上去的commit id同名的文件夹，服务器会直接完成远程链接的相关工作；
5. 如果不符合第4步中提到的情况，在完成远程连接的相关工作前，服务器就会试图从vscode官方提供的网站下载对应的文件并把它们放到相应的目录下；
6. vscode每次更新版本时就会换commit id，所以每次更新后服务器都会执行第5步中提到的操作；


# 二、为什么vscode有时不能完成上述工作以至于需要我们自行完成相关操作


  自2023年的某月始，出于某些未知原因，vscode官方提供的网站 https://update.code.visualstudio.com 无法稳定访问。因此，我们需要把该网址换成国内的cdn https://vscode.cdn.azure.cn


# 三、常见问题


问：本脚本能彻底解决vscode ssh连接问题吗？

答：暂时不能。首先，有的服务器是没法联网的，对于这些服务器，惟一的解决方法就是在本地下载文件然后传到服务器上，但这个方法对于能联网的服务器就不太合适；其次，config文件的配置形式是多种多样的：ssh端口可以换，proxyjump也可以设置。我暂时还没想好如何处理config文件中的内容。

问：为什么不默认用bash执行？

答：因为我本人用的zsh，为了提高脚本兼容性，所以选择最基础的sh。

问：能不能出一个windows系统下直接运行的batch脚本？

答：暂无这个计划，毕竟windows上也能靠git的终端运行这个脚本。当然了，最主要的问题是我不会batch语法。

问：为什么不让用户手动输入lk的值来确定选择哪种解决方略？

答：对于大部分人来说，服务器的联网状态是比较稳定的。能联网的服务器会长期保持联网的状态，不能联网的服务器也会长期保持不能联网的状态。每次让用户输入lk的值只会给用户增加麻烦。
