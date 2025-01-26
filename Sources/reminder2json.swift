import ArgumentParser
import Foundation
import EventKit

enum CLIError: Error {
    case unexpected
}

enum OutputFormat : String, ExpressibleByArgument, CaseIterable {
    case fullJson, remindmd
}

@main
struct Reminder2Json: AsyncParsableCommand {
    @Option(help: "Lists to include regex, defaults to '.*' (all).")
    var includeLists: String = ".*"

    @Option(help: "Lists to exclude regex, defaults to '' (none).")
    var excludeLists: String = ""

    @Flag(help: "If true, include deleted reminders. Defaults to false.")
    var includeDeleted = false

    @Option(help: "the output format, defaults to fullJson [fullJson, remindmd]")
    var outputFormat: OutputFormat = .fullJson

    func skip(reminder: EKReminder) throws -> Bool {
        let includeRegex = try Regex(includeLists)
        let excludeRegex = try Regex(excludeLists)
        if !includeDeleted && reminder.isCompleted {
            return true
        }
        if excludeLists != "" && reminder.calendar.title.contains(excludeRegex) {
            return true
        }
        return !(includeLists == "" || reminder.calendar.title.contains(includeRegex))
    }

    mutating func run() async throws {
        let store = EKEventStore()
        let granted = try await store.requestFullAccessToReminders()
        if !granted {
            print("reminder2json needs access to reminders to function")
        }

        let predicate = store.predicateForReminders(in: nil)
        let remindersStore = try await store.reminders(matching: predicate)
        var reminders = [EKReminder]()
        for r in remindersStore {
             reminders.append(r)
        }
        reminders.sort { $0.creationDate! < $1.creationDate! }
        var all = Dictionary<String, Dictionary<String, [Any]>>()
        for r in reminders {
            if try skip(reminder:r) {
                continue
            }
            let d = switch outputFormat {
                case .fullJson: r.asJson()
                case .remindmd: try r.asSimpleJson()
            }
            all[r.calendar.source.title, default: [:]][r.calendar.title, default: []].append(d)
        }
        let j = try JSONSerialization.data(withJSONObject: ["reminders": all], options: [.prettyPrinted, .sortedKeys])
        let out = FileHandle.standardOutput
        out.write(j)
    }
}
