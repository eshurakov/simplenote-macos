import Foundation


// MARK: - EntityObserverDelegate
//
protocol EntityObserverDelegate: class {
    func entityObserver<T: NSManagedObject>(_ observer: EntityObserver<T>, didObserveChanges entities: Set<T>)
}


// MARK: - EntityObserver
//         Listens for changes applied over a set of ObjectIDs, and invokes a closure whenever any of the entities gets updated.
//
class EntityObserver<T: NSManagedObject> {

    /// Identifiers of the objects being observed
    ///
    let entities: [T]

    /// Observed Change Types
    ///
    var changeTypes = [NSUpdatedObjectsKey, NSRefreshedObjectsKey]

    /// NotificationCenter Observer Token.
    ///
    private var notificationsToken: Any!

    /// Closure to be invoked whenever any of the observed entities gets updated
    ///
    weak var delegate: EntityObserverDelegate?


    /// Designed Initialier
    ///
    /// - Parameters:
    ///     - context: NSManagedObjectContext in which we should listen for changes
    ///     - entities: NSManagedObject(s) that should be observed for changes
    ///
    init(context: NSManagedObjectContext, entities: [T]) {
        self.entities = entities
        self.notificationsToken = startListeningForNotifications(in: context)
    }

    /// Convenience Initializer
    ///
    /// - Parameters:
    ///     - identifier: NSManagedObjectID of the observed entity
    ///     - context: NSManagedObjectContext in which we should listen for changes
    ///
    convenience init(context: NSManagedObjectContext, identifier: NSManagedObjectID) {
        self.init(context: context, identifiers: [identifier])
    }
}


// MARK: - Listening for Changes!
//
private extension EntityObserver {

    func startListeningForNotifications(in context: NSManagedObjectContext) -> Any {
        let nc = NotificationCenter.default
        return nc.addObserver(forName: .NSManagedObjectContextObjectsDidChange, object: context, queue: nil) { [weak self] note in
            self?.contextDidChange(note)
        }
    }

    func contextDidChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo, let delegate = delegate else {
            return
        }

        let observedIdentifiers = entities.map { $0.objectID }
        let updatedObjects = extractManagedObjects(from: userInfo, keys: changeTypes).filter {
            observedIdentifiers.contains($0.objectID)
        }

        guard !updatedObjects.isEmpty else {
            return
        }

        DispatchQueue.main.async {
            delegate.entityObserver(self, didObserveChanges: updatedObjects)
        }
    }

    /// Given a Notification's Payload, this API will extract the collection of NSManagedObjectID(s) stored under the specified keys.
    ///
    func extractManagedObjects(from userInfo: [AnyHashable: Any], keys: [String]) -> Set<T> {
        var output = Set<T>()
        for key in keys {
            guard let objects = userInfo[key] as? Set<NSManagedObject> else {
                continue
            }

            let mappedObject = objects.compactMap { $0 as? T }
            output.formUnion(mappedObject)
        }

        return output
    }
}
