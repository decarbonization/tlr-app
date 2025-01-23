//
//  FileSystemWatcher.swift
//  M9r
//
//  Created by P. Kevin Contreras on 1/23/25.
//  Copyright © 2025 M9r Project. All rights reserved.
//

import CoreServices
import Foundation

final class FileSystemWatcher {
    private final class Info {
        init(watcher: FileSystemWatcher) {
            self.watcher = watcher
        }
        
        weak var watcher: FileSystemWatcher?
    }
    
    private struct Event {
        let url: URL
        let flags: FSEventStreamEventFlags
        let id: FSEventStreamEventId
    }
    
    init(watchURLs: [URL],
         excludeURLs: [URL]) {
        self.workQueue = DispatchQueue(label: "M9r.FileSystemWatcher",
                                       qos: .background,
                                       autoreleaseFrequency: .workItem)
        self.queueWatchURLs = watchURLs
        self.queueExcludeURLs = excludeURLs
    }
    
    deinit {
        stop()
    }
    
    private let workQueue: DispatchQueue
    private var queueWatchURLs: [URL]
    private var queueExcludeURLs: [URL]
    private var queueFSEventStream: FSEventStreamRef?
    
    private func processEvents(_ events: [Event]) {
        
    }
    
    func start() {
        stop()
        workQueue.sync {
            let pathsToWatch = queueWatchURLs.map { $0.path(percentEncoded: false) } as CFArray
            let exclusionPaths = queueExcludeURLs.map { $0.path(percentEncoded: false) } as CFArray
            let callback: FSEventStreamCallback = { stream, info, numEvents, eventPaths, flags, eventIDs in
                let info = Unmanaged<Info>.fromOpaque(info!).takeUnretainedValue()
                guard let watcher = info.watcher else {
                    return
                }
                let paths = eventPaths.assumingMemoryBound(to: UnsafePointer<Int8>.self)
                let events = (0 ..< numEvents).map { index in
                    Event(url: URL(fileURLWithFileSystemRepresentation: paths[index],
                                   isDirectory: false,
                                   relativeTo: nil),
                          flags: flags[index],
                          id: eventIDs[index])
                }
                watcher.processEvents(events)
            }
            let info = Info(watcher: self)
            var context = FSEventStreamContext(version: 0,
                                               info: Unmanaged.passRetained(info).toOpaque(),
                                               retain: { UnsafeRawPointer(Unmanaged<Info>.fromOpaque($0!).retain().toOpaque()) },
                                               release: { Unmanaged<Info>.fromOpaque($0!).release() },
                                               copyDescription: nil)
            let fsEventStream = FSEventStreamCreate(kCFAllocatorNull,
                                                     callback,
                                                     &context,
                                                     pathsToWatch,
                                                     FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
                                                     7,
                                                     FSEventStreamCreateFlags())!
            FSEventStreamSetDispatchQueue(fsEventStream, workQueue)
            FSEventStreamSetExclusionPaths(fsEventStream, exclusionPaths)
            if !FSEventStreamStart(fsEventStream) {
                fatalError()
            }
            queueFSEventStream = fsEventStream
        }
    }
    
    func stop() {
        workQueue.sync {
            guard let queueFSEventStream else {
                return
            }
            FSEventStreamStop(queueFSEventStream)
            FSEventStreamRelease(queueFSEventStream)
            self.queueFSEventStream = nil
        }
    }
}
