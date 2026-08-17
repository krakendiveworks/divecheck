import Foundation

/// Requirement template for the PADI Divemaster course -- transcribed from
/// PADI's own Divemaster Course Instructor Slates (the Candidate Roster and
/// Requirements Check List, Waterskills Development, Diver Rescue, Practical
/// Application Skills, Divemaster-Conducted Program Workshops, and Practical
/// Assessment cards) plus the separate Skill Evaluation Slate card.
///
/// Each multi-step skill/workshop/assessment is a single top-level
/// checkable item (the completion check the instructor actually cares
/// about); its component steps are non-checkable bullet subItems
/// (`noteItem`) underneath it, rather than each being independently
/// checkable -- so checking off "Diver Rescue" or "ReActivate Program" is
/// the one action that counts toward progress, and the listed steps are
/// just reference detail on what that skill/workshop covers.
///
/// Unlike the single-diver Training checklists in TrainingSeedData.swift,
/// Divemaster is a candidate-tracked program (see TrainingRosterProgram):
/// an instructor runs several candidates through the same requirement set
/// at once, so `makeRequirementChecklists()` returns a blank template --
/// AppStore hands each newly-added candidate their own independent copy of
/// it rather than everyone sharing one set of checkmarks.
///
/// Kept in its own file (rather than folded into TrainingSeedData.swift)
/// since the content is sizeable on its own and conceptually separate --
/// it's a program template, not a diver's personal checklist tree.
enum DivemasterSeedData {
    static func makeRequirementChecklists() -> [Checklist] {
        [
            waterskillsExercises(),
            diverRescue(),
            practicalApplication(),
            programWorkshops(),
            practicalAssessments(),
            skillEvaluationSlate()
        ]
    }

    // MARK: - Waterskills Exercises

    private static func waterskillsExercises() -> Checklist {
        Checklist(
            name: "Waterskills Exercises",
            items: [
                item("1", "400-Metre/Yard Swim",
                     note: "Swim 400 metres/yards nonstop, without swimming aids and using any stroke or combination of strokes. Scoring (400m/400yd): under 6:30/under 6 min = 5, 6:30-8:40/6-8 min = 4, 8:40-11:00/8-10 min = 3, 11:00-13:00/10-12 min = 2, over 13:00/over 12 min = 1, stopped = incomplete.",
                     fields: [.text("Time"), .choice("Score", options: ["5", "4", "3", "2", "1", "Incomplete"])]),
                item("2", "15-Minute Tread",
                     note: "Tread water, drown-proof, bob or float using no aids and wearing only a swimsuit for 15 minutes, with hands (not arms) out of the water during the last two minutes. Scoring: performed satisfactorily = 5, stayed afloat but hands not out of water entire two minutes = 3, used side/bottom for momentary support no more than twice = 1, used side/bottom for support more than twice = incomplete.",
                     fields: [.choice("Score", options: ["5", "3", "1", "Incomplete"])]),
                item("3", "800-Metre/Yard Swim",
                     note: "Swim 800 metres/yards face down, using mask, snorkel and fins, nonstop, without flotation aids and without using arms to swim. Scoring (800m/800yd): under 14:00/under 13 min = 5, 14:00-16:30/13-15 min = 4, 16:30-18:30/15-17 min = 3, 18:30-21:00/17-19 min = 2, over 21:00/over 19 min = 1, stopped = incomplete.",
                     fields: [.text("Time"), .choice("Score", options: ["5", "4", "3", "2", "1", "Incomplete"])]),
                item("4", "100-Metre/Yard Inert Diver Tow",
                     note: "Tow (or push) a diver for 100 metres/yards nonstop, at the surface, without assistance -- both divers equipped in full scuba equipment. Scoring (100m/100yd): under 2:10/under 2 min = 5, 2:10-3:15/2-3 min = 4, 3:15-4:20/3-4 min = 3, 4:20-5:30/4-5 min = 2, over 5:30/over 5 min = 1, stopped = incomplete.",
                     fields: [.text("Time"), .choice("Score", options: ["5", "4", "3", "2", "1", "Incomplete"])]),
                item("5", "Equipment Exchange",
                     note: "In confined water, demonstrate the ability to effectively respond to an unusual circumstance underwater by exchanging all scuba equipment (except exposure suits and weight belts) with a buddy while neutrally buoyant, earning a minimum score of 3. When divers switch scuba kits they should breathe from their buddy's alternate air source, not the primary second stage; instead of exchanging masks, divers remove and replace their own masks. Scoring: 5 = well-thought-out, efficient, purposeful, no sign of problems, very low anxiety, neither diver touched the bottom or surface. 4 = performed competently with relatively low anxiety, challenges handled easily/efficiently, neither diver touched the bottom or surface. 3 = complete exchange occurred while neutrally buoyant, but numerous challenges delayed speed and efficiency (also appropriate for a diver overly dependent on another). 2 = significant problems demonstrated, exchange completed only after one or both team members surfaced once. 1 = inability to complete the exchange, or exchange completed with one or both divers surfacing more than once.",
                     fields: [.choice("Score", options: ["5", "4", "3", "2", "1"])])
            ],
            scoringNote: "Performance Requirement: Candidates must complete all five Waterskills Exercises, earning a combined exercise score of at least 15. Candidates must score at least a 3 on the Equipment Exchange; there is no passing score required for any other single exercise."
        )
    }

