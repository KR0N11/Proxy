//
//  CoreData.swift
//  Proxy
//
//  Created by Kevin Alinazar on 2026-02-08.
//

import CoreData

extension AppViewModel {

    // MARK: - CoreData Sync
    // NOTE: must NOT be private anymore because fetchCurrentUser() calls this from another file

    func saveUserToCoreData(user: AppUser) {
        let request = NSFetchRequest<NSManagedObject>(entityName: "CachedUser")
        request.predicate = NSPredicate(format: "id == %@", user.id)

        do {
            let results = try viewContext.fetch(request)
            let cachedUser = results.first ?? NSEntityDescription.insertNewObject(
                forEntityName: "CachedUser",
                into: viewContext
            )

            cachedUser.setValue(user.id, forKey: "id")
            cachedUser.setValue(user.username, forKey: "username")
            cachedUser.setValue(user.profilePicURL, forKey: "profilePicURL")

            try viewContext.save()
        } catch {
            print("CoreData Error: \(error)")
        }
    }
}
