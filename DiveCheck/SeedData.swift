import Foundation

/// Builds the app's starting content: five top-level categories (Open
/// Circuit, Closed Circuit, Technical Diving, General Items, Travel) with
/// starter checklists, including the full Hollis Prism 2 Assembly,
/// Operational, and Post-Dive checklists transcribed from the manual under
/// Closed Circuit. General Items used to be duplicated inside Open Circuit,
/// Closed Circuit, and Technical Diving (see v13 changelog below); it's now
/// its own single top-level category instead.
enum SeedData {
    /// Canonical home-screen order. AppStore re-applies this to persisted
    /// data too, so reordering here also fixes existing installs.
    static let canonicalOrder = ["Open Circuit", "Closed Circuit", "Technical Diving", "General Items", "Travel"]

    /// Name of the "Scuba Class Packing" category -- still a plain
    /// DiveCategory in `categories` like everything else (so persistence,
    /// reseeding, and sync all keep working unchanged), but AppStore's
    /// `checklistCategories`/`scubaClassPackingCategory` use this to split
    /// it out so it surfaces as the first entry under Training instead of
    /// under Checklists -- see TrainingAgenciesListView.
    static let scubaClassPackingCategoryName = "Scuba Class Packing"

    /// Bump this whenever the starter checklist content itself changes
    /// (item wording, new sections, new units, etc.). AppStore compares it
    /// against a value saved on-device and reseeds automatically when it's
    /// higher, so updates to this file actually reach installs that already
    /// have persisted data.
    ///
    /// v9 was already consumed by earlier content changes (charging cords/
    /// bathing suit in General Items, the Mares rEvo checklists, etc.)
    /// before the "Scuba Class Packing" category below was added under the
    /// same version number -- on a device that had already reseeded at v9,
    /// that meant the new category never actually reached its persisted
    /// data. v10 re-bumps to force a fresh reseed and guarantee it shows up.
    ///
    /// v11: fixes a real iCloud sync race that could undo v10's reseed on
    /// a device with real iCloud history (e.g. a physical iPhone tested
    /// across many sessions) even though it worked fine on a fresh
    /// Simulator -- CloudSync.load always preferred whatever's in iCloud,
    /// so a stale synced copy of `categories` arriving asynchronously via
    /// `didChangeExternallyNotification` after the reseed already ran
    /// could silently overwrite the fresh content. AppStore now checks a
    /// separate synced version marker (see CloudSync.saveVersion) before
    /// applying an incoming change to this key, so a stale copy paired
    /// with an old version marker gets rejected instead. v11 forces one
    /// more clean, now-protected reseed on devices already affected.
    ///
    /// v12: the v11 sync-race guard closed one specific race but not the
    /// underlying problem -- `categories` and Training's `trainingAgencies`
    /// are by far the largest things synced through
    /// `NSUbiquitousKeyValueStore`, which caps out around 1MB total across
    /// all keys, and as more starter content was added (SDI/PADI
    /// checklists, the full Divemaster program, etc.) their combined size
    /// kept pushing closer to that ceiling. That looked exactly like
    /// content silently vanishing again after being confirmed working,
    /// worst on whichever device had the most real iCloud history (a
    /// physical iPhone used across many sessions) and eventually on a
    /// fresh Simulator too once even that margin ran out. `categories` is
    /// now persisted local-only (UserDefaults, no iCloud) via
    /// `CloudSync.saveLocalOnly`/`loadLocalOnly` -- see the doc comment on
    /// those in CloudSync.swift. v12 forces one more reseed so every
    /// device picks up this change cleanly.
    ///
    /// v13:
    /// - Prism 2 Operational, step 3.A "Check O2 cell mV readings in air"
    ///   now records 3 readings (one per sensor) instead of 1, matching how
    ///   step 9's calibration check already records Sensor 1/2/3 mV.
    /// - Open Circuit's "Dive Checklist" renamed to "Dive Gear Checklist";
    ///   "Mask (+ spare)" split into separate "Mask"/"Spare Mask" lines;
    ///   "Backup mask" removed from Safety & Signaling (redundant with the
    ///   new Spare Mask line above); the "Between Dives" section is gone --
    ///   Certification card/Dive insurance card/Logbook/Rinse bucket moved
    ///   into General Items (see below), and Buddy check/Surface interval
    ///   were dropped rather than moved, since neither fits a packing-style
    ///   reference checklist.
    /// - Closed Circuit > Common Gear: "Mask (+ spare)" split the same way
    ///   into "Mask"/"Spare Mask".
    /// - General Items is no longer duplicated inside Open Circuit, Closed
    ///   Circuit, and Technical Diving (three separate copies with
    ///   independent checkmarks) -- it's now one shared top-level category,
    ///   positioned between Technical Diving and Travel. "Hat & sunglasses"
    ///   split into separate "Hat"/"Sunglasses" lines, plus a new "Contact
    ///   Lenses" line, and the four items moved over from Open Circuit's
    ///   removed Between Dives section above.
    /// v13 forces one more reseed so every device picks up all of this.
    ///
    /// v14: every "Date"/"Date Packed" field (Prism 2 Operational and
    /// Post-Dive headers, Assembly's scrubber-packing field, Scuba Class
    /// Packing's header) is now a calendar picker (`ItemField.Kind.date`)
    /// instead of a free-text field -- see ItemField.swift. v14 forces one
    /// more reseed so already-installed checklists pick up the new field
    /// kind on those specific fields (existing custom/typed-in checklists
    /// are untouched either way, since Reset is the only thing that ever
    /// touches field *values*, not field *kind*).
    static let contentVersion = 14

