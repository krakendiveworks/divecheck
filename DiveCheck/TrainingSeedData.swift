import Foundation

/// Builds the starting content for the Training section (Settings >
/// Training toggle). Grouped by certifying agency, then by certification
/// level, then by dive/skill-grouping -- each level is just a set of
/// Checklists reusing the existing Checklist/ChecklistItem model, so
/// ChecklistDetailView renders and edits these exactly like the main Dive
/// Checklists tree with no new UI needed.
///
/// Kept separate from SeedData.swift (rather than folding in) since this is
/// an independently-growing tree -- new agencies and certification levels
/// get added here over time without bloating the main checklist seed file,
/// and it reseeds against its own content-version key so adding a new
/// agency/certification later doesn't force a reseed of the user's
/// checklists, equipment, etc.
enum TrainingSeedData {
    /// Bump whenever this file's content changes (new agency, new
    /// certification, wording/skill edits). AppStore compares against a
    /// value saved on-device (separate key from SeedData's contentVersion)
    /// and reseeds trainingAgencies automatically when it's higher.
    ///
    /// v2: PADI > Open Water Diver > Confined Water Dives -- full content
    /// transcribed from the "Aquatic Cue Card - Confined Water Dives"
    /// photos (Dives 1-5, Waterskills Assessment, Dive Flexible Skills).
    /// Each skill item's note is the matching numbered Performance
    /// Requirement text from the back of that dive's card, only where a
    /// confident match exists -- a handful of skills (predive prep, exit,
    /// equipment stowage, "fun and skill practice") have no single numbered
    /// requirement tied to them and are left without a note. Skills Bill
    /// crossed out on his cards as not covered that dive (a couple of
    /// "dive flexible" items on Dives 3 and 4) are omitted here too --
    /// they're still covered in the Dive Flexible Skills checklist below.
    /// Dive 2's Performance Requirements card was partly obscured by an
    /// overlapping card in the photo; the left edge of each line was
    /// reconstructed from the visible remainder plus the standard PADI
    /// phrasing used on the other four cards -- worth a quick check against
    /// the physical card if anything there reads oddly.
    ///
    /// v3: SDI > Open Water Scuba Diver > Confined Water Dives -- CW1-CW4
    /// transcribed from SDI's own training slates (each slate is a flat
    /// skill checklist, not paired with a separate performance-requirement
    /// card like PADI's, so these items have no note text). Bold section
    /// lines with their own sub-steps (ABCDE, 6 Point Descent, Mask, BCD,
    /// etc.) became a checkable parent item with lettered checkable
    /// subItems, mirroring how each line has its own checkbox on the
    /// physical slate.
    ///
    /// v4: SDI > Open Water Scuba Diver > Open Water Dives -- OW1-OW4
    /// transcribed the same way as the Confined Water slates above (flat
    /// checklists, no separate performance-requirement text). OW1's blue
    /// "Check for Signed Waiver Releases" banner isn't a checkbox row on
    /// the physical slate, so it became a plain note item at the top of
    /// that checklist instead of a checkable step.
    ///
    /// v5: PADI > Divemaster -- added as a roster program (agency.rosterPrograms)
    /// rather than a plain certification, since Divemaster requirements are
    /// tracked per-candidate: an instructor adds each student by name and
    /// gets them their own independent copy of the 5 requirement checklists
    /// (Waterskills Exercises, Diver Rescue & Dive Skills Workshop,
    /// Practical Skills, Divemaster-Conducted Program Workshops, Practical
    /// Assessments), so one candidate's checkmarks never affect another's.
    /// Content transcribed from the 8 PADI Divemaster training slate photos
    /// -- see DivemasterSeedData.swift for the full checklist content and
    /// per-checklist transcription notes.
    ///
    /// v6: PADI > Divemaster -- added the "Skill Evaluation Slate" checklist
    /// (24 skills, each scored 1-5 against the slate's Evaluation Criteria,
    /// transcribed once as a header note) transcribed from the separate
    /// PADI "Skill Evaluation Slate" card. Skills 7 and 8 (Regulator
    /// recovery and clearing; Mask removal, replacement and clearing) are
    /// the two the physical slate marks with "*" -- a 5 on either requires
    /// performing the skill neutrally buoyant, called out on those two
    /// items specifically. See DivemasterSeedData.swift.
    ///
    /// v7: fixes a real iCloud sync race that could silently undo v6's
    /// reseed on a device with real iCloud sync history (this is why the
    /// Skill Evaluation Slate showed up correctly in the Simulator but not
    /// on a physical iPhone that had been used across many earlier test
    /// sessions) -- AppStore.reloadFromCloud now checks a synced version
    /// marker before applying an incoming trainingAgencies change, instead
    /// of blindly trusting whatever iCloud sends. See CloudSync.swift and
    /// AppStore.swift. v7 forces one more clean, now-protected reseed.
    ///
    /// v8: PADI > Divemaster -- restructured several checklists so each
    /// skill/workshop/assessment is a single completion check, with its
    /// component steps as non-checkable bullet reference text underneath
    /// rather than independently checkable items:
    /// - Removed the "Dive Skills Workshop" item; the checklist (renamed
    ///   "Diver Rescue", was "Diver Rescue & Dive Skills Workshop") now
    ///   only has the "Diver Rescue" completion check, with its 8 steps as
    ///   bullets.
    /// - Renamed "Practical Skills" to "Practical Application"; its
    ///   sub-steps are now bullets. Added a new 6th skill, "Create an
    ///   Emergency Action Plan", with bullet points -- authored for this
    ///   app (not transcribed from a slate, since the physical cards don't
    ///   cover it).
    /// - "Divemaster-Conducted Program Workshops" and "Practical
    ///   Assessments" keep their existing top-level checks; their
    ///   sub-steps are now bullets too.
    /// See DivemasterSeedData.swift.
    ///
    /// v9: PADI > Divemaster -- added `scoringNote` (a new optional field
    /// on the Checklist model, shown in ChecklistDetailView right under
    /// the live Total Score) to the Waterskills Exercises and Skill
    /// Evaluation Slate checklists, spelling out the actual pass/fail
    /// requirement next to the running total: Waterskills Exercises needs
    /// all 5 exercises done with a combined score of at least 15 (at least
    /// a 3 specifically on the Equipment Exchange, no minimum on the
    /// others); Skill Evaluation Slate needs at least a 3 on every skill
    /// and at least 82 points total, with at least one underwater skill
    /// scored a 5. See Checklist.swift, ChecklistDetailView.swift, and
    /// DivemasterSeedData.swift.
    ///
    /// v10: the v7 sync-race guard closed one specific race but not the
    /// underlying problem -- `trainingAgencies` (this file's content: SDI
    /// OW1-4, PADI Confined Water, the full Divemaster program with 6
    /// checklists including the 24-item Skill Evaluation Slate) and
    /// SeedData's `categories` are by far the largest things synced through
    /// `NSUbiquitousKeyValueStore`, which caps out around 1MB total across
    /// all keys, and kept growing as more starter content got added here.
    /// That looked exactly like content silently vanishing again after
    /// being confirmed working -- worst on a physical device with a lot of
    /// real iCloud history, but eventually on a fresh Simulator too once
    /// even that margin ran out (this is why the v9 scoringNote additions
    /// above didn't show up anywhere, Simulator included). `trainingAgencies`
    /// is now persisted local-only (UserDefaults, no iCloud) via
    /// `CloudSync.saveLocalOnly`/`loadLocalOnly` -- see the doc comment on
    /// those in CloudSync.swift. v10 forces one more reseed so every device
    /// picks up this change cleanly.
    ///
    /// v11: PADI Open Water Diver (Confined Water Dives, Waterskills
    /// Assessment, Dive Flexible Skills) and SDI Open Water Scuba Diver
    /// (Confined Water 1-4, Open Water 1-4) are no longer per-student
    /// tracked checklists -- every item in them (including lettered
    /// subItems) is now a non-checkable reference bullet, so an instructor
    /// can use them as a plain reference list without checkmarks to manage.
    /// Divemaster is untouched and still fully checkable/trackable, since
    /// that's the one program tracked per-candidate. See the `item()`
    /// helpers at the bottom of this file.
    ///
    /// v12: PADI > Advanced Open Water Diver -- added as a plain
    /// `TrainingCertification` (not a roster program) with all 14 checklists
    /// (13 Adventure Dives plus the shared "Thinking Like a Diver"
    /// briefing/debriefing framework card), ordered Thinking Like a Diver,
    /// Deep Dive, Underwater Navigation Dive, then the rest. Content
    /// transcribed from the 14 PADI Advanced Open Water Diver Instructor
    /// Slates and built using the same non-checkable reference-bullet
    /// convention as v11 above, since Advanced Open Water has no per-student
    /// tracking need either. See AdvancedOpenWaterSeedData.swift, including
    /// its notes on two things the physical cards show that the app's
    /// text-only checklist model can't represent: the Search and Recovery
    /// Dive card's knot-tying diagrams, and a couple of handwritten
    /// annotations/signatures omitted as personal (not official card)
    /// content.
    ///
    /// v13: PADI > Rescue Diver -- added as a plain `TrainingCertification`
    /// (not a roster program, for the same reason as v12 above) with 16
    /// checklists covering the Self-Rescue Review, Rescue Exercises 1-10,
    /// two standalone multi-exercise practice/review sessions, Open Water
    /// Scenarios One and Two, and the Inwater Rescue Breathing Guidelines --
    /// ordered by the page number printed on each of the 16 PADI Rescue
    /// Diver Instructor Slates. Unlike the Advanced Open Water slates,
    /// content here flows continuously across several physical cards rather
    /// than resetting per card, so checklists are grouped by the card's own
    /// named section headings instead of strictly one per card -- see
    /// RescueDiverSeedData.swift for the full transcription and its notes
    /// on how the two standalone "Exercise Practice" sessions were told
    /// apart from the three exercises that have their own practice
    /// subsection built into that same exercise's card.
    /// v14: PADI > Open Water Diver > Open Water Dives -- added as a new
    /// sibling `TrainingCertification` to the existing Confined Water Dives
    /// one (named "Open Water Diver -- Open Water Dives", mirroring how SDI
    /// already has separate Confined Water Dives/Open Water Dives
    /// certifications), listed directly after it. Covers Open Water Dives
    /// 1-4, Dive Flexible Skills, and the Controlled Emergency Swimming
    /// Ascent (CESA) requirements, transcribed from the "Aquatic Cue Card --
    /// Open Water Dives" photos. Built inline in this file (not a separate
    /// SeedData file) reusing the existing `item()`/`noteItem()` helpers
    /// below, since it's the same non-checkable-reference-bullet family as
    /// the Confined Water content right above it. Each Dive 1-4 checklist
    /// item's note is the matching numbered Performance Requirement text
    /// from that dive's own card, following the same "only where a
    /// confident match exists" rule used for Confined Water in v2 --
    /// several Overview bullets combine more than one Performance
    /// Requirement into a single note when the card's Overview groups them
    /// as one step (e.g. "Explore the dive site -- avoid bottom contact and
    /// stay close to buddy"), and skills tagged "(dive flexible)" on a
    /// dive's Overview card are left without a note since their full
    /// requirement text lives on the separate Dive Flexible Skills card
    /// instead. Dive Flexible Skills and CESA each print their own two/
    /// three named subsections (At the Surface/Underwater;
    /// Briefing/Set Up/Conduct) -- these became nested parent items with
    /// the card's own lead-in sentence as the parent's note, the same
    /// pattern RescueDiverSeedData.swift uses for verbatim section
    /// headings. Handwritten annotations on the physical cards (a
    /// crossed-out original heading, "Replace BC"/"Remove/Replace BC"
    /// margin notes, and the instructor's initials/signature) are personal
    /// markup, not official card content, and are omitted here.
    static let contentVersion = 14

