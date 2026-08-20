import Foundation

/// Content for the PADI Advanced Open Water Diver certification -- transcribed
/// from PADI's own Advanced Open Water Diver Instructor Slates (14 cards: the
/// 13 Adventure Dive slates plus the separate "Thinking Like a Diver" card
/// that isn't a dive at all, but shared briefing/debriefing framework content
/// used across every Adventure Dive).
///
/// Each dive's slate has two distinct sections on the physical card: a flat,
/// unlabeled predive/dive/postdive process list, and a "<Dive Name> --
/// Performance Requirements" list of what the student diver must be able to
/// do by the end of the dive. Both are represented here as two top-level
/// items per checklist -- "Process" and "Performance Requirements" -- with
/// the card's own bullets as subItems underneath; "Process" is a label
/// invented for structure here since the card itself doesn't title that
/// section. Altitude Dive additionally has a card-labeled "Optional" bullet,
/// kept as its own third top-level item rather than folded into Performance
/// Requirements. Indented sub-bullets on the card (Peak Performance
/// Buoyancy's weight-rigging considerations; Thinking Like a Diver's two
/// debrief follow-up questions) become nested subItems.
///
/// Like TrainingSeedData.swift's other plain `TrainingCertification` content
/// (PADI Open Water Diver, SDI Open Water Scuba Diver), every item here is a
/// non-checkable reference bullet (`isNote: true`) rather than a checkable
/// one -- Advanced Open Water isn't candidate-tracked the way Divemaster is
/// (see DivemasterSeedData.swift), so there's no per-student "reset" workflow
/// that a checkbox would support. An instructor uses this as a static
/// reference list, not a per-student checklist.
///
/// Two things on the physical cards aren't represented here since the app's
/// checklist model is text-only: the Search and Recovery Dive card's
/// knot-tying diagrams (Bowline, Two Half-Hitches, Sheet Bend) alongside its
/// knot-tying performance requirement, and handwritten annotations/instructor
/// signatures present on a couple of cards (a "w/assistant" note on
/// Underwater Navigation Dive, illegible signatures on Altitude Dive) --
/// personal markings, not official card content.
///
/// Kept in its own file (rather than folded into TrainingSeedData.swift)
/// since the content is sizeable on its own and conceptually separate --
/// see DivemasterSeedData.swift for the same reasoning.
enum AdvancedOpenWaterSeedData {
    static func makeChecklists() -> [Checklist] {
        [
            thinkingLikeADiver(),
            deepDive(),
            underwaterNavigationDive(),
            wreckDive(),
            underwaterNaturalistDive(),
            searchAndRecoveryDive(),
            peakPerformanceBuoyancyDive(),
            nightDive(),
            fishIdentificationDive(),
            drySuitDive(),
            driftDive(),
            digitalUnderwaterImagingDive(),
            boatDive(),
            altitudeDive()
        ]
    }

    // MARK: - Thinking Like a Diver

    private static func thinkingLikeADiver() -> Checklist {
        Checklist(
            name: "Thinking Like a Diver",
            items: [
                item(nil, "Adventure Dive briefing reminders", subItems: [
                    noteItem("Primary objective (returning safely) and secondary objectives."),
                    noteItem("Dive planning -- maximum depth, maximum time, gas turn, reserve and ascent pressures."),
                    noteItem("Situational awareness -- gas management, exertion, depth, buddy, navigation, equipment, hazards and the environment."),
                    noteItem("Managing task loading -- dive first, situation second, communicate third."),
                    noteItem("Practicing good habits -- examples: predive safety check, mask on and snorkel or regulator in, maintaining buoyancy and diving conservatively.")
                ]),
                item(nil, "Adventure Dive debriefing questions", subItems: [
                    item(nil, "What did you base your gas planning on? How did that work out?", subItems: [
                        noteItem("When did you turn the dive? Why?"),
                        noteItem("How much of your reserve pressure did you have left?")
                    ]),
                    item(nil, "What choices did you have to make based on environmental conditions?", subItems: [
                        noteItem("How did you and your buddy communicate this?"),
                        noteItem("Which of these were expected and which were unexpected?")
                    ]),
                    noteItem("How did you navigate to and from the entry/exit point?"),
                    noteItem("What are examples of how you used thinking priorities on the dive? (Dive first, situation second, communicate third.)"),
                    noteItem("What good dive habits did you practice and observe in your buddy?"),
                    noteItem("If you could change anything and do it differently from this dive, what would it be?"),
                    noteItem("What did you learn on this dive?")
                ])
            ]
        )
    }

