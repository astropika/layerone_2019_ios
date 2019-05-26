//
//  config.swift
//  layerone2019swift

import Foundation


struct AlarmSetting {
    var faces:Int
    var period:CFTimeInterval
    var cooldown:CFTimeInterval
}

struct AlarmTrigger {
    var period:Double
    var start:Date
}


class Config
{

   var prefs = [
        "badge_url": "http://192.168.4.1/jpg_stream",
        "prerotate": 0,
        "url_working": false,
        "error_tries": 4,
        "debug": false] as [String : Any]

    
    init() {
        let defaults = UserDefaults.standard
        if  defaults.string(forKey: "badge_url") == nil {
            UserDefaults.standard.set(prefs["badge_url"], forKey: "badge_url")
        }
        if (defaults.object(forKey: "prerotate") == nil) {
            UserDefaults.standard.set(prefs["prerotate"], forKey: "prerotate")
        }
        //actually really irritating having this set persistently
        alarm = nil
    }
    
    var url_working: Bool {
        get {
            return prefs["url_working"] as! Bool
        }
        set {
            prefs["url_working"] = newValue
        }
    }
    
    var error_tries: Int {
        get {
            return prefs["error_tries"] as! Int
        }
        set {
            prefs["error_tries"] = newValue
        }
    }
    
    var debug: Bool {
        get {
            return prefs["debug"] as! Bool
        }
        set {
            prefs["debug"] = newValue
        }
    }
    
    var badge_url: String
    {
        set {
            UserDefaults.standard.set(newValue, forKey: "badge_url")
        }
        get {
            return UserDefaults.standard.string(forKey: "badge_url") ?? prefs["badge_url"] as! String
        }
    }

    
    var prerotate: Int
    {
        set {
            UserDefaults.standard.set(newValue, forKey: "prerotate")
        }
        get {
            return UserDefaults.standard.integer(forKey: "prerotate") ?? prefs["prerotate"] as! Int        }
    }
    
    var alarm:AlarmSetting?
    {
        set {
            if newValue != nil {
                let alarmdict = ["faces": newValue!.faces, "period": newValue!.period, "cooldown":newValue!.cooldown] as [String : Any]
                UserDefaults.standard.set(alarmdict, forKey: "alarm")
            }
            else {
                UserDefaults.standard.removeObject(forKey: "alarm")
            }
        }
        get {
            let alarm = UserDefaults.standard.dictionary(forKey: "alarm")
            if alarm != nil {
                var retalarm = AlarmSetting( faces: alarm!["faces"] as! Int, period: alarm!["period"] as! CFTimeInterval, cooldown: alarm!["cooldown"] as! CFTimeInterval)
                return retalarm
            }
            else {
                return nil
            }
        }
    }

}