    static func makeAgencies() -> [TrainingAgency] {
        [
            padi(),
            sdi()
        ]
    }

    // MARK: - PADI

    private static func padi() -> TrainingAgency {
        TrainingAgency(
            name: "PADI",
            symbolName: "graduationcap.fill",
            certifications: [
                openWaterDiverConfinedWater(),
                openWaterDiverOpenWater(),
                advancedOpenWaterDiver(),
                rescueDiver()
            ],
            rosterPrograms: [
                divemaster()
            ]
        )
    }

    private static func advancedOpenWaterDiver() -> TrainingCertification {
        TrainingCertification(
            name: "Advanced Open Water Diver",
            checklists: AdvancedOpenWaterSeedData.makeChecklists()
        )
    }

    private static func rescueDiver() -> TrainingCertification {
        TrainingCertification(
            name: "Rescue Diver",
            checklists: RescueDiverSeedData.makeChecklists()
        )
    }

    private static func divemaster() -> TrainingRosterProgram {
        TrainingRosterProgram(
            name: "Divemaster",
            requirementChecklists: DivemasterSeedData.makeRequirementChecklists()
        )
    }

    private static func openWaterDiverConfinedWater() -> TrainingCertification {
        TrainingCertification(
            name: "Open Water Diver -- Confined Water Dives",
            checklists: [
                confinedWaterDive1(),
                confinedWaterDive2(),
                confinedWaterDive3(),
                confinedWaterDive4(),
                confinedWaterDive5(),
                waterskillsAssessment(),
                diveFlexibleSkills()
            ]
        )
    }

