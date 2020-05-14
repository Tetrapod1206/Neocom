//
//  NCFittingSpaceStructureStatsViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 14.03.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

#import "NCFittingSpaceStructureStatsViewController.h"
#import "NCFittingSpaceStructureViewController.h"
#import "NCFittingShipWeaponsCell.h"
#import "NCFittingShipResourcesCell.h"
#import "NCFittingResistancesCell.h"
#import "NCFittingEHPCell.h"
#import "NCFittingShipCapacitorCell.h"
#import "NCFittingShipFirepowerCell.h"
#import "NCFittingDamageVectorCell.h"
#import "NCFittingShipTankCell.h"
#import "NCFittingShipMiscCell.h"
#import "NCFittingShipPriceCell.h"
#import "NSString+Neocom.h"
#import "NSNumberFormatter+Neocom.h"
#import "NCPriceManager.h"
#import "NCTableViewHeaderView.h"

@interface NCFittingSpaceStructureStatsViewControllerRow : NSObject
@property (nonatomic, assign) BOOL isUpToDate;
@property (nonatomic, strong) NSDictionary* data;
@property (nonatomic, strong) NSString* cellIdentifier;
@property (nonatomic, copy) void (^configurationBlock)(id tableViewCell, NSDictionary* data);
@property (nonatomic, copy) void (^loadingBlock)(NCFittingSpaceStructureStatsViewController* controller, void (^completionBlock)(NSDictionary* data));
@end

@interface NCFittingSpaceStructureStatsViewControllerSection : NSObject
@property (nonatomic, strong) NSString* title;
@property (nonatomic, strong) NSArray* rows;
@end

@implementation NCFittingSpaceStructureStatsViewControllerRow
@end

@implementation NCFittingSpaceStructureStatsViewControllerSection
@end

@interface NCFittingSpaceStructureStatsViewController()
@property (nonatomic, strong) NSArray* sections;
@end


@implementation NCFittingSpaceStructureStatsViewController

- (void) viewDidLoad {
	[super viewDidLoad];
}