    static func makeCategories() -> [DiveCategory] {
        [
            openCircuit(),
            closedCircuit(),
            technicalDiving(),
            generalItems(),
            travel(),
            scubaClassPacking()
        ]
    }

    // MARK: - General Items ("day of diving" extras, not scuba gear)
    //
    // Its own top-level category (between Technical Diving and Travel) --
    // previously duplicated as an extra checklist inside Open Circuit,
    // Closed Circuit, and Technical Diving (three independent copies with
    // separate checkmarks); see the v13 changelog above for why that
    // changed.

    private static func generalItems() -> DiveCategory {
        DiveCategory(name: "General Items", symbolName: "bag.fill", checklists: [generalItemsChecklist()])
    }

    private static func generalItemsChecklist() -> Checklist {
        Checklist(
            name: "General Items",
            items: [
                item("Water (extra bottles for surface intervals)"),
                item("Lunch / snacks"),
                item("Warm jacket or layer for between dives"),
                item("Blanket"),
                item("Towel(s)"),
                item("Bathing suit"),
                item("Sunscreen (reef-safe)"),
                item("Hat"),
                item("Sunglasses"),
                item("Contact Lenses"),
                item("Cash & ID"),
                item("Certification card"),
                item("Dive insurance card"),
                item("Logbook"),
                item("Phone / camera"),
                item("First aid kit"),
                item("Save-a-dive spare parts kit"),
                item("Spare Drysuit Seals"),
                item("Extra batteries (light, computer, torch)"),
                item("Charging cords (phone, dive computer, lights)"),
                item("Dry bag for valuables"),
                item("Cooler with cold drinks"),
                item("Rinse bucket / fresh water for gear"),
                item("Folding chair / shade tent")
            ]
        )
    }

    // MARK: - Closed Circuit

    private static func closedCircuit() -> DiveCategory {
        let prism2 = DiveSubcategory(
            name: "Hollis Prism 2",
            symbolName: "lungs.fill",
            checklists: [assemblyChecklist(), operationalChecklist(), postDiveChecklist()]
        )
        let revo = DiveSubcategory(
            name: "Mares rEvo",
            symbolName: "lungs",
            checklists: [revoBuildChecklist(), revoOperationChecklist()]
        )
        let commonGear = DiveSubcategory(
            name: "Common Gear",
            symbolName: "bag.badge.plus",
            checklists: [commonGearChecklist()]
        )
        return DiveCategory(
            name: "Closed Circuit",
            symbolName: "arrow.triangle.2.circlepath",
            subcategories: [prism2, revo, commonGear]
        )
    }