    private static func openWaterDiverOpenWater() -> TrainingCertification {
        TrainingCertification(
            name: "Open Water Diver -- Open Water Dives",
            checklists: [
                openWaterDive1(),
                openWaterDive2(),
                openWaterDive3(),
                openWaterDive4(),
                openWaterDiveFlexibleSkills(),
                controlledEmergencySwimmingAscent()
            ]
        )
    }

    // MARK: - Waterskills Assessment

    private static func waterskillsAssessment() -> Checklist {
        Checklist(
            name: "Waterskills Assessment",
            items: [
                item("1", "10-minute survival swim/float without swim aids", note: "Must be completed before Open Water Dive 2."),
                item("2", "200 metre/yard continuous surface swim OR 300 metre/yard mask, fin, snorkel swim")
            ]
        )
    }

    // MARK: - Confined Water Dive 1

    private static func confinedWaterDive1() -> Checklist {
        Checklist(
            name: "Confined Water Dive 1",
            items: [
                item("1", "Equipment preparation and mask defogging"),
                item("2", "Entry, put on gear and weights", note: "Put on and adjust mask, fins, snorkel, BCD, scuba kit and weights with assistance -- using proper lifting techniques."),
                item("3", "Predive safety check -- guided (in water, BWRAF)", note: "Participate in a predive safety check."),
                item("4", "BCD inflation/deflation on surface", note: "Inflate/deflate a BCD using the low pressure inflator in shallow water."),
                item("5", "Introduction to breathing underwater", note: "Breathe compressed air by breathing naturally, without breath-holding."),
                item("6", "Regulator clear -- exhalation and purge", note: "Clear a regulator using both the exhalation and purge-button methods, then resume breathing from it."),
                item("7", "Regulator recovery", note: "Recover a regulator from behind the shoulder."),
                item("8", "Clear partially flooded mask", note: "Clear a partially flooded mask."),
                item("9", "Alternate air source use (30 seconds)", note: "Breathe from an alternate air source supplied by another diver for at least 30 seconds."),
                item("10", "Descent and equalization", note: "Descend at a controlled rate into water too deep in which to stand, equalizing the ears and mask."),
                item("11", "Underwater swimming (swim to deep end)", note: "Swim with scuba equipment while maintaining control of both direction and depth."),
                item("12", "Hand signals", note: "Recognize and demonstrate hand signals."),
                item("13", "SPG use and air monitoring", note: "Locate and read SPG and signal whether the air supply is adequate or low based on the gauge's caution zone and/or an assigned supply limit."),
                item("14", "Fun and skill practice"),
                item("15", "Ascent and positive buoyancy", note: "Ascend using proper technique. After ascent, keep the mask on and continue breathing from the regulator while using the low pressure inflator to attain positive buoyancy."),
                item("16", "Oral BCD inflation at surface", note: "Deflate the BCD, then orally inflate it until positively buoyant."),
                item("17", "Surface swimming and good surface habits", note: "While positively buoyant, breathe from a snorkel or regulator while swimming facedown."),
                item("18", "Emergency weight drop (dive flexible)", note: "During any dive, in either confined or open water, at the surface in water too deep in which to stand, with a deflated BCD, use the weight system's quick release to pull clear and drop sufficient weight to become positively buoyant."),
                item("19", "Exit"),
                item("20", "Equipment disassembly and care")
            ]
        )
    }

    // MARK: - Confined Water Dive 2

    private static func confinedWaterDive2() -> Checklist {
        Checklist(
            name: "Confined Water Dive 2",
            items: [
                item("1", "Dive planning and air management reminder", note: "Plan dive."),
                item("2", "Assemble and put on gear", note: "Put on and adjust mask, fins, snorkel, BCD, scuba and weights with buddy -- using proper lifting techniques."),
                item("3", "Predive safety check", note: "Perform the buddy predive safety check."),
                item("4", "Deep water entry (seated entry)", note: "Demonstrate appropriate deep-water entry."),
                item("5", "Weight check", note: "Adjust for proper weighting -- float at eye level at the surface with no or minimal air in the BCD and while holding a normal breath."),
                item("6", "Snorkel breathing and clearing", note: "Clear a snorkel using the blast method, then resume breathing through it without lifting the face from the water."),
                item("7", "Snorkel/regulator exchange", note: "Exchange snorkel for regulator and regulator for snorkel repeatedly (at least two exchanges) without lifting the face from the water."),
                item("8", "Snorkel swimming with buddy (to shallow end)", note: "Swim at least 50 metres/yards while wearing scuba, breathing through a snorkel and staying close to buddy."),
                item("9", "Disconnect inflator hose (dive flexible)", note: "Disconnect the low pressure hose from the inflator in shallow water (either underwater or at surface). By the end of CW Dive 3 for PADI Scuba Divers; by the end of CW Dive 5 for all student divers."),
                item("10", "Loose cylinder band (dive flexible)", note: "During any CW Dive, resecure a loose cylinder band in the water either at the surface or underwater."),
                item("11", "Five point descent (dive together)", note: "With a buddy, descend in water too deep in which to stand using the five-point method, primarily using the BCD for buoyancy control."),
                item("12", "Neutral buoyancy (fin pivot)", note: "Use low-pressure BCD inflation to become neutrally buoyant. Gently rise and fall in a controlled manner, during inhalation and exhalation."),
                item("13", "Clear fully flooded mask", note: "Clear a fully flooded mask."),
                item("14", "Remove, replace and clear mask", note: "Remove, replace and clear a mask."),
                item("15", "No mask breathing (60 seconds)", note: "Breathe without a mask for at least one minute."),
                item("16", "Air depletion exercise (turn off gas)", note: "Respond to air depletion by signaling \"out-of-air\" in water too deep in which to stand."),
                item("17", "Air management within 20 bar/300 psi", note: "Indicate remaining air supply within 20 bar/300 psi without rechecking the SPG."),
                item("18", "Fun and skill practice"),
                item("19", "Five point ascent", note: "Ascend using the five-point method, primarily using the BCD for buoyancy control."),
                item("20", "Exit", note: "Exit using the most appropriate technique. (Buddy assistance allowed.)"),
                item("21", "Equipment disassembly and care")
            ]
        )
    }

    // MARK: - Confined Water Dive 3

