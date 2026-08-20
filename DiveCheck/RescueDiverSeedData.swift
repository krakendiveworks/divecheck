import Foundation

/// Content for the PADI Rescue Diver certification -- transcribed from PADI's
/// own Rescue Diver Instructor Slates (16 cards, numbered 2-17 in the
/// corner of each physical card -- card 1 is a cover/title card with no
/// transcribable content). That page numbering is what fixes the order
/// below; it isn't itself shown anywhere in the app.
///
/// Unlike the Divemaster slates (DivemasterSeedData.swift), these cards are
/// instructor lesson-plan/session-conduct notes for running the Rescue
/// Diver course -- not a per-student skill scoring sheet -- so, like
/// TrainingSeedData.swift's Open Water Diver content and
/// AdvancedOpenWaterSeedData.swift, this is a plain `TrainingCertification`
/// with every item a non-checkable reference bullet (`isNote: true`), not a
/// candidate-tracked `TrainingRosterProgram`.
///
/// Content flows continuously across several of the physical cards rather
/// than resetting per card the way the Advanced Open Water dive slates did,
/// so checklists here are grouped by the card's own named sections (Rescue
/// Exercise 1, Rescue Exercise 2, etc.) rather than strictly one checklist
/// per card -- a section that starts on one card and finishes on the next
/// is transcribed as a single checklist. Two sections are titled "Exercise
/// Practice" but are genuinely distinct standalone review sessions (one
/// covers Rescue Exercises 1-2, the other 1-3) rather than a repeat, so
/// both are kept and distinguished by name; three other exercises (5, 7,
/// and 10) have their own "Exercise Practice" as a subsection of that same
/// exercise's own card rather than a separate standalone card, so those
/// stay nested inside that exercise's checklist instead of becoming
/// separate top-level entries. Each section header actually printed on the
/// cards (Overview and Learning Objective, Performance Requirements,
/// Session Conduct and Focus, Postdive, etc.) is kept as a top-level item
/// with that card's own bullets as subItems underneath.
enum RescueDiverSeedData {
    static func makeChecklists() -> [Checklist] {
        [
            selfRescueReview(),
            rescueExercise1(),
            rescueExercise2(),
            exercisePracticeExercises1And2(),
            rescueExercise3(),
            exercisePracticeExercises1Through3(),
            rescueExercise4(),
            rescueExercise5(),
            rescueExercise6(),
            rescueExercise7(),
            rescueExercise8(),
            rescueExercise9(),
            rescueExercise10(),
            openWaterScenarioOne(),
            openWaterScenarioTwo(),
            inwaterRescueBreathingGuidelines()
        ]
    }

    // MARK: - Self-Rescue Review

    private static func selfRescueReview() -> Checklist {
        Checklist(
            name: "Self-Rescue Review",
            items: [
                section("Overview and Learning Objective", [
                    noteItem("This exercise reviews the self-rescue skills from the PADI Open Water Diver course.")
                ]),
                section("Performance Requirements", [
                    noteItem("By the end of the self-rescue review, the student should be able to:"),
                    item("1", "Demonstrate the correct procedures for the following self-rescue situations:", subItems: [
                        noteItem("Cramp release -- pull on fin tip to stretch cramped muscle."),
                        noteItem("Establishing buoyancy at the surface -- demonstrate positive buoyancy at the surface by inflating BCD using auto and oral inflation, and by releasing/discarding weight belts/systems."),
                        noteItem("Airway control -- practice snorkel to regulator exchange and breathing past small amounts of water."),
                        noteItem("Use of an alternate air source -- locate, secure and breathe from an alternate air source supplied by a buddy, in a stationary position, then swimming together, as both donor and receiver. Finish each exercise by ascending while breathing from the alternate air source. Review the use of an independent air source such as a pony bottle or a self-contained ascent bottle."),
                        noteItem("Overcoming vertigo and re-establishing sense of direction -- simulate vertigo, and then grab a descent line to re-establish sense of direction.")
                    ])
                ]),
                section("Session Conduct and Focus", [
                    noteItem("Position student divers wearing full scuba in water too deep in which to stand."),
                    noteItem("Divide class into buddy teams (\"victims\" and \"rescuers\")."),
                    noteItem("Demonstrate and have class practice each self-rescue skill."),
                    noteItem("Emphasize the identification of and the problem-solving aspect of common problems."),
                    noteItem("Students should be able to perform self-rescue skills competently.")
                ])
            ]
        )
    }

    // MARK: - Rescue Exercise 1