    // MARK: - Diver Rescue

    private static func diverRescue() -> Checklist {
        Checklist(
            name: "Diver Rescue",
            items: [
                item(nil, "Diver Rescue",
                     note: "Performance Requirement: Respond to an unresponsive, nonbreathing diver, including these steps:",
                     subItems: [
                        noteItem("Enter the water, locate and surface a submerged diver who is about 25 metres/yards away."),
                        noteItem("Turn the diver face up and establish buoyancy."),
                        noteItem("Remove the diver's mask and regulator, open airway and check for breathing."),
                        noteItem("Call for help."),
                        noteItem("Give two initial rescue breaths and continue with an effective rescue breath every five seconds with no or very few interruptions."),
                        noteItem("Tow the diver to safety while protecting the airway, continuing rescue breathing."),
                        noteItem("Remove both sets of equipment."),
                        noteItem("Exit the water with the diver.")
                     ])
            ]
        )
    }

    // MARK: - Practical Application

    private static func practicalApplication() -> Checklist {
        Checklist(
            name: "Practical Application",
            items: [
                item("1", "Dive Site Set Up and Management",
                     note: "Set up a dive site and manage predive preparation, including:",
                     subItems: [
                        noteItem("Choose a location appropriate for divers to assemble equipment."),
                        noteItem("Prepare emergency equipment, such as a first aid kit and oxygen unit."),
                        noteItem("Greet divers as they arrive at the site/boat and provide direction, such as where to place equipment, location of nearest facilities, etc."),
                        noteItem("Organize a dive roster and review check in and check out procedures with divers."),
                        noteItem("Prepare and set a float/dive flag if diving from shore, or ensure the descent line and dive flag are ready, as appropriate, on the boat."),
                        noteItem("Choose an appropriate vantage point from which to monitor the dive."),
                        noteItem("Be accessible to answer diver questions and prepared to assist divers before and after the dive.")
                     ]),
                item("2", "Mapping Project",
                     note: "Survey an open water dive site and create a detailed map of the site showing underwater relief, important points of interest, any relevant environmental notes, recommended entry/exit areas, local facilities, and potential hazards."),
                item("3", "Dive Briefing",
                     note: "Conduct a dive briefing for a familiar dive site covering all 10 points as listed on the Divemaster Slates."),
                item("4", "Search and Recovery Scenario",
                     note: "During various search and recovery scenarios, complete the following:",
                     subItems: [
                        noteItem("Demonstrate a methodical search of an area to find a small submerged object."),
                        noteItem("Demonstrate a methodical search of an area to find a submerged object not more than 11 kilograms/25 pounds negatively buoyant."),
                        noteItem("Tie the following knots correctly underwater: the bowline, two half-hitches and a sheet bend."),
                        noteItem("Demonstrate how to safely rig and bring to the surface an object not more than 11 kilograms/25 pounds negatively buoyant using an appropriate lifting device.")
                     ]),
                item("5", "Deep Dive Scenario",
                     note: "During a deep dive, complete the following:",
                     subItems: [
                        noteItem("Before the dive, prepare emergency breathing equipment and position it at the safety stop."),
                        noteItem("Descend using a reference line, wall or sloping bottom as a visual guide only, while staying with a buddy and controlling the descent rate."),
                        noteItem("Navigate with a compass at least 20 kick cycles away from and back to the reference line or designated spot."),
                        noteItem("Use a depth gauge and timing device or a dive computer to monitor an ascent rate no faster than 18 metres/60 feet per minute while using a reference line, wall or sloping bottom as a visual guide only."),
                        noteItem("Perform a 3-minute safety stop at 5 metres/15 feet before surfacing without holding on to a reference line for positioning.")
                     ]),
                item("6", "Create an Emergency Action Plan",
                     note: "Develop a written emergency action plan appropriate for the dive site, including:",
                     subItems: [
                        noteItem("Identify and record emergency contact numbers (local EMS, DAN, nearest hospital/recompression chamber) for the dive site."),
                        noteItem("Determine directions and the evacuation route from the dive site to the nearest medical facility capable of treating a diving emergency."),
                        noteItem("Confirm the location and condition of on-site emergency equipment (oxygen unit, first aid kit, AED, if available)."),
                        noteItem("Assign roles and responsibilities for an emergency response -- who calls for help, who administers oxygen/first aid, who accounts for the rest of the group."),
                        noteItem("Identify the nearest means of communication (phone, radio) and confirm it works at the site."),
                        noteItem("Post or otherwise make the plan accessible to staff and divers, and review it with the team before diving begins.")
                     ])
            ]
        )
    }

