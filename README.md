# ElectricFence
电子围栏,区域监听demo
#### 1.前言:
* 这篇的主题写的不是基础实现,如果想看入门篇可以看下面的文章:
[iOS地图 -- 区域监听的实现和小练习](https://www.cnblogs.com/gchlcc/p/5844028.html)
[Core Location 电子围栏：入门](https://blog.csdn.net/kmyhy/article/details/81665195)
* 当然,如果你集成的是三方框架,比如百度地图和高德地图,那你就照着官方文档来.
* 这篇主要是记录我在实践的过程中遇到的一些疑问以及解决的过程.这其中的点是网上一些入门文章没有提到.所以一方面是对自己的总结方便以后温故而知新,另一方面也希望可以帮到一些刚接触这方面的人
#### 2.关于位置访问权限的问题:
* 电子围栏功能需要用户同意**"始终访问"**这一项,**"仅使用期间"**和**"拒绝访问"**这两个权限都会使该功能不能达到预期的效果,会有问题.拒绝状态直接导致该功能无法使用.仅使用期间会导致App退到后台或者在控制中心手动杀掉后不能正常使用.
* 所以,每次使用该功能前,最好获取一下用户的权限设置,如果是拒绝状态可以提示用户,并引导跳转到权限设置界面.如果是仅使用期间状态,可以给与用户提示切换成始终访问权限.
#### 3.关于CLRegion:
请使用CLRegion的子类,比如:CLCircularRegion.
#### 4.核心代码(swift为例):
```
// 创建监听区域
let region = CLCircularRegion.init(center: coordinate, radius: distance, identifier: type.rawValue)
// 开始监听
self.locationManager.startMonitoring(for: region)
// 延时2秒后获取围栏状态(为什么延时,请看后文)
DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
  self.locationManager.requestState(for: region)
}
```
* 调用startMonitoring开始监听.设置代理后主要关注以下代理回调:
```
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("...进入电子围栏...")
    }
    
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("...离开电子围栏...")
    }
    
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print("...监听围栏失败:\(region!), error:\(error)")
    }
    
    
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        print("...开始监听...")
    }
```
* 调用requestState方法可以获取到当前位置状态,设置代理后会执行以下代理回调:
```
    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        let regionType = RegionType.init(rawValue: region.identifier)
        guard regionType != .unknown else {return}
        let str = state == .inside ? "状态: 电子围栏内" : (state == .outside ? "状态: 电子围栏外" : "状态: 未知")
        if regionType == .company
        {
            self.clabel.text = str
        }
        else
        {
            self.hLabel.text = str
        }
    }
```
#### 5.关于监听电子围栏数量问题:
* 一个App最多只能同时监听20个电子围栏,超过后会走monitoringDidFail回调.会报(Domain=kCLErrorDomain Code=5)的错误提示.
#### 6.关于startMonitoring方法和requestState方法的区别,以及为何要requestState延时调用问题
* 对于startMonitoring和requestState的区别,这里是我自己的一些理解,可能对可能不对,仅供参考.
* startMonitoring调用后,即就开始了围栏的监听,只要没有移除监听,一旦状态发生变化,就会走对应的代理回调方法.
* requestState看官方注释不难理解,异步的获取当前电子围栏的状态(是否在电子围栏内,是否在电子围栏外和未知状态).
* 一般我们使用startMonitoring开启区域监听后,都会调用requestState来获取一下初始状态.为何延时是因为如果立即调用的话,会有概率报(Domain=kCLErrorDomain Code=5)的错误提,导致获取失败.
#### 7.针对在始终访问权限下App被销毁后,关于移除电子围栏你需要注意的问题
* 首先提两个问题,如果我监听了某个区域,然后在控制中心销毁了App.请问此时,这个区域监听的功能还生效吗?下一次进入App的时候,是否需要重新监听.
* 针对第一个问题.通过代码测试后,我得到了以下结果.当处于"始终访问位置"权限时,只要没有通过代码来移除监听,即使App被销毁了.系统还是会继续处于监听状态.这个通过手机屏幕状态栏左上角位置访问小角标并没有消失就可以确定![880DC4D0F5DD8C41F766C1D797404985.png](https://upload-images.jianshu.io/upload_images/3096223-36136684c6432651.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
* 针对第二个问题:CLLocationManager有一个可以获取当前监听了哪些电子围栏的集合.
![4FC4D04F-3CBD-4D40-87BB-44DA132CA769.png](https://upload-images.jianshu.io/upload_images/3096223-6b4dec441c1ce49a.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
>实践:
1.当我没有开始监听时,获取此集合的count = 0;
2.当我开启一个电子围栏后,销毁App.然后重启App.获取此集合的count = 1
结论:
App被销毁后,下次重启App.之前没有移除的电子围栏仍然处于监听状态.不需要重新添加.
**所以:这里需要特别注意,前面提到了一个App最多只能监听20个区域.因此电子围栏的监听和移除管理,自己要心里特别清晰.哪些不用了需要及时移除,否则会占用不必要的名额.另外一点就是,如果某个电子围栏不需要监听了请及时移除,否则,即使用户销毁了App,仍然还是会占用系统资源,背地里在使用用户的位置权限.作为强迫症的我可受不了.**
#### 8.最后再说一下didEnterRegion和didExitRegion这两个代理回调的执行
* 一个是进入电子围栏会触发,一个是离开电子围栏会触发
* app处于后台,状态发生改变了.回调是否会调用 --> 答案是会的
* app被销毁后,电子围栏处于监听状态,状态发生改变后,回调是否会被调用 --> 我之前心里想着是不会,因为App都被销毁了,内部代码应该不会执行吧.结果我通过注册本地通知的方式来验证后,答案是依然会执行.
代码如下:
```
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("...进入电子围栏...")
        self.locationManager.requestState(for: region)
        let type = RegionType.init(rawValue: region.identifier)!
        let str = type == .home ? "🏠" : "公司"
        self.addLocalNotification(body: "你已经进入\(str)电子围栏内")
    }
    
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("...离开电子围栏...")
        self.locationManager.requestState(for: region)
        let type = RegionType.init(rawValue: region.identifier)!
        let str = type == .home ? "🏠" : "公司"
        self.addLocalNotification(body: "你已经离开\(str)电子围栏")
    }
```
代码思路很简单,我把注册本地通知的代码写在了代理回调里.如果回调执行了,那么本地通知就能注册成功,我就能收到通知.如果不执行,本地通知就不会被注册,我就收不到通知.最后结果如图:
![0927B894-6F6A-4D3D-A22F-25E0D8A8ABB4.png](https://upload-images.jianshu.io/upload_images/3096223-6a7cc11a801ef47c.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

#### 9.写在最后
在验证上文那些内容的时候,我顺带写了一个小项目,demo里弄了2个电子围栏,一个是公司的一个是租房的.每天上下班可以监听我是否到公司了,是否到家了.无论是离开还是进入电子围栏都会给我发个本地通知.然后就是当时Domain=kCLErrorDomain Code=5这个问题困住了我许久.解决的时候参考了以下文章(其实没帮到我什么,但是code=5的原因很多,如果你也遇到了,也许这里会有你想要的):
* https://github.com/evothings/phonegap-estimotebeacons/issues/94
* https://stackoverflow.com/questions/17733875/corelocation-kclerrordomain-error-5

[最后附上简书地址,欢迎留言交流](https://www.jianshu.com/p/e7015207ecef)