    private static func rescueExercise1() -> Checklist {
        Checklist(
            name: "Rescue Exercise 1: Tired Diver",
            items: [
                section("Overview and Learning Objective", [
                    noteItem("This exercise covers the procedures for responding to a distressed diver who, although still rational, needs assistance. Students should focus first on assessing the victim and the problem, then on acting to provide assistance.")
                ]),
                section("Performance Requirements", [
                    noteItem("By the end of this exercise, the student should be able to:"),
                    item("1", "Demonstrate the correct procedure for assisting a tired (rational responsive) diver at the surface, including:", subItems: [
                        noteItem("Approach -- continuously watch the tired diver and pace approach to have enough energy to complete rescue."),
                        noteItem("Evaluation -- stop near but out of reach, assess victim's mental state, and note the type and location of BCD inflator. Give clear and concise instructions."),
                        noteItem("Making contact -- approach from the front while explaining your actions. Use a contact-support position. Establish personal positive buoyancy and provide tired diver with positive buoyancy (low-pressure inflator preferred)."),
                        noteItem("Reassure the diver -- make eye contact and talk directly to the victim. Rest before resuming activity."),
                        noteItem("Assists and transport -- encourage the diver to do as much as possible. Maintain eye-to-eye contact, diver's face out of the water, and positive buoyancy. Rescuer and diver should be horizontal to swim effectively. Review underarm tow and modified tired-swimmers carry, use of BCDs as swimming aids, and tank-valve tow."),
                        noteItem("Equipment removal -- removing equipment, except for dropping weights, is usually of low priority. Practice using BCDs as an extension and procedures for removing weights.")
                    ])
                ]),
                section("Session Conduct and Focus", [
                    noteItem("Position student divers wearing full scuba in water too deep to stand up in."),
                    noteItem("Divide class into buddy teams (\"victims\" and \"rescuers\")."),
                    noteItem("Demonstrate and have class practice and perform each tow for a short distance. Allow ample time to determine which techniques work best for them as individuals."),
                    noteItem("Emphasize continually evaluating the victim's state of mind."),
                    noteItem("Tired diver exercises should focus on developing individualized rescuer techniques.")
                ])
            ]
        )
    }

    // MARK: - Rescue Exercise 2

    private static func rescueExercise2() -> Checklist {
        Checklist(
            name: "Rescue Exercise 2: Panicked Diver",
            items: [
                section("Overview and Learning Objective", [
                    noteItem("This exercise teaches students to respond to a panicked diver. Students should focus on safely rescuing an irrational diver and assisting. Encourage realism, but caution divers about not demonstrating extreme physical panic.")
                ]),
                section("Performance Requirements", [
                    noteItem("By the end of this exercise, the student should be able to:"),
                    item("1", "Demonstrate the correct procedure for rescuing a panicked (irrational) diver.", subItems: [
                        noteItem("Approach and evaluation -- approach and evaluate as with tired diver. Attempt to talk to panicked diver. Determine how to make contact."),
                        noteItem("Making contact using surface approach -- fastest, more risk. Swim behind diver and quickly grasp tank valve and assume knee-cradle position or grasp victim's opposite wrist and quickly pull and turn to spin diver away from you. Inflate diver's BCD and/or drop weights."),
                        noteItem("Making contact using underwater approach -- slower, less risk. Approach from underwater at knee or ankle (the victim's, weight may be removed). Turn/swim around to get behind diver. Ascend, maintain contact, grasp tank valve and assume the knee-cradle position. Inflate diver's BCD (drop weights at this time if not already removed)."),
                        noteItem("Releases -- demonstrate release to regain control: breathe from your regulator and descend; inflate both BCDs; push victim up and away. Option may be to wait for victim to reach exhaustion/unconsciousness, then handle the situation."),
                        noteItem("Approach with a quick reverse to stay out of a panicked diver's grasp -- be prepared to back away quickly. Lean backward, angle legs towards diver to be able to kick away quickly.")
                    ])
                ]),
                section("Session Conduct and Focus", [
                    noteItem("Position student divers wearing full scuba in water too deep to stand in."),
                    noteItem("Divide class into buddy teams (\"victims\" and \"rescuers\")."),
                    noteItem("Demonstrate and have class practice panicked diver surface and underwater rescues. Allow ample time to determine which techniques work best for them as individuals."),
                    noteItem("Emphasize continually evaluating the victim's state of mind."),
                    noteItem("Panicked diver exercises should focus on developing individualized rescuer techniques."),
                    noteItem("Do not expect competence on the first trial; rescue procedures are relatively long and complex, and some students will require multiple attempts for competence."),
                    noteItem("Stress that rescuing a panicked diver is the most dangerous situation for the rescuer.")
                ])
            ]
        )
    }

    // MARK: - Exercise Practice (Rescue Exercises 1-2)