    private static func commonGearChecklist() -> Checklist {
        Checklist(
            name: "Common Gear",
            items: [
                noteItem("Exposure Protection"),
                item("Mask"),
                item("Spare Mask"),
                item("Fins"),
                item("Compass"),
                item("Wetsuit / drysuit"),
                item("Undergarments"),
                item("Hood"),
                item("Gloves"),
                item("Booties"),
                noteItem("Bailout"),
                item("Bailout bottle(s) - filled, analyzed, and labeled with MOD"),
                item("Bailout regulator - breathing tested"),
                item("Weights for CCR buoyancy trim"),
                noteItem("Scrubber & Sanitizing"),
                item("CO2 absorbent (sorb) - sufficient supply for planned dives"),
                item("Sorb packing tools (scale, packing rod/tool, storage container)"),
                item("Sanitizer / cleaning solution for loop and mouthpiece"),
                noteItem("Safety & Signaling"),
                item("Primary dive light"),
                item("Backup dive light"),
                item("Strobe"),
                item("Surface marker buoy (SMB) and reel/spool"),
                item("Lift bag"),
                item("Reef hook"),
                item("Jon line"),
                item("Whistle / signaling device"),
                item("Cutting tool"),
                item("Slate / wetnotes"),
                noteItem("Site Safety"),
                item("Site emergency kit: first aid / O2 / AED"),
                item("Dive flag"),
                item("Changing mat"),
                item("Emergency action plan reviewed with team")
            ]
        )
    }

    private static func assemblyChecklist() -> Checklist {
        Checklist(
            name: "Assembly",
            items: [
                item("1", "Fill scrubber basket with CO2 adsorbent + store in airtight container. Label container: Date Packed, Grade, Time Used, Time Left, User",
                     fields: [.date("Date Packed"), .text("Grade"), .text("Time Used"), .text("Time Left"), .text("User")]),
                noteItem("Maximum Scrubber Duration (EN 14143 conforming testing): 190 min (0.5% SEV CO2) using 8-12 @ 40°F/4°C, 1.6 L/min CO2, 131 fsw/40 msw · 215 min (0.5% SEV CO2) using 8-12 @ 40°F/4°C, 1.6 L/min CO2, 330 fsw/100 msw · 190 min (0.5% SEV CO2) using 8-12 @ 40°F/4°C, 1.6 L/min CO2, 18 fsw/6 msw"),
                item("2", "Fill O2 & Diluent cylinders, analyze contents, label cylinders with name, date, contents",
                     fields: [.text("O2 %"), .text("O2 Pressure"), .text("Dil Contents"), .text("Dil Pressure"), .text("MOD")]),
                item("3", "Install Regulators + Hoses on H-Plate", subItems: [
                    item("A", "O2 system on right (head facing up) - run all lines under bottom cylinder straps"),
                    item("B", "Attach Solenoid supply hose")
                ]),
                item("4", "Install BCD, BMCL + Backplate onto H-Plate", subItems: [
                    item("A", "Long screw on top, short screw on bottom - secure with nylon keepers"),
                    item("B", "Install BCD on plate - inflator facing H-Plate"),
                    item("C", "Pull gas supply hoses thru cylinder band notches in BCD"),
                    item("D", "Install BMCL - T-Pieces facing BCD"),
                    item("E", "Install backplate and harness - place on washers and tighten butterfly nuts")
                ]),
                item("5", "Attach Counterlungs to Harness", subItems: [
                    item("A", "Fold the T-Pieces over onto the harness and secure velcro tabs on the inhale and exhale sides onto the harness")
                ]),
                item("6", "Install T-Piece Breathing Hoses to Head", subItems: [
                    item("A", "Clean and lubricate O-rings, O-ring grooves and mating surfaces"),
                    item("B", "Install hose nuts finger tight. Inhalation side nut is white indicating counter-clockwise threads. Do not over-tighten")
                ]),
                item("7", "Attach Gas Supply Lines to Diluent + Oxygen Addition Blocks, ADV + BCD Inflator", subItems: [
                    item("A", "Attach O2 supply hose QD to Manual Addition Block"),
                    item("B", "Attach ADV supply hose (screw-on fitting)"),
                    item("C", "Attach Diluent supply hose QD to Manual Addition Block"),
                    item("D", "Attach BCD Inflation QD")
                ]),
                item("8", "Assemble DSV + Hoses, Check + Install", subItems: [
                    item("A", "Open/close, purge, mouthpiece"),
                    item("B", "Check mushroom valve seals and flow direction"),
                    item("C", "Install hoses onto DSV"),
                    item("D", "Install LED Heads Up Display holder, fix/attach cable to breathing hose")
                ]),
                item("9", "Clean Head to Bucket Sealing Rings, O-Ring Grooves + Lube O-Rings", subItems: [
                    item("A", "Remove O-rings per manual instructions, clean + replace if needed")
                ]),
                item("P", "Clean Red CO2 Seal + Secure in Place", subItems: [
                    item("A", "Make sure there is no debris, dust, or lubricant. Clean seal groove"),
                    item("B", "Make sure the red CO2 seal is firmly seated in its groove (triple check!)")
                ]),
                item("Q", "Check Filled CO2 Scrubber Basket", subItems: [
                    item("A", "Basket top secure"),
                    item("B", "Check for settling and firmness of absorbent bed")
                ]),
                item("R", "Check Scrubber Bucket", subItems: [
                    item("A", "Ensure bucket sealing surface is clean"),
                    item("B", "Basket compression spring installed + functional"),
                    item("C", "Install bucket moisture pads"),
                    item("D", "Make sure the pad is not resting on or interfering with the basket compression spring")
                ]),
                item("S", "Place CO2 basket in bucket, confirm center tube opening up, mount + seal bucket to head", note: "Record usage time on the Operational checklist"),
                item("T", "Mount cylinders to H-Plate & thread 1st stages into valves")
            ]
        )
    }