    // MARK: - Deep Dive

    private static func deepDive() -> Checklist {
        Checklist(
            name: "Deep Dive",
            items: [
                processItem([
                    "Knowledge Review",
                    "Assembling and Positioning Emergency Equipment",
                    "Briefing -- Thinking Like a Diver",
                    "Plan Dive Limits and Gas Management",
                    "Gearing Up",
                    "Predive Safety Check",
                    "Entry",
                    "Descent",
                    "Compare Changes in Color",
                    "Depth Gauge Comparisons at Depth",
                    "Tour (time/air pressure permitting)",
                    "Ascent -- Safety Stop",
                    "Debrief -- Thinking Like a Diver",
                    "Log Dive -- Complete Adventure Dive Training Record"
                ]),
                performanceRequirements([
                    "With a buddy, plan and manage gas use, including determining turn pressure, ascent pressure and reserve pressure. Establish no stop and dive time limits.",
                    "Descend using a line, wall or sloping bottom.",
                    "Compare changes in color at the surface and at depth.",
                    "Compare a dive computer (or depth gauge) reading to another diver's depth reading.",
                    "Ascend at a rate not to exceed 18 metres/60 feet per minute using a dive computer (or depth gauge and timing device).",
                    "Make a safety stop at 5 metres/15 feet for at least three minutes."
                ])
            ]
        )
    }

    // MARK: - Underwater Navigation Dive

    private static func underwaterNavigationDive() -> Checklist {
        Checklist(
            name: "Underwater Navigation Dive",
            items: [
                processItem([
                    "Knowledge Review",
                    "Compass Use on Land",
                    "Briefing -- Thinking Like a Diver",
                    "Gearing Up",
                    "Predive Safety Check",
                    "Entry",
                    "Descent",
                    "Distance/Time Estimation Swim",
                    "Navigate a Straight Line Using Natural Navigation Techniques",
                    "Navigate a Straight Line and its Reciprocal Underwater Using a Compass",
                    "Navigate a Square Pattern Underwater Using a Compass",
                    "Ascent -- Safety Stop",
                    "Exit",
                    "Debrief -- Thinking Like a Diver",
                    "Log Dive -- Complete Adventure Dive Training Record"
                ]),
                performanceRequirements([
                    "Maintain neutral buoyancy.",
                    "Determine the average number of kick cycles and average amount of time required to swim underwater at a normal, relaxed pace approximately 30 metres/100 feet.",
                    "Navigate to a predetermined location and return to within 15 metres/50 feet of the starting point using natural references and estimated distance measurement (kick cycles or time). Surface only if necessary to verify direction or location.",
                    "Position and handle a compass underwater to maintain an accurate heading while swimming.",
                    "Navigate without surfacing to a predetermined location and return to within 6 metres/20 feet of the starting point using a compass and estimated distance measurement (kick cycles or time).",
                    "Swim a square or rectangular pattern underwater, returning to within 8 metres/25 feet of the starting point using a compass and beginning from a fixed location. Recommended size of square -- each side 30 metres/100 feet, or total combined length of approximately 120 metres/400 feet."
                ])
            ]
        )
    }

    // MARK: - Wreck Dive

    private static func wreckDive() -> Checklist {
        Checklist(
            name: "Wreck Dive",
            items: [
                processItem([
                    "Knowledge Review",
                    "Briefing -- Thinking Like a Diver",
                    "Gearing Up",
                    "Predive Safety Check",
                    "Entry",
                    "Descent",
                    "Navigating the Wreck",
                    "Returning to Ascent Point",
                    "Ascent -- Safety Stop",
                    "Exit",
                    "Debrief -- Thinking Like a Diver",
                    "Log Dive -- Complete Adventure Dive Training Record"
                ]),
                performanceRequirements([
                    "Swim on the outside of a wreck while maintaining proper buoyancy. Identify and avoid potential hazards.",
                    "Navigate the wreck to locate the ascent point without surfacing. Use instructor/certified assistant as needed.",
                    "Maintain neutral buoyancy and body position to avoid touching the bottom and the wreck."
                ])
            ]
        )
    }