    private static func exercisePracticeExercises1And2() -> Checklist {
        Checklist(
            name: "Exercise Practice (Rescue Exercises 1-2)",
            items: [
                noteItem("Exercise practice teaches students to apply what they've learned in Rescue Exercises 1 and 2. The goal is to have students react appropriately to differing rescue scenarios. Challenge rescuers by having to evaluate on the fly."),
                section("Conduct and Focus", [
                    noteItem("Divide class into buddy teams (\"victims\" and \"rescuers\")."),
                    noteItem("Position yourself or staff near the \"victims\" and whisper the type of victim to play."),
                    noteItem("Include variables such as victims too tired to swim, the need for releases, tired diver who panics during approach, the panicked diver who calms down once buoyant, the passive panicked diver -- does not thrash or appear overtly panicked, but does not respond to questions or directions, etc."),
                    noteItem("Include as much realistic variety as possible. The more variation, the better."),
                    noteItem("Move into scenario practice unannounced during skill practice. When students have practiced Rescue Exercise 2 enough to show proficiency, quietly tell a \"victim\" to simulate a tired diver instead of a panicked diver."),
                    noteItem("If the rescuer treats the \"victim\" as a panicked diver, interrupt and have the student reevaluate the \"victim.\" If the rescuer correctly responds with a tired diver rescue, give the student praise and call attention to it."),
                    noteItem("Rescue situations based on what students have already learned are fair game throughout the scenario practice session. Remind students to stop, think and then act based on their evaluation of the situation.")
                ]),
                section("Postdive", [
                    noteItem("Performance Review -- Talk about the application of good judgment in evaluating the \"victims'\" situations. Discuss techniques used. Have students critique themselves while you guide the process.")
                ])
            ]
        )
    }

    // MARK: - Rescue Exercise 3

    private static func rescueExercise3() -> Checklist {
        Checklist(
            name: "Rescue Exercise 3: Response from Shore, Boat or Dock (Responsive Diver)",
            items: [
                section("Overview and Learning Objective", [
                    noteItem("This exercise guides student divers through nonswimming and swimming assists to help a responsive diver. Emphasize efficiency and build upon skills practiced in previous exercises, and principles learned in the first two knowledge development sections.")
                ]),
                section("Performance Requirements", [
                    noteItem("By the end of this exercise, the student should be able to:"),
                    item("1", "In practice drills based on conditions and criteria described and varied by the instructor, demonstrate the following skills for assisting a responsive diver in distress:", subItems: [
                        noteItem("Nonswimming assists, including reaches/extensions and throws -- demonstrate the proper technique for throwing a line and retrieving a distressed diver from approximately 9 metres/30 feet."),
                        noteItem("Water entries with eyes on the victim and paced to conserve energy -- always respond with at least mask, snorkel, fins and some form of flotation; donning other equipment depends on circumstance. Enter water as near as possible to the distressed diver. Keep victim in view at all times."),
                        noteItem("Swimming assists and rescues, with and without emergency flotation equipment."),
                        noteItem("Tows with and without equipment removed, including underarm tow, tank valve tow and modified tired-swimmers carry."),
                        noteItem("Assisting two responsive divers at once -- multiple divers require the same techniques. Use judgment about whom to help first."),
                        noteItem("Exits with responsive divers who need assistance -- if exit is difficult have distressed diver rest/save energy then try to exit. If diver cannot recover and assist, follow procedures for exiting the water with an unresponsive diver.")
                    ]),
                    item("2", "Demonstrate the above while continuing to apply the information and skills learned in Rescue Exercises 1 and 2.")
                ]),
                section("Session Conduct and Focus", [
                    noteItem("Divide class into buddy teams (\"victims\" and \"rescuers\")."),
                    noteItem("Position the distressed divers in water too deep to stand up in and as far as possible from the pool deck/dock/shore/boat. Position rescuers ashore."),
                    noteItem("Assign \"victims\" the roles as tired or panicked divers (do not tell rescuers)."),
                    noteItem("Rescuers without scuba respond to distressed divers and take appropriate action."),
                    noteItem("Each exercise continues until the victim is out of the water."),
                    noteItem("Students are to try various entry and approach techniques. Repeat exercises until all have practiced with and without flotation aids, the three tows, tows with and without equipment, two or more victims, and exits with a tired diver."),
                    noteItem("Continuously vary the practice situation (victim type, equipment available, etc.). Do not expect all students to use the same techniques. Encourage students to find techniques that work for them.")
                ])
            ]
        )
    }

    // MARK: - Exercise Practice (Rescue Exercises 1-3)

    private static func exercisePracticeExercises1Through3() -> Checklist {
        Checklist(
            name: "Exercise Practice (Rescue Exercises 1-3)",
            items: [
                noteItem("Exercise practice teaches student divers to apply what they've learned in Rescue Exercises 1, 2 and 3. The goal is to have students react appropriately to differing rescue scenarios. Challenge them by having to evaluate \"on the fly.\""),
                section("Conduct and Focus", [
                    noteItem("Position student divers wearing full scuba in water too deep to stand in."),
                    noteItem("Divide class into \"victims\" and \"rescuers.\" Reverse roles at conclusion of each exercise and mix up partners. Staff may play \"victim.\""),
                    noteItem("Position yourself or staff near the \"victims\" and whisper the type of victim to play."),
                    noteItem("Include variables such as victims who are too tired to swim, the need for releases, tired diver who panics during approach, etc. Allow all flotation devices, improvised flotation devices and no flotation devices in various exercises. Allow rescuers to call for and get assistance in some exercises and to deal with the situation alone in others."),
                    noteItem("Include as much realistic variety as possible. Begin each drill with rescuer on shore and end with victim out of the water."),
                    noteItem("Move into scenario practice unannounced during skill practice. When students have shown proficiency with Rescue Exercise 3, quietly tell a \"victim\" to simulate a panicked diver within reach/extension distance."),
                    noteItem("If the rescuer responds with an inwater rescue, interrupt and ask the student to consider the best response for the circumstances. If the rescuer correctly evaluates and responds with a reach or extension rescue, praise and call attention to it."),
                    noteItem("Rescue situations based on what students have already learned are fair game throughout the scenario practice session. Remind students to stop, think and then act based on their evaluation of the situation.")
                ]),
                section("Postdive", [
                    noteItem("Performance Review -- Talk about the application of good judgment in evaluating the \"victims'\" situations. Compare and contrast the different techniques used. Have students critique themselves constructively while you guide the process.")
                ])
            ]
        )
    }