    private static func confinedWaterDive3() -> Checklist {
        Checklist(
            name: "Confined Water Dive 3",
            items: [
                noteItem("Skin Diving (dive flexible) may be introduced this dive -- see the Dive Flexible Skills checklist."),
                item("1", "Assemble, put on gear and predive safety check"),
                item("2", "Deep water entry (giant stride)", note: "Demonstrate appropriate deep-water entry."),
                item("3", "Weight check and adjustment", note: "With a buddy, perform a weight check and adjust for proper weighting."),
                item("4", "Cramp release", note: "Demonstrate the cramp release technique for self and buddy (at the surface or underwater)."),
                item("5", "Descent with visual reference", note: "With a buddy, descend using only a visual reference in water too deep in which to stand, using the five-point method."),
                item("6", "Hovering (30 seconds)", note: "Hover using buoyancy control for at least 30 seconds, without kicking or sculling."),
                item("7", "Trim and weight positioning", note: "While neutrally buoyant, swim slowly in a horizontal position to determine trim. Adjust trim, as feasible, for a normal swimming position."),
                item("8", "Air depletion/alternate air source use -- donor and receiver (60 seconds)", note: "Respond to air depletion by signaling \"out of air\" and securing and breathing from an alternate air source supplied by a buddy. Continue for at least one minute while swimming, surface and inflate the BCD orally. Supply air to another diver using an alternate air source."),
                item("9", "Controlled emergency swimming ascent (30 feet)", note: "Simulate a controlled emergency swimming ascent by swimming horizontally for at least 9 metres/30 feet while emitting a continuous sound."),
                item("10", "Air management within 20 bar/300 psi", note: "Indicate remaining air supply within 20 bar/300 psi without rechecking the SPG."),
                item("11", "Fun and skill practice"),
                item("12", "Five point ascent (weight removal/replace, weight drop, gear removal)"),
                item("13", "Exit"),
                item("14", "Equipment disassembly and care")
            ]
        )
    }

    // MARK: - Confined Water Dive 4

    private static func confinedWaterDive4() -> Checklist {
        Checklist(
            name: "Confined Water Dive 4",
            items: [
                item("1", "Assemble, put on gear and predive safety check"),
                item("2", "Entry"),
                item("3", "Weight and trim check", note: "With a buddy, perform a weight check and adjust for proper weighting and trim."),
                item("4", "Tired-diver tow (25 yards)", note: "Perform a tired diver tow for 25 metres/yards."),
                item("5", "Scuba kit removal/replacement at surface", note: "Remove, replace, adjust and secure the scuba kit with minimal assistance."),
                item("6", "Descent -- stop before contacting bottom", note: "With a buddy, descend in water too deep in which to stand using the five-point method and use buoyancy control to stop the descent without contacting the bottom."),
                item("7", "Underwater swim over sensitive bottom (to shallow end)", note: "With a buddy, swim over a simulated environmentally sensitive bottom while maintaining buoyancy control."),
                item("8", "Hover -- oral BCD inflation (60 seconds)", note: "Orally inflate the BCD to hover for at least one minute, without kicking or sculling."),
                item("9", "Freeflow regulator breathing (30 seconds)", note: "Breathe effectively from a simulated freeflowing regulator for at least 30 seconds."),
                item("10", "No mask swim (50 feet)", note: "Swim without a mask for at least 15 metres/50 feet, then replace and clear the mask."),
                item("11", "Air management within 20 bar/300 psi", note: "Indicate remaining air supply within 20 bar/300 psi without rechecking the SPG."),
                item("12", "Fun and skill practice"),
                item("13", "Ascent without contacting bottom", note: "Make a five point ascent from above a simulated environmentally sensitive bottom without contacting the bottom."),
                item("14", "Exit"),
                item("15", "Equipment disassembly and care")
            ]
        )
    }

    // MARK: - Confined Water Dive 5

    private static func confinedWaterDive5() -> Checklist {
        Checklist(
            name: "Confined Water Dive 5",
            items: [
                item("1", "Assemble, put on gear and predive safety check"),
                item("2", "Entry"),
                item("3", "Scuba kit removal and replacement -- underwater", note: "Remove, replace, adjust and secure the scuba kit with minimal assistance in water too deep in which to stand, without losing control of buoyancy, body position and depth."),
                item("4", "Weight system removal and replacement -- underwater", note: "Remove, replace, adjust and secure all or part of the weight system without losing control of buoyancy, body position and depth. With weight belt or weight integrated BCD -- on the bottom in water too deep in which to stand. With any weight system that requires reassembly after weights are removed -- in shallow water."),
                item("5", "Air management within 20 bar/300 psi", note: "Indicate remaining air supply within 20 bar/300 psi without rechecking the SPG."),
                item("6", "Minidive", note: "Complete a simulated dive -- Minidive -- including planning with a buddy, an entry and exit, a weight and trim check, a five point descent, practicing previously learned skills with emphasis on neutral buoyancy, hovering and swimming, avoiding contact with simulated sensitive bottom and fragile aquatic organisms, responding correctly to at least one but not more than three simulated situations (leg cramp, out of air/share air, freeflow regulator, mask flooded, mask off, regulator dropped from mouth, BCD inflator failure, buddy separation), and a five point ascent with a safety stop at planned time limit or designated ascent pressure."),
                item("7", "Exit"),
                item("8", "Equipment disassembly and care")
            ]
        )
    }

    // MARK: - Open Water Dive 1

    private static func openWaterDive1() -> Checklist {
        Checklist(
            name: "Open Water Dive 1",
            items: [
                item("1", "Briefing and hand signal review", note: "During briefing, recognize the hand signals for \"okay,\" \"something is wrong,\" \"ear problem,\" \"low air,\" \"up/end the dive,\" \"stay with your buddy,\" and the audible and visual signal for \"look at me.\""),
                item("2", "Predive acclimation"),
                item("3", "Assemble and put on gear", note: "Put on and adjust equipment -- using proper lifting techniques."),
                item("4", "Predive safety check", note: "Perform a predive safety check."),
                item("5", "Entry -- positively buoyant", note: "Enter the water with BCD inflated to provide positive buoyancy."),
                item("6", "Check and adjust weighting", note: "Check and adjust weighting."),
                item("7", "Snorkel-to-regulator exchange (dive flexible)"),
                item("8", "Controlled descent", note: "Descend with control and reference using a descent line or sloping bottom contour to a depth not greater than 12 metres/40 feet."),
                item("9", "Trim check", note: "Participate in a trim check."),
                item("10", "Clear partially flooded mask", note: "Clear a partially flooded mask."),
                item("11", "Regulator recovery and clear", note: "Recover and clear the regulator at depth."),
                item("12", "Explore the dive site", note: "Explore the dive site."),
                item("13", "Air monitoring", note: "Signal whether remaining air supply is near designated caution zone, and/or indicate air supply in bar/psi."),
                item("14", "Ascent", note: "Ascend no faster than 18 metres/60 feet per minute while maintaining buddy contact. Use the five point method (if Confined Water Dive 3 completed)."),
                item("15", "Emergency weight drop (dive flexible)"),
                item("16", "Exit"),
                item("17", "Equipment disassembly and care"),
                item("18", "Debriefing and log dive")
            ]
        )
    }