    // MARK: - Underwater Naturalist Dive

    private static func underwaterNaturalistDive() -> Checklist {
        Checklist(
            name: "Underwater Naturalist Dive",
            items: [
                processItem([
                    "Knowledge Review",
                    "Briefing -- Thinking Like a Diver",
                    "Gearing Up",
                    "Predive Safety Check",
                    "Entry",
                    "Descent",
                    "Identification of Aquatic Plant Life",
                    "Identification and Observation of Aquatic Invertebrate Animals",
                    "Identification and Observation of Aquatic Vertebrate Animals",
                    "Ascent -- Safety Stop",
                    "Exit",
                    "Debrief -- Thinking Like a Diver",
                    "Log Dive -- Complete Adventure Dive Training Record"
                ]),
                performanceRequirements([
                    "Passively observe aquatic life.",
                    "Maintain neutral buoyancy and body-positioning to avoid negative effects on aquatic organisms.",
                    "With a buddy, locate and identify at least two aquatic plants (one for freshwater).",
                    "With a buddy, locate, observe and identify at least four aquatic invertebrate animals (one for freshwater).",
                    "With a buddy, locate, observe and identify at least five aquatic vertebrate animals (two for freshwater)."
                ])
            ]
        )
    }

    // MARK: - Search and Recovery Dive
    //
    // The physical card also shows knot-tying diagrams (Bowline, Two
    // Half-Hitches, Sheet Bend) alongside the knot-tying performance
    // requirement below -- not representable in the app's text-only
    // checklist model, so only the requirement text is included.

    private static func searchAndRecoveryDive() -> Checklist {
        Checklist(
            name: "Search and Recovery Dive",
            items: [
                processItem([
                    "Knowledge Review",
                    "Briefing -- Thinking Like a Diver",
                    "Practice Search Patterns on Land",
                    "Practice Object Rigging on Land",
                    "Gearing Up",
                    "Predive Safety Check",
                    "Entry",
                    "Descent",
                    "Small Area Search",
                    "Large Area Search",
                    "Knot Tying",
                    "Rigging and Lifting an Object",
                    "Ascent and Safety Stop",
                    "Exit",
                    "Debrief -- Thinking Like a Diver",
                    "Log Dive -- Complete Adventure Dive Training Record"
                ]),
                performanceRequirements([
                    "Search an area approximately 15 x 15 metres/50 x 50 feet to find a small submerged object, or search until reaching a planned dive limit.",
                    "Search an area approximately 30 x 30 metres/100 x 100 feet to find a submerged object that weighs no more than 11 kilograms/25 pounds, or search until reaching a planned dive limit.",
                    "Tie knots underwater: bowline, two half-hitches, sheet bend.",
                    "Use an appropriate lifting device to safely rig and bring to the surface an object that weighs no more than 11 kilograms/25 pounds."
                ])
            ]
        )
    }

    // MARK: - Peak Performance Buoyancy Dive