    // MARK: - Rescue Exercise 4

    private static func rescueExercise4() -> Checklist {
        Checklist(
            name: "Rescue Exercise 4: Distressed Diver Underwater",
            items: [
                section("Overview and Learning Objective", [
                    noteItem("This exercise focuses on underwater problems. During skills practice, divers deal with overexertion and out-of-air situations. Emphasize that as rescue divers, they need to be able to recognize these problems quickly and respond appropriately.")
                ]),
                section("Performance Requirements", [
                    noteItem("By the end of this exercise, the student should be able to:"),
                    item("1", "Demonstrate the ability to correctly identify and respond to a diver simulating overexertion and an active panic ascent underwater."),
                    item("2", "Correctly identify, and supply air to, via an alternate air source, a diver simulating an out-of-air emergency, and make a controlled air-sharing ascent with the diver.")
                ]),
                section("Session Conduct and Focus", [
                    item(nil, "Conduct this exercise in water too deep to stand up in, but not deeper than 12 metres/40 feet.", subItems: [
                        noteItem("Assign buddies roles as \"victims\" and \"rescuers.\""),
                        noteItem("Victims simulate distress/overexertion by breathing rapidly and appearing near exhaustion."),
                        noteItem("At a distance appropriate for local conditions and visibility, rescuer responds and assists in regaining control and proper breathing rhythm."),
                        noteItem("After completing overexertion, victim simulates a panicked diver beginning an uncontrolled ascent. Remind those simulating the victim to retain the regulator and to ascend at a normal safe rate."),
                        noteItem("Rescuer contacts low/behind, empties victim's and/or own BCD and flares the body."),
                        noteItem("At the surface, rescuer continues with surface procedures for a tired/panicked diver."),
                        noteItem("Team descends again. The victim signals \"out of air.\""),
                        noteItem("Rescuer provides alternate air source, makes contact and assures a controlled ascent. At the surface, the victim orally inflates BCD."),
                        noteItem("Repeat sequence until all students have practiced the rescuer role.")
                    ])
                ])
            ]
        )
    }

    // MARK: - Rescue Exercise 5

    private static func rescueExercise5() -> Checklist {
        Checklist(
            name: "Rescue Exercise 5: Missing Diver",
            items: [
                section("Overview and Learning Objective", [
                    noteItem("During this exercise, student divers organize and conduct a search for a missing diver."),
                    noteItem("It's best to have divers look for an object, rather than an actual diver, so that bubbles don't give away the location. In a small area, such as a pool, divers can search for a small object using the search patterns scaled down. Review basic compass navigation with divers who need a refresher and provide a thorough orientation to search techniques for those with little or no previous experience.")
                ]),
                section("Performance Requirements", [
                    noteItem("By the end of this exercise, the student should be able to:"),
                    item("1", "Demonstrate how to quickly and efficiently search for and locate a missing diver using an underwater search pattern prescribed by the instructor.")
                ]),
                section("Session Conduct and Focus", [
                    noteItem("Review missing diver procedures."),
                    noteItem("Review search patterns and techniques appropriate for the area."),
                    noteItem("Do a dry practice walk through each of the search patterns."),
                    noteItem("Focus on recognizing and responding quickly to problems."),
                    noteItem("Focus on effective implementation of all four search patterns.")
                ]),
                section("Exercise Practice", [
                    noteItem("This exercise teaches students to implement a search for a missing diver. Focus on the implementation of the search, with actual searches secondary and optional."),
                    item(nil, "Conduct and Focus", subItems: [
                        noteItem("Break the class into teams of two or three to practice missing diver procedures with only two or three divers available."),
                        noteItem("Review missing diver procedures."),
                        noteItem("Position student divers wearing full scuba in water too deep to stand in."),
                        noteItem("Run through the exercises several times with all divers taking turns in different roles."),
                        noteItem("Change the situation often: include simulated boat dives, shore dives and make equipment available or unavailable."),
                        noteItem("Focus on the organization and the procedures involved in the search for a missing diver.")
                    ])
                ]),
                section("Postdive", [
                    noteItem("Performance Review -- Talk about the application of good judgment in evaluating the \"victims'\" situations. Compare and contrast the different techniques used. Have students critique themselves constructively while you guide the process.")
                ])
            ]
        )
    }

    // MARK: - Rescue Exercise 6

