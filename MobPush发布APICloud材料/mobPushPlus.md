/*
Title: mobPushPlus
Description: MobPush 在 APICloud 平台的插件
*/

## 概述

当前 MobPush 版本，iOS：v2.2.2、android：v2.2.2   

### MobPush 简介

MobPush是Mob推出的一款免费的推送服务工具，客户端SDK支持iOS和Android两大平台，集成方便简单快捷，且提供完整的可视化数据和强大的管理后台。


### MobPush 功能

- 支持通知栏通知和自定义消息。
- 可对通知和自定义通知进行定时发送。
- 可根据标签、别名、Registration ID、地理位置精确推送。
- 用户量，推送数量，成功数量，点击数量，发送API调用数详细统计数据一览无余。
- 提供简单接入的Rest API接口，方便开发者定制推送需求。
- MobPush管理后台提供推送相关数据统计查询，包含新增用户数、推送数量、推送点击量、用户点击数、发送API调用次数等数据。还可多维度对数据进行筛选分析，有助于开发者实时监控并了解app整体趋势。


### mobPushPlus 模块概述

mobPushPlus 封装了 MobPush，是对 APICloud 平台的支持，为APICloud开发的App提供推送功能的一个组件，支持当前主流的推送功能。

如有问题请联系技术支持:  

```
服务电话:   400-685-2216  
节假日值班电话:
    iOS：185-1664-1951
Android: 185-1664-1950
电子邮箱:   support@mob.com
市场合作:   021-54623189
```

## 模块使用攻略

