import Foundation

struct SeedItem {
    let titleKey: String
    let sortOrder: Int
}

struct SeedChecklist {
    let titleKey: String
    let iconName: String
    let sortOrder: Int
    let items: [SeedItem]
}

enum DefaultChecklists {
    static let all: [SeedChecklist] = [
        preDeparture,
        campSetup,
        leavingCampsite,
        winterization,
        deWinterization,
        weeklyMaintenance
    ]

    // MARK: - 1. Yola Çıkış Öncesi / Pre-Departure (22 items)
    static let preDeparture = SeedChecklist(
        titleKey: "checklist.preDeparture",
        iconName: "car.side",
        sortOrder: 0,
        items: [
            SeedItem(titleKey: "item.checkTirePressure", sortOrder: 0),
            SeedItem(titleKey: "item.checkLugNuts", sortOrder: 1),
            SeedItem(titleKey: "item.attachHitch", sortOrder: 2),
            SeedItem(titleKey: "item.attachSafetyChains", sortOrder: 3),
            SeedItem(titleKey: "item.connectElectricalPlug", sortOrder: 4),
            SeedItem(titleKey: "item.testLights", sortOrder: 5),
            SeedItem(titleKey: "item.releaseHandbrake", sortOrder: 6),
            SeedItem(titleKey: "item.removeChocks", sortOrder: 7),
            SeedItem(titleKey: "item.retractStep", sortOrder: 8),
            SeedItem(titleKey: "item.closeWindowsVents", sortOrder: 9),
            SeedItem(titleKey: "item.lockCabinets", sortOrder: 10),
            SeedItem(titleKey: "item.fridgeTravelMode", sortOrder: 11),
            SeedItem(titleKey: "item.turnOffGas", sortOrder: 12),
            SeedItem(titleKey: "item.turnOffWaterPump", sortOrder: 13),
            SeedItem(titleKey: "item.lowerAntenna", sortOrder: 14),
            SeedItem(titleKey: "item.retractAwning", sortOrder: 15),
            SeedItem(titleKey: "item.stowOutdoorFurniture", sortOrder: 16),
            SeedItem(titleKey: "item.adjustMirrors", sortOrder: 17),
            SeedItem(titleKey: "item.checkCargoSecured", sortOrder: 18),
            SeedItem(titleKey: "item.drainGreyWater", sortOrder: 19),
            SeedItem(titleKey: "item.checkFuel", sortOrder: 20),
            SeedItem(titleKey: "item.checkDocuments", sortOrder: 21),
        ]
    )

    // MARK: - 2. Kamp Kurulumu / Camp Setup (20 items)
    static let campSetup = SeedChecklist(
        titleKey: "checklist.campSetup",
        iconName: "tent",
        sortOrder: 1,
        items: [
            SeedItem(titleKey: "item.parkLevel", sortOrder: 0),
            SeedItem(titleKey: "item.engageHandbrake", sortOrder: 1),
            SeedItem(titleKey: "item.placeChocks", sortOrder: 2),
            SeedItem(titleKey: "item.levelCaravan", sortOrder: 3),
            SeedItem(titleKey: "item.lowerStabilizers", sortOrder: 4),
            SeedItem(titleKey: "item.connectShorePower", sortOrder: 5),
            SeedItem(titleKey: "item.checkVoltage", sortOrder: 6),
            SeedItem(titleKey: "item.connectWater", sortOrder: 7),
            SeedItem(titleKey: "item.attachGreyWaterHose", sortOrder: 8),
            SeedItem(titleKey: "item.openGasValve", sortOrder: 9),
            SeedItem(titleKey: "item.startFridge", sortOrder: 10),
            SeedItem(titleKey: "item.startWaterHeater", sortOrder: 11),
            SeedItem(titleKey: "item.deployAwning", sortOrder: 12),
            SeedItem(titleKey: "item.setupOutdoorFurniture", sortOrder: 13),
            SeedItem(titleKey: "item.raiseAntenna", sortOrder: 14),
            SeedItem(titleKey: "item.lowerStep", sortOrder: 15),
            SeedItem(titleKey: "item.openVentsAirflow", sortOrder: 16),
            SeedItem(titleKey: "item.setupClothesline", sortOrder: 17),
            SeedItem(titleKey: "item.setupExteriorLighting", sortOrder: 18),
            SeedItem(titleKey: "item.checkSafetyEquipment", sortOrder: 19),
        ]
    )

    // MARK: - 3. Kamptan Ayrılış / Leaving Campsite (18 items)
    static let leavingCampsite = SeedChecklist(
        titleKey: "checklist.leavingCampsite",
        iconName: "arrow.right.circle",
        sortOrder: 2,
        items: [
            SeedItem(titleKey: "item.stowOutdoorItems", sortOrder: 0),
            SeedItem(titleKey: "item.retractAwningDepart", sortOrder: 1),
            SeedItem(titleKey: "item.drainGreyWaterDepart", sortOrder: 2),
            SeedItem(titleKey: "item.emptyToiletCassette", sortOrder: 3),
            SeedItem(titleKey: "item.disconnectWater", sortOrder: 4),
            SeedItem(titleKey: "item.disconnectPower", sortOrder: 5),
            SeedItem(titleKey: "item.turnOffGasDepart", sortOrder: 6),
            SeedItem(titleKey: "item.checkFridgeContents", sortOrder: 7),
            SeedItem(titleKey: "item.closeWindowsDepart", sortOrder: 8),
            SeedItem(titleKey: "item.lockCabinetsDepart", sortOrder: 9),
            SeedItem(titleKey: "item.raiseStabilizers", sortOrder: 10),
            SeedItem(titleKey: "item.removeChocksDepart", sortOrder: 11),
            SeedItem(titleKey: "item.attachHitchDepart", sortOrder: 12),
            SeedItem(titleKey: "item.attachChainsDepart", sortOrder: 13),
            SeedItem(titleKey: "item.connectPlugDepart", sortOrder: 14),
            SeedItem(titleKey: "item.testLightsDepart", sortOrder: 15),
            SeedItem(titleKey: "item.cleanCampsite", sortOrder: 16),
            SeedItem(titleKey: "item.checkExitPath", sortOrder: 17),
        ]
    )

