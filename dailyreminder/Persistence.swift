//
//  Persistence.swift
//  dailyreminder
//
//  Created by BMIIT on 02/12/25.
//
import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext

        // Sample Task
        let task = TaskItem(context: viewContext)
        task.id = UUID()
        task.title = "Sample Task"
        task.date = Date()
        task.isCompleted = false

        // Sample Habit
        let habit = HabitItem(context: viewContext)
        habit.id = UUID()
        habit.title = "Drink Water"
        habit.time = Date()
        habit.repeatSunday = false
        habit.repeatMonday = true
        habit.repeatTuesday = true
        habit.repeatWednesday = true
        habit.repeatThursday = true
        habit.repeatFriday = true
        habit.repeatSaturday = false
        habit.isActive = true
        habit.baseNotificationId = habit.id?.uuidString ?? UUID().uuidString

        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        // IMPORTANT: name must equal your .xcdatamodeld filename
        // e.g. "dailyreminder" if the model file is dailyreminder.xcdatamodeld
        container = NSPersistentContainer(name: "dailyreminder")

        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (_, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