    private static func operationalChecklist() -> Checklist {
        Checklist(
            name: "Operational",
            headerFields: [
                .text("Name"),
                .date("Date"),
                .choice("Intra-Dive", options: ["No", "Yes"]),
                .choice("Scrubber", options: ["New", "Used"]),
                .text("Total Time Used on Scrubber")
            ],
            items: [
                item("1", "Assembly Checklist Completed"),
                item("2", "Install Analyzed + Labeled Gas Cylinders"),
                item("3", "Turn On Wrist Display", subItems: [
                    item("A", "Check O2 cell mV readings in air - 3 presses right button", note: "Acceptable: 8.5 mV to 14 mV - replace if needed", fields: [.text("Sensor 1 mV"), .text("Sensor 2 mV"), .text("Sensor 3 mV")]),
                    item("B", "Change to Setpoint .19")
                ]),
                item("4", "Turn On HUD - Check Battery Status"),
                item("5", "Oxygen System Leak Test", note: "Hold for 30 seconds minimum", subItems: [
                    item("A", "Slowly open oxygen valve, pressurize hoses, close valve"),
                    item("B", "Watch oxygen pressure gauge for pressure loss"),
                    item("C", "Slowly open oxygen valve")
                ]),
                item("6", "Negative Pressure Test", note: "Hold for 1 minute minimum", subItems: [
                    item("A", "Open DSV"),
                    item("B", "Inhale from DSV in CC mode, exhaling through nose until counterlungs are fully collapsed"),
                    item("C", "Close DSV"),
                    item("D", "Allow to sit for one minute; watch for signs of leaks")
                ]),
                item("7", "Positive Pressure Test", note: "Hold for 1 minute minimum", subItems: [
                    item("A", "Close OPV"),
                    item("B", "Fill loop fully with oxygen using manual oxygen addition valve until OPV vents"),
                    item("C", "Allow to sit for one minute, watch for signs of leaks"),
                    item("D", "Open DSV, evacuate loop contents")
                ]),
                item("8", "Flush Loop (2 times)", subItems: [
                    item("A", "Close DSV"),
                    item("B", "Fill loop with oxygen until OPV vents"),
                    item("C", "Evacuate loop fully"),
                    item("D", "Repeat steps A. & B."),
                    item("E", "Open DSV to equalize pressure to ambient pressure, close DSV")
                ]),
                item("9", "Calibrate Wrist Display & HUD", subItems: [
                    item(nil, "Wrist Display", subItems: [
                        item("A", "Menu to calibrate (2 X MENU - left button)"),
                        item("B", "Press Select (right button) twice to calibrate"),
                        item("C", "Check mV readings in O2", note: "Acceptable: 40.6 mV - 66.9 mV", fields: [.text("Sensor 1 mV"), .text("Sensor 2 mV"), .text("Sensor 3 mV")])
                    ]),
                    item(nil, "HUD", subItems: [
                        item("D", "2 presses on HUD switch - press & hold to confirm")
                    ])
                ]),
                item("10", "Check Solenoid & Wrist Display Battery", subItems: [
                    item("A", "Setpoint to high (>1.1)"),
                    item("B", "Solenoid fires, O2 injection verified"),
                    item("C", "Change setpoint to .19"),
                    item("D", "Solenoid and wrist display battery check (8 X SELECT - Right button)", note: "Acceptable: Ext V ≥ 7 / Int V ≥ 3.18", fields: [.text("Ext V"), .text("Int V")])
                ]),
                item("11", "Install Cover"),
                item("12", "Diluent System Leak Test", note: "Hold for 30 seconds minimum", subItems: [
                    item("A", "Open diluent valve - pressurize - close valve"),
                    item("B", "Watch diluent pressure gauge for pressure loss"),
                    item("C", "Open diluent cylinder")
                ]),
                item("13", "Check ADV and BCD", subItems: [
                    item("A", "Open DSV, inhale from loop until ADV engages, dropping loop PO2"),
                    item("B", "BCD inflation + deflation mechanisms / air holding")
                ]),
                item("14", "Pre-Breathe", note: "If diving immediately, continue with Pre-Dive Checks below. If NOT diving immediately, close O2 + diluent cylinder valves, drain hoses, turn off electronics, and secure unit.", subItems: [
                    item("A", "Change wrist display to low setpoint"),
                    item("B", "Block nose and begin breathing from the Prism 2 while seated in a safe location"),
                    item("C", "Observe setpoint maintenance")
                ]),
                noteItem("Pre-Dive Checks"),
                item("15", "Weights"),
                item("16", "HUD and Wrist Displays On"),
                item("17", "Cylinder Valves Open"),
                item("18", "Verify Setpoint and Loop Contents"),
                item("19", "Don the Prism 2"),
                item("20", "Pre-Jump", note: "See hang tag on rebreather", subItems: [
                    item("A", "Begin breathing unit"),
                    item("B", "Check: ADV, O2 Add, Dil Add, BCD"),
                    item("C", "Check SPG: O2, Dil, OC"),
                    item("D", "Observe setpoint maintained"),
                    item("E", "Always know PPO2 & have fun")
                ])
            ]
        )
    }

