//
//
//  Created by Todd Kerpelman on 8/18/23.
//

import Foundation
import FirebaseAuth

///
/// Just a helper class that simplifies some of the work involved in calling our server
///
class ServerCommunicator {

    enum HTTPMethod: String {
        case get = "GET"
        case post = "POST"
    }

    enum Error: LocalizedError {
        case invalidUrl(String)
        case networkError(String)
        case encodingError(String)
        case decodingError(String)
        case nilData
        case authError(String)

        var localizedDescription: String {
            switch self {
            case .invalidUrl(let url): return "Invalid URL: \(url)"
            case .networkError(let error): return "Network Error: \(error)"
            case .encodingError(let error): return "Encoding Error: \(error)"
            case .decodingError(let error): return "Decoding Error: \(error)"
            case .nilData: return "Server returned null data"
            case .authError(let error): return "Authentication Error: \(error)"
            }
        }

        var errorDescription: String? {
            return localizedDescription
        }
    }

    init(baseURL: String = "http://localhost:8000/") {
        self.baseURL = baseURL
    }

    func callMyServer<T: Decodable>(
        path: String,
        httpMethod: HTTPMethod,
        params: [String: Any]? = nil,
        completion: @escaping (Result<T, ServerCommunicator.Error>) -> Void) {

        // Ensure user is authenticated
        guard let user = Auth.auth().currentUser else {
            print("No authenticated user found.")
            completion(.failure(.authError("No authenticated user.")))
            return
        }

        // Retrieve Firebase authentication token
        user.getIDToken { idToken, error in
            if let error = error {
                print("Error getting ID token: \(error.localizedDescription)")
                completion(.failure(.authError("Failed to get Firebase ID token.")))
                return
            }

            guard let idToken = idToken else {
                print("Failed to retrieve ID token")
                completion(.failure(.authError("ID token is nil.")))
                return
            }

            let path = path.hasPrefix("/") ? String(path.dropFirst()) : path
            let urlString = self.baseURL + path

            guard let url = URL(string: urlString) else {
                completion(.failure(ServerCommunicator.Error.invalidUrl(urlString)))
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = httpMethod.rawValue
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            request.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization") // 🔥 Attach Firebase token

            if httpMethod == .post, let params = params {
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: params, options: [])
                    request.httpBody = jsonData
                } catch {
                    completion(.failure(.encodingError("\(error)")))
                    return
                }
            }

            // Create the task
            let task = URLSession.shared.dataTask(with: request) { (data, _, error) in
                DispatchQueue.main.async {
                    if let error = error {
                        completion(.failure(.networkError("\(error)")))
                        return
                    }

                    guard let data = data else {
                        completion(.failure(.nilData))
                        return
                    }
                    print("Received data from: \(path)")
                    data.printJson()

                    do {
                        let object = try JSONDecoder().decode(T.self, from: data)
                        completion(.success(object))
                    } catch {
                        completion(.failure(.decodingError("\(error)")))
                    }
                }
            }

            task.resume()
        }
    }

    struct DummyDecodable: Decodable {}

    // Convenience method for API calls without needing a completion handler
    func callMyServer(
        path: String,
        httpMethod: HTTPMethod,
        params: [String: Any]? = nil
    ) {
        callMyServer(path: path, httpMethod: httpMethod, params: params) { (_: Result<DummyDecodable, ServerCommunicator.Error>) in
            // Do nothing here
        }
    }

    private let baseURL: String
}

extension Data {
    fileprivate func printJson() {
        do {
            let json = try JSONSerialization.jsonObject(with: self, options: [])
            let data = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
            guard let jsonString = String(data: data, encoding: .utf8) else {
                print("Invalid data")
                return
            }
            print(jsonString)
        } catch {
            print("Error: \(error.localizedDescription)")
        }
    }
}