    // MARK: - Open Water Dive 2

    private static func openWaterDive2() -> Checklist {
        Checklist(
            name: "Open Water Dive 2",
            items: [
                item("1", "Dive planning and briefing", note: "Plan dive, including air supply management/turn pressure, time limits, entry and exit, buddy separation procedures and emergency procedures."),
                item("2", "Assemble and put on gear", note: "Put on, adjust and streamline equipment. Use proper lifting techniques."),
                item("3", "Predive safety check", note: "Perform a predive safety check."),
                item("4", "Entry and good surface habits", note: "When at the surface, establish positive buoyancy, keep the mask on and breathe from the snorkel or regulator."),
                item("5", "Weight and trim check", note: "Adjust weighting and trim, as necessary."),
                item("6", "BCD oral inflation at surface", note: "Deflate BCD, then orally inflate it until positively buoyant in water too deep in which to stand."),
                item("7", "Cramp release (dive flexible)"),
                item("8", "Tired diver tow (dive flexible)"),
                item("9", "Controlled descent", note: "Descend using a descent line or sloping bottom contour for control and reference to a depth not greater than 12 m/40 ft. Use five-point method."),
                item("10", "Neutral buoyancy", note: "Become neutrally buoyant by adjusting air in the BCD (or dry suit) with the low pressure inflator."),
                item("11", "Clear fully flooded mask", note: "Clear a fully flooded mask."),
                item("12", "Alternate air source use (donor/receiver) and ascent", note: "Perform each role: In a stationary position, one person signals \"out of air\" and secures and breathes from an alternate air source provided by another diver; the other diver provides the air source. Ascend properly using an alternate air source and establish positive buoyancy at the surface. Act as either donor or receiver."),
                item("13", "Explore the dive site -- avoid bottom contact and stay close to buddy", note: "Explore the dive site. Avoid contact with sensitive organisms and the bottom, and resecure any equipment that becomes loose. Stay close enough to make physical contact with buddy within 2 seconds."),
                item("14", "Air management within 20 bar/300 psi and signal air remaining", note: "Indicate remaining air supply within 20 bar/300 psi without rechecking. Signal air remaining at intervals assigned during dive planning."),
                item("15", "Five point ascent -- safety stop, if feasible", note: "Ascend no faster than 18 m/60 ft per minute while maintaining buddy contact. Use five-point method. Make a safety stop if feasible."),
                item("16", "Inflatable signal tube deployment (dive flexible)"),
                item("17", "Exit"),
                item("18", "Equipment disassembly and care"),
                item("19", "Debriefing and log dive")
            ]
        )
    }

    // MARK: - Open Water Dive 3

    private static func openWaterDive3() -> Checklist {
        Checklist(
            name: "Open Water Dive 3",
            items: [
                item("1", "Dive planning and briefing", note: "Plan the dive."),
                item("2", "Assemble and put on gear", note: "Put on, adjust and streamline equipment. Use proper lifting techniques."),
                item("3", "Predive safety check", note: "Perform a predive safety check."),
                item("4", "Entry and good surface habits", note: "When at the surface, establish positive buoyancy, keep the mask on and breathe from the snorkel or regulator."),
                item("5", "Weight and trim check", note: "Adjust weighting and trim, as necessary."),
                item("6", "Weight system and scuba kit removal and replacement at surface (dive flexible)"),
                item("7", "Straight line surface swim with compass (dive flexible)"),
                item("8", "Descent with visual reference", note: "Descend with a visual reference for control to no greater than 18 metres/60 feet. Use the five-point method."),
                item("9", "Hovering -- oral BCD inflation", note: "Become neutrally buoyant and hover by inflating the BCD orally."),
                item("10", "Mask removal and replacement", note: "Remove, replace and clear the mask."),
                item("11", "Underwater compass navigation (dive flexible)"),
                item("12", "Controlled emergency swimming ascent (dive flexible)"),
                item("13", "Explore the dive site -- avoid bottom contact and stay close to buddy", note: "Explore the dive site. Avoid contact with sensitive organisms and the bottom, and resecure any equipment that becomes loose. Stay close enough to make physical contact with buddy within 2 seconds."),
                item("14", "Air management within 20 bar/300 psi and signal air remaining", note: "Indicate remaining air supply within 20 bar/300 psi without rechecking. Signal air remaining at intervals assigned during dive planning."),
                item("15", "Five point ascent -- safety stop, if feasible", note: "Ascend no faster than 18 metres/60 feet per minute while maintaining buddy contact. Use the five-point method. Make a safety stop if feasible."),
                item("16", "Exit"),
                item("17", "Equipment disassembly and care"),
                item("18", "Debriefing and log dive")
            ]
        )
    }

    // MARK: - Open Water Dive 4

    private static func openWaterDive4() -> Checklist {
        Checklist(
            name: "Open Water Dive 4",
            items: [
                item("1", "Plan dive using Dive Planning Slate", note: "As a buddy team, plan the dive using the PADI Skills Practice and Dive Planning Slate."),
                item("2", "Assemble and put on gear", note: "Put on, adjust and streamline equipment. Use proper lifting techniques."),
                item("3", "Predive safety check", note: "Perform a predive safety check."),
                item("4", "Entry and good surface habits", note: "When at the surface, establish positive buoyancy, keep the mask on and breathe from the snorkel or regulator."),
                item("5", "Weight and trim check", note: "Adjust weighting and trim, as necessary."),
                item("6", "Free descent without reference", note: "Descend with no visual reference to no greater than 18 metres/60 feet. Use the five-point method."),
                item("7", "Explore the dive site as buddy team -- avoid bottom contact and stay close to buddy", note: "With a buddy, explore the dive site. Avoid contact with sensitive organisms and the bottom, and resecure any equipment that becomes loose. Stay close enough to make physical contact with buddy within 2 seconds."),
                item("8", "Air management within 20 bar/300 psi and signal turn/ascent points", note: "Indicate remaining air supply within 20 bar/300 psi without rechecking. With a buddy, signal when to turn the dive and when to ascend, based on air supply or time per the dive plan, and take appropriate action."),
                item("9", "Five point ascent with safety stop", note: "Ascend no faster than 18 metres/60 feet per minute while maintaining buddy contact. Use the five-point method. Make a safety stop."),
                item("10", "Exit"),
                item("11", "Equipment disassembly and care"),
                item("12", "Debriefing and log dive")
            ]
        )
    }

