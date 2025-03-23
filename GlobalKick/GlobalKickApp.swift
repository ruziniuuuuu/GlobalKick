//
//  GlobalKickApp.swift
//  GlobalKick
//
//  Created by 孺子牛 on 2025/3/23.
//

import SwiftUI
import UserNotifications

@main
struct GlobalKickApp: App {
    // 应用生命周期代理
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    // 场景阶段
    @Environment(\.scenePhase) var scenePhase
    
    // 用户设置
    @StateObject private var preferencesService = UserPreferencesService.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(preferencesService.useDarkMode ? .dark : .light)
                .onAppear {
                    // 配置全局外观
                    configureAppearance()
                }
                .onChange(of: scenePhase) { newPhase in
                    switch newPhase {
                    case .active:
                        print("应用进入活跃状态")
                    case .inactive:
                        print("应用进入非活跃状态")
                    case .background:
                        print("应用进入后台")
                    @unknown default:
                        print("未知的场景阶段")
                    }
                }
        }
    }
    
    // 配置全局UI外观
    private func configureAppearance() {
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
        
        // 配置Tab Bar外观
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        
        // 设置全局颜色
        UITabBar.appearance().tintColor = UIColor.systemBlue
        UINavigationBar.appearance().tintColor = UIColor.systemBlue
    }
}

// 应用代理
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // 应用启动配置
        configurePushNotifications(application)
        
        // 加载初始数据
        preloadInitialData()
        
        return true
    }
    
    // 配置推送通知
    private func configurePushNotifications(_ application: UIApplication) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    application.registerForRemoteNotifications()
                }
            }
        }
    }
    
    // 预加载必要数据
    private func preloadInitialData() {
        Task {
            // 这里可以预加载必要的数据
            // 例如: 检查和下载翻译模型
            try? await TranslationService.shared.downloadModelIfNeeded(for: .chineseSimplified)
        }
    }
    
    // 推送通知令牌
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // 将设备令牌发送到服务器
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("设备推送令牌: \(tokenString)")
    }
    
    // 推送通知注册失败
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("推送通知注册失败: \(error.localizedDescription)")
    }
}