    private static func peakPerformanceBuoyancyDive() -> Checklist {
        Checklist(
            name: "Peak Performance Buoyancy Dive",
            items: [
                processItem([
                    "Knowledge Review",
                    "Briefing -- Thinking Like a Diver",
                    "Assembly of Weight System",
                    "Streamline Equipment",
                    "Gearing Up",
                    "Predive Safety Check",
                    "Entry",
                    "Predive Buoyancy Check",
                    "Neutral Buoyancy During Slow Descent",
                    "Hover -- 60 seconds",
                    "Fine-tune and Control Buoyancy",
                    "Hover -- Different Positions",
                    "Ascent -- Safety Stop",
                    "Exit",
                    "Debrief -- Thinking Like a Diver",
                    "Log Dive -- Complete Adventure Dive Training Record"
                ]),
                item(nil, "Performance Requirements", subItems: [
                    item(nil, "Rig a weight system with the following considerations in mind:", subItems: [
                        noteItem("Estimate weights using PADI's Basic Weighting Guidelines and/or based on prior experience using the same equipment in the same type of environment."),
                        noteItem("Position and distribute the weight for comfort and desired body position (trim) in the water.")
                    ]),
                    noteItem("Streamline equipment by properly securing and attaching all hoses, gauges and accessories."),
                    noteItem("Adjust for proper weighting -- float at eye level at the surface with an empty BCD, while holding a normal breath (top of head level if using a rebreather)."),
                    noteItem("Make a controlled, slow descent to the bottom and adjust for neutral buoyancy."),
                    noteItem("Adjust for neutral buoyancy at a predetermined depth."),
                    noteItem("Hover for 60 seconds without rising or sinking more than 1 metre/3 feet by making minor depth adjustments using breath control only (open-circuit scuba), or using very minor hand/fin sculling only (rebreathers)."),
                    noteItem("Throughout the dive, control buoyancy and swim relaxed and neutrally buoyant in a horizontal position without touching the bottom or breaking the surface, making frequent and small adjustments to buoyancy as needed."),
                    noteItem("Reposition weights as appropriate to adjust trim, and hover in different positions -- vertical, horizontal, feet elevated and head elevated."),
                    noteItem("Conduct a post-dive buoyancy check to confirm the appropriateness of the amount of weight worn.")
                ])
            ]
        )
    }

    // MARK: - Night Dive

    private static func nightDive() -> Checklist {
        Checklist(
            name: "Night Dive",
            items: [
                processItem([
                    "Knowledge Review",
                    "Briefing -- Thinking Like a Diver",
                    "Gearing Up",
                    "Predive Safety Check",
                    "Entry",
                    "Descent",
                    "Acclimatization on the Bottom",
                    "Navigation Exercise",
                    "Tour",
                    "Ascent -- Safety Stop",
                    "Exit",
                    "Debrief -- Thinking Like a Diver",
                    "Log Dive -- Complete Adventure Dive Training Record"
                ]),
                performanceRequirements([
                    "Descend using a reference line or sloping bottom.",
                    "Communicate on the dive using both hand signals and dive lights.",
                    "Demonstrate how to use a dive light, submersible pressure gauge, compass, timing device and depth gauge at night.",
                    "Navigate to a predetermined location using a compass/natural features and return to within 8 metres/25 feet of the starting point. When necessary, surface for orientation.",
                    "Maintain buddy contact throughout the dive.",
                    "Ascend using a reference line or sloping bottom."
                ])
            ]
        )
    }

    // MARK: - Fish Identification Dive

    private static func fishIdentificationDive() -> Checklist {
        Checklist(
            name: "Fish Identification Dive",
            items: [
                processItem([
                    "Knowledge Review",
                    "Slate Preparation",
                    "Briefing -- Thinking Like a Diver",
                    "Equipment Preparation",
                    "Predive Safety Check",
                    "Entry",
                    "Descent",
                    "Observe and Identify Fish Families",
                    "Record Sightings",
                    "Sketch/Describe Unfamiliar Fish",
                    "Ascent and Exit",
                    "Post Dive Procedures",
                    "Use Reference Materials to Identify Unfamiliar Fish",
                    "Debrief -- Thinking Like a Diver",
                    "Log Dive -- Complete Adventure Dive Training Record"
                ]),
                performanceRequirements([
                    "Categorize fish by placing them in appropriate family groups, and identify specific species when possible.",
                    "Record fish sightings on a slate, including abundance and habitat information when possible.",
                    "Sketch/photograph and describe characteristics of unfamiliar fish, then attempt to determine their identities after the dive using a field guide, fish identification slate and/or online resources.",
                    "Demonstrate appropriate and responsible diving practices and behaviors to minimize negative environmental effects."
                ])
            ]
        )
    }

    // MARK: - Dry Suit Dive

