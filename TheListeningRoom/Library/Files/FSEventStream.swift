/*
 * The Listening Room Project
 * Copyright (C) 2025  MAINTAINERS
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import Foundation

final class FSEventStream: CustomStringConvertible, @unchecked Sendable {
    struct InitFlags: OptionSet {
        var rawValue: FSEventStreamCreateFlags
        
        static let None = Self(rawValue: FSEventStreamCreateFlags(kFSEventStreamCreateFlagNone))
        static let noDefer = Self(rawValue: FSEventStreamCreateFlags(kFSEventStreamCreateFlagNoDefer))
        static let watchRoot = Self(rawValue: FSEventStreamCreateFlags(kFSEventStreamCreateFlagWatchRoot))
        static let ignoreSelf = Self(rawValue: FSEventStreamCreateFlags(kFSEventStreamCreateFlagIgnoreSelf))
        static let fileEvents = Self(rawValue: FSEventStreamCreateFlags(kFSEventStreamCreateFlagFileEvents))
        static let markSelf = Self(rawValue: FSEventStreamCreateFlags(kFSEventStreamCreateFlagMarkSelf))
        static let useExtendedData = Self(rawValue: FSEventStreamCreateFlags(kFSEventStreamCreateFlagUseExtendedData))
        static let fullHistory = Self(rawValue: FSEventStreamCreateFlags(kFSEventStreamCreateFlagFullHistory))
        static let withDocID = Self(rawValue: FSEventStreamCreateFlags(kFSEventStreamCreateWithDocID))
    }
    
    struct EventFlags: OptionSet {
        var rawValue: FSEventStreamEventFlags
        
        static let mustScanSubDirs = Self(rawValue: FSEventStreamEventFlags(kFSEventStreamEventFlagMustScanSubDirs))
        static let userDropped = Self(rawValue: FSEventStreamEventFlags(kFSEventStreamEventFlagUserDropped))
        static let kernelDropped = Self(rawValue: FSEventStreamEventFlags(kFSEventStreamEventFlagKernelDropped))
        static let eventIdsWrapped = Self(rawValue: FSEventStreamEventFlags(kFSEventStreamEventFlagEventIdsWrapped))
        static let historyDone = Self(rawValue: FSEventStreamEventFlags(kFSEventStreamEventFlagHistoryDone))
        static let rootChanged = Self(rawValue: FSEventStreamEventFlags(kFSEventStreamEventFlagRootChanged))
        static let mount = Self(rawValue: FSEventStreamEventFlags(kFSEventStreamEventFlagMount))
        static let unmount = Self(rawValue: FSEventStreamEventFlags(kFSEventStreamEventFlagUnmount))
        static let itemCreated = Self(rawValue: FSEventStreamEventFlags(kFSEventStreamEventFlagItemCreated))
        static let itemRemoved = Self(rawValue: FSEventStreamEventFlags(kFSEventStreamEventFlagItemRemoved))
        static let itemInodeMetaMod = Self(rawValue: FSEventStreamEventFlags(kFSEventStreamEventFlagItemInodeMetaMod))
        static let itemRenamed = Self(rawValue: FSEventStreamEventFlags(kFSEventStreamEventFlagItemRenamed))
        static let itemModified = Self(rawValue: FSEventStreamEventFlags(kFSEventStreamEventFlagItemModified))
        static let itemFinderInfoMod = Self(rawValue: FSEventStreamEventFlags(kFSEventStreamEventFlagItemFinderInfoMod))
        static let itemChangeOwner = Self(rawValue: FSEventStreamEventFlags(kFSEventStreamEventFlagItemChangeOwner))
        static let itemXattrMod = Self(rawValue: FSEventStreamEventFlags(kFSEventStreamEventFlagItemXattrMod))
        static let itemIsFile = Self(rawValue: FSEventStreamEventFlags(kFSEventStreamEventFlagItemIsFile))
        static let itemIsDir = Self(rawValue: FSEventStreamEventFlags(kFSEventStreamEventFlagItemIsDir))
        static let itemIsSymlink = Self(rawValue: FSEventStreamEventFlags(kFSEventStreamEventFlagItemIsSymlink))
        static let ownEvent = Self(rawValue: FSEventStreamEventFlags(kFSEventStreamEventFlagOwnEvent))
        static let itemIsHardlink = Self(rawValue: FSEventStreamEventFlags(kFSEventStreamEventFlagItemIsHardlink))
        static let itemIsLastHardlink = Self(rawValue: FSEventStreamEventFlags(kFSEventStreamEventFlagItemIsLastHardlink))
        static let itemCloned = Self(rawValue: FSEventStreamEventFlags(kFSEventStreamEventFlagItemCloned))
    }
    
    struct EventID: RawRepresentable, Hashable, Codable {
        init(rawValue: FSEventStreamEventId) {
            self.rawValue = rawValue
        }
        
        init(from decoder: any Decoder) throws {
            let container = try decoder.singleValueContainer()
            rawValue = try container.decode(FSEventStreamEventId.self)
        }
        
        func encode(to encoder: any Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(rawValue)
        }
        
        var rawValue: FSEventStreamEventId
        
        static let sinceNow = Self(rawValue: FSEventStreamEventId(kFSEventStreamEventIdSinceNow))
        static var current: Self {
            Self(rawValue: FSEventsGetCurrentEventId())
        }
    }
    
    struct Event: Identifiable {
        let id: EventID
        let flags: EventFlags
        let url: URL
    }
    
    enum InitError: Error {
        case couldNotCreateStream(placesToWatch: [URL],
                                  sinceWhen: EventID,
                                  latency: TimeInterval,
                                  flags: InitFlags)
    }
    
    private final class Callback {
        init(_ callback: @escaping @Sendable ([Event]) -> Void) {
            self.callback = callback
        }
        
        private let callback: @Sendable ([Event]) -> Void
        
        func callAsFunction(_ numEvents: Int,
                            _ eventPaths: UnsafeMutableRawPointer,
                            _ eventFlags: UnsafePointer<FSEventStreamEventFlags>,
                            _ eventIds: UnsafePointer<FSEventStreamEventId>) {
            let eventPaths = eventPaths.assumingMemoryBound(to: UnsafePointer<Int8>.self)
            let events = (0 ..< numEvents).map { index in
                let id = EventID(rawValue: eventIds[index])
                let flags = EventFlags(rawValue: eventFlags[index])
                let url = URL(fileURLWithFileSystemRepresentation: eventPaths[index],
                              isDirectory: flags.contains(.itemIsDir),
                              relativeTo: nil)
                return Event(id: id, flags: flags, url: url)
            }
            callback(events)
        }
        
        static let bridge: FSEventStreamCallback = { _, clientCallBackInfo, numEvents, eventPaths, eventFlags, eventIds in
            guard let clientCallBackInfo else {
                return
            }
            let callback = Unmanaged<Callback>.fromOpaque(clientCallBackInfo).takeUnretainedValue()
            callback(numEvents, eventPaths, eventFlags, eventIds)
        }
    }
    
    init(placesToWatch: [URL],
         sinceWhen: EventID,
         latency: TimeInterval,
         flags: InitFlags,
         callback: @escaping @Sendable ([Event]) -> Void) throws {
        let callback = Callback(callback)
        var context = FSEventStreamContext(version: 0,
                                           info: Unmanaged.passUnretained(callback).toOpaque(),
                                           retain: { UnsafeRawPointer(Unmanaged<Callback>.fromOpaque($0!).retain().toOpaque()) },
                                           release: { Unmanaged<Callback>.fromOpaque($0!).release() },
                                           copyDescription: nil)
        let pathsToWatch = [String](
            placesToWatch.lazy
                .map { $0.path(percentEncoded: false) }
                .filter { FileManager.default.fileExists(atPath: $0) }
        )
        guard let fsStream = FSEventStreamCreate(kCFAllocatorDefault,
                                                 Callback.bridge,
                                                 &context,
                                                 pathsToWatch as CFArray,
                                                 sinceWhen.rawValue,
                                                 latency,
                                                 flags.rawValue) else {
            throw InitError.couldNotCreateStream(placesToWatch: placesToWatch,
                                                 sinceWhen: sinceWhen,
                                                 latency: latency,
                                                 flags: flags)
        }
        self.fsStream = fsStream
        self.queue = DispatchQueue(label: "FSEventStream",
                                   qos: .background,
                                   autoreleaseFrequency: .workItem)
        FSEventStreamSetDispatchQueue(fsStream, queue)
    }
    
    deinit {
        FSEventStreamInvalidate(fsStream)
        FSEventStreamRelease(fsStream)
    }
    
    private let fsStream: FSEventStreamRef
    private let queue: DispatchQueue
    
    var latestEventID: EventID {
        EventID(rawValue: FSEventStreamGetLatestEventId(fsStream))
    }
    
    @discardableResult func setExclusionPlaces(_ placesToExclude: [URL]) -> Bool {
        let pathsToExclude = placesToExclude.map { $0.path(percentEncoded: false) } as CFArray
        return FSEventStreamSetExclusionPaths(fsStream, pathsToExclude)
    }
    
    func start() -> Bool {
        FSEventStreamStart(fsStream)
    }
    
    func stop() {
        FSEventStreamStop(fsStream)
    }
    
    var description: String {
        "FSEventStream(\(FSEventStreamCopyDescription(fsStream)))"
    }
}