    // MARK: - Divemaster-Conducted Program Workshops

    private static func programWorkshops() -> Checklist {
        Checklist(
            name: "Divemaster-Conducted Program Workshops",
            items: [
                item("1", "ReActivate Program",
                     note: "Conduct: Review standards. Conduct a role model water skills session. Have candidates interview participants and prescriptively decide skills to practice. Ask participants to request skills to practice or imply a need to review certain skills. Assign problems for candidates to catch and correct. Remediate demonstrations and problem solving as necessary. Review procedures for processing certification cards with ReActivate dates.",
                     subItems: [
                        noteItem("Access ReActivate program standards in the PADI Instructor Manual."),
                        noteItem("State ReActivate knowledge assessment options."),
                        noteItem("Demonstrate prescriptive ReActivate method for determining skills to practice."),
                        noteItem("Recognize and correct problems during skill practice.")
                     ]),
                item("2", "Advanced Snorkeler (Skin Diver) Course and Snorkeling Supervision",
                     note: "Conduct in either confined water or open water. Conduct: Discuss the difference between a scuba dive briefing and a snorkel tour briefing. Have candidates conduct a briefing. Have candidates practice advanced snorkeling skills or lead a short tour while other candidates/staff act as participants. Randomly assign problems for candidates to catch and correct. Remediate supervision techniques and problem solving as necessary.",
                     subItems: [
                        noteItem("Give the Advanced Snorkeler course briefing; or a snorkeling tour briefing."),
                        noteItem("Conduct an Advanced Snorkeler course confined water or open water dive; or lead a snorkel tour, demonstrating control and supervision."),
                        noteItem("Recognize and correct problems during the dive or snorkel tour.")
                     ]),
                item("3", "Discover Scuba Diving Program in Confined Water",
                     note: "Conduct: Review standards regarding a certified assistant during a confined water experience. Conduct a role model confined water session. Have candidates act as a certified assistant while other candidates/staff act as participants. Randomly assign problems for candidates to catch and correct. Remediate assistant positioning, supervision and problem solving as necessary. Review Discover Scuba Diving Leader Internship requirements.",
                     subItems: [
                        noteItem("Access Discover Scuba Diving program standards in the PADI Instructor Manual and explain a divemaster's role as an assistant during a confined water experience."),
                        noteItem("Demonstrate proper positioning relative to the participants as directed by the instructor."),
                        noteItem("Recognize and correct problems during the experience.")
                     ]),
                item("4", "Discover Scuba Diving Program -- Additional Open Water Dive",
                     note: "Conduct: Review standards relative to a divemaster-led additional open water dive. Have candidates conduct a dive briefing. Have candidates lead the dive while other candidates/staff act as participants. Randomly assign problems for candidates to catch and correct. Remediate supervision techniques and problem solving as necessary.",
                     subItems: [
                        noteItem("State the ratio and supervision requirements for an additional dive for Discover Scuba Diving participants conducted by a PADI Divemaster (subsequent to the initial open water dive conducted by the PADI Instructor)."),
                        noteItem("Give a dive briefing appropriate for Discover Scuba Diving participants for this additional open water dive."),
                        noteItem("Give a dive briefing appropriate for Discover Scuba Diving participants for a subsequent open water dive."),
                        noteItem("Lead the dive, demonstrating proper control and required supervision."),
                        noteItem("Recognize and correct problems during the dive.")
                     ]),
                item("5", "Discover Local Diving in Open Water",
                     note: "Conduct: Review standards. Ask candidates to evaluate dive conditions and explain observations. Have candidates create a dive plan and conduct a dive briefing. Have candidates lead the dive while other candidates/staff act as participants. Randomly assign problems for candidates to catch and correct. Remediate supervision techniques and problem solving as necessary. Have candidates demonstrate how to deploy one or more types of surface markers used in the region.",
                     subItems: [
                        noteItem("Locate Discover Local Diving program standards in the PADI Instructor Manual."),
                        noteItem("Assess dive site conditions and plan the dive."),
                        noteItem("Give a Discover Local Diving briefing."),
                        noteItem("Lead a dive, demonstrating control and supervision."),
                        noteItem("Recognize and correct problems during the dive."),
                        noteItem("Demonstrate how to deploy a surface marker.")
                     ])
            ]
        )
    }