    // MARK: - 4. Kışlama / Winterization (20 items)
    static let winterization = SeedChecklist(
        titleKey: "checklist.winterization",
        iconName: "snowflake",
        sortOrder: 3,
        items: [
            SeedItem(titleKey: "item.drainAllTanks", sortOrder: 0),
            SeedItem(titleKey: "item.clearPipes", sortOrder: 1),
            SeedItem(titleKey: "item.drainWaterHeater", sortOrder: 2),
            SeedItem(titleKey: "item.leaveFaucetsOpen", sortOrder: 3),
            SeedItem(titleKey: "item.winterizeToilet", sortOrder: 4),
            SeedItem(titleKey: "item.winterizeFridge", sortOrder: 5),
            SeedItem(titleKey: "item.removeAllFood", sortOrder: 6),
            SeedItem(titleKey: "item.ventCabinets", sortOrder: 7),
            SeedItem(titleKey: "item.storeMattresses", sortOrder: 8),
            SeedItem(titleKey: "item.placeMoistureAbsorbers", sortOrder: 9),
            SeedItem(titleKey: "item.winterizeGas", sortOrder: 10),
            SeedItem(titleKey: "item.winterizeBatteries", sortOrder: 11),
            SeedItem(titleKey: "item.winterizeTires", sortOrder: 12),
            SeedItem(titleKey: "item.exteriorWashWax", sortOrder: 13),
            SeedItem(titleKey: "item.inspectRoofSeals", sortOrder: 14),
            SeedItem(titleKey: "item.installRodentGuards", sortOrder: 15),
            SeedItem(titleKey: "item.installCover", sortOrder: 16),
            SeedItem(titleKey: "item.lubricateSeals", sortOrder: 17),
            SeedItem(titleKey: "item.disconnectMainPower", sortOrder: 18),
            SeedItem(titleKey: "item.installAntiTheft", sortOrder: 19),
        ]
    )

    // MARK: - 5. Kışlamadan Çıkış / De-winterization (18 items)
    static let deWinterization = SeedChecklist(
        titleKey: "checklist.deWinterization",
        iconName: "sun.max",
        sortOrder: 4,
        items: [
            SeedItem(titleKey: "item.inspectExterior", sortOrder: 0),
            SeedItem(titleKey: "item.checkRoofSeals", sortOrder: 1),
            SeedItem(titleKey: "item.ventilateInterior", sortOrder: 2),
            SeedItem(titleKey: "item.removeMoistureAbsorbers", sortOrder: 3),
            SeedItem(titleKey: "item.chargeBatteries", sortOrder: 4),
            SeedItem(titleKey: "item.closeFaucets", sortOrder: 5),
            SeedItem(titleKey: "item.sanitizeWaterSystem", sortOrder: 6),
            SeedItem(titleKey: "item.checkForLeaks", sortOrder: 7),
            SeedItem(titleKey: "item.testWaterHeater", sortOrder: 8),
            SeedItem(titleKey: "item.checkGasLeaks", sortOrder: 9),
            SeedItem(titleKey: "item.testStoveOven", sortOrder: 10),
            SeedItem(titleKey: "item.testFridge", sortOrder: 11),
            SeedItem(titleKey: "item.testElectrical", sortOrder: 12),
            SeedItem(titleKey: "item.springCheckTires", sortOrder: 13),
            SeedItem(titleKey: "item.checkBrakes", sortOrder: 14),
            SeedItem(titleKey: "item.prepareToilet", sortOrder: 15),
            SeedItem(titleKey: "item.replaceMattresses", sortOrder: 16),
            SeedItem(titleKey: "item.checkSafetyGear", sortOrder: 17),
        ]
    )

    // MARK: - 6. Haftalık Bakım / Weekly Maintenance (15 items)
    static let weeklyMaintenance = SeedChecklist(
        titleKey: "checklist.weeklyMaintenance",
        iconName: "wrench.and.screwdriver",
        sortOrder: 5,
        items: [
            SeedItem(titleKey: "item.weeklyTirePressure", sortOrder: 0),
            SeedItem(titleKey: "item.weeklyWaterTank", sortOrder: 1),
            SeedItem(titleKey: "item.weeklyDrainGrey", sortOrder: 2),
            SeedItem(titleKey: "item.weeklyToilet", sortOrder: 3),
            SeedItem(titleKey: "item.weeklyGasLevel", sortOrder: 4),
            SeedItem(titleKey: "item.weeklyBatteryLevel", sortOrder: 5),
            SeedItem(titleKey: "item.weeklyFridgeTemp", sortOrder: 6),
            SeedItem(titleKey: "item.weeklyExteriorClean", sortOrder: 7),
            SeedItem(titleKey: "item.weeklyInteriorClean", sortOrder: 8),
            SeedItem(titleKey: "item.weeklyVentFilters", sortOrder: 9),
            SeedItem(titleKey: "item.weeklyAwningCheck", sortOrder: 10),
            SeedItem(titleKey: "item.weeklyLubricate", sortOrder: 11),
            SeedItem(titleKey: "item.weeklyDetectorTest", sortOrder: 12),
            SeedItem(titleKey: "item.weeklyRoofVents", sortOrder: 13),
            SeedItem(titleKey: "item.weeklyConnections", sortOrder: 14),
        ]
    )
}