    private static func drySuitDive() -> Checklist {
        Checklist(
            name: "Dry Suit Dive",
            items: [
                processItem([
                    "Knowledge Review",
                    "Briefing -- Thinking Like a Diver",
                    "Gearing Up",
                    "Predive Safety Check",
                    "Entry",
                    "Buoyancy Check with Dry Suit",
                    "Descent",
                    "Neutral Buoyancy -- Rising and Falling",
                    "Neutral Buoyancy -- Hovering",
                    "Dry Suit Dive for Fun and Pleasure",
                    "Ascent -- Safety Stop",
                    "Scuba Unit and Weight Belt Remove and Replace at Surface",
                    "Exit",
                    "Debrief -- Thinking Like a Diver",
                    "Log Dive -- Complete Adventure Dive Training Records"
                ]),
                performanceRequirements([
                    "Put on and remove a dry suit with another diver's help.",
                    "Adjust weighting at the surface -- deflate BCD and dry suit, hold a normal breath and float at eye level (top of head level if using a rebreather).",
                    "Perform a controlled descent and avoid suit squeeze.",
                    "Become neutrally buoyant underwater by gently rising and falling in a controlled manner during inhalation and exhalation for one minute (rise and fall not required if using a rebreather).",
                    "Hover using buoyancy control for at least one minute, without kicking or sculling (minor hand sculling allowed if using a rebreather).",
                    "Maintain neutral buoyancy during the dive and avoid accidentally kicking up silt or touching the bottom.",
                    "Perform a neutrally buoyant ascent from the bottom, at a rate no faster than 9 metres/30 feet per minute.",
                    "Make a safety stop at 5 metres/15 feet for at least three minutes.",
                    "Remove and replace the scuba kit and the weights (if worn), on the surface."
                ])
            ]
        )
    }

    // MARK: - Drift Dive

    private static func driftDive() -> Checklist {
        Checklist(
            name: "Drift Dive",
            items: [
                processItem([
                    "Knowledge Review",
                    "Briefing -- Thinking Like a Diver",
                    "Gearing Up",
                    "Predive Safety Check",
                    "Entry",
                    "Group Descent",
                    "Maintain Buddy Contact",
                    "Maintain Neutral Buoyancy",
                    "Drift Dive for Fun and Pleasure",
                    "Ascent -- Safety Stop",
                    "Exit",
                    "Debrief -- Thinking Like a Diver",
                    "Log Dive -- Complete Adventure Dive Training Record"
                ]),
                performanceRequirements([
                    "With a buddy, plan a drift dive accounting for appropriate techniques for the environment, conditions, depth and other variables.",
                    "Make an entry specific to the environmental conditions and the planned drift technique(s).",
                    "Maintain buddy contact as planned for that environment.",
                    "Maintain neutral buoyancy and avoid unintended contact with aquatic life and the bottom.",
                    "Make a safety stop at 5 metres/15 feet for at least three minutes.",
                    "Exit as planned, specific to the particular environmental conditions."
                ])
            ]
        )
    }

    // MARK: - Digital Underwater Imaging Dive

    private static func digitalUnderwaterImagingDive() -> Checklist {
        Checklist(
            name: "Digital Underwater Imaging Dive",
            items: [
                processItem([
                    "Knowledge Review",
                    "Briefing -- Thinking Like a Diver",
                    "Prepare and Assemble Underwater Camera System",
                    "Gearing Up",
                    "Predive Safety Check",
                    "Entry",
                    "Descent",
                    "Shoot Images -- Demonstrate Exposure, Focus and Composition",
                    "Ascent -- Safety Stop",
                    "Exit",
                    "Debrief -- Thinking Like a Diver",
                    "Post-dive Care and Disassemble Underwater Camera System",
                    "Log Dive -- Complete Adventure Dive Training Record"
                ]),
                performanceRequirements([
                    "Demonstrate how to properly set up an underwater camera system, including camera and external light (if used) settings and housing preparation.",
                    "Shoot stills and/or video that demonstrate fundamentally useable exposure, focus and composition.",
                    "If shooting video, demonstrate fundamental awareness of shooting to tell a story and allow for editing.",
                    "Dive with a camera in a manner that demonstrates prioritizing diver safety and protecting the environment over imaging and cameras."
                ])
            ]
        )
    }

    // MARK: - Boat Dive

