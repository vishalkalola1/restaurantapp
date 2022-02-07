//
//  Network.swift
//  ZattooPractical
//
//  Created by Vishal on 7/2/21.

import Foundation

protocol NetWorkType {
    @available(iOS 15.0, *)
    func api<T: Decodable>(with url:URL, model: T.Type) async -> Result<T, Error>
    
    @available(iOS 15.0, *)
    func api<T: Decodable>(with request: URLRequest, model: T.Type) async -> Result<T, Error>
    
    func api<T: Decodable>(with url:URL, model: T.Type, completion: @escaping (Result<T, Error>) -> Void)
    func api<T: Decodable>(with request: URLRequest, model: T.Type, completion: @escaping (Result<T, Error>) -> Void)
}

///Network Class is bind with server
/// Here you can define `POST`,`GET`,`PUT`.... API type
class Network: NetWorkType {
    
    static let shared = Network()
    
    @available(iOS, deprecated:6.0)
    /// Parameters: URL, ModelType, Completion Hanler
    /// Response `Result<T, Error>` where T is Model Which Pass for parsing
    func api<T: Decodable>(with url:URL, model: T.Type, completion: @escaping (Result<T, Error>) -> Void) {
        
        print("Request Url: 👉👉👉👉👉", url)
        ///Call API
        let task = URLSession.shared.dataTask(with: url){ (data, response, error) in
            let result = self.generateRersponse(model: model, data: data, response: response, error: error)
            completion(result)
        }
        task.resume()
    }
    
    @available(iOS, deprecated:6.0)
    func api<T: Decodable>(with request: URLRequest, model: T.Type, completion: @escaping (Result<T, Error>) -> Void) {
        
        print("Request Url: 👉👉👉👉👉", request.url?.absoluteString ?? "")
        ///Call API
        let task = URLSession.shared.dataTask(with: request){ (data, response, error) in
            let result = self.generateRersponse(model: model, data: data, response: response, error: error)
            completion(result)
        }
        task.resume()
    }
}

extension Network {
    
    private func generateRersponse<T: Decodable>(model: T.Type, data: Data?, response: URLResponse?, error: Error?) -> Result<T, Error> {
        guard let data = data else {
            let err = error ?? CustomError.NullData
            print("Response: ☠️☠️☠️☠️☠️", err.localizedDescription)
            return .failure(err)
        }
        if let JSONString = String(data: data, encoding: .utf8) {
            print("Response: 👉👉👉👉👉", JSONString)
        }
        if let status = response as? HTTPURLResponse, (status.statusCode == 200 || status.statusCode == 201)  {
            return data.decode(type: model)
        } else {
            let serverError = data.decode(type: ErrorMessage.self)
            switch(serverError) {
            case .success(let error):
                let error = ServerError(error.detail ?? "Unknows error")
                return .failure(error)
            case .failure(let error):
                return .failure(error)
            }
        }
    }
}

//Async/Await Api call
@available(iOS 15.0, *)
extension Network {
    func api<T: Decodable>(with url:URL, model: T.Type) async -> Result<T, Error> {
        print("Request Url: 👉👉👉👉👉", url)
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            return self.generateRersponse(model: model, data: data, response: response, error: nil)
        } catch let error {
            return self.generateRersponse(model: model, data: nil, response: nil, error: error)
        }
    }
    
    func api<T: Decodable>(with request: URLRequest, model: T.Type) async -> Result<T, Error> {
        
        print("Request Url: 👉👉👉👉👉", request.url!)
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            return self.generateRersponse(model: model, data: data, response: response, error: nil)
        } catch let error {
            return self.generateRersponse(model: model, data: nil, response: nil, error: error)
        }
    }
}

extension Data {
    func decode<T:Decodable>(type: T.Type) -> Result<T, Error> {
        do {
            let obj = try JSONDecoder().decode(T.self, from: self)
            return .success(obj)
        } catch let error {
            print("Response: ☠️☠️☠️☠️☠️", error)
            return.failure(error)
        }
    }
}
