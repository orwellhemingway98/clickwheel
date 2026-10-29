import XCTest
@testable import ClickWheel

@MainActor
final class NavigatorFirstGenTests: XCTestCase {
    private var spy: SpyPlayerControls!
    private var settings: AppSettings!
    private var suiteName: String!
    private var clock: TimeInterval = 100

    override func setUp() async throws {
        suiteName = "NavigatorFirstGenTests-\(UUID().uuidString)"
        settings = AppSettings(defaults: UserDefaults(suiteName: suiteName)!)
        spy = SpyPlayerControls()
        clock = 100
    }

    override func tearDown() async throws {
        UserDefaults().removePersistentDomain(forName: suiteName)
    }

    private func navigator(_ model: IPodModel = .firstGen, rows: [MenuItem] = []) -> Navigator {
        Navigator(player: spy, settings: settings,
                  musicMenu: { MenuScreen(title: "Music", items: rows) },
                  shuffle: {},
                  profile: model.spec.firmware,
                  browse: { MenuScreen(title: "Browse", items: [
                      MenuItem("Artists", action: .run {}), MenuItem("Albums", action: .run {}), MenuItem("Songs", action: .run {}),
                  ]) },
                  playlists: { MenuItem("Playlists", action: .push { MenuScreen(title: "Playlists", items: rows) }) },
                  now: { [unowned self] in self.clock })
    }

    private func menu(_ nav: Navigator) -> MenuScreen? {
        if case .menu(let screen) = nav.current { return screen }
        return nil
    }

    private func open(_ nav: Navigator, _ label: String) {
        guard let index = menu(nav)?.items.firstIndex(where: { $0.label == label }) else { return XCTFail("no \(label)") }
        nav.handle(.scroll(steps: index - menu(nav)!.selectedIndex))
        nav.handle(.center)
    }

    private let track = NowPlayingInfo(trackID: "t", title: "T", artist: "A", album: "B", duration: 100,
                                       position: 10, index: nil, count: nil, source: .appleMusic)

    func testFirstGenRoot() {
        let nav = navigator()
        XCTAssertEqual(menu(nav)?.items.map(\.label), ["Playlists", "Browse", "Extras", "Settings", "Backlight"])
        nav.setTrack(track)
        XCTAssertEqual(menu(nav)?.items.last?.label, "Now Playing")
    }

    func testBrowseMenu() {
        let nav = navigator()
        open(nav, "Browse")
        XCTAssertEqual(menu(nav)?.items.map(\.label), ["Artists", "Albums", "Songs"])
    }

    func testExtrasHasClockOnly() {
        let nav = navigator()
        open(nav, "Extras")
        XCTAssertEqual(menu(nav)?.items.map(\.label), ["Clock"])
    }

    func testSettingsPerModel() {
        let first = navigator()
        open(first, "Settings")
        XCTAssertEqual(menu(first)?.items.map(\.label), ["Model", "Source", "Backlight Timer", "Clicker"])
        let fifth = navigator(.fifthGen)
        open(fifth, "Settings")
        XCTAssertEqual(menu(fifth)?.items.map(\.label), ["Model", "Source", "Clicker"])
    }

    func testModelRowOpensTheList() {
        settings.model = .firstGen
        let nav = navigator()
        open(nav, "Settings")
        XCTAssertEqual(menu(nav)?.items.first?.detail(), "1st gen")
        XCTAssertTrue(menu(nav)?.items.first?.opensSubmenu == true)
        nav.handle(.center)
        XCTAssertEqual(menu(nav)?.title, "Model")
        XCTAssertEqual(menu(nav)?.items.map(\.label), ["1st generation", "2nd generation", "3rd generation", "iPod mini", "4th generation", "iPod photo", "iPod mini (2nd gen)", "iPod nano", "5th generation", "iPod nano (2nd gen)"])
        XCTAssertEqual(menu(nav)?.items.map { $0.detail() }, ["✓ 2001", "2002", "2003", "2004", "2004", "2004", "2005", "2005", "2005", "2006"])
        XCTAssertEqual(menu(nav)?.selectedIndex, 0)
    }