    // MARK: - Open Water Dive Flexible Skills
    //
    // Skills that can be completed across any Open Water Dive (or
    // specifically OW Dives 2, 3 or 4) rather than being tied to one
    // specific dive -- see the "Dive Flexible Skills -- Performance
    // Requirements" card. Referenced from the per-dive checklists above
    // wherever a card tagged a skill "(dive flexible)" for that dive. This
    // is a separate checklist from Confined Water's own `diveFlexibleSkills()`
    // above (different card, different certification).

    private static func openWaterDiveFlexibleSkills() -> Checklist {
        Checklist(
            name: "Dive Flexible Skills",
            items: [
                item(nil, "At the Surface", note: "During any OW Dive, have student divers demonstrate the following:", subItems: [
                    item(nil, "Cramp Release", note: "Release a simulated cramp for self and buddy."),
                    item(nil, "Tired Diver Tow", note: "Tow a simulated tired buddy in scuba equipment for 25 metres/yards."),
                    item(nil, "Inflatable Signal Tube Use", note: "Deploy an inflatable signal tube at the surface, or deploy a delayed surface marker buoy (DSMB) from underwater."),
                    item(nil, "Straight Line Surface Swim With Compass", note: "Snorkel swim in a straight line for 50 metres/yards while keeping the face in the water and using only the compass for direction reference."),
                    item(nil, "Snorkel/Regulator Exchange", note: "Clear water from a snorkel and resume breathing without removing the snorkel from the mouth. Alternately breathe from snorkel and regulator without lifting the face from the water for at least two exchanges."),
                    item(nil, "Remove and Replace Weight System and Scuba Kit", note: "Remove and replace the weight system in water too deep in which to stand. Remove and replace the scuba kit in water too deep in which to stand."),
                    item(nil, "Emergency Weight Drop", note: "In either confined or open water too deep in which to stand, with a deflated BCD, use the weight system's quick release to pull clear and drop sufficient weight to become positively buoyant.")
                ]),
                item(nil, "Underwater", note: "During OW Dives 2, 3 or 4, have student divers demonstrate the following:", subItems: [
                    item(nil, "Compass Navigation", note: "Swim a straight-line reciprocal course using a compass. Each diver navigates out and back."),
                    item(nil, "Controlled Emergency Swimming Ascent (CESA)", note: "Perform a controlled emergency swimming ascent from a depth of 6-9 metres/20-30 feet and establish positive buoyancy at the surface.")
                ])
            ]
        )
    }

    // MARK: - Controlled Emergency Swimming Ascent (CESA)

    private static func controlledEmergencySwimmingAscent() -> Checklist {
        Checklist(
            name: "Controlled Emergency Swimming Ascent (CESA)",
            items: [
                item(nil, "Briefing", note: "Instruct student divers to:", subItems: [
                    item(nil, "Retain their regulators in their mouths."),
                    item(nil, "Not drop their weights."),
                    item(nil, "Not use the control line for assistance -- the line is only for instructor control and emergency stopping."),
                    item(nil, "Maintain a normal ascent rate. Kick to begin ascent, then reduce effort. Hold deflator to vent excess air during ascent."),
                    item(nil, "Make a continuous sound throughout the ascent."),
                    item(nil, "Resume normal breathing if you stop the ascent, or if they experience any difficulty."),
                    item(nil, "Orally inflate the BCD or drop weights upon reaching the surface.")
                ]),
                item(nil, "Set Up", subItems: [
                    item(nil, "Use a vertical line buoyed by a float and either tied off at the bottom or held down with sufficient weight to enable you to stop the ascent by grasping it while holding the student firmly. Conduct one student at a time while maintaining physical contact with student and control line."),
                    item(nil, "Depth -- at least 6 metres/20 feet but not exceeding 9 metres/30 feet.")
                ]),
                item(nil, "Conduct", subItems: [
                    item(nil, "Grasp the student with one hand and maintain contact with the line."),
                    item(nil, "Give the \"up\" signal, prompting the student to exhale while emitting a continuous sound."),
                    item(nil, "Observe -- student kicks to start, then reduces effort; doesn't use the line; keeps regulator and weights in place; maintains contact with the BCD or dry suit deflator mechanism to vent excess air during ascent."),
                    item(nil, "Observe and maintain control during the ascent, not exceeding 18 metres/60 feet per minute. Position student near and below you, which allows you to listen for the sound and makes the student look up toward you. Be sure student exhales continuously. Stop ascent if there is any doubt. If you stop, have student repeat the skill from the beginning."),
                    item(nil, "Upon surfacing, have student orally inflate the BCD or drop weights. Look for divers below before releasing weight. Wait for the student to become calm and relaxed before engaging in other training exercises.")
                ])
            ]
        )
    }

    // MARK: - SDI

    private static func sdi() -> TrainingAgency {
        TrainingAgency(
            name: "SDI",
            symbolName: "graduationcap.fill",
            certifications: [
                sdiOpenWaterConfinedWater(),
                sdiOpenWaterDives()
            ]
        )
    }

    private static func sdiOpenWaterConfinedWater() -> TrainingCertification {
        TrainingCertification(
            name: "Open Water Scuba Diver -- Confined Water Dives",
            checklists: [
                sdiConfinedWater1(),
                sdiConfinedWater2(),
                sdiConfinedWater3(),
                sdiConfinedWater4()
            ]
        )
    }

    private static func sdiOpenWaterDives() -> TrainingCertification {
        TrainingCertification(
            name: "Open Water Scuba Diver -- Open Water Dives",
            checklists: [
                sdiOpenWater1(),
                sdiOpenWater2(),
                sdiOpenWater3(),
                sdiOpenWater4()
            ]
        )
    }

