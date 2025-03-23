import Foundation
import Combine

enum NetworkError: Error {
    case invalidURL
    case requestFailed(Error)
    case invalidResponse
    case decodingFailed(Error)
    case serverError(Int)
    case noData
    case timeout
    
    var localizedDescription: String {
        switch self {
        case .invalidURL: 
            return "无效的URL"
        case .requestFailed(let error): 
            return "请求失败: \(error.localizedDescription)"
        case .invalidResponse: 
            return "无效的服务器响应"
        case .decodingFailed(let error): 
            return "数据解析失败: \(error.localizedDescription)"
        case .serverError(let code): 
            return "服务器错误: \(code)"
        case .noData: 
            return "没有返回数据"
        case .timeout: 
            return "请求超时"
        }
    }
}

class NetworkService {
    static let shared = NetworkService()
    
    private let baseURL = "https://api.footiekick.com/v1"
    private let session: URLSession
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 5.0  // 5秒超时
        config.timeoutIntervalForResource = 10.0
        config.waitsForConnectivity = true
        
        session = URLSession(configuration: config)
    }
    
    // MARK: - 组合式API请求方法
    func request<T: Decodable>(
        endpoint: String,
        method: HTTPMethod = .get,
        parameters: [String: Any]? = nil,
        retryCount: Int = 3
    ) async throws -> T {
        guard var urlComponents = URLComponents(string: baseURL + endpoint) else {
            throw NetworkError.invalidURL
        }
        
        // 添加GET参数
        if method == .get, let parameters = parameters {
            urlComponents.queryItems = parameters.map { 
                URLQueryItem(name: $0.key, value: "\($0.value)")
            }
        }
        
        guard let url = urlComponents.url else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // 添加请求体
        if method != .get, let parameters = parameters {
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
            } catch {
                throw NetworkError.requestFailed(error)
            }
        }
        
        var currentRetry = 0
        
        while true {
            do {
                let (data, response) = try await session.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.invalidResponse
                }
                
                switch httpResponse.statusCode {
                case 200...299:
                    do {
                        let decoder = JSONDecoder()
                        decoder.dateDecodingStrategy = .iso8601
                        return try decoder.decode(T.self, from: data)
                    } catch {
                        throw NetworkError.decodingFailed(error)
                    }
                case 401:
                    // 此处可添加刷新认证Token的逻辑
                    throw NetworkError.serverError(httpResponse.statusCode)
                case 429:
                    // 限流处理，可以增加延迟再重试
                    if currentRetry < retryCount {
                        currentRetry += 1
                        try await Task.sleep(nanoseconds: UInt64(1_000_000_000))  // 延迟1秒
                        continue
                    }
                    throw NetworkError.serverError(httpResponse.statusCode)
                default:
                    throw NetworkError.serverError(httpResponse.statusCode)
                }
            } catch let error as NetworkError {
                throw error
            } catch {
                if error is URLError && currentRetry < retryCount {
                    currentRetry += 1
                    continue
                }
                throw NetworkError.requestFailed(error)
            }
        }
    }
}

// HTTP方法枚举
enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
} 