    func testModelListAlwaysOpensAtTheTop() {
        settings.model = .fifthGen
        let nav = navigator(.fifthGen)
        open(nav, "Settings")
        nav.handle(.center)
        XCTAssertEqual(menu(nav)?.title, "Model")
        XCTAssertEqual(menu(nav)?.selectedIndex, 0, "like every iPod list, it starts at the top")
        XCTAssertEqual(menu(nav)?.items[IPodModel.allCases.firstIndex(of: .fifthGen)!].detail(), "✓ 2005",
                       "the tick still marks the current model")
        nav.handle(.scroll(steps: 1))
        nav.handle(.center)
        XCTAssertEqual(settings.model, .secondGen, "one step down from the top is the 2nd generation")
    }

    func testSelectingAModelSwitchesAndPersists() {
        settings.model = .firstGen
        let nav = navigator()
        open(nav, "Settings")
        nav.handle(.center)
        open(nav, "2nd generation")
        XCTAssertEqual(settings.model, .secondGen)
        XCTAssertEqual(AppSettings(defaults: UserDefaults(suiteName: suiteName)!).model, .secondGen)
    }

    func testSelectingTheCurrentModelGoesBack() {
        settings.model = .firstGen
        let nav = navigator()
        open(nav, "Settings")
        nav.handle(.center)
        nav.handle(.center)                 // "1st generation" is current
        XCTAssertEqual(settings.model, .firstGen)
        XCTAssertEqual(menu(nav)?.title, "Settings")
    }

    func testBacklightTimerRowCycles() {
        let nav = navigator()
        open(nav, "Settings")
        open(nav, "Backlight Timer")
        XCTAssertEqual(settings.backlightTimer, .twenty)
        XCTAssertEqual(menu(nav)?.items[2].detail(), "20 s")
    }

    func testHoldMenuTogglesBacklightOnFirstGen() {
        settings.backlightTimer = .ten
        let nav = navigator()
        open(nav, "Extras")
        nav.handle(.menuHold)                   // input woke it, so the hold turns it off
        XCTAssertFalse(nav.backlight.isOn)
        XCTAssertEqual(menu(nav)?.title, "Extras", "hold MENU must not leave the screen on 1G")
        nav.handle(.menuHold)
        XCTAssertTrue(nav.backlight.isOn)
    }

    func testHoldMenuStillGoesHomeOnFifthGen() {
        let nav = navigator(.fifthGen)
        nav.handle(.center)
        nav.handle(.menuHold)
        XCTAssertEqual(nav.stack.count, 1)
    }

    func testBacklightRowToggles() {
        let nav = navigator()
        open(nav, "Backlight")                  // the scroll woke it; the row turns it off
        XCTAssertFalse(nav.backlight.isOn)
    }

    func testInputWakesAndTickExpires() {
        settings.backlightTimer = .five
        let nav = navigator()
        nav.handle(.scroll(steps: 1))
        XCTAssertTrue(nav.backlight.isOn)
        nav.handle(.tick(now: clock + 4.9))
        XCTAssertTrue(nav.backlight.isOn)
        nav.handle(.tick(now: clock + 5.1))
        XCTAssertFalse(nav.backlight.isOn)
    }

    func testNoQuickScrollOnFirstGen() async {
        let rows = (0..<50).map { MenuItem("Row \($0)", action: .run {}) }
        let nav = Navigator(player: spy, settings: settings, profile: IPodModel.firstGen.spec.firmware,
                            browse: { MenuScreen(title: "Browse", items: [
                                MenuItem("Songs", quickScrollList: true, action: .load(title: "Songs", empty: "No songs") { rows }),
                            ]) },
                            now: { [unowned self] in self.clock })
        open(nav, "Browse")
        nav.handle(.center)
        await nav.lastTask?.value
        for _ in 0..<8 { clock += 0.02; nav.handle(.scroll(steps: 1)) }
        XCTAssertNil(nav.quickScrollLetter)
        XCTAssertGreaterThan(menu(nav)!.selectedIndex, 8, "acceleration still works")
    }

    func testSetProfileResetsToNewRoot() {
        let nav = navigator(.fifthGen)
        nav.setTrack(track)
        nav.handle(.scroll(steps: 10))
        nav.handle(.center)                     // Now Playing
        nav.handle(.center)                     // scrubbing
        nav.setProfile(IPodModel.firstGen.spec.firmware)
        XCTAssertEqual(nav.stack.count, 1)
        XCTAssertEqual(nav.nowPlayingMode, .normal)
        XCTAssertEqual(menu(nav)?.items.first?.label, "Playlists")
        XCTAssertEqual(menu(nav)?.items.last?.label, "Now Playing")
    }

