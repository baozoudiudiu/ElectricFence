//
//  ViewController.swift
//  RegionObserve
//
//  Created by 罗泰 on 2019/1/7.
//  Copyright © 2019 chenwang. All rights reserved.
//

import UIKit
import CoreLocation
import UserNotifications

enum RegionType: String {
    case unknown
    case company = "homeRegionId"
    case home = "companyRegionId"
}


class ViewController: UIViewController {
    
    //MARK: - 属性
    lazy var locationManager: CLLocationManager = {
        let manager = CLLocationManager.init()
        manager.allowsBackgroundLocationUpdates = true
        manager.distanceFilter = 1
        manager.desiredAccuracy = kCLLocationAccuracyBest
        return manager
    }()
    lazy var companyCoordinate: CLLocationCoordinate2D = {
        return CLLocationCoordinate2D.init(latitude: 31.268948472562446, longitude: 121.51801651608812)
    }()
    lazy var homeCoordinate: CLLocationCoordinate2D = {
        return CLLocationCoordinate2D.init(latitude: 31.2563307022, longitude: 121.4418733120)
    }()
    @IBOutlet var clabel: UILabel!
    @IBOutlet var hLabel: UILabel!
    @IBOutlet var cSwitch: UISwitch!
    @IBOutlet var hSwitch: UISwitch!
    
    //MARK: - 生命周期
    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureUI()
        print("count->\(self.locationManager.monitoredRegions.count)")
        self.getLocation()
    }
}


// MARK: - ConfigureUI
extension ViewController {
    private func configureUI() {
        self.valueChangedBy(switchSender: self.cSwitch)
        self.valueChangedBy(switchSender: self.hSwitch)
        self.cSwitch.isOn = UserDefaults.standard.bool(forKey: RegionType.company.rawValue)
        self.hSwitch.isOn = UserDefaults.standard.bool(forKey: RegionType.home.rawValue)
    }
    
    
    @objc private func switchValueChanged(_ switchSender: UISwitch) {
        let on = switchSender.isOn
        var type: RegionType = .unknown
        var execute = true
        switch switchSender.tag
        {
        case 0:
            type = .company
        case 1:
            type = .home
        default:
            execute = false
        }
        UserDefaults.standard.set(switchSender.isOn, forKey: type.rawValue)
        UserDefaults.standard.synchronize()
        guard execute else {return}
        if on { self.addRegion(type: type);print("count->\(self.locationManager.monitoredRegions.count)")}
        else { self.removeRegion(type: type);print("count->\(self.locationManager.monitoredRegions.count)")}
    }
    
    
    private func valueChangedBy(switchSender: UISwitch) {
        switchSender.addTarget(self, action: #selector(switchValueChanged(_:)), for: .valueChanged)
    }
}


// MARK: - 业务逻辑
extension ViewController {
    private func addLocalNotification(body: String) {
        let content = UNMutableNotificationContent.init()
        content.title = "电子围栏监控"
        content.body = body
        content.sound = UNNotificationSound.default
        let trigger = UNTimeIntervalNotificationTrigger.init(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest.init(identifier: body, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { (error) in
            if error != nil
            {
                print("本地推送注册失败...")
            }
        }
    }
    
    
    private func addLocalNotification(region: CLRegion, type: RegionType) {
        let content = UNMutableNotificationContent.init()
        content.title = "电子围栏监控(0.0)"
        content.body = "region触发" + (type == .home ? "🏠" : "公司")
        content.sound = UNNotificationSound.default
        let trigger = UNLocationNotificationTrigger.init(region: region, repeats: false)
        let request = UNNotificationRequest.init(identifier: type.rawValue, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { (error) in
            if error != nil
            {
                print("本地推送注册失败...")
            }
        }
    }
}


// MARK: - CLLlocation相关
extension ViewController {
    private func getLocation() {
        guard CLLocationManager.locationServicesEnabled() else { self.alertString("...定位服务不可用..."); return}
        self.locationManager.delegate = self
        self.locationManager.requestAlwaysAuthorization()
        self.locationManager.startUpdatingLocation()
    }
    
    private func addRegion(type: RegionType) {
        guard type != .unknown else { self.alertString("电子围栏监听类型有误!");return}
        self.removeRegion(id: type.rawValue)
        guard CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) else { self.alertString("...不支持区域监听..."); return }
        let distance: CLLocationDistance = 60
        let coordinate = type == .company ? self.companyCoordinate : self.homeCoordinate
        let region = CLCircularRegion.init(center: coordinate, radius: distance, identifier: type.rawValue)
        self.locationManager.startMonitoring(for: region)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.locationManager.requestState(for: region)
        }
        self.addLocalNotification(region: region, type: type)
    }
    
    
    private func removeRegion(type: RegionType) {
        self.removeRegion(id: type.rawValue)
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [type.rawValue])
    }
    
    
    private func removeRegion(id: String?) {
        guard id != nil else
        {
            for region in self.locationManager.monitoredRegions
            {
                self.locationManager.stopMonitoring(for: region)
            }
            return
        }
        for region in self.locationManager.monitoredRegions
        {
            if region.identifier == id!
            {
                self.locationManager.stopMonitoring(for: region)
                break;
            }
        }
    }
}



// MARK: - 定位代理和电子围栏代理
extension ViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.locationManager.stopUpdatingLocation()
        for location in locations
        {
            print("ccww: \(location.coordinate)")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.alertString("...定位失败...")
        self.locationManager.stopUpdatingLocation()
    }
    
    
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
    
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print("...监听围栏失败:\(region!), error:\(error)")
        manager.requestState(for: region!)
    }
    
    
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        print("...开始监听...")
    }
    
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
}


// MARK: - Helper
extension ViewController {
    private func alertString(_ str: String) {
        let alertController = UIAlertController.init(title: "提示", message: str, preferredStyle: .alert)
        let closeAction = UIAlertAction.init(title: "关闭", style: .cancel, handler: nil)
        alertController.addAction(closeAction)
        self.present(alertController, animated: true, completion: nil)
    }
}