    private static func postDiveChecklist() -> Checklist {
        Checklist(
            name: "Post-Dive",
            headerFields: [.text("Name"), .date("Date")],
            items: [
                item("1", "Verify and record batteries (Solenoid/Wrist Display)", subItems: [
                    item(nil, "Solenoid battery", fields: [.text("V"), .choice("Status", options: ["Good", "Replaced"])]),
                    item(nil, "Wrist Display battery", fields: [.text("V"), .choice("Status", options: ["Good", "Replaced"])])
                ]),
                item("2", "Turn off, secure Wrist Display"),
                item("3", "Verify Heads Up Display Battery", fields: [.choice("Status", options: ["Good", "Replaced"])]),
                item("4", "Drain counterlungs of fluid"),
                item("5", "Remove CL weights"),
                item("6", "Remove weight pockets, weights, rinse and hang to dry"),
                item("7", "Soak complete, sealed unit in fresh water for 20 minutes if possible or hose off with fresh water"),
                item("8", "Turn off O2 and drain lines, remove cylinder"),
                item("9", "Turn off diluent and drain lines, remove cylinder"),
                item("10", "Detach bucket from head, record absorbent usage, or discard absorbent material",
                     fields: [.choice("Absorbent", options: ["Stored for re-use", "Discarded"]), .date("Date Packed"), .text("Size"), .text("Total Hours Used")]),
                item("11", "Sanitize bucket"),
                item("12", "Inspect O2 sensors, record readings in air", fields: [.text("Sensor 1"), .text("Sensor 2"), .text("Sensor 3")]),
                item("13", "Disassemble mouthpiece to counterlung hose assembly, sanitize; hang to dry"),
                item("14", "Remove counterlungs, sanitize, hang to dry"),
                item("15", "Drain and hang BCD/backplate/head assembly in a shaded area to dry"),
                item("16", "Review maintenance/repair log and address any repairs if required")
            ]
        )
    }

