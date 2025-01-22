import ArgumentParser
import Foundation
import EventKit

enum CLIError: Error {
    case unexpected
}

extension EKEventStore {
    func reminders(matching predicate: NSPredicate) async throws -> [EKReminder] {
        try await withCheckedThrowingContinuation { continuation in
            fetchReminders(matching: predicate) { reminders in
                if let reminders {
                    continuation.resume(returning: reminders)
                } else {
                    continuation.resume(throwing: CLIError.unexpected)
                }
            }
        }
    }
}

@main
struct Reminder2Json: AsyncParsableCommand {
    @Option(help: "Lists to include regex, defaults to '.*' (all).")
    var includeLists: String = ".*"

    @Option(help: "Lists to exclude regex, defaults to '' (none).")
    var excludeLists: String = ""

    @Flag(help: "If true, include deleted reminders. Defaults to false.")
    var includeDeleted = false

    private func toObject(alarm: EKAlarm) -> Dictionary<String, Any> {
        var d: [String: Any] = [:]
        if let absoluteDate = alarm.absoluteDate {
            d["absoluteDate"] = absoluteDate.description
        }
        if alarm.relativeOffset > 0 {
            d["relativeOffset"] = alarm.relativeOffset
        }

        if let location = alarm.structuredLocation {
            d["structuredLocation"] = location.title
            if alarm.proximity == EKAlarmProximity.enter {
                d["proximity"] = "enter"
            }
            if alarm.proximity == EKAlarmProximity.leave {
                d["proximity"] = "leave"
            }
        }
        // skipping type and sound
        if let emailAddress = alarm.emailAddress {
            d["emailAddress"] = emailAddress
        }
        return d
    }

    private func toObject(recurrenceRule rule: EKRecurrenceRule) -> Dictionary<String, Any> {
        var d: [String: Any] = [:]
        d["rrule"] = rule.description.components(separatedBy:"RRULE ").last
        // if let recurrenceEnd = rule.recurrenceEnd {
        //     d["recurrenceEnd"]
        // }
        return d
    }

    private func toObject(reminder: EKReminder) -> Dictionary<String, Any> {
        var d: [String: Any] = [:]
        d["list"] = reminder.calendar.title
        d["account"] = reminder.calendar.source.title
        d["calendarItemIdentifier"] = reminder.calendarItemIdentifier
        d["calendarItemExternalIdentifier"] = reminder.calendarItemExternalIdentifier
        d["title"] = reminder.title
        if let location = reminder.location {
            d["location"] = location
        }
        if let creationDate = reminder.creationDate {
            d["creationDate"] = creationDate.description
        }
        if let lastModifiedDate = reminder.lastModifiedDate {
            d["lastModifiedDate"] = lastModifiedDate.description
        }
        if let timeZone = reminder.timeZone {
            d["timeZone"] = timeZone.description
        }
        if let url = reminder.url {
            d["url"] = url.description
        }
        if let notes = reminder.notes {
            d["notes"] = notes
        }

        // skipped Attendees

        if let alarms = reminder.alarms {
            var l = [Dictionary<String, Any>]()
            for alarm in alarms {
                l.append(toObject(alarm:alarm))
            }
            if l.count > 0 {
                d["alarms"] = l
            }
        }

        if let recurrenceRules = reminder.recurrenceRules {
            var l = [Dictionary<String, Any>]()
            for rule in recurrenceRules {
                l.append(toObject(recurrenceRule:rule))
            }
            if l.count > 0 {
                d["recurrenceRules"] = l
            }
        }

        d["priority"] = "\(reminder.priority)"
        // if reminder.priority == EKReminderPriority.low {
        //     d["priority"] = "low"
        // }
        // if reminder.priority == EKReminderPriority.medium {
        //     d["priority"] = "medium"
        // }
        // if reminder.priority == EKReminderPriority.high {
        //     d["priority"] = "high"
        // }

        if let startDateComponents = reminder.startDateComponents {
            if let date = startDateComponents.date {
                d["startDate"] = date.description
            }
        }
        if let dueDateComponents = reminder.dueDateComponents {
            if let date = dueDateComponents.date {
                d["dueDate"] = date.description
            }
        }

        d["completed"] = NSNumber(value:reminder.isCompleted)

        if let completionDate = reminder.completionDate {
            d["completionDate"] = completionDate.description
        }

        return d
    }

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
        let reminders = try await store.reminders(matching: predicate)
        var l = [Any]()
        for r in reminders {
            if try skip(reminder:r) {
                continue
            }
            let d = toObject(reminder: r)
            l.append(d)
        }
        let j = try JSONSerialization.data(withJSONObject: l, options: [.prettyPrinted])
        let out = FileHandle.standardOutput
        out.write(j)
    }
}