    // MARK: - Practical Assessments

    private static func practicalAssessments() -> Checklist {
        Checklist(
            name: "Practical Assessments",
            items: [
                item("1", "Open Water Diver Students in Confined Water", subItems: [
                    noteItem("Organize predive equipment setup by student divers."),
                    noteItem("Coordinate student diver flow during training."),
                    noteItem("Supervise student divers not receiving the immediate attention of the instructor during training."),
                    noteItem("Help a student diver overcome a learning difficulty."),
                    noteItem("Respond to, or prevent, student diver problems as they occur."),
                    noteItem("Demonstrate a skill for student divers.")
                ]),
                item("2", "Open Water Diver Students in Open Water", subItems: [
                    noteItem("Assess an open water training site; report recommendations as to site suitability for training entry-level divers."),
                    noteItem("Organize predive equipment setup by student divers."),
                    noteItem("Assist in the preparation of the site."),
                    noteItem("Coordinate student diver flow during training."),
                    noteItem("Supervise student divers not receiving the immediate attention of the instructor during training."),
                    noteItem("Respond to, or prevent, student diver problems as they occur."),
                    noteItem("Lead student divers on an underwater tour (ratio 2:1).")
                ]),
                item("3", "Continuing Education Student Divers in Open Water", subItems: [
                    noteItem("Coordinate student diver flow during training."),
                    noteItem("Escort continuing education student divers (under the indirect supervision of the instructor) during training; report performance and learning difficulties to instructor."),
                    noteItem("Help a continuing education student diver overcome a learning difficulty."),
                    noteItem("Respond to, or prevent, student diver problems as they occur.")
                ]),
                item("4", "Certified Divers in Open Water", subItems: [
                    noteItem("Conduct environmental and diver assessments, taking appropriate supervisory steps based on the assessments."),
                    noteItem("Give a predive briefing appropriate to the dive site."),
                    noteItem("Account for buddy teams entering and leaving the water."),
                    noteItem("Respond to, or prevent, diver problems appropriately.")
                ])
            ]
        )
    }