    private static func boatDive() -> Checklist {
        Checklist(
            name: "Boat Dive",
            items: [
                processItem([
                    "Knowledge Review",
                    "Briefing -- Thinking Like a Diver",
                    "Gearing Up",
                    "Predive Safety Check",
                    "Boat Diving Entry",
                    "Descent",
                    "Dive for Fun and Pleasure",
                    "Navigate From and Back to Boat",
                    "Ascent -- Safety Stop",
                    "Surface Signaling Device Use",
                    "Boat Diving Exit",
                    "Stow Equipment",
                    "Debrief -- Thinking Like a Diver",
                    "Log Dive -- Complete Adventure Dive Training Record"
                ]),
                performanceRequirements([
                    "Identify the following areas of the specific boat being used for the dive: bow, stern, starboard, port, entry area, exit area and area to stow dive equipment.",
                    "Locate important emergency/safety equipment aboard the boat (such as: first aid kit, oxygen, AED unit, life preservers, dive flag, radio and fire extinguisher).",
                    "Enter the water based on the type of dive boat being used.",
                    "Navigate from and back to the boat, using method appropriate for the environment, and ascend using the boat's mooring/anchor line, a reference line, or near the exit area, as planned and appropriate for the environment and boat.",
                    "Make a safety stop at 5 metres/15 feet for at least three minutes.",
                    "Deploy an inflatable signal tube at the surface, or deploy a delayed surface marker buoy (DSMB) from underwater.",
                    "Exit the water based on the type of dive boat being used."
                ])
            ]
        )
    }

    // MARK: - Altitude Dive

    private static func altitudeDive() -> Checklist {
        Checklist(
            name: "Altitude Dive",
            items: [
                processItem([
                    "Knowledge Review",
                    "Briefing -- Thinking Like a Diver",
                    "Gearing Up",
                    "Predive Safety Check",
                    "Entry",
                    "Descent",
                    "Computer Depth Reading Comparisons",
                    "Tour (time/air pressure permitting)",
                    "Ascent -- Safety Stop",
                    "Exit",
                    "Debrief -- Thinking Like a Diver",
                    "Log Dive -- Complete Adventure Dive Training Record"
                ]),
                performanceRequirements([
                    "Determine the no decompression limits for depth at the altitude at which the dive will take place using a dive computer that has altitude capability or using the Recreational Dive Planner and the Theoretical Depth at Altitude Table.",
                    "Descend using a reference line or sloping bottom.",
                    "Compare computer depth readings to another diver's computer (or depth gauge) and record differences (if any) on a slate or wet book.",
                    "Ascend no faster than 9 metres/30 feet per minute, using a dive computer (or depth gauge and timing device).",
                    "Ascend using a reference line or sloping bottom.",
                    "Make a safety stop for at least three minutes at a theoretical depth of 5 metres/15 feet, or as guided by dive computer."
                ]),
                item(nil, "Optional", subItems: [
                    noteItem("Demonstrate the correct use of the Recreational Dive Planner and the Theoretical Depth at Altitude Chart for planning single and repetitive dives at altitude.")
                ])
            ]
        )
    }

    // MARK: - Section helpers

    /// The card's own flat, unlabeled process list -- see the file doc
    /// comment for why "Process" is a synthesized heading rather than
    /// transcribed text.
    private static func processItem(_ steps: [String]) -> ChecklistItem {
        item(nil, "Process", subItems: steps.map { noteItem($0) })
    }

    /// The card's own "<Dive Name> -- Performance Requirements" list.
    private static func performanceRequirements(_ requirements: [String]) -> ChecklistItem {
        item(nil, "Performance Requirements", subItems: requirements.map { noteItem($0) })
    }

    // MARK: - Item helpers (mirrors SeedData.swift's helpers -- kept local
    // since SeedData's are private to that enum)
    //
    // Every item here is a non-checkable reference bullet (isNote: true) --
    // see the file doc comment above.

    private static func item(
        _ label: String?,
        _ text: String,
        note: String? = nil,
        fields: [ItemField] = [],
        subItems: [ChecklistItem] = []
    ) -> ChecklistItem {
        ChecklistItem(label: label, text: text, note: note, isNote: true, fields: fields, subItems: subItems)
    }

    private static func noteItem(_ text: String, fields: [ItemField] = []) -> ChecklistItem {
        ChecklistItem(text: text, isNote: true, fields: fields)
    }
}
