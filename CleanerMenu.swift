import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var cpuItem: NSMenuItem!
    var memoryItem: NSMenuItem!
    var diskItem: NSMenuItem!
    var uptimeItem: NSMenuItem!
    var topEater1: NSMenuItem!
    var topEater2: NSMenuItem!
    var topEater3: NSMenuItem!
    var timer: Timer!
    var reduceFX = false
    var vmCache: (free: Double, active: Double, wired: Double, inactive: Double, spec: Double, compressed: Double)?
    var vmCacheTime: Date = .distantPast

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        let menu = NSMenu()
        menu.delegate = self

        cpuItem = NSMenuItem(title: "⚡ CPU: ...", action: nil, keyEquivalent: "")
        menu.addItem(cpuItem)

        memoryItem = NSMenuItem(title: "🧠 Memory: ...", action: nil, keyEquivalent: "")
        menu.addItem(memoryItem)

        diskItem = NSMenuItem(title: "💾 Disk: ...", action: nil, keyEquivalent: "")
        menu.addItem(diskItem)

        uptimeItem = NSMenuItem(title: "⏱ Uptime: ...", action: nil, keyEquivalent: "")
        menu.addItem(uptimeItem)

        let procsHeader = NSMenuItem(title: "─── TOP PROCESSES ───", action: nil, keyEquivalent: "")
        procsHeader.attributedTitle = NSAttributedString(string: "  TOP PROCESSES  ", attributes: [
            .font: NSFont.boldSystemFont(ofSize: 10),
            .foregroundColor: NSColor.systemGray
        ])
        menu.addItem(procsHeader)

        topEater1 = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        menu.addItem(topEater1)

        topEater2 = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        menu.addItem(topEater2)

        topEater3 = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        menu.addItem(topEater3)

        menu.addItem(NSMenuItem.separator())

        addItem(menu, title: "🧹  Clear Inactive Memory", action: #selector(purgeMemory), key: "p")
        addItem(menu, title: "⚡  Auto Free Memory (>80%)", action: #selector(autoFreeMemory), key: "m")
        addItem(menu, title: "💿  Free Purgeable Disk Space", action: #selector(freeDiskSpace), key: "d")
        addItem(menu, title: "🗑  Empty Trash", action: #selector(emptyTrash), key: "t")
        addItem(menu, title: "🌐  Clear DNS Cache", action: #selector(flushDNS), key: "n")
        addItem(menu, title: "🧼  Deep Clean", action: #selector(deepClean), key: "l")

        menu.addItem(NSMenuItem.separator())

        addItem(menu, title: "🔄  Restart Finder", action: #selector(restartFinder), key: "r")
        addItem(menu, title: "💀  Kill Heavy Apps", action: #selector(killHeavy), key: "k")
        addItem(menu, title: "📦  Kill Dev Servers", action: #selector(killDevServers), key: "z")
        addItem(menu, title: "☠️  Kill Everything", action: #selector(killEverything), key: "e")

        menu.addItem(NSMenuItem.separator())

        reduceFX = UserDefaults.standard.bool(forKey: "reduceFX")
        let fxItem = addItem(menu, title: "🎨  Reduce Animations: \(reduceFX ? "ON" : "OFF")", action: #selector(toggleAnimations), key: "v")
        fxItem.tag = 42

        menu.addItem(NSMenuItem.separator())

        let brandItem = NSMenuItem(title: "🧹 CleanerMenu · STAGSTER LABS", action: nil, keyEquivalent: "")
        brandItem.attributedTitle = NSAttributedString(string: "  CleanerMenu · STAGSTER LABS", attributes: [
            .font: NSFont.systemFont(ofSize: 9),
            .foregroundColor: NSColor.systemGray
        ])
        menu.addItem(brandItem)

        let quitItem = NSMenuItem(title: "🚪  Quit", action: #selector(NSApp.terminate), keyEquivalent: "q")
        quitItem.target = NSApp
        menu.addItem(quitItem)

        statusItem.menu = menu
        refresh()
        timer = Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(refresh), userInfo: nil, repeats: true)
    }

    @discardableResult
    func addItem(_ menu: NSMenu, title: String, action: Selector, key: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = self
        menu.addItem(item)
        return item
    }

    @objc func refresh() {
        updateCPU()
        updateMemory()
        updateDisk()
        updateUptime()
        updateTopEaters()
        updateMenuBar()
    }

    func getVMStat() -> (free: Double, active: Double, wired: Double, inactive: Double, spec: Double, compressed: Double) {
        if let c = vmCache, Date().timeIntervalSince(vmCacheTime) < 0.8 { return c }
        let out = shell("/usr/bin/vm_stat")
        let lines = out.components(separatedBy: "\n")
        var free = 0.0, active = 0.0, wired = 0.0, inactive = 0.0, spec = 0.0, compressed = 0.0
        for line in lines {
            let parts = line.components(separatedBy: ":").map { $0.trimmingCharacters(in: .whitespaces) }
            guard parts.count == 2, let v = Double(parts[1].replacingOccurrences(of: ".", with: "").trimmingCharacters(in: .whitespaces)) else { continue }
            if parts[0].hasPrefix("Pages free") { free = v }
            else if parts[0].hasPrefix("Pages active") { active = v }
            else if parts[0].hasPrefix("Pages wired") { wired = v }
            else if parts[0].hasPrefix("Pages inactive") { inactive = v }
            else if parts[0].hasPrefix("Pages speculative") { spec = v }
            else if parts[0].hasPrefix("Pages occupied by compressor") { compressed = v }
        }
        let c = (free, active, wired, inactive, spec, compressed)
        vmCache = c; vmCacheTime = Date()
        return c
    }

    func updateMenuBar() {
        let s = getVMStat()
        let avail = s.free + s.inactive + s.spec
        let total = avail + s.active + s.wired + s.compressed
        let availPct = total > 0 ? Int(avail / total * 100) : 0
        let pressureStr = availPct < 3 ? "🟡MEM" : "🟢MEM"
        let color: NSColor = availPct < 3 ? .systemYellow : .systemGreen
        let str = NSMutableAttributedString()
        str.append(NSAttributedString(string: "🧹", attributes: [.font: NSFont.systemFont(ofSize: 11)]))
        str.append(NSAttributedString(string: pressureStr, attributes: [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 9, weight: .medium),
            .foregroundColor: color
        ]))
        statusItem.button?.attributedTitle = str
    }

    func updateCPU() {
        var cpuLoad = host_cpu_load_info()
        var count = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info>.stride / MemoryLayout<integer_t>.stride)
        let result = withUnsafeMutablePointer(to: &cpuLoad) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return }

        let user = Double(cpuLoad.cpu_ticks.0)
        let system = Double(cpuLoad.cpu_ticks.1)
        let idle = Double(cpuLoad.cpu_ticks.2)
        let nice = Double(cpuLoad.cpu_ticks.3)
        let totalTicks = max(user + system + idle + nice, 1)
        let usedPct = Int((user + system + nice) / totalTicks * 100)
        cpuItem.title = "⚡ CPU: \(usedPct)%"
    }

    func updateMemory() {
        let s = getVMStat()
        let ps: Double = 16384
        let usedMB = (s.active + s.wired + s.compressed) * ps / 1048576
        let availMB = (s.free + s.inactive + s.spec) * ps / 1048576
        let total = usedMB + availMB
        let pct = total > 0 ? Int(usedMB / total * 100) : 0
        memoryItem.title = String(format: "🧠 Memory: %.0f MB free / %.0f MB (%d%%)", availMB, total, pct)
    }

    func updateDisk() {
        let out = shell("/bin/df", args: ["-k", "/"])
        let lines = out.components(separatedBy: "\n")
        if lines.count >= 2 {
            let parts = lines[1].components(separatedBy: .whitespaces).filter { !$0.isEmpty }
            if parts.count >= 4, let totalKB = Double(parts[1]), let usedKB = Double(parts[2]), let _ = Double(parts[3]) {
                let totalGB = Int(totalKB / 1_000_000)
                let usedGB = Int(usedKB / 1_000_000)
                let pct = totalGB > 0 ? Int(usedKB / totalKB * 100) : 0
                diskItem.title = "💾 Storage: \(usedGB) GB used / \(totalGB) GB (\(pct)%)"
            }
        }
    }

    func updateUptime() {
        var boot = timeval()
        var size = MemoryLayout<timeval>.stride
        sysctlbyname("kern.boottime", &boot, &size, nil, 0)
        let uptime = Date().timeIntervalSince1970 - Double(boot.tv_sec)
        let days = Int(uptime) / 86400
        let hours = (Int(uptime) % 86400) / 3600
        let mins = (Int(uptime) % 3600) / 60
        if days > 0 {
            uptimeItem.title = "⏱ Uptime: \(days)d \(hours)h \(mins)m"
        } else {
            uptimeItem.title = "⏱ Uptime: \(hours)h \(mins)m"
        }
    }

    func updateTopEaters() {
        let psOut = shell("/bin/ps", args: ["-arc", "-eo", "%mem,comm"])
        var eaters = [(mem: Double, name: String)]()
        for line in psOut.components(separatedBy: "\n").dropFirst() {
            let parts = line.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
            if parts.count >= 2, let mem = Double(parts[0]) {
                eaters.append((mem, parts[1]))
            }
        }
        eaters.sort { $0.mem > $1.mem }
        let top = Array(eaters.prefix(3))
        let labels = [topEater1!, topEater2!, topEater3!]
        for (i, label) in labels.enumerated() {
            if i < top.count {
                label.title = String(format: "   %@  %.1f%%", top[i].name, top[i].mem)
            } else {
                label.title = ""
            }
        }
    }

    @objc func purgeMemory() {
        runSudo("/usr/sbin/purge")
        notify("Inactive memory cleared!")
    }

    @objc func freeDiskSpace() {
        runSudo("/usr/sbin/diskutil", args: ["apfs", "purge", "/"])
        notify("Purgeable disk space freed!")
    }

    @objc func restartFinder() {
        _ = shell("/usr/bin/killall", args: ["Finder"])
        notify("Finder restarted!")
    }

    @objc func autoFreeMemory() {
        var pct = memoryUsagePct()
        if pct < 80 {
            notify("Memory at \(pct)% — no action needed (below 80%)")
            return
        }

        runSudo("/usr/sbin/purge")
        pct = memoryUsagePct()

        if pct < 80 {
            notify("Memory dropped to \(pct)% after purge — no processes killed")
            refresh()
            return
        }

        let psOut = shell("/bin/ps", args: ["-arc", "-eo", "pid,%mem,rss,comm"])
        var procs = [(pid: String, mem: Double, name: String)]()
        for line in psOut.components(separatedBy: "\n").dropFirst() {
            let parts = line.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
            if parts.count >= 4, let mem = Double(parts[1]), mem > 2.0 {
                procs.append((parts[0], mem, parts[3]))
            }
        }
        procs.sort { $0.mem > $1.mem }

        let protected = ["WindowServer", "kernel_task", "launchd", "opencode", "CleanerMenu",
                         "Finder", "ControlCenter", "Dock", "SystemUIServer", "loginwindow",
                         "notifyd", "configd", "corebrightnessd", "powerd", "thermald",
                         "rapportd", "sharingd", "locationd", "airportd", "WiFiAgent",
                         "Spotlight", "mds", "mds_stores", "backupd", "AppleMobileDevice", "Stats"]

        var killed = [String]()
        for proc in procs {
            if killed.count >= 3 || memoryUsagePct() < 75 { break }
            let name = proc.name.lowercased()
            if protected.contains(where: { name.hasPrefix($0.lowercased()) }) { continue }
            _ = shell("/bin/kill", args: [proc.pid])
            killed.append("\(proc.name) (\(Int(proc.mem))%)")
        }

        if killed.isEmpty {
            notify("Memory stuck at \(pct)% — no killable processes found")
        } else {
            notify("Memory was \(pct)%, now \(memoryUsagePct())% — killed: \(killed.joined(separator: ", "))")
        }
        refresh()
    }

    func memoryUsagePct() -> Int {
        let s = getVMStat()
        let total = s.free + s.active + s.wired + s.inactive + s.spec + s.compressed
        return total > 0 ? Int((s.active + s.wired + s.compressed) / total * 100) : 0
    }

    @objc func killHeavy() {
        let heavy = ["Google Chrome", "Safari", "Firefox", "Slack", "Spotify", "Discord",
                     "Telegram", "WhatsApp", "Microsoft Teams", "Zoom", "Visual Studio Code",
                     "Sublime Text", "iTerm2", "Terminal", "Photoshop", "Figma", "Android Studio",
                     "Xcode", "IntelliJ IDEA", "PyCharm", "WebStorm", "Docker"]
        var killed = [String]()
        for app in heavy {
            let out = shell("/usr/bin/pkill", args: ["-f", app])
            if out == "" { killed.append(app) }
        }
        notify(killed.isEmpty ? "No heavy apps running" : "Killed: \(killed.joined(separator: ", "))")
    }

    @objc func killDevServers() {
        let patterns = ["npm run", "next-server", "node.*dev", "esbuild", "workerd", "vite", "tsx", "nodemon", "turbo"]
        var killed = [String]()
        for pattern in patterns {
            let out = shell("/usr/bin/pkill", args: ["-f", pattern])
            if out == "" { killed.append(pattern) }
        }
        notify(killed.isEmpty ? "No dev servers running" : "Killed: \(killed.joined(separator: ", "))")
    }

    @objc func flushDNS() {
        _ = shell("/usr/bin/dscacheutil", args: ["-flushcache"])
        _ = shell("/usr/bin/sudo", args: ["/usr/bin/killall", "-HUP", "mDNSResponder"])
        notify("DNS cache cleared!")
    }

    @objc func emptyTrash() {
        _ = shell("/usr/bin/osascript", args: ["-e", "tell application \"Finder\" to empty trash"])
        notify("Trash emptied!")
    }

    @objc func deepClean() {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        purgeMemory()
        emptyTrash()
        freeDiskSpace()
        _ = shell("/bin/rm", args: ["-rf", "\(home)/Library/Caches/*"])
        _ = shell("/bin/rm", args: ["-rf", "\(home)/Library/Developer/Xcode/DerivedData/*"])
        notify("Deep clean done — memory purged, caches cleared, trash emptied")
    }

    @objc func killEverything() {
        let myPid = String(ProcessInfo().processIdentifier)
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let protected = ["WindowServer", "kernel_task", "launchd", "opencode", "CleanerMenu",
                         "Finder", "ControlCenter", "Dock", "SystemUIServer", "loginwindow",
                         "notifyd", "configd", "corebrightnessd", "powerd", "thermald",
                         "rapportd", "sharingd", "locationd", "airportd", "WiFiAgent",
                         "mDNSResponder",
                         "Spotlight", "mds", "mds_stores", "backupd", "AppleMobileDevice", "Stats",
                         "logd", "syslogd", "opendirectoryd", "hidd", "usbd", "amfid", "syspolicyd"]

        runSudo("/usr/sbin/purge")
        _ = shell("/bin/rm", args: ["-rf", "\(home)/Library/Caches/*"])
        _ = shell("/usr/bin/sudo", args: ["/bin/rm", "-rf", "/Library/Caches/*"])

        var killPIDs = Set<String>()

        for app in NSWorkspace.shared.runningApplications {
            let pid = String(app.processIdentifier)
            guard let name = app.localizedName, !name.isEmpty else { continue }
            if pid == myPid { continue }
            let lower = name.lowercased()
            if protected.contains(where: { lower.hasPrefix($0.lowercased()) }) { continue }
            killPIDs.insert(pid)
        }

        let psOut = shell("/bin/ps", args: ["-arc", "-eo", "pid,%mem,rss,comm"])
        for line in psOut.components(separatedBy: "\n").dropFirst() {
            let parts = line.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
            if parts.count >= 4, let mem = Double(parts[1]), mem > 5.0 {
                let pid = parts[0]
                if killPIDs.contains(pid) { continue }
                let name = parts[3]
                let lower = name.lowercased()
                if protected.contains(where: { lower.hasPrefix($0.lowercased()) }) { continue }
                if pid == myPid { continue }
                killPIDs.insert(pid)
            }
        }

        for pid in killPIDs {
            _ = shell("/bin/kill", args: ["-9", pid])
        }

        notify("Kill Everything: \(killPIDs.count) processes killed, memory purged, caches cleared")
    }

    @objc func toggleAnimations() {
        reduceFX.toggle()
        UserDefaults.standard.set(reduceFX, forKey: "reduceFX")
        let val = reduceFX ? "true" : "false"
        _ = shell("/usr/bin/defaults", args: ["write", "NSGlobalDomain", "NSAutomaticWindowAnimationsEnabled", "-bool", val])
        _ = shell("/usr/bin/defaults", args: ["write", "NSGlobalDomain", "NSScrollAnimationEnabled", "-bool", val])
        _ = shell("/usr/bin/defaults", args: ["write", "com.apple.finder", "DisableAllAnimations", "-bool", val])
        notify("Animations \(reduceFX ? "reduced" : "restored") — restart apps to see effect")

        if let item = statusItem.menu?.item(withTag: 42) {
            item.title = "Reduce Animations: \(reduceFX ? "ON" : "OFF")"
        }
    }

    func runSudo(_ cmd: String, args: [String] = []) {
        _ = shell("/usr/bin/sudo", args: [cmd] + args)
    }

    func notify(_ msg: String) {
        let n = NSUserNotification()
        n.title = "Cleaner Menu"
        n.informativeText = msg
        NSUserNotificationCenter.default.deliver(n)
    }

    func shell(_ cmd: String, args: [String] = []) -> String {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: cmd)
        p.arguments = args
        let pipe = Pipe()
        p.standardOutput = pipe
        p.standardError = pipe
        try? p.run()
        p.waitUntilExit()
        return String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
    }
}

extension AppDelegate: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        updateCPU()
        updateTopEaters()
        updateMemory()
    }
}

NSApplication.shared.setActivationPolicy(.accessory)
let delegate = AppDelegate()
NSApplication.shared.delegate = delegate
_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
