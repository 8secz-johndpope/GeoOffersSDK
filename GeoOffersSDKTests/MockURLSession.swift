//  Copyright © 2019 Zappit. All rights reserved.

import Foundation
import XCTest

class MockURLSessionTask: URLSessionDataTask {
    var resumptionHandler: (() -> Void)?
    var testError: Error?

    override var error: Error? {
        return testError
    }

    private let identifier = Int(Date().timeIntervalSinceReferenceDate)
    override var taskIdentifier: Int {
        return identifier
    }

    override init() {}
    override func cancel() {}
    override func suspend() {}
    override func resume() {
        resumptionHandler?()
    }

    public override var state: URLSessionTask.State {
        return URLSessionTask.State.suspended
    }
}

class MockURLSessionDownloadTask: URLSessionDownloadTask {
    var resumptionHandler: (() -> Void)?
    var testError: Error?

    override var error: Error? {
        return testError
    }

    private let identifier = Int(Date().timeIntervalSinceReferenceDate)
    override var taskIdentifier: Int {
        return identifier
    }

    override init() {}
    override func cancel() {}
    override func suspend() {}
    override func resume() {
        resumptionHandler?()
    }

    public override var state: URLSessionTask.State {
        return URLSessionTask.State.suspended
    }
}

class MockURLSession: URLSession {
    var responseError: Error?
    var responseData: Data?
    var httpResponse: URLResponse?
    var testExpectation: XCTestExpectation?
    private var downloadedDataURL: URL?
    var testDelegate: URLSessionDelegate?
    override var delegate: URLSessionDelegate? {
        return testDelegate
    }

    private(set) var taskComplete = false
    private(set) var taskCompleteWithError = false

    override init() {
        do {
            downloadedDataURL = URL(fileURLWithPath: try FileManager.default.documentPath(for: "test_data.data"))
        } catch {}
    }

    override func dataTask(with _: URL) -> URLSessionDataTask {
        return MockURLSessionTask()
    }

    override func downloadTask(with _: URLRequest) -> URLSessionDownloadTask {
        taskComplete = true
        taskCompleteWithError = responseError != nil
        testExpectation?.fulfill()
        let task = MockURLSessionDownloadTask()
        if let delegate = delegate as? URLSessionDownloadDelegate,
            let downloadedDataURL = downloadedDataURL {
            do {
                if let data = responseData {
                    try data.write(to: downloadedDataURL)
                } else {
                    try FileManager.default.removeItem(at: downloadedDataURL)
                }
            } catch {}
            task.resumptionHandler = {
                delegate.urlSession(self, downloadTask: task, didFinishDownloadingTo: downloadedDataURL)
            }
            task.testError = responseError
        }

        return task
    }

    override func dataTask(with _: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        assertionFailure("Should not be called")
        return MockURLSessionTask()
    }

    override func dataTask(with _: URLRequest) -> URLSessionDataTask {
        taskComplete = true
        taskCompleteWithError = responseError != nil
        testExpectation?.fulfill()
        let task = MockURLSessionTask()
        if let delegate = delegate as? URLSessionTaskDelegate {
            task.resumptionHandler = {
                delegate.urlSession?(self, task: task, didCompleteWithError: self.responseError)
            }
            task.testError = responseError
        }
        return task
    }

    override func dataTask(with _: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        assertionFailure("Should not be called")
        return MockURLSessionTask()
    }
}