    private static func sdiConfinedWater1() -> Checklist {
        Checklist(
            name: "Confined Water 1",
            items: [
                item("1", "Swimming Evaluations"),
                item("2", "Buddy Teams"),
                item("3", "Hand Signals (Communication)"),
                item("4", "Weight System & Mask Defog"),
                item("5", "SCUBA Unit Assembly"),
                item("6", "Don SCUBA Unit"),
                item("7", "Briefing"),
                item("8", "ABCDE", subItems: [
                    item("A", "Air on"),
                    item("B", "BCD inflated"),
                    item("C", "Computer on"),
                    item("D", "Dive gear on"),
                    item("E", "Enter on go")
                ]),
                item("9", "Equalization"),
                item("10", "Entry: Controlled Seated"),
                item("11", "BCD Inflation & Deflation (Surface & Underwater)", subItems: [
                    item("A", "Power"),
                    item("B", "Oral")
                ]),
                item("12", "Regulator (Surface & Underwater)", subItems: [
                    item("A", "Purge: Mechanical & Oral"),
                    item("B", "Recovery: Sweep & Reach")
                ]),
                item("13", "Mask", subItems: [
                    item("A", "Partial Flood & Clear")
                ]),
                item("14", "Finning", subItems: [
                    item("A", "Flutter"),
                    item("B", "Frog")
                ]),
                item("15", "Alternate-Air Sharing Ascent", subItems: [
                    item("A", "Donor"),
                    item("B", "Receiver")
                ]),
                item("16", "Weight Systems at Surface (Remove & Replace)"),
                item("17", "Practice Time (Play Time & Skills Practice)"),
                item("18", "Exit (Appropriate Method)"),
                item("19", "Check Air (SPG or Computer)"),
                item("20", "Disassemble & Clean SCUBA Unit"),
                item("21", "Debriefing"),
                item("22", "Log and Sign Dive Books")
            ]
        )
    }

    private static func sdiConfinedWater2() -> Checklist {
        Checklist(
            name: "Confined Water 2",
            items: [
                item("1", "Briefing"),
                item("2", "Weight System & Mask Defog"),
                item("3", "SCUBA Unit Assembly"),
                item("4", "Don SCUBA Unit"),
                item("5", "ABCDE"),
                item("6", "Entry: Giant Stride"),
                item("7", "6 Point Descent (ORCESD)", subItems: [
                    item("A", "Orient"),
                    item("B", "Regulator in the Mouth"),
                    item("C", "Computer On"),
                    item("D", "Equalize"),
                    item("E", "Signal Buddy"),
                    item("F", "Deflate & Descend")
                ]),
                item("8", "Computer Use", subItems: [
                    item("A", "Reading & Understanding Data"),
                    item("B", "Understanding the Computer Functions")
                ]),
                item("9", "Breathing from a Free Flowing Regulator"),
                item("10", "Mask", subItems: [
                    item("A", "Full Flood & Clear")
                ]),
                item("11", "Weight Systems Underwater", subItems: [
                    item("A", "Remove"),
                    item("B", "Replace")
                ]),
                item("12", "Snorkel Use", subItems: [
                    item("A", "Adjustment"),
                    item("B", "Clearing (Blast Method)")
                ]),
                item("13", "Snorkel to Regulator Exchange"),
                item("14", "Snorkel Swim on Scuba"),
                item("15", "Tired Diver Tow"),
                item("16", "Cramp Removal"),
                item("17", "Exit (Appropriate Method)"),
                item("18", "Check Air (SPG or Computer)"),
                item("19", "Disassemble & Clean SCUBA Unit"),
                item("20", "Debriefing"),
                item("21", "Log & Sign Dive Books")
            ]
        )
    }

    private static func sdiConfinedWater3() -> Checklist {
        Checklist(
            name: "Confined Water 3",
            items: [
                item("1", "Briefing"),
                item("2", "Weight System & Mask Defog"),
                item("3", "SCUBA Unit Assembly"),
                item("4", "Don SCUBA Unit"),
                item("5", "ABCDE"),
                item("6", "Entry: Back Roll"),
                item("7", "Weight Check"),
                item("8", "Bubble Check"),
                item("9", "6 Point Descent (ORCESD)"),
                item("10", "Hover: Neutral Buoyancy"),
                item("11", "Mask", subItems: [
                    item("A", "Remove, Replace & Clear"),
                    item("B", "Remove, Breathe, Swim, Replace & Clear")
                ]),
                item("12", "BCD", subItems: [
                    item("A", "Remove & Replace Surface"),
                    item("B", "Remove & Replace Underwater")
                ]),
                item("13", "Controlled Ascent: Monitor Computer"),
                item("14", "Exit: Beach Simulation"),
                item("15", "Check Air (SPG or Computer)"),
                item("16", "Disassemble & Clean SCUBA Unit"),
                item("17", "Debriefing"),
                item("18", "Log & Sign Dive Books")
            ]
        )
    }

    private static func sdiConfinedWater4() -> Checklist {
        Checklist(
            name: "Confined Water 4",
            items: [
                item("1", "Briefing"),
                item("2", "Weight System"),
                item("3", "Mask Defog"),
                item("4", "SCUBA Unit Assembly"),
                item("5", "Entry", subItems: [
                    item("A", "Walk In"),
                    item("B", "Don SCUBA Unit in Water")
                ]),
                item("6", "ABCDE"),
                item("7", "6 Point Descent (ORCESD)"),
                item("8", "Controlled Swimming Ascent"),
                item("9", "Compass Navigation: Underwater"),
                item("10", "Practice Time (Play Time & Skills Practice)"),
                item("11", "Exit (Appropriate Method)"),
                item("12", "Check Air (SPG or Computer)"),
                item("13", "Disassemble & Clean SCUBA Unit"),
                item("14", "Debriefing"),
                item("15", "Log & Sign Dive Books")
            ]
        )
    }

    private static func sdiOpenWater1() -> Checklist {
        Checklist(
            name: "Open Water 1",
            items: [
                noteItem("Check for Signed Waiver Releases"),
                item("1", "Briefing"),
                item("2", "Weight System & Mask Defog"),
                item("3", "SCUBA Unit Assembly"),
                item("4", "Don SCUBA Unit"),
                item("5", "Review ABCDE", subItems: [
                    item("A", "Air on"),
                    item("B", "BCD inflated"),
                    item("C", "Computer on"),
                    item("D", "Dive gear on"),
                    item("E", "Enter on go")
                ]),
                item("6", "Entry", subItems: [
                    item("A", "Weight Check"),
                    item("B", "Bubble Check")
                ]),
                item("7", "ORCESD: On Buoyed Line"),
                item("8", "Regulator", subItems: [
                    item("A", "Remove, Recover & Clear")
                ]),
                item("9", "Mask", subItems: [
                    item("A", "Partial Flood & Clear")
                ]),
                item("10", "Tour: Neutral Buoyancy & Finning Practice"),
                item("11", "Monitor", subItems: [
                    item("A", "Depth"),
                    item("B", "Time"),
                    item("C", "No Decompression Limit"),
                    item("D", "Cylinder Pressure")
                ]),
                item("12", "Controlled Ascent: On Buoyed Line"),
                item("13", "Safety Stop"),
                item("14", "Exit (Appropriate Method)"),
                item("15", "Debriefing"),
                item("16", "Log & Sign Dive Books")
            ]
        )
    }