    // MARK: - Mares rEvo
    //
    // Transcribed from the rEvo CCR complete checklist (Build Checklist +
    // Closed Check) published at techdivingtraining.com/revo-checklist --
    // unlike the Prism 2's manual-sourced Assembly/Operational/Post-Dive
    // split, the source only publishes two lists, so this unit gets a
    // Build checklist and an Operation checklist.

    private static func revoBuildChecklist() -> Checklist {
        Checklist(
            name: "Build",
            items: [
                noteItem("Check millivolts in air in Controller", fields: [.text("Cell 1"), .text("Cell 2"), .text("Cell 3")]),
                noteItem("Check millivolts in Backup SW/rEvo Dreams", fields: [.text("Cell 4"), .text("Cell 5")]),
                item("Setpoint to 0.7 to fire solenoid. Check batteries: EXT > 6.5V, INT > 1.4V or 3.4V on SAFT. Put setpoint back to 0.19"),
                item("Sensor age: Youngest < 7 months?"),
                item("Remaining scrubber time checked"),
                item("Remove water from counterlungs if needed"),
                item("Place moisture absorber in inhale lung"),
                item("Install sensor grid/solenoid grid, check routing"),
                item("Install scrubbers correctly (TOP markers up)"),
                item("Check scrubber O-rings, sealing, grease if needed"),
                item("Close cover, screw hand-tight"),
                noteItem("Analyse O2 and Dil content", fields: [.text("Oxygen %"), .text("Dil O2 %"), .text("Dil He %")]),
                noteItem("Check cylinder pressures", fields: [.text("O2 Tank (bar)"), .text("Diluent Tank (bar)")]),
                item("Program gasses into computers"),
                item("Install tanks on unit securely"),
                item("Connect regulators to tanks"),
                item("Squeeze water from loop if needed"),
                item("Stereo check on non-return valves"),
                item("Check bite-piece"),
                item("Check O-rings on loop ends"),
                item("Grease and clean loop sealing surfaces"),
                item("Install loop, check orientation"),
                item("Wrap HUD/NERD cable 3-4x clockwise"),
                item("Install drysuit bottle if used")
            ]
        )
    }

    private static func revoOperationChecklist() -> Checklist {
        Checklist(
            name: "Operation",
            items: [
                noteItem("Closed Check on Oxygen Side"),
                item("Open oxygen, check pressure"),
                item("Test MAV O2 button"),
                item("Setpoint to 0.7, solenoid fires?"),
                item("Return setpoint to 0.19"),
                item("Flush with O2 (DSV slightly open)"),
                item("Calibrate controller & backup"),
                item("Check EXT battery > 6.5V"),
                item("INT battery OK?"),
                item("Backup device battery OK?"),
                item("Close O2 valve, CMF test"),
                item("Depressurize O2 line"),
                noteItem("Closed Check on Diluent Side"),
                item("Open diluent, check pressure"),
                item("Test MAV Diluent button"),
                item("Test ADV"),
                item("Test counterlung OPV"),
                item("Overpressure test 1 min"),
                item("Test wing inflation/deflation"),
                item("Diluent flush: PPO2 matches?"),
                item("Close diluent, check if pressure holds"),
                item("Depressurize diluent line"),
                item("Start negative test for about 5 minutes"),
                noteItem("Bailout Cylinders"),
                item("Analyse content, program into computers"),
                item("Check pressure"),
                item("Vacuum/leak test regulators"),
                item("Check LPI connections (attach/test)"),
                item("Did you finish the negative test on the unit?")
            ]
        )
    }

    // MARK: - Open Circuit (comprehensive multi-dive day)

