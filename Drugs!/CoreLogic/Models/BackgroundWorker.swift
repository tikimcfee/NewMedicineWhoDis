//
//  BackgroundWorker.swift
//  Drugs!
//
//  Created by Ivan Lugo on 3/27/22.
//  Copyright © 2022 Ivan Lugo. All rights reserved.
//

import Foundation

typealias BackgroundClosure = (_ loop: RunLoop) -> Void

open class BackgroundWorker: NSObject {
    private let id = UUID()
    private var started = false
    
    private lazy var workerThread: Thread = {
        let newThread = Thread { [weak self] in self?.monitorThread() }
        newThread.name = "BackgroundWorker-\(id)"
        return newThread
    }()
    
    func start() {
        guard !started else { return }
        started.toggle()
        workerThread.start()
    }
    
    func stop() {
        workerThread.cancel()
    }
    
    func run(_ block: @escaping BackgroundClosure) {
        start()
        
        perform(#selector(execute),
                on: workerThread,
                with: block,
                waitUntilDone: false,
                modes: [RunLoop.Mode.default.rawValue])
    }
    
    // Signature *must me* of the form `(_ closure: Any!) -> Unmanaged<AnyObject>!`,
    // such that perform(selector:) delivers the current untyped object to cast
    @objc private func execute(_ closure: Any!) -> Unmanaged<AnyObject>! {
        if let closure = closure as? BackgroundClosure {
            closure(RunLoop.current)
        }
        return nil
    }
    
    public func monitorThread() {
        while !workerThread.isCancelled {
            RunLoop.current.run(
                mode: RunLoop.Mode.default,
                before: Date.distantFuture
            )
        }
        Thread.exit()
    }
}