    private static func rescueExercise6() -> Checklist {
        Checklist(
            name: "Rescue Exercise 6: Surfacing the Unresponsive Diver",
            items: [
                noteItem("IMPORTANT: During these next exercises, divers playing the victims will keep the regulators in their mouths at all times. During the exercise, victims and rescuers will ascend no faster than 18 metres/60 feet per minute, or slower if stipulated by a diver's computer."),
                section("Overview and Learning Objective", [
                    noteItem("This exercise develops bringing a diver simulating unresponsiveness to the surface. Emphasize proper positioning and ascent control. Encourage divers to think during ascent about the next step to take upon surfacing.")
                ]),
                section("Performance Requirements", [
                    noteItem("By the end of this exercise, the student should be able to:"),
                    item("1", "Demonstrate the use of controlled positive buoyancy as an aid to ascent."),
                    item("2", "Demonstrate how to bring an unresponsive diver to the surface using buoyancy control of either the unresponsive diver or the rescuer.")
                ]),
                section("Session Conduct and Focus", [
                    noteItem("Assign buddies roles as \"victims\" and \"rescuers.\""),
                    noteItem("Perform the surfacing unresponsive diver skill in water too deep to stand up in, but not deeper than 9 metres/30 feet."),
                    noteItem("Demonstrate procedures and options for surfacing an unconscious diver."),
                    noteItem("Have students practice several ascents to adapt and master the procedure."),
                    noteItem("Remind all divers to breathe normally at all times, even when simulating unresponsiveness. If the rescuer loses control of the ascent, both the victim and rescuer should abort the exercise, establish control and try again."),
                    noteItem("Watch for correct and efficient positioning. Allow students to experiment with when and how to drop whose weights and inflate BCDs."),
                    noteItem("Point out how techniques require change depending upon different equipment configurations.")
                ])
            ]
        )
    }

    // MARK: - Rescue Exercise 7

    private static func rescueExercise7() -> Checklist {
        Checklist(
            name: "Rescue Exercise 7: Unresponsive Diver at the Surface",
            items: [
                section("Overview and Learning Objective", [
                    noteItem("This exercise teaches students the initial steps for helping the unresponsive diver at the surface.")
                ]),
                section("Performance Requirements", [
                    noteItem("By the end of this exercise, the student should be able to:"),
                    item("1", "On a diver simulating unresponsiveness at the surface, demonstrate the following four emergency steps:", subItems: [
                        noteItem("Call for help while you establish buoyancy."),
                        noteItem("Turn the unconscious diver face up."),
                        noteItem("Remove the diver's mask and regulator, open airway and check for breathing."),
                        noteItem("Begin rescue breaths if required.")
                    ]),
                    item("2", "On a diver simulating unresponsiveness at the surface, demonstrate the following methods of inwater rescue breathing stationary and then towing the victim:", subItems: [
                        noteItem("Mouth-to-rescue breathing mask"),
                        noteItem("Mouth-to-snorkel (optional)"),
                        noteItem("Mouth-to-mouth"),
                        noteItem("Mouth-to-nose (optional)")
                    ]),
                    item("3", "On a diver simulating unresponsiveness at the surface, demonstrate equipment removal from the victim and the rescuer, including masks, weights and BCD/tank (as appropriate for the environment and equipment configurations worn), while continuing effective rescue breathing in water too deep to stand up in.")
                ]),
                section("Session Conduct and Focus", [
                    noteItem("Assign buddies roles as \"victims\" and \"rescuers.\""),
                    noteItem("Conduct rescue breathing demonstrations where students can clearly see above and below the water."),
                    noteItem("Have all students perform mouth-to-mouth and mouth-to-rescue breathing mask methods of rescue breathing in full scuba and in water too deep to stand up in. Practice optional methods of rescue breathing as appropriate for local conditions."),
                    noteItem("Using preferred method, rescuers remove all equipment necessary to get the victim out of the water while continuing to administer effective artificial respiration."),
                    noteItem("Focus on the initial steps for helping the unresponsive diver at the surface.")
                ]),
                section("Exercise Practice", [
                    noteItem("This exercise practice teaches divers to apply what they've learned to date. The emphasis should be on practicing new skills, but with variation and inclusion of old skills to require constant thinking before acting."),
                    item(nil, "Conduct and Focus", subItems: [
                        noteItem("Divide students into groups of victims/rescuers as appropriate for different exercises."),
                        noteItem("Each student should have at least one role as the rescuer bringing an unresponsive diver to the surface, continuing to tow a long distance while removing equipment and rescue breathing."),
                        noteItem("Mix it up -- Present the entire class with a missing diver whom they find, bring to the surface and tow to the exit. Give sufficient variety to constantly challenge the students to think, adapt and apply the resources available.")
                    ])
                ]),
                section("Postdive", [
                    noteItem("Performance Review -- Talk about the application of good judgment in evaluating the \"victims'\" situation. Compare and contrast the different techniques used. Have students critique themselves constructively while you guide the process.")
                ]),
                item(nil, "About Calling for Help", note: "Under stress, people tend to do what they've practiced. It's preferable for students to train by doing what they would in a real emergency as much as possible.", subItems: [
                    noteItem("The optimum call for help is, \"Help! I have a diver emergency! Call 911!\" or whatever corresponds in the local area."),
                    noteItem("In some training locations bystanders may not be aware that there's a class in progress -- take precautions.")
                ])
            ]
        )
    }