    private static func openCircuit() -> DiveCategory {
        let starter = Checklist(
            name: "Dive Gear Checklist",
            items: [
                noteItem("Exposure Protection"),
                item("Wetsuit / drysuit"),
                item("Undergarments"),
                item("Hood"),
                item("Gloves"),
                item("Booties"),
                noteItem("Core Gear"),
                item("Mask"),
                item("Spare Mask"),
                item("Fins"),
                item("Snorkel"),
                item("Compass"),
                item("BCD - inflator/deflator function tested"),
                item("Weights & weight belt/pockets sized for exposure suit"),
                noteItem("Air Supply"),
                item("Tank(s) filled and valve checked - enough for all planned dives"),
                item("Regulator (primary 2nd stage)"),
                item("Octopus / alternate air source"),
                item("SPG reads correctly, no leaks at first stage"),
                item("Tank valve O-rings inspected"),
                item("Pony/bailout bottle if carried"),
                noteItem("Instrumentation"),
                item("Dive computer / bottom timer - battery checked"),
                item("Backup Computer / Bottom Timer"),
                noteItem("Safety & Signaling"),
                item("Surface marker buoy (SMB) and reel/spool"),
                item("Whistle / signaling device"),
                item("Dive light + backup light"),
                item("Strobe"),
                item("Lift bag"),
                item("Reef hook"),
                item("Jon line"),
                item("Cutting tool / dive knife"),
                noteItem("Site Safety"),
                item("Site emergency kit: first aid / O2 / AED"),
                item("Dive flag"),
                item("Changing mat"),
                item("Emergency action plan reviewed with team")
            ]
        )
        return DiveCategory(name: "Open Circuit", symbolName: "wind", checklists: [starter])
    }

    // MARK: - Technical Diving (comprehensive multi-dive day)

    private static func technicalDiving() -> DiveCategory {
        let starter = Checklist(
            name: "Dive Checklist",
            items: [
                noteItem("Exposure Protection"),
                item("Drysuit / wetsuit"),
                item("Undergarments (weight appropriate for planned depth/time)"),
                item("Hood"),
                item("Gloves (dry gloves if applicable)"),
                item("Spare seals / o-rings for drysuit"),
                noteItem("Core Gear"),
                item("Mask (+ spare)"),
                item("Fins"),
                item("Compass"),
                item("BCD / wing & backplate - inflator/deflator tested"),
                item("Weights sized for exposure protection and full gas loadout"),
                noteItem("Back Gas"),
                item("Back gas cylinders analyzed, labeled with blend + MOD"),
                item("Primary regulator (long hose) and necklace backup leak-checked"),
                item("SPGs read correctly on both regulators"),
                noteItem("Stage / Deco Gas"),
                item("Stage/deco cylinders analyzed and labeled with contents + MOD"),
                item("Deco regulators attached, breathing tested, and leak-checked"),
                item("Cylinders clipped in correct switch order, bottom to top"),
                item("Gas switch procedure reviewed with team"),
                noteItem("Instrumentation"),
                item("Dive computer(s) set with correct gas mixes for each cylinder"),
                item("Backup Computer / Bottom Timer"),
                item("Wetnotes/slate with planned run time, gas switches, and deco schedule"),
                noteItem("Safety & Signaling"),
                item("Reels, spools, and SMBs (primary + backup)"),
                item("Lift bag"),
                item("Reef hook"),
                item("Jon line"),
                item("Strobe"),
                item("Backup mask"),
                item("Cutting tool (primary + backup)"),
                item("Dive light + backup light"),
                noteItem("Site Safety"),
                item("Site emergency kit: first aid / O2 / AED"),
                item("Dive flag"),
                item("Changing mat"),
                item("Emergency action plan reviewed with team"),
                noteItem("Spares & Documentation"),
                item("Save-a-dive spares specific to technical config (o-rings, LP hose, SPG)"),
                item("Certification card(s) for planned gas/depth"),
                item("Logbook"),
                item("Team gas-matching and configuration check completed"),
                item("Emergency signals and lost-buddy/lost-gas procedure reviewed")
            ]
        )
        return DiveCategory(name: "Technical Diving", symbolName: "gauge.with.dots.needle.bottom.50percent", checklists: [starter])
    }

    // MARK: - Travel

    private static func travel() -> DiveCategory {
        let starter = Checklist(
            name: "Starter Checklist",
            items: [
                item("Passport / ID valid for travel dates"),
                item("Dive certification card(s)"),
                item("Dive travel/accident insurance confirmation"),
                item("Logbook"),
                item("Airline checked-baggage weight limits confirmed"),
                item("Regulator, computer, and mask packed in carry-on"),
                item("Spare mask strap, fin straps, o-rings"),
                item("Adapter/charger for dive computer and dive light"),
                item("Reef-safe sunscreen"),
                item("Motion sickness medication"),
                item("Copy of travel itinerary and dive shop/operator contact info"),
                item("Emergency contact and dive accident insurance number")
            ]
        )
        return DiveCategory(name: "Travel", symbolName: "airplane", checklists: [starter])
    }