    func testFirstGenUsesSixRows() {
        let rows = (0..<20).map { MenuItem("Row \($0)", action: .run {}) }
        let nav = navigator(rows: rows)
        open(nav, "Playlists")
        nav.handle(.scroll(steps: 7))
        XCTAssertEqual(menu(nav)?.windowStart, 2)
    }

    func testChangingModelFromSettingsLeavesAWorkingMenu() {
        let nav = navigator(.fifthGen)
        settings.model = .fifthGen
        // As in the app: a model change switches the navigator's firmware.
        let observer = settings.$model.dropFirst().sink { [unowned nav] model in nav.setProfile(model.spec.firmware) }
        defer { observer.cancel() }
        open(nav, "Settings")
        nav.handle(.center)                      // Model list
        open(nav, "1st generation")              // 5th gen → 1st gen
        XCTAssertEqual(settings.model, .firstGen)
        XCTAssertEqual(nav.stack.count, 1)
        XCTAssertEqual(menu(nav)?.title, "iPod", "the new model's main menu, not the old Settings screen")
        open(nav, "Settings")
        XCTAssertEqual(menu(nav)?.title, "Settings")
        nav.handle(.menu)
        XCTAssertEqual(menu(nav)?.title, "iPod", "MENU goes back from Settings")
    }

    // MARK: - Backlight review fixes

    private func row(_ nav: Navigator, _ label: String) {
        guard let index = menu(nav)?.items.firstIndex(where: { $0.label == label }) else { return XCTFail("no \(label)") }
        nav.handle(.scroll(steps: index - menu(nav)!.selectedIndex))
    }

    func testBacklightRowTurnsOnThenOff() {
        settings.backlightTimer = .ten
        let nav = navigator()
        row(nav, "Backlight")
        nav.handle(.tick(now: clock + 11))          // let it go dark
        XCTAssertFalse(nav.backlight.isOn)
        clock += 11
        nav.handle(.center)
        XCTAssertTrue(nav.backlight.isOn, "Backlight row lights a dark screen")
        nav.handle(.center)
        XCTAssertFalse(nav.backlight.isOn, "Backlight row turns a lit screen off")
    }

    func testTimerChangeAppliesImmediately() {
        settings.backlightTimer = .twenty
        let nav = navigator()
        open(nav, "Settings")
        row(nav, "Backlight Timer")
        nav.handle(.center)                         // 20 s → Always
        XCTAssertEqual(settings.backlightTimer, .always)
        nav.handle(.tick(now: clock + 1000))
        XCTAssertTrue(nav.backlight.isOn, "Always never times out")
        nav.handle(.center)                         // Always → Off
        nav.handle(.center)                         // Off → 2 s
        XCTAssertEqual(settings.backlightTimer, .two)
        nav.handle(.tick(now: clock + 3))
        XCTAssertFalse(nav.backlight.isOn, "the new 2 s timer applies; Always doesn't linger")
    }

    func testTickDoesNotRepublishWhenNothingChanges() {
        let nav = navigator(.fifthGen)
        var changes = 0
        let observer = nav.objectWillChange.sink { changes += 1 }
        defer { observer.cancel() }
        for i in 1...10 { nav.handle(.tick(now: clock + Double(i) / 10)) }
        XCTAssertEqual(changes, 0)
    }

    // MARK: - Clickable rows

    func testChooseRowHighlightsAndOpensIt() {
        let nav = navigator()
        nav.choose(row: 1)                       // Browse
        XCTAssertEqual(menu(nav)?.title, "Browse")
        nav.handle(.menu)
        XCTAssertEqual(menu(nav)?.selectedIndex, 1, "the clicked row stays highlighted")
    }

    func testChooseIgnoresPlaceholderAndOutOfRangeRows() {
        let nav = Navigator(player: spy, settings: settings, profile: IPodModel.firstGen.spec.firmware,
                            browse: { MenuScreen(title: "Browse", items: [.placeholder("Loading…")]) },
                            now: { [unowned self] in self.clock })
        open(nav, "Browse")
        nav.choose(row: 0)
        XCTAssertEqual(menu(nav)?.title, "Browse")
        nav.choose(row: 9)
        XCTAssertEqual(nav.stack.count, 2)
    }

    func testClickingFifthGenerationInTheModelListSwitches() {
        settings.model = .secondGen
        let nav = navigator(.secondGen)
        open(nav, "Settings")
        nav.handle(.center)
        nav.choose(row: IPodModel.allCases.firstIndex(of: .fifthGen)!)
        XCTAssertEqual(settings.model, .fifthGen)
    }