开发者使用本模块之前需要先到[Mob官网](https://www.mob.com)申请开发者账号，并在账号内填写相应信息创建自己的 APP，从而获取AppKey和AppSecret,然后添加MobPush功能。  
详情参考:[快速集成获取apppkey和appSecret](http://wiki.mob.com/%E4%BA%A7%E5%93%81%E7%AE%80%E4%BB%8B-2/)


**使用此模块之前建议先配置  [config.xml](https://docs.apicloud.com/Dev-Guide/app-config-manual) 文件，配置完毕，需通过云端编译生效，配置方法如下：**

<div id="p1"></div>

### iOS配置：
**1.配置config.xml文件** 

```xml
  <preference name="backgroundMode" value="remote-notification"/>
```

>字段描述:  
> **backgroundMode**：用于实现 Xcode 的远程推送权限开启。  


**2. 配置info.plist文件**
该文件含MOB平台MOBAppKey和MOBAppSecret、特殊平台appkey配置、白名单配置,将info.plist放在widget://res文件目录下，文件内容：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>MOBAppKey</key>
	<string>moba6b6c6d6</string>
	<key>MOBAppSecret</key>
	<string>b89d2427a3bc7ad1aea1e1e8c1d36bf3</string>
	<key>NSAppTransportSecurity</key>
	<dict>
		<key>NSAllowsArbitraryLoads</key>
		<true/>
	</dict>
</dict>
</plist>
```

> **MOBAppKey、MOBAppSecret**:（必须配置）从mob平台创建应用后，申请的app Key和app Secret.  
> 配置ATS（App Transport Security），在info.plist文件中，APP可以使用http协议访问。配置方法参考[iOS修改Info.plist之配置ATS](https://community.apicloud.com/bbs/forum.php?mod=viewthread&tid=20). 


    
<div id="p2"></div>
    
### Android配置：  
Mob-AppKey/Mob-AppSecret的配置：
这两个参数的配置在config.xml文件里，以meta-data标签的形式来配置，例如：

    <meta-data name="Mob-AppKey" value="mob的appkey"/>
    <meta-data name="Mob-AppSecret" value="mob的appSecret"/>
    
Android配置第三方平台的AppKey等信息遵循APICloud的惯例是在config.xml中配置。
下面是配置各个平台信息的例子，实际的使用中需要开发者填写自己在第三方网站申请的值（只需要替换成对应的值，不需要替换name，否则将会读取不到）
	
	<meta-data name="com.mob.push.xiaomi.appid" value="小米的appId" />
    <meta-data name="com.mob.push.xiaomi.appkey" value="小米的appkey" />
	
	<meta-data name="com.vivo.push.api_key" value="vivo的apiKey" />
    <meta-data name="com.vivo.push.app_id" value="vivo的appId" />
	
	<meta-data name="com.mob.push.oppo.appkey" value="oppo的appKey" />
    <meta-data name="com.mob.push.oppo.appsecret" value="oppo的appsecret" />
	
	<meta-data name="com.huawei.hms.client.appid" value="华为的appId" />
	
	<meta-data name="com.mob.push.meizu.appid" value="魅族的appId" />
	<meta-data name="com.mob.push.meizu.appkey" value="魅族的appKey" />
    
    
### **引入模块**

```js
var pushApi = api.require('mobPushPlus');
```

<div id="a1"></div>

### **setAPNsForProduction**

设置 APNs 推送证书环境  
setAPNsForProduction({params})

#### params
isPro：

- 类型：布尔
- 描述：iOS APNs 推送证书环境， true 生产环境，false 开发环境

#### 示例代码

```js
var pushApi = api.require('mobPushPlus');
pushApi.setAPNsForProduction({
    isPro : true
});
```

#### 可用性

iOS系统

可提供的1.0.0及更高版本


<div id="a2"></div>

### **addLocalNotification**

添加本地通知  
addLocalNotification({params})

#### params
localParams：

- 类型：集合
- 描述：本地通知定制参数

#### 示例代码

```js
var pushApi = api.require('mobPushPlus');
if (systemType == 'ios') {
    localParams =  { // ios 参数主要有content, title, subTitle, timeStamp, badge, sound
        "content" : "本地通知",
        "title" : "标题",
        "subTitle" : "副标题",
        "timeStamp" : 1 // 1 秒后触发
    };
} else { // android 参数主要有notificationId, title, content, voice, shake, light
    localParams =  {
        "notificationId" : 1,
        "title":"MobPushForAPICloud",
        "content":"本地通知测试",
        "voice":true,
        "shake":true,
        "light":true
        
    };
}
pushApi.addLocalNotification({
    localParams: localParams
});
```

#### 可用性

iOS系统，Android系统

可提供的1.0.0及更高版本


<div id="a3"></div>

### **addpushReceiver**

接收通知的回调

addpushReceiver(callback(ret, err))

#### callback(ret, err)

ret：

- 类型：JSON 对象
- 内部字段：

```js
{
    action: 1      //消息类型，0:自定义消息 1:收到消息 2:点击消息
    result:  // 消息的具体内容
    {
    
    }		
}
```

#### 示例代码

```js
var pushApi = api.require('mobPushPlus');
pushApi.addpushReceiver(function(ret, err){
    api.toast({
        msg: "收到消息",
        location: 'middle'
    });
});
```

#### 可用性

iOS系统，Android系统

可提供的1.0.0及更高版本

<div id="a4"></div>

### **getTags**

获取标签  
getTags(callback(ret, err))

#### callback(ret, err)

ret：

- 类型：JSON 对象
- 内部字段：

```js
{ 
    tags: [tag1, tag2],
    errorCode:  1  // 1成功，0失败
 }
```

#### 示例代码

```js
var pushApi = api.require('mobPushPlus');
pushApi.getTags(function(ret, err){
    var err_code = ret.errorCode; // 0 失败， 1 成功
    var tags = ret.tags;
    api.toast({
        msg: err_code ? "获取标签：" + tags + "成功" : "获取标签失败",
        location: 'middle'
    });
});
```

#### 可用性

iOS系统，Android系统

可提供的1.0.0及更高版本


<div id="a5"></div>
### **addTags**

添加标签
addTags({params}, callback(ret, err))

#### params
tags：

- 类型：数组
- 描述：添加的标签组合

#### callback(ret, err)

ret：

- 类型：JSON 对象
- 内部字段：

```js
{ 
        errorCode :  1
 }
```

#### 示例代码

```js
var pushApi = api.require('mobPushPlus');
var tags = ["tag1", "tag2"];
pushApi.addTags({
    tags : tags
}, function(ret, err){
    var err_code = ret.errorCode; // 0 失败， 1 成功
    api.toast({
        msg: err_code ? "添加标签："+ tags +"成功" : "添加标签失败",
        location: 'middle'
    });
});
```

#### 可用性

iOS系统，Android系统

可提供的1.0.0及更高版本

<div id="a6"></div>
### **deleteTags**

删除指定标签
deleteTags({params}, callback(ret, err))

#### params
tags：

- 类型：数组
- 描述：删除的标签组合

#### callback(ret, err)

ret：

- 类型：JSON 对象
- 内部字段：

```js
{ 
        errorCode :  1
 }
```

#### 示例代码

```js
var tags = ["tag1"];
var pushApi = api.require('mobPushPlus');
pushApi.deleteTags({
     tags : tags
}, function(ret, err){
    var err_code = ret.errorCode; // 0 失败， 1 成功
    api.toast({
        msg: err_code ? "删除标签：" + tags + "成功" : "删除标签失败",
        location: 'middle'
    });
});
```

#### 可用性

iOS系统，Android系统

可提供的1.0.0及更高版本

<div id="a7"></div>
### **cleanTags**

清空所有标签
cleanTags(callback(ret, err))

#### callback(ret, err)

ret：

- 类型：JSON 对象
- 内部字段：

```js
{ 
        errorCode :  1
 }
```

#### 示例代码

```js
var pushApi = api.require('mobPushPlus');
pushApi.cleanAllTags(function(ret, err){
    var err_code = ret.errorCode; // 0 失败， 1 成功
    api.toast({
        msg: err_code ? "清空所有标签成功" : "清空所有标签失败",
        location: 'middle'
    });
});
```

#### 可用性

iOS系统，Android系统

可提供的1.0.0及更高版本

<div id="a8"></div>
### **getRegistrationID**

获取 RegistrationID
getRegistrationID(callback(ret, err))

#### callback(ret, err)

ret：

- 类型：JSON 对象
- 内部字段：

```js
 { 
    regId: '02393ebsikk9'
 }
```

#### 示例代码

```js
var pushApi = api.require('mobPushPlus');
pushApi.getRegistrationID(function(ret, err){
    var regId = ret.regId; // reg有值成功，否则失败
    api.toast({
        msg: regId ? "获取regId："+ regId +"成功" : "获取regId失败",
        location: 'middle'
    });
});
```

#### 可用性

iOS系统，Android系统

可提供的1.0.0及更高版本

<div id="a9"></div>
### **setAlias**

设置别名
setAlias({params}, callback(ret, err))

#### params

alias：

- 类型：字符串
- 描述：别名字符串

#### callback(ret, err)

ret：

- 类型：JSON 对象
- 内部字段：

```js
{ 
    errorCode :  0
}
```

#### 示例代码

```js
var pushApi = api.require('mobPushPlus');
var alias = "小王";
pushApi.setAlias({
    alias : alias
},function(ret, err){
    var err_code = ret.errorCode; // 0 失败， 1 成功
    api.toast({
      msg: err_code ? "设置别名："+ alias +"成功" : "设置别名失败",
      location: 'middle'
    });
});
```

#### 可用性

iOS系统，Android系统

可提供的1.0.0及更高版本

<div id="a10"></div>
### **deleteAlias**

删除别名
deleteAlias(callback(ret, err))

#### callback(ret, err)

ret：

- 类型：JSON 对象
- 内部字段：

```js
{ 
    errorCode :  0
}
```

#### 示例代码

```js
var pushApi = api.require('mobPushPlus');
pushApi.deleteAlias(function(ret, err){
    var err_code = ret.errorCode; // 0 失败， 1 成功
    api.toast({
        msg: err_code ? "删除别名成功" : "删除别名失败",
        location: 'middle'
    });
});
```

#### 可用性

iOS系统，Android系统

可提供的1.0.0及更高版本

<div id="a11"></div>
### **getAlias**

获取别名
getAlias(callback(ret, err))

#### callback(ret, err)

ret：

- 类型：JSON 对象
- 内部字段：

```js
{ 
    errorCode :  0
}
```

#### 示例代码

```js
var pushApi = api.require('mobPushPlus');
pushApi.getAlias(function(ret, err){
    var err_code = ret.errorCode; // 0 失败， 1 成功
    var alias = ret.alias;
    api.toast({
        msg: err_code ? "获取别名：" + alias + "成功" : "获取别名失败",
        location: 'middle'
    });
});
```

#### 可用性

iOS系统，Android系统

可提供的1.0.0及更高版本

<div id="a12"></div>
### **bindPhoneNum**

绑定手机号
bindPhoneNum({params}, callback(ret, err))

#### params

phoneNum：

- 类型：字符串
- 描述：手机号字符串

#### callback(ret, err)

ret：

- 类型：JSON 对象
- 内部字段：

```js
{ 
    errorCode :  0
}
```

#### 示例代码

```js
var pushApi = api.require('mobPushPlus');
var phoneNum = "110";
pushApi.bindPhoneNum({
    phoneNum : phoneNum
},function(ret, err){
    var err_code = ret.errorCode; // 0 失败， 1 成功
    api.toast({
        msg: err_code ? "绑定手机号："+ phoneNum + "成功" : "绑定手机号失败",
        location: 'middle'
    });
});
```

#### 可用性

iOS系统，Android系统

可提供的1.0.0及更高版本

<div id="a13"></div>
### **sendMessage**

发送推送
sendMessage({params}, callback(ret, err))

#### params

msgType：

- 类型：数字
- 描述：消息类型: 1 apns, 2 自定义消息， 3 定时 apns

content：

- 类型：字符串
- 描述：模拟发送内容

space：

- 类型：数字
- 描述：定时消息时间（仅对定时消息有效，单位分钟，默认值为1）

extras：

- 类型：字典
- 描述：额外字段，用于自定义字段添加

#### callback(ret, err)

ret：

- 类型：JSON 对象
- 内部字段：

```js
{ 
    errorCode :  0
}
```

#### 示例代码

```js
var pushApi = api.require('mobPushPlus');
pushApi.sendMessage({
    msgType:  1, //消息类型: 1 apns, 2 自定义消息， 3 定时 apns
    content: '远程推送', // 模拟发送内容
    space:  2, // 定时消息时间（仅对定时消息有效，单位分钟，默认值为1）
    extras: { } // 额外字段
},function(ret, err){
    var err_code = ret.errorCode; // 0 失败， 1 成功
    api.toast({
        msg: err_code ? "发送APNs成功" : "发送APNs失败",
        location: 'middle'
    });
});
```

#### 可用性

iOS系统，Android系统

可提供的1.0.0及更高版本


### GitHub

[点击此处]()