    // MARK: - Skill Evaluation Slate
    //
    // The 24-skill scoring slate from PADI's separate "Skill Evaluation
    // Slate" card. Every skill gets a 1-5 Score field matching the
    // Evaluation Criteria, which is transcribed once as a
    // header note rather than repeated on each item. Skills 7 and 8 are the
    // two skills the physical slate marks with "*" -- they can only be
    // scored a 5 if performed neutrally buoyant, called out on the affected
    // items via both the "*" in the item text and an explicit note (matching
    // the slate's own footnote placement).

    private static func skillEvaluationSlate() -> Checklist {
        Checklist(
            name: "Skill Evaluation Slate",
            items: [
                noteItem("Evaluation Criteria -- 1: participant unable to perform exercise. 2: exercise performed with significant difficulty or error. 3: exercise performed correctly, though too quickly to adequately exhibit (or illustrate) details of skill. 4: exercise performed correctly and slowly enough to adequately exhibit (or illustrate) details of skill. 5: exercise performed correctly, slowly and with exaggerated movement (appeared \"easy\")."),
                item("1", "Equipment assembly, adjustment, preparation, donning and disassembly", fields: [scoreField()]),
                item("2", "Predive safety check (BWRAF)", fields: [scoreField()]),
                item("3", "Deep-water entry", fields: [scoreField()]),
                item("4", "Buoyancy check at surface", fields: [scoreField()]),
                item("5", "Snorkel-regulator/regulator-snorkel exchange", fields: [scoreField()]),
                item("6", "Five-point descent, using buoyancy control to stop descent without contacting the bottom", fields: [scoreField()]),
                item("7", "Regulator recovery and clearing *", note: "* To earn a 5, diver must demonstrate skill while neutrally buoyant.", fields: [scoreField()]),
                item("8", "Mask removal, replacement and clearing *", note: "* To earn a 5, diver must demonstrate skill while neutrally buoyant.", fields: [scoreField()]),
                item("9", "Air depletion exercise and alternate air source use (stationary)", fields: [scoreField()]),
                item("10", "Alternate air source-assisted ascent", fields: [scoreField()]),
                item("11", "Free flowing regulator breathing", fields: [scoreField()]),
                item("12", "Neutral buoyancy, rise and fall -- using low pressure inflation", fields: [scoreField()]),
                item("13", "Five-point ascent", fields: [scoreField()]),
                item("14", "Controlled Emergency Swimming Ascent", fields: [scoreField()]),
                item("15", "Orally inflate BCD to hover for at least 60 seconds", fields: [scoreField()]),
                item("16", "Underwater swim without a mask", fields: [scoreField()]),
                item("17", "Remove and replace weight system underwater", fields: [scoreField()]),
                item("18", "Remove and replace scuba unit underwater", fields: [scoreField()]),
                item("19", "Remove and replace scuba unit on the surface", fields: [scoreField()]),
                item("20", "Remove and replace weight system on the surface", fields: [scoreField()]),
                item("21", "Surface dive while skin diving and clear snorkel using blast method upon surfacing", fields: [scoreField()]),
                item("22", "Disconnect low pressure inflator", fields: [scoreField()]),
                item("23", "Re-secure a loose cylinder band", fields: [scoreField()]),
                item("24", "Perform an emergency weight drop", fields: [scoreField()])
            ],
            scoringNote: "Performance Requirement: Demonstrate all scuba and snorkeling skills, scoring at least a 3 on each skill, and scoring at least 82 points total, with at least one underwater skill to a 5."
        )
    }

    private static func scoreField() -> ItemField {
        .choice("Score", options: ["1", "2", "3", "4", "5"])
    }

    // MARK: - Item helpers (mirrors SeedData.swift's helpers -- kept local
    // since SeedData's are private to that enum)

    private static func item(_ text: String) -> ChecklistItem {
        ChecklistItem(text: text)
    }

    private static func item(
        _ label: String?,
        _ text: String,
        note: String? = nil,
        fields: [ItemField] = [],
        subItems: [ChecklistItem] = []
    ) -> ChecklistItem {
        ChecklistItem(label: label, text: text, note: note, fields: fields, subItems: subItems)
    }

    private static func noteItem(_ text: String, fields: [ItemField] = []) -> ChecklistItem {
        ChecklistItem(text: text, isNote: true, fields: fields)
    }
}