    // MARK: - 3rd generation (firmware 2.3)

    func testThirdGenRoot() {
        let nav = navigator(.thirdGen)
        XCTAssertEqual(menu(nav)?.items.map(\.label), ["Music", "Extras", "Settings", "Shuffle Songs", "Backlight"])
        nav.setTrack(track)
        XCTAssertEqual(menu(nav)?.items.last?.label, "Now Playing")
    }

    func testThirdGenSettingsAndHoldMenu() {
        let nav = navigator(.thirdGen)
        open(nav, "Settings")
        XCTAssertEqual(menu(nav)?.items.map(\.label), ["Model", "Source", "Backlight Timer", "Clicker"])
        nav.handle(.menuHold)
        XCTAssertEqual(menu(nav)?.title, "Settings", "hold MENU toggles the backlight, it doesn't go home")
    }

    // MARK: - iPod mini

    func testMiniSettingsHaveColour() {
        let nav = navigator(.mini)
        open(nav, "Settings")
        XCTAssertEqual(menu(nav)?.items.map(\.label), ["Model", "Colour", "Source", "Backlight Timer", "Clicker"])
        XCTAssertEqual(menu(nav)?.items[1].detail(), "Silver")
    }

    func testChoosingAColourPersistsAndGoesBack() {
        let nav = navigator(.mini)
        open(nav, "Settings")
        open(nav, "Colour")
        XCTAssertEqual(menu(nav)?.title, "Colour")
        XCTAssertEqual(menu(nav)?.items.map(\.label), ["Silver", "Gold", "Pink", "Blue", "Green"])
        XCTAssertEqual(menu(nav)?.items.first?.detail(), "✓")
        XCTAssertEqual(menu(nav)?.selectedIndex, 0)
        nav.choose(row: 2)
        XCTAssertEqual(settings.colour(in: .mini).id, "pink")
        XCTAssertEqual(menu(nav)?.title, "Settings")
        XCTAssertEqual(AppSettings(defaults: UserDefaults(suiteName: suiteName)!).colour(in: .mini).id, "pink")
    }

    func testOtherModelsHaveNoColourRow() {
        let nav = navigator(.thirdGen)
        open(nav, "Settings")
        XCTAssertFalse(menu(nav)!.items.map(\.label).contains("Colour"))
    }

    func testMiniShowsFiveRows() {
        let rows = (0..<20).map { MenuItem("Row \($0)", action: .run {}) }
        let nav = Navigator(player: spy, settings: settings, musicMenu: { MenuScreen(title: "Music", items: rows) },
                            profile: IPodModel.mini.spec.firmware, now: { [unowned self] in self.clock })
        open(nav, "Music")
        nav.handle(.scroll(steps: 6))
        XCTAssertEqual(menu(nav)?.windowStart, 2)
    }

    // MARK: - iPod 4th gen

    func testFourthGenSettingsHaveColour() {
        let nav = navigator(.fourthGen)
        open(nav, "Settings")
        XCTAssertEqual(menu(nav)?.items.map(\.label), ["Model", "Colour", "Source", "Backlight Timer", "Clicker"])
        XCTAssertEqual(menu(nav)?.items[1].detail(), "White")
    }

    func testChoosingTheU2EditionPersistsPerModel() {
        let nav = navigator(.fourthGen)
        open(nav, "Settings")
        open(nav, "Colour")
        XCTAssertEqual(menu(nav)?.items.map(\.label), ["White", "U2 Special Edition"])
        nav.choose(row: 1)
        XCTAssertEqual(menu(nav)?.title, "Settings")
        XCTAssertEqual(settings.colour(in: .fourthGen).id, "u2")
        XCTAssertEqual(settings.colour(in: .mini).id, "silver", "each model keeps its own colour")
    }

    func testFifthGenHasNoColourRow() {
        let nav = navigator(.fifthGen)
        open(nav, "Settings")
        XCTAssertFalse(menu(nav)!.items.map(\.label).contains("Colour"))
    }

    func testMiniReadsTheColourSavedBeforeColoursWerePerModel() {
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.set("blue", forKey: "miniColor")
        XCTAssertEqual(AppSettings(defaults: defaults).colour(in: .mini).id, "blue")
        XCTAssertEqual(AppSettings(defaults: defaults).colour(in: .fourthGen).id, "white")
    }