    private static func sdiOpenWater2() -> Checklist {
        Checklist(
            name: "Open Water 2",
            items: [
                item("1", "Briefing"),
                item("2", "Weight System & Mask Defog"),
                item("3", "SCUBA Unit Assembly"),
                item("4", "Don SCUBA Unit"),
                item("5", "Review ABCDE"),
                item("6", "Entry"),
                item("7", "ORCESD: With Reference"),
                item("8", "Mask", subItems: [
                    item("A", "Full Flood & Clear")
                ]),
                item("9", "Alternate Air Assisted Ascent"),
                item("10", "Tour: Neutral Buoyancy & Finning Practice"),
                item("11", "Safety Stop"),
                item("12", "Controlled Ascent with Reference"),
                item("13", "Tired Diver Tow"),
                item("14", "Snorkel to Regulator Exchange"),
                item("15", "Cramp Removal"),
                item("16", "Exit (Appropriate Method)"),
                item("17", "Debriefing"),
                item("18", "Log & Sign Dive Books")
            ]
        )
    }

    private static func sdiOpenWater3() -> Checklist {
        Checklist(
            name: "Open Water 3",
            items: [
                item("1", "Briefing"),
                item("2", "Weight System & Mask Defog"),
                item("3", "SCUBA Unit Assembly"),
                item("4", "Don SCUBA Unit"),
                item("5", "Review ABCDE"),
                item("6", "Entry"),
                item("7", "Weight Systems At Surface", subItems: [
                    item("A", "Remove"),
                    item("B", "Replace")
                ]),
                item("8", "Surface Navigation Run: Use 3 Points"),
                item("9", "ORCESD: Without Reference"),
                item("10", "Hover: Low Pressure Inflator"),
                item("11", "Monitor", subItems: [
                    item("A", "Depth"),
                    item("B", "Time"),
                    item("C", "No Decompression Limit"),
                    item("D", "Cylinder Pressure")
                ]),
                item("12", "Controlled Swim Ascent with Instructor"),
                item("13", "Tour: Neutral Buoyancy & Finning Practice"),
                item("14", "Controlled Ascent: On Buoyed Line"),
                item("15", "Safety Stop"),
                item("16", "Exit (Appropriate Method)"),
                item("17", "Debriefing"),
                item("18", "Log & Sign Dive Books")
            ]
        )
    }

    private static func sdiOpenWater4() -> Checklist {
        Checklist(
            name: "Open Water 4",
            items: [
                item("1", "Briefing"),
                item("2", "Weight System/Mask Defog"),
                item("3", "SCUBA Unit Assembly"),
                item("4", "Don SCUBA Unit"),
                item("5", "Review ABCDE"),
                item("6", "Entry"),
                item("7", "BCD At Surface", subItems: [
                    item("A", "Remove"),
                    item("B", "Replace")
                ]),
                item("8", "Controlled Descent without Reference"),
                item("9", "Weight System Underwater", subItems: [
                    item("A", "Remove"),
                    item("B", "Replace")
                ]),
                item("10", "Compass Run Underwater with Reciprocal"),
                item("11", "Tour: Slate Tour / Make Notes"),
                item("12", "Controlled Ascent"),
                item("13", "Safety Stop"),
                item("14", "Exit (Appropriate Method)"),
                item("15", "Debriefing"),
                item("16", "Log and Sign Dive Books")
            ]
        )
    }

    // MARK: - Dive Flexible Skills
    //
    // Skills that can be completed across any of Dives 2-5 (or with their
    // own multi-dive deadlines) rather than being tied to one specific
    // dive -- see the "Dive Flexible Skills -- Performance Requirements"
    // card. Referenced from the per-dive checklists above wherever a card
    // tagged a skill "(dive flexible)" for that dive.

    private static func diveFlexibleSkills() -> Checklist {
        Checklist(
            name: "Dive Flexible Skills",
            items: [
                item(nil, "Skin Diving", note: "During CW Dives 2, 3, 4 or 5, perform:", subItems: [
                    item("1", "A vertical dive from the surface in water too deep in which to stand (without excessive splashing or arm movement)."),
                    item("2", "A proper ascent, clearing and breathing from a snorkel without lifting the face from the water."),
                    item("3", "Proper buddy team procedures for skin diving.")
                ]),
                item(nil, "Equipment Preparation and Care", subItems: [
                    item("1", "Assemble and disassemble the scuba kit five times during confined water training.", subItems: [
                        item("a", "At least three times by the end of CW Dive 3, with little or no assistance on the last assembly and disassembly."),
                        item("b", "At least five times before the end of CW Dive 5, with little or no assistance on the last two assemblies and disassemblies.")
                    ]),
                    item("2", "Streamline and secure equipment for confined water dives by the end of CW Dive 3."),
                    item("3", "Demonstrate proper post-dive care of scuba equipment by the end of CW Dive 3.")
                ]),
                item(nil, "Disconnect Low Pressure Inflator Hose", note: "Disconnect the low pressure hose from the inflator in shallow water (either underwater or at surface).", subItems: [
                    item(nil, "By the end of CW Dive 3 for PADI Scuba Divers."),
                    item(nil, "By the end of CW Dive 5 for all student divers.")
                ]),
                item(nil, "Loose Cylinder Band", note: "During any CW Dive, resecure a loose cylinder band in the water either at the surface or underwater."),
                item(nil, "Weight System Removal and Replacement (surface)", note: "After CW Dive 1, remove, replace, adjust and secure weight system with minimal assistance at the surface in water too deep in which to stand.", subItems: [
                    item(nil, "By the end of CW Dive 3 for PADI Scuba Divers."),
                    item(nil, "By the end of CW Dive 5 for all student divers.")
                ]),
                item(nil, "Emergency Weight Drop", note: "During any dive, in either confined or open water, at the surface in water too deep in which to stand, with a deflated BCD, use the weight system's quick release to pull clear and drop sufficient weight to become positively buoyant.")
            ]
        )
    }

    // MARK: - Item helpers (mirrors SeedData.swift's helpers -- kept local
    // since SeedData's are private to that enum)

    // NOTE: as of v11, every item this file builds via these two helpers is
    // a non-checkable reference bullet (isNote: true) -- see the v11
    // changelog above. This intentionally covers everything in this file
    // (PADI Open Water Diver's Confined Water Dives/Waterskills
    // Assessment/Dive Flexible Skills, and SDI's Confined Water 1-4/Open
    // Water 1-4), since Divemaster is the only tracked roster program and
    // it lives entirely in DivemasterSeedData.swift with its own separate
    // item()/noteItem() helpers that this change does not touch.

    private static func item(_ text: String) -> ChecklistItem {
        ChecklistItem(text: text, isNote: true)
    }

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