    // MARK: - Rescue Exercise 8

    private static func rescueExercise8() -> Checklist {
        Checklist(
            name: "Rescue Exercise 8: Exiting the Unresponsive Diver",
            items: [
                section("Overview and Learning Objective", [
                    noteItem("This exercise allows students to practice techniques for exiting the water with an injured diver. Stress that rescuer's size compared to the injured diver's is an important consideration for appropriate technique. If possible, conduct exercise simulating conditions expected at the local dive site.")
                ]),
                section("Performance Requirements", [
                    noteItem("By the end of this exercise, the student should be able to:"),
                    item("1", "Demonstrate how to remove a diver simulating a breathing unresponsive victim from the water, both with and without assistance."),
                    item("2", "Demonstrate how to remove a diver simulating a nonbreathing unresponsive victim from the water, both with and without assistance.")
                ]),
                section("Session Conduct and Focus", [
                    noteItem("Assign buddies roles as \"victims\" and \"rescuers.\""),
                    noteItem("Demonstrate and have teams practice unassisted and assisted exit techniques appropriate for the local area."),
                    noteItem("After showing rudimentary mastery for simulated breathing unresponsive divers, have students repeat the exit techniques with simulated nonbreathing unresponsive divers.")
                ])
            ]
        )
    }

    // MARK: - Rescue Exercise 9

    private static func rescueExercise9() -> Checklist {
        Checklist(
            name: "Rescue Exercise 9: First Aid for Pressure-Related Injuries and Oxygen Administration",
            items: [
                section("Overview and Learning Objective", [
                    noteItem("In this exercise, students practice emergency care for suspected decompression illness. Have divers set up an oxygen unit. Stress importance of oxygen in dive accidents. If possible, have different oxygen units and rescue breathing masks for expanded practice.")
                ]),
                section("Performance Requirements", [
                    noteItem("By the end of this exercise, the student should be able to:"),
                    item("1", "Demonstrate the recommended steps and procedures for administering oxygen to a breathing unresponsive diver with suspected decompression illness."),
                    item("2", "Demonstrate the recommended steps and procedures for delivering mouth-to-rescue breathing mask or mouth-to-mouth rescue breaths and administering oxygen to a nonbreathing unresponsive diver.")
                ]),
                section("Session Conduct and Focus", [
                    noteItem("Assign buddies roles as \"victims\" and \"rescuers.\""),
                    noteItem("Demonstrate and practice proper positioning of the injured diver."),
                    noteItem("In groups of two or three, have students practice deploying and using oxygen systems with nonresuscitator demand valve, nonrebreather mask and rescue breathing mask with simulated breathing, breathing weakly and nonbreathing patients."),
                    noteItem("Expand this to nonbreathing patients in full cardiac arrest."),
                    noteItem("Have students disassemble and then reassemble oxygen units. Allow adequate time and practice until all students can reliably and confidently deploy and use oxygen.")
                ])
            ]
        )
    }

    // MARK: - Rescue Exercise 10

    private static func rescueExercise10() -> Checklist {
        Checklist(
            name: "Rescue Exercise 10: Response from Shore or Boat, Unresponsive Diver",
            items: [
                section("Overview and Learning Objective", [
                    noteItem("This exercise combines many of the skills students have learned. It involves assessing an emergency situation, organizing a plan and responding from a boat or shore to the needs of an unconscious, nonbreathing diver. The goal is to apply the skills and knowledge presented throughout this course to a realistic scenario.")
                ]),
                section("Performance Requirements", [
                    noteItem("By the end of this exercise, the student should be able to:"),
                    item("1", "In teams and with minimal staff assistance, demonstrate the techniques for responding to a diver emergency that requires inwater rescue breathing, exiting the water with a nonbreathing unresponsive diver and then rendering appropriate first aid procedures, as a single integrated activity.")
                ]),
                section("Session Conduct and Focus", [
                    noteItem("Assign buddies roles as \"victims\" and \"rescuers.\""),
                    noteItem("Have students respond to an unresponsive diver from shore or boat. This should involve assessing an emergency situation, organizing a plan and responding to the needs of an unconscious, nonbreathing diver."),
                    noteItem("The focus is to provide student divers with an opportunity to apply the skills and knowledge presented throughout the course.")
                ]),
                section("Exercise Practice", [
                    item(nil, "Conduct and Focus", subItems: [
                        noteItem("Divide students into groups of victims, rescuers, gear handlers, or bystanders as appropriate for different exercises."),
                        noteItem("Include challenging scenarios and continue all scenarios through the exit and first aid as appropriate."),
                        noteItem("The focus is to have students face simulated emergencies they have been trained for.")
                    ])
                ]),
                section("Postdive", [
                    noteItem("Performance Review -- Talk about the application of good judgment in evaluating the \"victims'\" situations. Compare and contrast the different techniques used. Have students critique themselves constructively while you guide the process.")
                ])
            ]
        )
    }

