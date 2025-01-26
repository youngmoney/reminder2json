import EventKit

extension EKReminder {
    private func dateDescription(date: Date) -> String {
        return date.description.components(separatedBy: " +0000").first ?? ""
    }

    private func simpleDateDescription(date: Date) -> String {
        let simple = date.description.components(separatedBy: " +0000").first ?? ""
        return String(simple.dropLast(3))
    }

    private func toDictionary(alarm: EKAlarm) -> Dictionary<String, Any> {
        var d: [String: Any] = [:]
        if let absoluteDate = alarm.absoluteDate {
            d["absoluteDate"] = dateDescription(date: absoluteDate)
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

    private func toDictionary(recurrenceRule rule: EKRecurrenceRule) -> Dictionary<String, Any> {
        var d: [String: Any] = [:]
        d["rrule"] = rule.description.components(separatedBy:"RRULE ").last
        // if let recurrenceEnd = rule.recurrenceEnd {
        //     d["recurrenceEnd"]
        // }
        return d
    }

    func asJson() -> Dictionary<String, Any> {
        var d: [String: Any] = [:]
        // d["list"] = self.calendar.title
        // d["account"] = self.calendar.source.title
        d["calendarItemIdentifier"] = self.calendarItemIdentifier
        d["calendarItemExternalIdentifier"] = self.calendarItemExternalIdentifier
        d["title"] = self.title
        if let location = self.location {
            d["location"] = location
        }
        if let creationDate = self.creationDate {
            d["creationDate"] = dateDescription(date: creationDate)
        }
        if let lastModifiedDate = self.lastModifiedDate {
            d["lastModifiedDate"] = dateDescription(date: lastModifiedDate)
        }
        if let timeZone = self.timeZone {
            d["timeZone"] = timeZone.description
        }
        if let url = self.url {
            d["url"] = url.description
        }
        if let notes = self.notes {
            d["notes"] = notes
        }

        // Attendees are not currently being added.

        if let alarms = self.alarms {
            var l = [Dictionary<String, Any>]()
            for alarm in alarms {
                l.append(toDictionary(alarm:alarm))
            }
            if l.count > 0 {
                d["alarms"] = l
            }
        }

        if let recurrenceRules = self.recurrenceRules {
            var l = [Dictionary<String, Any>]()
            for rule in recurrenceRules {
                l.append(toDictionary(recurrenceRule:rule))
            }
            if l.count > 0 {
                d["recurrenceRules"] = l
            }
        }

        d["priority"] = NSNumber(value:self.priority)

        if let startDateComponents = self.startDateComponents {
            if let date = startDateComponents.date {
                d["startDate"] = dateDescription(date: date)
            }
        }
        if let dueDateComponents = self.dueDateComponents {
            if let date = dueDateComponents.date {
                d["dueDate"] = dateDescription(date: date)
            }
        }

        d["completed"] = NSNumber(value:self.isCompleted)

        if let completionDate = self.completionDate {
            d["completionDate"] = dateDescription(date: completionDate)
        }

        return d
    }

    func asSimpleJson() throws -> Dictionary<String, Any> {
        var d: [String: Any] = [:]
        d["title"] = self.title
        if let creationDate = self.creationDate {
            d["creationDate"] = simpleDateDescription(date: creationDate)
        }
        if let timeZone = self.timeZone {
            d["timeZone"] = timeZone.description
        }
        if let notes = self.notes {
            d["notes"] = notes
        }

        if let recurrenceRules = self.recurrenceRules {
            if recurrenceRules.count == 1 {
                d["recurrence"] = recurrenceRules.first!.description.components(separatedBy:"RRULE ").last
            }
            if recurrenceRules.count > 1 {
                throw CLIError.unexpected
            }
        }

        d["priority"] = NSNumber(value:self.priority)

        if let startDateComponents = self.startDateComponents {
            if let date = startDateComponents.date {
                d["startDate"] = simpleDateDescription(date: date)
            }
        }
        if let dueDateComponents = self.dueDateComponents {
            if let date = dueDateComponents.date {
                d["dueDate"] = simpleDateDescription(date: date)
            }
        }

        d["completed"] = NSNumber(value:self.isCompleted)

        if let completionDate = self.completionDate {
            d["completionDate"] = simpleDateDescription(date: completionDate)
        }

        return d
    }
}