    // MARK: - Scuba Class Packing
    //
    // Transcribed from the "Scuba Class Packing Checklist" PDF -- an
    // instructor/dive-shop packing list for a class (student gear boxes,
    // tanks, site and safety equipment), not a personal per-dive checklist
    // like the categories above. Section banners on the form (Student
    // Boxes, Tanks and Other Gear, etc.) become noteItem() header rows
    // within the flat item list, same convention used for "Pre-Dive
    // Checks" in the Prism 2 Operational checklist. Blank write-in lines
    // on the form were skipped -- the app already supports adding custom
    // items to any checklist. The form's "#" fill-in blanks (tank counts,
    // IDs) became a text field on that item instead.

    private static func scubaClassPacking() -> DiveCategory {
        let packing = Checklist(
            name: "Scuba Class Packing Checklist",
            headerFields: [
                .text("Class"),
                .date("Date"),
                .text("Number of Students")
            ],
            items: [
                noteItem("Reminder: Pros / Staff are expected to be responsible for their own gear (BCD, Tanks, Weights, Regulators, Lights, Etc) and MUST make special accommodations with the course leaders if their needs must be incorporated into the packing requirements."),

                noteItem("Student Boxes: Verify Contents of Each Box"),
                item("BCDs"),
                item("Wetsuit / Drysuit"),
                item("Regulators"),
                item("Hoods and Gloves"),

                noteItem("Tanks and Other Gear (For Students Only)"),
                item(nil, "Air Tanks", fields: [.text("Count / IDs")]),
                item(nil, "Nitrox Tanks", fields: [.text("Count / IDs")]),
                item(nil, "Compasses", fields: [.text("Count / IDs")]),
                item(nil, "Computers", fields: [.text("Count / IDs")]),
                item("Weight (enough for Students + extra)"),
                item(nil, "Lights", fields: [.text("Count / IDs")]),

                noteItem("Spare Tanks and Equipment"),
                item(nil, "Spare Air Tanks", fields: [.text("Count / IDs")]),
                item(nil, "Spare Nitrox Tanks", fields: [.text("Count / IDs")]),
                item(nil, "Spare BCDs", fields: [.text("Count / IDs")]),
                item(nil, "Spare Regulators", fields: [.text("Count / IDs")]),

                noteItem("Documents & Paperwork"),
                item("Dive Log Book"),
                item("Student Folders and Course Box"),
                item("Dive Planning Sheets"),
                item("Pens"),
                item("Any Required Waivers"),
                item("PIC Forms"),

                noteItem("Specialty Equipment"),
                item("Strobes"),
                item("Strobe Light Pole"),
                item("Anchor"),
                item("Lift Bag"),
                item("Weight Drop Rope"),
                item("Line to Clip Off BCDs in Water"),
                item("CPR Dummy"),
                item("Carabiners to Clip BCDs"),

                noteItem("Site Equipment"),
                item(nil, "Tents", fields: [.text("Count / IDs")]),
                item("Tip Jar"),
                item(nil, "Rugs", fields: [.text("Count / IDs")]),
                item("Save-A-Dive Kit"),
                item(nil, "Buoys", fields: [.text("Count / IDs")]),
                item("Changing Tent"),
                item("Rinse Kit"),
                item("Water Jug"),
                item("Easel / Dry Erase Markers / Eraser"),
                item("Propane Tank"),
                item("Heater"),
                item("Grill"),
                item(nil, "Tank / Rig Tables", fields: [.text("Count / IDs")]),
                item("Dive Flags"),

                noteItem("Safety Equipment"),
                item("Oxygen Kit"),
                item("AED"),
                item("First Aid Kit"),
                item("Dive Site Emergency Plan")
            ]
        )
        return DiveCategory(name: scubaClassPackingCategoryName, symbolName: "list.clipboard.fill", checklists: [packing])
    }

    // MARK: - Item helpers

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