    // MARK: - Open Water Scenario One

    private static func openWaterScenarioOne() -> Checklist {
        Checklist(
            name: "Open Water Scenario One: Unresponsive Diver Underwater",
            items: [
                section("Performance Requirements", [
                    noteItem("By the end of this rescue scenario, the student should be able to search for and locate a missing diver during an accident simulation while:"),
                    item("1", "As part of a team or as an individual, interview the victim's buddy and draw logical conclusions from the information presented."),
                    item("2", "As part of a team or as an individual, organize a quick and effective search (using surface and underwater search patterns)."),
                    item("3", "As part of a team or as an individual, search for and locate a missing diver."),
                    item("4", "As part of a team or as an individual, bring a diver simulating unresponsiveness to the surface using controlled positive buoyancy.")
                ]),
                section("Suggested Background and Setup", [
                    noteItem("DIVE GROUP has been diving in buddy teams. Everyone has been having a good time, with DIVEMASTER generally looking things over. All the buddy teams have returned, except one. Suddenly DIVER 1 surfaces and yells, \"I've lost DIVER 2! Has anybody seen DIVER 2?\" No one has."),
                    item("1", "Begin the scenario with DIVER 1 on the surface."),
                    item("2", "Continue the scenario until you find, surface and take the initial steps on the surface for DIVER 2, until I stop you, or until you reach the assigned time/depth/air supply limits.")
                ]),
                section("Instructor Notes", [
                    item("1", "DIVER GROUP is generally the entire class, plus other staff or certified PADI Rescue Divers who you wish to include."),
                    item("2", "Ideally, during the search for DIVER 2 make it an object they have to find rather than a person so that bubbles won't give away the location. The object should be the approximate size of a person, and you can put it in place before the class arrives. A staff member accompanies the search team(s) and takes over as DIVER 2 on the bottom for the rest of the scenario. Brief students that this is how you will handle it."),
                    item("3", "There are two strategies for assigning the DIVEMASTER role. You can assign it to a student with strong scene management skills based on what you've seen in the rescue training exercises. This gives the class experience in secondary rescues and with what will likely be an organized and effective search. The other strategy is to assign a student with weak management skills. This develops that student's skills and gives the others experience with having to self-direct more to make the search effective while not compromising the overall rescue effort.")
                ]),
                section("Predive Briefing and Conduct", [
                    noteItem("Dive Site and Dive Overview"),
                    noteItem("Buddy Teams Plan Dives"),
                    noteItem("Gear Up and Complete Predive Safety Check"),
                    noteItem("Open Water Scenario One")
                ]),
                section("Postdive", [
                    noteItem("Performance Review -- Ask these questions as debriefing points:"),
                    noteItem("Was the missing diver found? If not, why?"),
                    noteItem("Was the search organized quickly and effectively? Was anything missing? If so, what?"),
                    noteItem("Did the rescuers note the victim's condition on the bottom?"),
                    noteItem("What worked effectively during the rescue? What didn't?"),
                    noteItem("Was emergency care summoned as quickly as possible? Why or why not?"),
                    noteItem("What would you do differently?"),
                    noteItem("Divers disassemble and stow equipment, calculate dive profile, and log dive.")
                ])
            ]
        )
    }

    // MARK: - Open Water Scenario Two

    private static func openWaterScenarioTwo() -> Checklist {
        Checklist(
            name: "Open Water Scenario Two: Unresponsive Diver on the Surface",
            items: [
                section("Performance Requirements", [
                    noteItem("By the end of this rescue scenario, the student should be able to:"),
                    item("1", "As part of a team or as an individual, effectively respond to an unresponsive, nonbreathing diver during an accident simulation."),
                    item("2", "As part of a team or as an individual, effectively evaluate, tow, provide inwater rescue breaths, remove equipment, exit and provide CPR.")
                ]),
                section("Suggested Background and Setup", [
                    noteItem("DIVE GROUP is diving at a local site. Everyone has just entered the water and started snorkeling on the surface to the descent point. However, one buddy pair, DIVER 1 and DIVER 2, gets well ahead and has already reached the area and descended. Out of the water, DIVEMASTER is generally providing indirect supervision. Suddenly, DIVER 1 pops to the surface yells \"Help!\" weakly and slumps over in the water face down."),
                    noteItem("DIVER 2 surfaces behind DIVER 1 and starts waving for help."),
                    item("1", "Begin the scenario with DIVER 1 and DIVER 2 on the surface, with DIVE GROUP snorkeling on the surface about 100 metres/yards away. DIVEMASTER is at the entry/exit."),
                    item("2", "Continue the scenario through exiting the water and first aid until I stop you.")
                ]),
                section("Instructor Notes", [
                    item("1", "DIVER GROUP is generally the entire class, plus other staff or certified PADI Rescue Divers who you wish to include."),
                    item("2", "Tell DIVER 2 to provide this information when asked: DIVER 1 suddenly panicked and bolted to the surface. DIVER 2 does not know why."),
                    item("3", "When the rescue begins and students check for breathing, DIVER 1 is not breathing (instructor informs rescuer of this during assessment). When they get DIVER 1 ashore/aboard, DIVER 1 has no heartbeat. Switch to a CPR manikin or have students simulate a manikin."),
                    item("4", "There are two strategies for assigning the DIVEMASTER role. You can assign it to a student with strong scene management skills based on what you've seen in the rescue training exercises. This gives the class experience in secondary rescues and with what will likely be an organized rescue. The other strategy is to assign a student with weak management skills. This develops that student's skills and gives the others experience with having to self-direct more to make the rescue effective."),
                    item("5", "If AEDs are legal and available in your area, include one in the scenario.")
                ]),
                section("Predive Briefing and Conduct", [
                    noteItem("Dive Site and Dive Overview"),
                    noteItem("Buddy Teams Plan Dive"),
                    noteItem("Gear Up and Complete Predive Safety Check"),
                    noteItem("Open Water Scenario Two")
                ]),
                section("Postdive", [
                    noteItem("Performance Review -- Ask these questions as debriefing points:"),
                    noteItem("Did rescuers assess the victim's condition (breathing or not)?"),
                    noteItem("Did rescuers assess how long it would take to reach help (more or less than five minutes)?"),
                    noteItem("Was emergency care summoned as quickly as possible? Why or why not?"),
                    noteItem("Was equipment removed? If so, was it done in the best place for the circumstances?"),
                    noteItem("How effective was first aid? What could have been improved?"),
                    noteItem("What worked effectively during the rescue? What didn't?"),
                    noteItem("What would you do differently?"),
                    noteItem("Divers disassemble and stow equipment, calculate dive profile, and log dive.")
                ])
            ]
        )
    }