    func testAnUnknownSavedColourFallsBackToTheFirst() {
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.set("plaid", forKey: "colour.fourthGen")
        XCTAssertEqual(AppSettings(defaults: defaults).colour(in: .fourthGen).id, "white")
    }

    // MARK: - iPod photo

    func testPhotoRootAndSettings() {
        let nav = navigator(.photo)
        XCTAssertEqual(menu(nav)?.items.map(\.label), ["Music", "Extras", "Settings", "Shuffle Songs", "Backlight"])
        open(nav, "Settings")
        XCTAssertEqual(menu(nav)?.items.map(\.label), ["Model", "Colour", "Source", "Backlight Timer", "Clicker"])
    }

    func testPhotoColourIsSeparateFromTheFourthGen() {
        let nav = navigator(.photo)
        open(nav, "Settings")
        open(nav, "Colour")
        nav.choose(row: 1)
        XCTAssertEqual(settings.colour(in: IPodModel.photo.spec.firmware.colours!).id, "u2")
        XCTAssertEqual(settings.colour(in: .fourthGen).id, "white")
    }

    func testPhotoHoldMenuTogglesTheBacklight() {
        let nav = navigator(.photo)
        open(nav, "Settings")
        let before = nav.backlight.isOn
        nav.handle(.menuHold)
        XCTAssertEqual(menu(nav)?.title, "Settings", "hold MENU toggles the backlight, it doesn't go home")
        XCTAssertNotEqual(nav.backlight.isOn, before)
        nav.handle(.menuHold)
        XCTAssertEqual(nav.backlight.isOn, before)
    }

    func testSwitchingToThePhotoLightsItsScreen() {
        let nav = navigator(.fifthGen)
        nav.setProfile(IPodModel.photo.spec.firmware)
        XCTAssertTrue(nav.backlight.isOn, "a colour screen must not come back dimmed")
    }

    // MARK: - iPod mini 2G

    func testMiniSecondGenColourIsSeparateFromTheMini() {
        let nav = navigator(.miniSecondGen)
        open(nav, "Settings")
        open(nav, "Colour")
        XCTAssertEqual(menu(nav)?.items.map(\.label), ["Silver", "Pink", "Blue", "Green"])
        nav.choose(row: 2)
        XCTAssertEqual(menu(nav)?.title, "Settings")
        XCTAssertEqual(settings.colour(in: .miniSecondGen).id, "blue")
        XCTAssertEqual(settings.colour(in: .mini).id, "silver")
    }

    // MARK: - iPod nano

    func testNanoMenus() {
        let nav = navigator(.nano)
        XCTAssertEqual(menu(nav)?.items.map(\.label), ["Music", "Extras", "Settings", "Shuffle Songs"])
        open(nav, "Extras")
        XCTAssertEqual(menu(nav)?.items.map(\.label), ["Clock", "Stopwatch"])
        nav.handle(.menu)
        open(nav, "Settings")
        XCTAssertEqual(menu(nav)?.items.map(\.label), ["Model", "Colour", "Source", "Backlight Timer", "Clicker"])
        nav.handle(.menuHold)
        XCTAssertEqual(menu(nav)?.title, "Settings", "hold MENU toggles the backlight, it doesn't go home")
    }

    func testNanoBacklightTogglesAndTimesOut() {
        settings.backlightTimer = .five
        let nav = navigator(.nano)
        nav.handle(.scroll(steps: 1))
        XCTAssertTrue(nav.backlight.isOn, "input lights the nano's screen")
        nav.handle(.tick(now: clock + 5.1))
        XCTAssertFalse(nav.backlight.isOn, "and the timer dims it")
        nav.handle(.menuHold)
        XCTAssertTrue(nav.backlight.isOn, "hold MENU turns it back on")
    }

    // MARK: - iPod nano 2G

    func testNanoSecondGenColourListAndChoice() {
        let nav = navigator(.nanoSecondGen)
        XCTAssertEqual(menu(nav)?.items.map(\.label), ["Music", "Extras", "Settings", "Shuffle Songs"])
        open(nav, "Settings")
        open(nav, "Colour")
        XCTAssertEqual(menu(nav)?.items.count, 6)
        nav.choose(row: 5)
        XCTAssertEqual(settings.colour(in: .nanoSecondGen).id, "red")
        XCTAssertEqual(settings.colour(in: .nano).id, "white")
    }
}