- (void) reloadWithCompletionBlock:(void (^)())completionBlock {
	auto pilot = self.controller.fit.pilot;
	if (pilot) {
		if (self.sections) {
			for (NCFittingSpaceStructureStatsViewControllerSection* section in self.sections)
				for (NCFittingSpaceStructureStatsViewControllerRow* row in section.rows)
					row.isUpToDate = NO;
			completionBlock();
		}
		else {
			[self.controller.engine performBlock:^{
				NSMutableArray* sections = [NSMutableArray new];
				NCFittingSpaceStructureStatsViewControllerSection* section;
				NCFittingSpaceStructureStatsViewControllerRow* row;
				
				section = [NCFittingSpaceStructureStatsViewControllerSection new];
				section.title = NSLocalizedString(@"Resources", nil);
				{
					NSMutableArray* rows = [NSMutableArray new];
					row = [NCFittingSpaceStructureStatsViewControllerRow new];
					row.cellIdentifier = @"NCFittingShipWeaponsCell";
					row.configurationBlock = ^(id tableViewCell, NSDictionary* data) {
						NCFittingShipWeaponsCell* cell = tableViewCell;
						cell.turretsLabel.text = data[@"turrets"];
						cell.turretsLabel.textColor = data[@"turretsColor"];
						
						cell.launchersLabel.text = data[@"launchers"];
						cell.launchersLabel.textColor = data[@"launchersColor"];
						
						cell.calibrationLabel.text = data[@"calibration"];
						cell.calibrationLabel.textColor = data[@"calibrationColor"];
						
						cell.dronesLabel.text = data[@"drones"];
						cell.dronesLabel.textColor = data[@"dronesColor"];
					};
					row.loadingBlock = ^(NCFittingSpaceStructureStatsViewController* controller, void (^completionBlock)(NSDictionary* data)) {
						auto character = controller.controller.fit.pilot;
						if (character) {
							[controller.controller.engine performBlock:^{
								auto spaceStructure = character->getSpaceStructure();
								int usedTurretHardpoints = spaceStructure->getUsedHardpoints(dgmpp::Module::HARDPOINT_TURRET);
								int totalTurretHardpoints = spaceStructure->getNumberOfHardpoints(dgmpp::Module::HARDPOINT_TURRET);
								int usedMissileHardpoints = spaceStructure->getUsedHardpoints(dgmpp::Module::HARDPOINT_LAUNCHER);
								int totalMissileHardpoints = spaceStructure->getNumberOfHardpoints(dgmpp::Module::HARDPOINT_LAUNCHER);
								
								int calibrationUsed = spaceStructure->getCalibrationUsed();
								int totalCalibration = spaceStructure->getTotalCalibration();
								
								int maxActiveDrones;
								int activeDrones;
								
								if (spaceStructure->getTotalFighterHangar() > 0) {
									maxActiveDrones = spaceStructure->getTotalFighterLaunchTubes();
									activeDrones = spaceStructure->getFighterLaunchTubesUsed();
								}
								else {
									maxActiveDrones = spaceStructure->getDroneSquadronLimit(dgmpp::Drone::FIGHTER_SQUADRON_NONE);
									activeDrones = spaceStructure->getDroneSquadronUsed(dgmpp::Drone::FIGHTER_SQUADRON_NONE);
								}
								
								NSDictionary* data =
								@{@"turrets": [NSString stringWithFormat:@"%d/%d", usedTurretHardpoints, totalTurretHardpoints],
								  @"turretsColor": usedTurretHardpoints > totalTurretHardpoints ? [UIColor redColor] : [UIColor whiteColor],
								  @"launchers": [NSString stringWithFormat:@"%d/%d", usedMissileHardpoints, totalMissileHardpoints],
								  @"launchersColor": usedMissileHardpoints > totalMissileHardpoints ? [UIColor redColor] : [UIColor whiteColor],
								  @"calibration": [NSString stringWithFormat:@"%d/%d", calibrationUsed, totalCalibration],
								  @"calibrationColor": calibrationUsed > totalCalibration ? [UIColor redColor] : [UIColor whiteColor],
								  @"drones": [NSString stringWithFormat:@"%d/%d", activeDrones, maxActiveDrones],
								  @"dronesColor": activeDrones > maxActiveDrones ? [UIColor redColor] : [UIColor whiteColor]};
								dispatch_async(dispatch_get_main_queue(), ^{
									completionBlock(data);
								});
							}];
						}
						else
							completionBlock(nil);
					};
					[rows addObject:row];
					
					row = [NCFittingSpaceStructureStatsViewControllerRow new];
					row.cellIdentifier = @"NCFittingShipResourcesCell";
					row.configurationBlock = ^(id tableViewCell, NSDictionary* data) {
						NCFittingShipResourcesCell* cell = (NCFittingShipResourcesCell*) tableViewCell;
						cell.powerGridLabel.text = data[@"powerGrid"];
						cell.powerGridLabel.progress = [data[@"powerGridProgress"] floatValue];
						cell.cpuLabel.text = data[@"cpu"];
						cell.cpuLabel.progress = [data[@"cpuProgress"] floatValue];
						cell.droneBandwidthLabel.text = data[@"droneBandwidth"];
						cell.droneBandwidthLabel.progress = [data[@"droneBandwidthProgress"] floatValue];
						cell.droneBayLabel.text = data[@"droneBay"];
						cell.droneBayLabel.progress = [data[@"droneBayProgress"] floatValue];
					};
					row.loadingBlock = ^(NCFittingSpaceStructureStatsViewController* controller, void (^completionBlock)(NSDictionary* data)) {
						auto character = controller.controller.fit.pilot;
						if (character) {
							[controller.controller.engine performBlock:^{
								auto spaceStructure = character->getSpaceStructure();
								float totalPG = spaceStructure->getTotalPowerGrid();
								float usedPG = spaceStructure->getPowerGridUsed();
								float totalCPU = spaceStructure->getTotalCpu();
								float usedCPU = spaceStructure->getCpuUsed();
								float totalDB;
								float usedDB;
								float totalBandwidth = spaceStructure->getTotalDroneBandwidth();
								float usedBandwidth = spaceStructure->getDroneBandwidthUsed();
								
								if (spaceStructure->getTotalFighterHangar() > 0) {
									totalDB = spaceStructure->getTotalFighterHangar();
									usedDB = spaceStructure->getFighterHangarUsed();
								}
								else {
									totalDB = spaceStructure->getTotalDroneBay();
									usedDB = spaceStructure->getDroneBayUsed();
								}
								
								NSDictionary* data =
								@{@"powerGrid": [NSString stringWithTotalResources:totalPG usedResources:usedPG unit:@"MW"],
								  @"powerGridProgress": totalPG > 0 ? @(usedPG / totalPG) : @(0),
								  @"cpu": [NSString stringWithTotalResources:totalCPU usedResources:usedCPU unit:@"tf"],
								  @"cpuProgress": totalCPU > 0 ? @(usedCPU / totalCPU) : @(0),
								  @"droneBandwidth": [NSString stringWithTotalResources:totalBandwidth usedResources:usedBandwidth unit:@"Mbit/s"],
								  @"droneBandwidthProgress": totalBandwidth > 0 ? @(usedBandwidth / totalBandwidth) : @(0),
								  @"droneBay": [NSString stringWithTotalResources:totalDB usedResources:usedDB unit:@"m3"],
								  @"droneBayProgress": totalDB > 0 ? @(usedDB / totalDB) : @(0)};
								dispatch_async(dispatch_get_main_queue(), ^{
									completionBlock(data);
								});
							}];
						}
						else
							completionBlock(nil);
					};
					[rows addObject:row];
					section.rows = rows;
				}
				[sections addObject:section];
				
				section = [NCFittingSpaceStructureStatsViewControllerSection new];
				section.title = NSLocalizedString(@"Resistances", nil);
				{
					NSMutableArray* rows = [NSMutableArray new];
					row = [NCFittingSpaceStructureStatsViewControllerRow new];
					row.cellIdentifier = @"NCFittingResistancesHeaderCell";
					row.configurationBlock = ^(id tableViewCell, NSDictionary* data) {
					};
					row.loadingBlock = ^(NCFittingSpaceStructureStatsViewController* controller, void (^completionBlock)(NSDictionary* data)) {
						completionBlock(nil);
					};
					[rows addObject:row];
					
					NSArray* images = @[@"shield", @"armor", @"hull", @"damagePattern"];
					for (int i = 0; i < 4; i++) {
						row = [NCFittingSpaceStructureStatsViewControllerRow new];
						row.cellIdentifier = @"NCFittingResistancesCell";
						row.configurationBlock = ^(id tableViewCell, NSDictionary* data) {
							NCFittingResistancesCell* cell = (NCFittingResistancesCell*) tableViewCell;
							NCProgressLabel* labels[] = {cell.emLabel, cell.thermalLabel, cell.kineticLabel, cell.explosiveLabel};
							NSArray* values = data[@"values"];
							NSArray* texts = data[@"texts"];
							for (int i = 0; i < 4; i++) {
								labels[i].progress = [values[i] floatValue];
								labels[i].text = texts[i];
							}
							cell.hpLabel.text = texts[4];
							cell.categoryImageView.image = data[@"categoryImage"];
						};
						row.loadingBlock = ^(NCFittingSpaceStructureStatsViewController* controller, void (^completionBlock)(NSDictionary* data)) {
							auto character = controller.controller.fit.pilot;
							if (character) {
								[controller.controller.engine performBlock:^{
									auto spaceStructure = character->getSpaceStructure();
									NSMutableArray* values = [NSMutableArray new];
									NSMutableArray* texts = [NSMutableArray new];
									
									if (i < 3) {
										auto resistances = spaceStructure->getResistances();
										auto hp = spaceStructure->getHitPoints();
										
										for (int j = 0; j < 4; j++) {
											[values addObject:@(resistances.layers[i].resistances[j])];
											[texts addObject:[NSString stringWithFormat:@"%.1f%%", resistances.layers[i].resistances[j] * 100]];
										}
										[values addObject:@(hp.layers[i])];
										[texts addObject:[NSString shortStringWithFloat:hp.layers[i] unit:nil]];
									}
									else {
										auto damagePattern = spaceStructure->getDamagePattern();
										for (int j = 0; j < 4; j++) {
											[values addObject:@(damagePattern.damageTypes[j])];
											[texts addObject:[NSString stringWithFormat:@"%.1f%%", damagePattern.damageTypes[j] * 100]];
										}
										[values addObject:@(0)];
										[texts addObject:@""];
									}
									
									NSDictionary* data =
									@{@"values": values,
									  @"texts": texts,
									  @"categoryImage": [UIImage imageNamed:images[i]]};
									dispatch_async(dispatch_get_main_queue(), ^{
										completionBlock(data);
									});
								}];
							}
							else
								completionBlock(nil);
						};
						[rows addObject:row];
					}
					
					row = [NCFittingSpaceStructureStatsViewControllerRow new];
					row.cellIdentifier = @"NCFittingEHPCell";
					row.configurationBlock = ^(id tableViewCell, NSDictionary* data) {
						NCFittingEHPCell* cell = (NCFittingEHPCell*) tableViewCell;
						cell.ehpLabel.text = data[@"ehp"];
					};
					row.loadingBlock = ^(NCFittingSpaceStructureStatsViewController* controller, void (^completionBlock)(NSDictionary* data)) {
						auto character = controller.controller.fit.pilot;
						if (character) {
							[controller.controller.engine performBlock:^{
								auto spaceStructure = character->getSpaceStructure();
								auto effectiveHitPoints = spaceStructure->getEffectiveHitPoints();
								float ehp = effectiveHitPoints.shield + effectiveHitPoints.armor + effectiveHitPoints.hull;
								
								NSDictionary* data =
								@{@"ehp": [NSString stringWithFormat:NSLocalizedString(@"EHP: %@", nil), [NSString shortStringWithFloat:ehp unit:nil]]};
								dispatch_async(dispatch_get_main_queue(), ^{
									completionBlock(data);
								});
							}];
						}
						else
							completionBlock(nil);
					};
					[rows addObject:row];
					section.rows = rows;
				}
				[sections addObject:section];
				
				section = [NCFittingSpaceStructureStatsViewControllerSection new];
				section.title = NSLocalizedString(@"Capacitor", nil);
				{
					NSMutableArray* rows = [NSMutableArray new];
					row = [NCFittingSpaceStructureStatsViewControllerRow new];
					row.cellIdentifier = @"NCFittingShipCapacitorCell";
					row.configurationBlock = ^(id tableViewCell, NSDictionary* data) {
						NCFittingShipCapacitorCell* cell = (NCFittingShipCapacitorCell*) tableViewCell;
						cell.capacitorCapacityLabel.text = data[@"capacitorCapacity"];
						cell.capacitorStateLabel.text = data[@"capacitorState"];
						cell.capacitorRechargeTimeLabel.text = data[@"capacitorRechargeTime"];
						cell.capacitorDeltaLabel.text = data[@"capacitorDelta"];
					};
					row.loadingBlock = ^(NCFittingSpaceStructureStatsViewController* controller, void (^completionBlock)(NSDictionary* data)) {
						auto character = controller.controller.fit.pilot;
						if (character) {
							[controller.controller.engine performBlock:^{
								auto spaceStructure = character->getSpaceStructure();
								float capCapacity = spaceStructure->getCapCapacity();
								bool capStable = spaceStructure->isCapStable();
								float capState = capStable ? spaceStructure->getCapStableLevel() * 100.0 : spaceStructure->getCapLastsTime();
								float capacitorRechargeTime = spaceStructure->getAttribute(dgmpp::RECHARGE_RATE_ATTRIBUTE_ID)->getValue() / 1000.0;
								float delta = spaceStructure->getCapRecharge() - spaceStructure->getCapUsed();
								
								NSDictionary* data =
								@{@"capacitorCapacity": [NSString stringWithFormat:NSLocalizedString(@"Total: %@", nil), [NSString shortStringWithFloat:capCapacity unit:@"GJ"]],
								  @"capacitorState": capStable ? [NSString stringWithFormat:NSLocalizedString(@"Stable: %.1f%%", nil), capState] : [NSString stringWithFormat:NSLocalizedString(@"Lasts: %@", nil), [NSString stringWithTimeLeft:capState]],
								  @"capacitorRechargeTime": [NSString stringWithFormat:NSLocalizedString(@"Recharge Time: %@", nil), [NSString stringWithTimeLeft:capacitorRechargeTime]],
								  @"capacitorDelta": [NSString stringWithFormat:NSLocalizedString(@"Delta: %@%@", nil), delta >= 0.0 ? @"+" : @"", [NSString shortStringWithFloat:delta unit:@"GJ/s"]]};
								dispatch_async(dispatch_get_main_queue(), ^{
									completionBlock(data);
								});
							}];
						}
						else
							completionBlock(nil);
					};
					[rows addObject:row];
					section.rows = rows;
				}
				[sections addObject:section];
				
				section = [NCFittingSpaceStructureStatsViewControllerSection new];
				section.title = NSLocalizedString(@"Recharge Rates (HP/s) / (EHP/s )", nil);
				{
					NSMutableArray* rows = [NSMutableArray new];
					row = [NCFittingSpaceStructureStatsViewControllerRow new];
					row.cellIdentifier = @"NCFittingShipTankHeaderCell";
					row.configurationBlock = ^(id tableViewCell, NSDictionary* data) {
					};
					row.loadingBlock = ^(NCFittingSpaceStructureStatsViewController* controller, void (^completionBlock)(NSDictionary* data)) {
						completionBlock(nil);
					};
					[rows addObject:row];
					
					row = [NCFittingSpaceStructureStatsViewControllerRow new];
					row.cellIdentifier = @"NCFittingShipTankCell";
					row.configurationBlock = ^(id tableViewCell, NSDictionary* data) {
						NCFittingShipTankCell* cell = (NCFittingShipTankCell*) tableViewCell;
						cell.categoryLabel.text = NSLocalizedString(@"Reinforced", nil);
						cell.shieldRecharge.text = data[@"shieldRecharge"];
						cell.shieldBoost.text = data[@"shieldBoost"];
						cell.armorRepair.text = data[@"armorRepair"];
						cell.hullRepair.text = data[@"hullRepair"];
					};
					row.loadingBlock = ^(NCFittingSpaceStructureStatsViewController* controller, void (^completionBlock)(NSDictionary* data)) {
						auto character = controller.controller.fit.pilot;
						if (character) {
							[controller.controller.engine performBlock:^{
								auto spaceStructure = character->getSpaceStructure();
								auto rtank = spaceStructure->getTank();
								auto ertank = spaceStructure->getEffectiveTank();
								
								NSDictionary* data =
								@{@"shieldRecharge": [NSString stringWithFormat:@"%.1f\n%.1f", rtank.passiveShield, ertank.passiveShield],
								  @"shieldBoost": [NSString stringWithFormat:@"%.1f\n%.1f", rtank.shieldRepair, ertank.shieldRepair],
								  @"armorRepair": [NSString stringWithFormat:@"%.1f\n%.1f", rtank.armorRepair, ertank.armorRepair],
								  @"hullRepair": [NSString stringWithFormat:@"%.1f\n%.1f", rtank.hullRepair, ertank.hullRepair]};
								dispatch_async(dispatch_get_main_queue(), ^{
									completionBlock(data);
								});
							}];
						}
						else
							completionBlock(nil);
					};
					[rows addObject:row];
					
					row = [NCFittingSpaceStructureStatsViewControllerRow new];
					row.cellIdentifier = @"NCFittingShipTankCell";
					row.configurationBlock = ^(id tableViewCell, NSDictionary* data) {
						NCFittingShipTankCell* cell = (NCFittingShipTankCell*) tableViewCell;
						cell.categoryLabel.text = NSLocalizedString(@"Sustained", nil);
						cell.shieldRecharge.text = data[@"shieldRecharge"];
						cell.shieldBoost.text = data[@"shieldBoost"];
						cell.armorRepair.text = data[@"armorRepair"];
						cell.hullRepair.text = data[@"hullRepair"];
					};
					row.loadingBlock = ^(NCFittingSpaceStructureStatsViewController* controller, void (^completionBlock)(NSDictionary* data)) {
						auto character = controller.controller.fit.pilot;
						if (character) {
							[controller.controller.engine performBlock:^{
								auto spaceStructure = character->getSpaceStructure();
								auto stank = spaceStructure->getSustainableTank();
								auto estank = spaceStructure->getEffectiveSustainableTank();
								
								NSDictionary* data =
								@{@"shieldRecharge": [NSString stringWithFormat:@"%.1f\n%.1f", stank.passiveShield, estank.passiveShield],
								  @"shieldBoost": [NSString stringWithFormat:@"%.1f\n%.1f", stank.shieldRepair, estank.shieldRepair],
								  @"armorRepair": [NSString stringWithFormat:@"%.1f\n%.1f", stank.armorRepair, estank.armorRepair],
								  @"hullRepair": [NSString stringWithFormat:@"%.1f\n%.1f", stank.hullRepair, estank.hullRepair]};
								dispatch_async(dispatch_get_main_queue(), ^{
									completionBlock(data);
								});
							}];
						}
						else
							completionBlock(nil);
					};
					[rows addObject:row];
					section.rows = rows;
				}
				[sections addObject:section];
				
				section = [NCFittingSpaceStructureStatsViewControllerSection new];
				section.title = NSLocalizedString(@"Firepower", nil);
				{
					NSMutableArray* rows = [NSMutableArray new];
					row = [NCFittingSpaceStructureStatsViewControllerRow new];
					row.cellIdentifier = @"NCFittingShipFirepowerCell";
					row.configurationBlock = ^(id tableViewCell, NSDictionary* data) {
						NCFittingShipFirepowerCell* cell = (NCFittingShipFirepowerCell*) tableViewCell;
						cell.weaponDPSLabel.text = data[@"weaponDPS"];
						cell.droneDPSLabel.text = data[@"droneDPS"];
						cell.volleyDamageLabel.text = data[@"volleyDamage"];
						cell.dpsLabel.text = data[@"dps"];
					};
					row.loadingBlock = ^(NCFittingSpaceStructureStatsViewController* controller, void (^completionBlock)(NSDictionary* data)) {
						auto character = controller.controller.fit.pilot;
						if (character) {
							[controller.controller.engine performBlock:^{
								auto spaceStructure = character->getSpaceStructure();
								float weaponDPS = spaceStructure->getWeaponDps();
								float droneDPS = spaceStructure->getDroneDps();
								float volleyDamage = spaceStructure->getWeaponVolley() + spaceStructure->getDroneVolley();
								float dps = weaponDPS + droneDPS;
								
								NSDictionary* data =
								@{@"weaponDPS": [NSString stringWithFormat:NSLocalizedString(@"%@ DPS", nil), [NSNumberFormatter neocomLocalizedStringFromNumber:@(weaponDPS)]],
								  @"droneDPS": [NSString stringWithFormat:NSLocalizedString(@"%@ DPS", nil), [NSNumberFormatter neocomLocalizedStringFromNumber:@(droneDPS)]],
								  @"volleyDamage": [NSNumberFormatter neocomLocalizedStringFromNumber:@(volleyDamage)],
								  @"dps": [NSString stringWithFormat:@"%@", [NSNumberFormatter neocomLocalizedStringFromNumber:@(dps)]]};
								dispatch_async(dispatch_get_main_queue(), ^{
									completionBlock(data);
								});
							}];
						}
						else
							completionBlock(nil);
					};
					[rows addObject:row];
					
					
					row = [NCFittingSpaceStructureStatsViewControllerRow new];
					row.cellIdentifier = @"NCFittingDamageVectorCell";
					row.configurationBlock = ^(id tableViewCell, NSDictionary* data) {
						NCFittingDamageVectorCell* cell = (NCFittingDamageVectorCell*) tableViewCell;
						NCProgressLabel* labels[] = {cell.emLabel, cell.thermalLabel, cell.kineticLabel, cell.explosiveLabel};
						NSArray* values = data[@"values"];
						NSArray* texts = data[@"texts"];
						for (int i = 0; i < 4; i++) {
							labels[i].progress = [values[i] floatValue];
							labels[i].text = texts[i];
						}
					};
					row.loadingBlock = ^(NCFittingSpaceStructureStatsViewController* controller, void (^completionBlock)(NSDictionary* data)) {
						auto character = controller.controller.fit.pilot;
						if (character) {
							[controller.controller.engine performBlock:^{
								auto spaceStructure = character->getSpaceStructure();
								NSMutableArray* values = [NSMutableArray new];
								NSMutableArray* texts = [NSMutableArray new];
								
								auto damagePattern = dgmpp::DamagePattern(spaceStructure->getWeaponDps() + spaceStructure->getDroneDps());
								for (int j = 0; j < 4; j++) {
									[values addObject:@(damagePattern.damageTypes[j])];
									[texts addObject:[NSString stringWithFormat:@"%.1f%%", damagePattern.damageTypes[j] * 100]];
								}
								[values addObject:@(0)];
								[texts addObject:@""];
								
								NSDictionary* data =
								@{@"values": values,
								  @"texts": texts};
								dispatch_async(dispatch_get_main_queue(), ^{
									completionBlock(data);
								});
							}];
						}
						else
							completionBlock(nil);
					};
					[rows addObject:row];
					
					
					section.rows = rows;
				}
				[sections addObject:section];
				
				section = [NCFittingSpaceStructureStatsViewControllerSection new];
				section.title = NSLocalizedString(@"Misc", nil);
				{
					NSMutableArray* rows = [NSMutableArray new];
					row = [NCFittingSpaceStructureStatsViewControllerRow new];
					row.cellIdentifier = @"NCFittingShipMiscCell";
					row.configurationBlock = ^(id tableViewCell, NSDictionary* data) {
						NCFittingShipMiscCell* cell = (NCFittingShipMiscCell*) tableViewCell;
						cell.targetsLabel.text = data[@"targets"];
						cell.targetRangeLabel.text = data[@"targetRange"];
						cell.scanResLabel.text = data[@"scanRes"];
						cell.sensorStrLabel.text = data[@"sensorStr"];
						cell.speedLabel.text = data[@"speed"];
						cell.alignTimeLabel.text = data[@"alignTime"];
						cell.signatureLabel.text = data[@"signature"];
						cell.cargoLabel.text = data[@"cargo"];
						cell.oreHoldLabel.text = data[@"oreHold"];
						cell.sensorImageView.image = data[@"sensorImage"];
						cell.droneRangeLabel.text = data[@"droneRange"];
						cell.warpSpeedLabel.text = data[@"warpSpeed"];
						cell.massLabel.text = data[@"mass"];
					};
					row.loadingBlock = ^(NCFittingSpaceStructureStatsViewController* controller, void (^completionBlock)(NSDictionary* data)) {
						auto character = controller.controller.fit.pilot;
						if (character) {
							[controller.controller.engine performBlock:^{
								auto spaceStructure = character->getSpaceStructure();
								int targets = spaceStructure->getMaxTargets();
								float targetRange = spaceStructure->getMaxTargetRange() / 1000.0;
								float scanRes = spaceStructure->getScanResolution();
								float sensorStr = spaceStructure->getScanStrength();
								float speed = spaceStructure->getVelocity();
								float alignTime = spaceStructure->getAlignTime();
								float signature = spaceStructure->getSignatureRadius();
								float cargo = spaceStructure->getCapacity();
								float oreHold = spaceStructure->getOreHoldCapacity();
								float mass = spaceStructure->getMass();
								float droneRange = character->getAttribute(dgmpp::DRONE_CONTROL_DISTANCE_ATTRIBUTE_ID)->getValue() / 1000;
								float warpSpeed = spaceStructure->getWarpSpeed();
								UIImage* sensorImage;
								switch(spaceStructure->getScanType()) {
									case dgmpp::Ship::SCAN_TYPE_GRAVIMETRIC:
										sensorImage = [UIImage imageNamed:@"gravimetric"];
										break;
									case dgmpp::Ship::SCAN_TYPE_LADAR:
										sensorImage = [UIImage imageNamed:@"ladar"];
										break;
									case dgmpp::Ship::SCAN_TYPE_MAGNETOMETRIC:
										sensorImage = [UIImage imageNamed:@"magnetometric"];
										break;
									case dgmpp::Ship::SCAN_TYPE_RADAR:
										sensorImage = [UIImage imageNamed:@"radar"];
										break;
									default:
										sensorImage = [UIImage imageNamed:@"multispectral"];
										break;
								}
								if (!sensorImage)
									sensorImage = [UIImage imageNamed:@"multispectral"];
								
								NSDictionary* data =
								@{@"targets": [NSString stringWithFormat:@"%d", targets],
								  @"targetRange": [NSString stringWithFormat:@"%.1f km", targetRange],
								  @"scanRes": [NSString stringWithFormat:@"%.0f mm", scanRes],
								  @"sensorStr": [NSString stringWithFormat:@"%.0f", sensorStr],
								  @"speed": [NSString stringWithFormat:@"%.0f m/s", speed],
								  @"alignTime": [NSString stringWithFormat:@"%.1f s", alignTime],
								  @"signature": [NSString stringWithFormat:@"%.0f", signature],
								  @"cargo": [NSString shortStringWithFloat:cargo unit:@"m3"],
								  @"oreHold": [NSString shortStringWithFloat:oreHold unit:@"m3"],
								  @"sensorImage": sensorImage,
								  @"droneRange": [NSString stringWithFormat:@"%.1f km", droneRange],
								  @"warpSpeed": [NSString stringWithFormat:@"%.2f AU/s", warpSpeed],
								  @"mass": [NSString stringWithFormat:@"%@ kg", [NSString shortStringWithFloat:mass unit:nil]]};
								dispatch_async(dispatch_get_main_queue(), ^{
									completionBlock(data);
								});
							}];
						}
						else
							completionBlock(nil);
					};
					[rows addObject:row];
					section.rows = rows;
				}
				[sections addObject:section];
				
				section = [NCFittingSpaceStructureStatsViewControllerSection new];
				section.title = NSLocalizedString(@"Fuel", nil);
				{
					NSMutableArray* rows = [NSMutableArray new];
					
					row = [NCFittingSpaceStructureStatsViewControllerRow new];
					row.cellIdentifier = @"Cell";
					row.configurationBlock = ^(id tableViewCell, NSDictionary* data) {
						NCDefaultTableViewCell* cell = (NCDefaultTableViewCell*) tableViewCell;
						cell.iconView.image = data[@"image"] ?: self.defaultTypeImage;
						cell.titleLabel.text = data[@"title"];
						cell.subtitleLabel.text = data[@"subtitle"];
					};
					row.loadingBlock = ^(NCFittingSpaceStructureStatsViewController* controller, void (^completionBlock)(NSDictionary* data)) {
						auto character = controller.controller.fit.pilot;
						if (character) {
							[controller.controller.engine performBlock:^{
								auto structure = character->getSpaceStructure();
								dgmpp::TypeID fuelBlockTyppeID = structure->getFuelBlockTypeID();
								float cycleFuelNeed = structure->getCycleFuelNeed();
								float cycleTime = structure->getCycleTime();
								NCDBInvType* type = [controller.controller.engine.databaseManagedObjectContext invTypeWithTypeID:fuelBlockTyppeID];
								NSMutableDictionary* data = [NSMutableDictionary new];
								data[@"image"] = type.icon.image.image ?: self.defaultTypeImage;
								data[@"title"] = type.typeName ?: NSLocalizedString(@"Unknown Type", nil);
								
								[[NCPriceManager sharedManager] requestPricesWithTypes:@[@(fuelBlockTyppeID)] completionBlock:^(NSDictionary *prices) {
									float fuelDailyCost = [prices[@(fuelBlockTyppeID)] floatValue] / cycleTime * 3600 * 24 * cycleFuelNeed;
									data[@"subtitle"] = [NSString stringWithFormat:NSLocalizedString(@"%d/h (%@ ISK/day)", nil),
														 (int) (cycleFuelNeed / cycleTime * 3600),
														 [NSNumberFormatter neocomLocalizedStringFromNumber:@(fuelDailyCost)]];
									dispatch_async(dispatch_get_main_queue(), ^{
										completionBlock(data);
									});
								}];
							}];
						}
						else
							completionBlock(nil);
					};
					[rows addObject:row];
					section.rows = rows;
				}
				[sections addObject:section];
				
				
				section = [NCFittingSpaceStructureStatsViewControllerSection new];
				section.title = NSLocalizedString(@"Price", nil);
				{
					NSMutableArray* rows = [NSMutableArray new];
					row = [NCFittingSpaceStructureStatsViewControllerRow new];
					row.cellIdentifier = @"NCFittingShipPriceCell";
					row.configurationBlock = ^(id tableViewCell, NSDictionary* data) {
						NCFittingShipPriceCell* cell = (NCFittingShipPriceCell*) tableViewCell;
						cell.shipPriceLabel.text = data[@"shipPrice"];
						cell.fittingsPriceLabel.text = data[@"fittingsPrice"];
						cell.dronesPriceLabel.text = data[@"dronesPrice"];
						cell.totalPriceLabel.text = data[@"totalPrice"];
					};
					row.loadingBlock = ^(NCFittingSpaceStructureStatsViewController* controller, void (^completionBlock)(NSDictionary* data)) {
						auto character = controller.controller.fit.pilot;
						if (character) {
							[controller.controller.engine performBlock:^{
								auto structure = character->getSpaceStructure();
								NSMutableDictionary* types = [NSMutableDictionary new];
								NSMutableSet* drones = [NSMutableSet set];
								__block int32_t structureTypeID;
								structureTypeID = structure->getTypeID();
								
								types[@(structure->getTypeID())] = @(1);
								
								for (const auto& i: structure->getModules())
									types[@(i->getTypeID())] = @([types[@(i->getTypeID())] intValue] + 1);
								
								for (const auto& i: structure->getDrones()) {
									types[@(i->getTypeID())] = @([types[@(i->getTypeID())] intValue] + 1);
									[drones addObject:@(i->getTypeID())];
								}
								[[NCPriceManager sharedManager] requestPricesWithTypes:[types allKeys] completionBlock:^(NSDictionary *prices) {
									__block float shipPrice = 0;
									__block float fittingsPrice = 0;
									__block float dronesPrice = 0;
									
									[prices enumerateKeysAndObjectsUsingBlock:^(NSNumber* key, NSNumber* obj, BOOL *stop) {
										int32_t typeID = [key intValue];
										if (typeID == structureTypeID)
											shipPrice = [obj doubleValue];
										else if ([drones containsObject:@(typeID)])
											dronesPrice += [obj doubleValue] * [types[key] intValue];
										else
											fittingsPrice += [obj doubleValue] * [types[key] intValue];
									}];
									float totalPrice = shipPrice + fittingsPrice + dronesPrice;
									NSDictionary* data =
									@{@"shipPrice": [NSString stringWithFormat:NSLocalizedString(@"%@ ISK", nil), [NSString shortStringWithFloat:shipPrice unit:nil]],
									  @"fittingsPrice": [NSString stringWithFormat:NSLocalizedString(@"%@ ISK", nil), [NSString shortStringWithFloat:fittingsPrice unit:nil]],
									  @"dronesPrice": [NSString stringWithFormat:NSLocalizedString(@"%@ ISK", nil), [NSString shortStringWithFloat:dronesPrice unit:nil]],
									  @"totalPrice": [NSString stringWithFormat:NSLocalizedString(@"Total: %@ ISK", nil), [NSString shortStringWithFloat:totalPrice unit:nil]]};
									dispatch_async(dispatch_get_main_queue(), ^{
										completionBlock(data);
									});
									
								}];
							}];
						}
						else
							completionBlock(nil);
					};
					[rows addObject:row];
					section.rows = rows;
				}
				[sections addObject:section];
				
				dispatch_async(dispatch_get_main_queue(), ^{
					self.sections = sections;
					completionBlock();
				});
			}];
		}
	}
	else
		completionBlock();
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return self.sections.count;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [[self.sections[section] rows] count];
}


- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return [self.sections[section] title];
}

#pragma mark - Table view delegate


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	NSString* title = [self tableView:tableView titleForHeaderInSection:section];
	if (title) {
		NCTableViewHeaderView* view = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"NCTableViewHeaderView"];
		view.textLabel.text = title;
		return view;
	}
	else
		return nil;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	NSString* title = [self tableView:tableView titleForHeaderInSection:section];
	return title ? 44 : 0;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == 1 && indexPath.row == 4)
		[self.controller performSegueWithIdentifier:@"NCFittingDamagePatternsViewController" sender:[tableView cellForRowAtIndexPath:indexPath]];
	else if (indexPath.section == 4 && indexPath.row == 0)
		[self.controller performSegueWithIdentifier:@"NCFittingShipOffenseStatsViewController" sender:[tableView cellForRowAtIndexPath:indexPath]];
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}


- (NSString*) tableView:(UITableView *)tableView cellIdentifierForRowAtIndexPath:(NSIndexPath *)indexPath {
	NCFittingSpaceStructureStatsViewControllerRow* row = [self.sections[indexPath.section] rows][indexPath.row];
	return row.cellIdentifier;
}

- (void) tableView:(UITableView *)tableView configureCell:(UITableViewCell *)tableViewCell forRowAtIndexPath:(NSIndexPath *)indexPath {
	NCFittingSpaceStructureStatsViewControllerRow* row = [self.sections[indexPath.section] rows][indexPath.row];
	if (!row.isUpToDate) {
		row.isUpToDate = YES;
		row.loadingBlock(self, ^(NSDictionary* data) {
			dispatch_async(dispatch_get_main_queue(), ^{
				row.data = data;
				if (data)
					[tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
			});
		});
	}
	if (row.data)
		row.configurationBlock(tableViewCell, row.data);
}

@end