    // MARK: - Inwater Rescue Breathing Guidelines

    private static func inwaterRescueBreathingGuidelines() -> Checklist {
        Checklist(
            name: "Inwater Rescue Breathing Guidelines",
            items: [
                noteItem("These guidelines serve as a guide to provide inwater resuscitation to a nonbreathing victim found in the water."),
                item("1", "Ensure the safety of the rescuer and victim.", note: "First verify scene safety. You cannot help another if you also become a victim. To successfully assist victim, rescuer must maintain a reasonable degree of safety. If you cannot safely provide rescue breaths where victim is found, immediately move to a position of safety."),
                item("2", "Ensure buoyancy of rescuer and victim. Call for help."),
                item("3", "Assess responsiveness and check for breathing."),
                item("4", "If you determine the diver is not breathing, give 2 slow, full rescue breaths.", note: "It's often difficult to determine whether an unconscious victim is breathing in the water. Ventilating a weakly breathing victim is unlikely to cause further harm. Ventilating a nonbreathing victim may revive the victim, or at least maintain circulation."),
                item("5", "If breathing resumes, proceed toward safety (boat or shore) intermittently stopping to check the victim is still breathing.", note: "Rescuer should always keep victim under observation during the rescue, even if the victim is breathing spontaneously, since the victim could again cease breathing."),
                item("6", "If you have determined the diver is not breathing and you can get the victim to immediate assistance (i.e., the boat or shore), do so while giving 1 rescue breath every 5 seconds.", note: "Establishing an open airway and rescue breathing can be lifesaving. When respiratory arrest occurs, the heart, blood and lungs can continue to circulate oxygen to the brain and other vital organs. Cardiac arrest follows respiratory arrest at a variable but short interval."),
                item("7", "Evaluate circumstances (your ability, opportunities for assistance, environmental conditions) while giving 1 rescue breath every 5 seconds and proceed depending upon conditions.", subItems: [
                    item("A", "If it appears you are less than 5 minutes from safety, tow the diver to safety while providing rescue breaths. Get the diver out of the water, continue rescue breaths and perform a circulation check. Begin CPR if necessary."),
                    item("B", "If it appears you are more than 5 minutes from safety, continue to ventilate while checking for movement or other reaction to ventilations for 1-2 minutes.", subItems: [
                        item("1", "If movement or reaction to rescue breaths is present, but no spontaneous breathing, continue providing rescue breaths while towing to safety."),
                        item("2", "If movement or reaction to rescue breaths is absent, the diver is probably in cardiac arrest. Discontinue rescue breaths and tow the victim to safety as quickly as possible, exit the water, perform a circulation check and begin CPR if necessary. Resume rescue breathing if circulation is present.", note: "The potential disadvantage of giving rescue breaths is that if the victim is already in cardiac arrest it may delay starting CPR. There is limited research that suggests the advantages outweigh this potential disadvantage.")
                    ])
                ])
            ]
        )
    }

    // MARK: - Section helper

    /// A card's own named section (e.g. "Overview and Learning Objective",
    /// "Performance Requirements", "Session Conduct and Focus", "Postdive")
    /// as a top-level item, with that section's own bullets as subItems --
    /// unlike AdvancedOpenWaterSeedData.swift's "Process"/"Performance
    /// Requirements" headers, every one of these titles is printed on the
    /// physical cards verbatim.
    private static func section(_ title: String, _ children: [ChecklistItem]) -> ChecklistItem {
        item(nil, title, subItems: children)
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
