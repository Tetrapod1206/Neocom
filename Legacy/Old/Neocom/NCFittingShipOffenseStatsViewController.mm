//
//  NCFittingShipOffenseStatsViewController.m
//  Neocom
//
//  Created by Артем Шиманский on 25.11.15.
//  Copyright © 2015 Artem Shimanski. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>
#import "NCFittingShipOffenseStatsViewController.h"
#include <initializer_list>
#include <vector>
#import "NCShipFit.h"
#import "NSNumberFormatter+Neocom.h"
#import <algorithm>
#import "NCDatabase.h"
#import "NSManagedObjectContext+NCDatabase.h"
#import "NCFittingHullTypePickerViewController.h"
#import "GAI+Neocom.h"

@interface NCFittingShipOffenseStatsViewController()<CALayerDelegate>
@property (nonatomic, strong) CAShapeLayer* axisLayer;
@property (nonatomic, strong) CAShapeLayer* dpsLayer;
@property (nonatomic, strong) CAShapeLayer* velocityLayer;
@property (nonatomic, strong) CAShapeLayer* markerLayer;
@property (nonatomic, assign) float maxRange;
@property (nonatomic, assign) float falloff;
@property (nonatomic, assign) float fullRange;
@property (nonatomic, strong) NSData* dpsPoints;
@property (nonatomic, strong) NSData* velocityPoints;
@property (nonatomic, assign) float markerPosition;
@property (nonatomic, strong) NSNumberFormatter* dpsNumberFormatter;
@property (nonatomic, strong) NCDBDgmppHullType* hullType;

@property (nonatomic, assign) BOOL needsUpdateState;
@property (nonatomic, assign) BOOL updatingState;
@property (nonatomic, assign) BOOL needsUpdateReport;
@property (nonatomic, assign) BOOL updatingReport;
- (void) reload;
- (void) updateState;
- (void) updateReport;
- (void) setNeedsUpdateState;
- (void) setNeedsUpdateReport;

@end

@implementation NCFittingShipOffenseStatsViewController

- (void) viewDidLoad {
	[super viewDidLoad];
	NSManagedObjectID* hullTypeID = self.fit.engine.userInfo[@"hullType"];
	NCDBDgmppHullType* hullType;
	if (hullTypeID)
		hullType = [self.databaseManagedObjectContext existingObjectWithID:hullTypeID error:nil];
	
	if (!hullType) {
		NCDBInvType* type = [self.databaseManagedObjectContext invTypeWithTypeID:self.fit.typeID];
		hullType = type.hullType;
	}
	self.hullType = hullType;

	self.dpsNumberFormatter = [[NSNumberFormatter alloc] init];
	[self.dpsNumberFormatter setPositiveFormat:@"#,##0.0"];
	[self.dpsNumberFormatter setGroupingSeparator:@" "];
	[self.dpsNumberFormatter setDecimalSeparator:@"."];

	self.axisLayer = [CAShapeLayer layer];
	self.axisLayer.strokeColor = [[UIColor whiteColor] CGColor];
	self.axisLayer.fillColor = [[UIColor clearColor] CGColor];
	self.axisLayer.delegate = (id <CALayerDelegate>) self;
	self.axisLayer.needsDisplayOnBoundsChange = YES;
	self.axisLayer.zPosition = 10;

	self.dpsLayer = [CAShapeLayer layer];
	self.dpsLayer.strokeColor = [[UIColor orangeColor] CGColor];
	self.dpsLayer.fillColor = [[UIColor clearColor] CGColor];
	self.dpsLayer.delegate = (id <CALayerDelegate>) self;
	self.dpsLayer.needsDisplayOnBoundsChange = YES;

	self.velocityLayer = [CAShapeLayer layer];
	self.velocityLayer.strokeColor = [[UIColor greenColor] CGColor];
	self.velocityLayer.fillColor = [[UIColor clearColor] CGColor];
	self.velocityLayer.delegate = (id <CALayerDelegate>) self;
	self.velocityLayer.needsDisplayOnBoundsChange = YES;

	[self.canvasView.layer addSublayer:self.axisLayer];
	[self.canvasView.layer addSublayer:self.dpsLayer];
	[self.canvasView.layer addSublayer:self.velocityLayer];
	self.axisLayer.frame = self.canvasView.layer.bounds;
	self.dpsLayer.frame = self.canvasView.layer.bounds;
	self.velocityLayer.frame = self.canvasView.layer.bounds;
	
	self.markerLayer = [CAShapeLayer layer];
	self.markerLayer.frame = self.markerView.layer.bounds;
	self.markerLayer.strokeColor = [[UIColor yellowColor] CGColor];
	self.markerLayer.fillColor = [[UIColor clearColor] CGColor];
	self.markerLayer.lineDashPattern = @[@4, @4];
	self.markerLayer.delegate = (id <CALayerDelegate>) self;
	self.markerLayer.needsDisplayOnBoundsChange = YES;
	[self.markerView.layer addSublayer:self.markerLayer];

	[self reload];
}

- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	[GAI createScreenWithName:NSStringFromClass(self.class)];
}

- (void) dealloc {
	self.dpsLayer.delegate = nil;
	self.axisLayer.delegate = nil;
	self.velocityLayer.delegate = nil;
	self.markerLayer.delegate = nil;
}

- (void) viewDidLayoutSubviews {
	[super viewDidLayoutSubviews];
	if (self.dpsLayer.bounds.size.width != self.canvasView.bounds.size.width ||
		self.velocityLayer.bounds.size.width != self.canvasView.bounds.size.width)
		[self setNeedsUpdateState];

	
	self.dpsLayer.frame = self.canvasView.bounds;
	self.velocityLayer.frame = self.canvasView.bounds;
	self.axisLayer.frame = self.canvasView.bounds;
	self.markerLayer.frame = self.markerView.layer.bounds;
}

- (void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
	[super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
	[self.view setNeedsUpdateConstraints];
}

- (void) displayLayer:(CALayer *)layer {
	if (layer == self.axisLayer) {
		UIBezierPath* bezierPath = [UIBezierPath bezierPath];
		[bezierPath moveToPoint:CGPointMake(0, 0)];
		[bezierPath addLineToPoint:CGPointMake(0, self.canvasView.bounds.size.height)];
		[bezierPath addLineToPoint:CGPointMake(self.canvasView.bounds.size.width, self.canvasView.bounds.size.height)];
		
		for (CGFloat x: {	self.canvasView.bounds.size.width * self.maxRange / self.fullRange,
			self.canvasView.bounds.size.width * (self.maxRange + self.falloff) / self.fullRange,
			self.canvasView.bounds.size.width}) {
				[bezierPath moveToPoint:CGPointMake(x, self.canvasView.bounds.size.height)];
				[bezierPath addLineToPoint:CGPointMake(x, self.canvasView.bounds.size.height - 4)];
			}
		
		for (CGFloat y: {(CGFloat) 0.0f, self.canvasView.bounds.size.height / 2}) {

			[bezierPath moveToPoint:CGPointMake(0, y)];
			[bezierPath addLineToPoint:CGPointMake(4, y)];
		}
		
		self.axisLayer.path = [bezierPath CGPath];
	}
	else if (layer == self.dpsLayer && self.dpsPoints) {
		SKShapeNode* node = [SKShapeNode shapeNodeWithPoints:(CGPoint*) [self.dpsPoints bytes] count:self.dpsPoints.length / sizeof(CGPoint)];
		UIBezierPath* path = [UIBezierPath bezierPathWithCGPath:node.path];
		CGAffineTransform transform = CGAffineTransformIdentity;
		transform = CGAffineTransformScale(transform, self.canvasView.bounds.size.width, -self.canvasView.bounds.size.height);
		transform = CGAffineTransformTranslate(transform, 0, -1);
		[path applyTransform:transform];
		self.dpsLayer.path = path.CGPath;
	}
	else if (layer == self.velocityLayer && self.velocityPoints) {
		SKShapeNode* node = [SKShapeNode shapeNodeWithPoints:(CGPoint*) [self.velocityPoints bytes] count:self.velocityPoints.length / sizeof(CGPoint)];
		UIBezierPath* path = [UIBezierPath bezierPathWithCGPath:node.path];
		CGAffineTransform transform = CGAffineTransformIdentity;
		transform = CGAffineTransformScale(transform, self.canvasView.bounds.size.width, -self.canvasView.bounds.size.height);
		transform = CGAffineTransformTranslate(transform, 0, -1);
		[path applyTransform:transform];
		self.velocityLayer.path = path.CGPath;
	}
	else if (layer == self.markerLayer) {
		UIBezierPath* path = [UIBezierPath bezierPath];
		CGFloat x = CGRectGetMidX(self.markerLayer.bounds);
		[path moveToPoint:CGPointMake(x, 0)];
		[path addLineToPoint:CGPointMake(x, self.markerLayer.bounds.size.height)];
		self.markerLayer.path = [path CGPath];
	}
}

- (IBAction)onChangeVelocity:(id) sender {
	[self setNeedsUpdateState];
	CGRect rect = [self.velocitySlider thumbRectForBounds:self.velocitySlider.bounds trackRect:[self.velocitySlider trackRectForBounds:self.velocitySlider.bounds] value:self.velocitySlider.value];

	[self.velocityLabelAuxiliaryView.superview removeConstraint:self.velocityLabelConstraint];
	id constraint = [NSLayoutConstraint constraintWithItem:self.velocityLabelAuxiliaryView
												 attribute:NSLayoutAttributeWidth
												 relatedBy:NSLayoutRelationEqual
													toItem:self.velocitySlider
												 attribute:NSLayoutAttributeWidth
												multiplier:CGRectGetMidX(rect) / self.velocitySlider.bounds.size.width
												  constant:0];
	self.velocityLabelConstraint = constraint;
	//self.velocityLabelConstraint.priority = UILayoutPriorityDefaultHigh;
	[self.velocityLabelAuxiliaryView.superview addConstraint:constraint];
	[self.view setNeedsUpdateConstraints];
}

- (IBAction)onPan:(UIPanGestureRecognizer*) recognizer {
	self.markerPosition = [recognizer locationInView:self.contentView].x / self.contentView.bounds.size.width;
}

- (IBAction)onTap:(UITapGestureRecognizer*) recognizer {
	self.markerPosition = [recognizer locationInView:self.contentView].x / self.contentView.bounds.size.width;
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	if ([segue.identifier isEqualToString:@"NCFittingHullTypePickerViewController"]) {
		NCFittingHullTypePickerViewController* controller = segue.destinationViewController;
		controller.selectedHullType = self.hullType;
	}
}

- (IBAction) unwindFromHullTypePicker:(UIStoryboardSegue*) segue {
	NCFittingHullTypePickerViewController* sourceViewController = segue.sourceViewController;
	if (sourceViewController.selectedHullType) {
		NCDBDgmppHullType* hullType = [self.databaseManagedObjectContext objectWithID:sourceViewController.selectedHullType.objectID];
		self.hullType = hullType;
		self.fit.engine.userInfo[@"hullType"] = sourceViewController.selectedHullType.objectID;
		[self setNeedsUpdateState];
	}
}



#pragma mark - Private

- (void) reload {
	__block float maxVelocity = 0;
	[self.fit.engine performBlockAndWait:^{
		auto pilot = self.fit.pilot;
		auto ship = pilot->getShip();
		
		float turretsDPS = 0;
		float maxRange = 0;
		float falloff = 0;
		for (const auto& module: ship->getModules()) {
			if (module->getHardpoint() == dgmpp::Module::HARDPOINT_TURRET) {
				float dps = module->getDps();
				if (dps > 0) {
					turretsDPS += dps;
					maxRange += module->getMaxRange() * dps;
					falloff += module->getFalloff() * dps;
				}
			}
		}
		if (turretsDPS > 0) {
			maxRange /= turretsDPS;
			falloff /= turretsDPS;
		}
		self.maxRange = maxRange;
		self.falloff = falloff;
		self.fullRange = self.maxRange + self.falloff * 2;
		maxVelocity = ship->getVelocity();
		if (self.fullRange == 0) {
			self.fullRange = ceil(ship->getOrbitRadiusWithTransverseVelocity(ship->getVelocity() * 0.95) * 1.5 / 1000) * 1000;
		}
	}];
	
	self.velocitySlider.minimumValue = 0;
	self.velocitySlider.maximumValue = maxVelocity;
	self.velocitySlider.value = maxVelocity;
	self.maxVelocityLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ m/s", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:maxVelocity]];
	
	//[self update];
	self.markerPosition = -1;
	[self onChangeVelocity:self.velocitySlider];
	
	self.optimalLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ m", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:self.maxRange]];
	self.falloffLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ m", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:self.falloff + self.maxRange]];
	self.doubleFalloffLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ m", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:self.fullRange]];
	
	
	[self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.optimalAuxiliaryView
																 attribute:NSLayoutAttributeWidth
																 relatedBy:NSLayoutRelationEqual
																	toItem:self.contentView
																 attribute:NSLayoutAttributeWidth
																multiplier:self.maxRange / (self.fullRange > 0 ? self.fullRange : 1)
																  constant:0]];
	
	[self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.falloffAuxiliaryView
																 attribute:NSLayoutAttributeWidth
																 relatedBy:NSLayoutRelationEqual
																	toItem:self.contentView
																 attribute:NSLayoutAttributeWidth
																multiplier:self.falloff / (self.fullRange > 0 ? self.fullRange : 1)
																  constant:0]];
	
	if (self.maxRange == 0 || self.falloff == 0) {
		self.optimalLabel.hidden = YES;
		self.falloffLabel.hidden = YES;
		for (UIView* label in self.axisLabels)
			label.hidden = YES;
	}
}



- (void) setMarkerPosition:(float)markerPosition {
	_markerPosition = markerPosition;
	[self.markerAuxiliaryView.superview removeConstraint:self.markerViewConstraint];
	id constraint = [NSLayoutConstraint constraintWithItem:self.markerAuxiliaryView
												 attribute:NSLayoutAttributeWidth
												 relatedBy:NSLayoutRelationEqual
													toItem:self.contentView
												 attribute:NSLayoutAttributeWidth
												multiplier:markerPosition >= 0 ? markerPosition : 0
												  constant:0];
	self.markerViewConstraint = constraint;
	[self.markerAuxiliaryView.superview addConstraint:constraint];
	[self setNeedsUpdateReport];
}

- (void) setHullType:(NCDBDgmppHullType*) hullType {
	_hullType = hullType;
	if (hullType) {
		NSMutableAttributedString* s = [[NSMutableAttributedString alloc] initWithString:hullType.hullTypeName ?: NSLocalizedString(@"Unknown", nil) attributes:@{NSUnderlineStyleAttributeName:@(NSUnderlineStyleSingle)}];
		[s appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:NSLocalizedString(@" (sig %.0f m)", nil), hullType.signature] attributes:nil]];
		self.targetLabel.attributedText = s;
	}
	else
		self.targetLabel.text = NSLocalizedString(@"None", nil);
	[self setNeedsUpdateState];
}

- (void) updateState {
	if (self.updatingState)
		return;
	if (self.needsUpdateState) {
		self.needsUpdateState = NO;
		self.updatingState = YES;
		
		float velocity = self.velocitySlider.value;
		float targetSignature = self.hullType.signature;

		[self.fit.engine performBlock:^{
			CGPoint maxDPS = CGPointZero;
			
			auto pilot = self.fit.pilot;
			auto ship = pilot->getShip();
			auto maxVelocity = ship->getVelocity();
			
			int n = self.canvasView.bounds.size.width / 2 - 1;
			CGPoint *dpsPoints = new CGPoint[n];
			CGPoint *velocityPoints = new CGPoint[n];
			float dx = self.fullRange / (n + 1);
			float x = dx;
			float optimalDPS = ship->getWeaponDps() + ship->getDroneDps();
			for (int i = 0; i < n; i++) {
				float v = ship->getMaxVelocityInOrbit(x);
				v = std::min(v, velocity);
				float angularVelocity = v / x;
				dgmpp::HostileTarget target = dgmpp::HostileTarget(x, angularVelocity, targetSignature, 0);
				
				dpsPoints[i] = CGPointMake(x / self.fullRange, optimalDPS > 0 ? (static_cast<float>(ship->getWeaponDps(target)) + ship->getDroneDps(target)) / optimalDPS : 0);
				
				if (dpsPoints[i].y >= maxDPS.y)
					maxDPS = dpsPoints[i];
				
				velocityPoints[i] = CGPointMake(x / self.fullRange, maxVelocity > 0 ? v / maxVelocity : 0);
				x += dx;
			}
			
			
			dispatch_async(dispatch_get_main_queue(), ^{
				self.dpsPoints = [NSData dataWithBytesNoCopy:dpsPoints length:sizeof(CGPoint) * n freeWhenDone:YES];
				self.velocityPoints = [NSData dataWithBytesNoCopy:velocityPoints length:sizeof(CGPoint) * n freeWhenDone:YES];
				
				if (self.markerPosition < 0)
					self.markerPosition = maxDPS.x;
				self.updatingState = NO;
				
				[self.dpsLayer setNeedsDisplay];
				[self.velocityLayer setNeedsDisplay];
				
				if (self.needsUpdateState) {
					[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateState) object:nil];
					[self performSelector:@selector(updateState) withObject:nil afterDelay:0];
				}
				[self setNeedsUpdateReport];
			});
		}];
	}
}

- (void) updateReport {
	if (self.updatingReport)
		return;
	if (self.needsUpdateReport) {
		self.needsUpdateReport = NO;
		self.updatingReport = YES;
		
		float velocity = self.velocitySlider.value;
		float targetSignature = self.hullType.signature;
		
		[self.fit.engine performBlock:^{
			float orbit = 0;
			float transverseVelocity = 0;
			float dps = 0;
			float droneDPS = 0;
			float turretsDPS = 0;
			float launchersDPS = 0;

			auto pilot = self.fit.pilot;
			auto ship = pilot->getShip();
			float optimalDPS = ship->getWeaponDps() + ship->getDroneDps();
			
			float x = self.fullRange * self.markerPosition;
			orbit = x;
			float v = ship->getMaxVelocityInOrbit(x);
			v = std::min(v, velocity);
			transverseVelocity = v;
			float angularVelocity = v / x;
			dgmpp::HostileTarget target = dgmpp::HostileTarget(x, angularVelocity, targetSignature, 0);
			droneDPS = ship->getDroneDps(target);
			
			for (const auto& module: ship->getModules()) {
				if (module->getHardpoint() == dgmpp::Module::HARDPOINT_TURRET)
					turretsDPS += module->getDps(target);
				else
					launchersDPS += module->getDps(target);
			}
			
			dps = turretsDPS + launchersDPS + droneDPS;
			dispatch_async(dispatch_get_main_queue(), ^{
				self.orbitLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ m", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:orbit]];
				self.transverseVelocityLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ m/s", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:transverseVelocity]];
				
				NSMutableAttributedString* s = [NSMutableAttributedString new];
				[s appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ (", [self.dpsNumberFormatter stringFromNumber:@(dps)]] attributes:nil]];
				
				NSTextAttachment* icon;
				
				icon = [NSTextAttachment new];
				icon.image = [UIImage imageNamed:@"turrets"];
				icon.bounds = CGRectMake(0, -7 -self.dpsLabel.font.descender, 15, 15);
				[s appendAttributedString:[NSAttributedString attributedStringWithAttachment:icon]];
				[s appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ + ", [self.dpsNumberFormatter stringFromNumber:@(turretsDPS)]] attributes:nil]];
				
				
				icon = [NSTextAttachment new];
				icon.image = [UIImage imageNamed:@"launchers"];
				icon.bounds = CGRectMake(0, -7 -self.dpsLabel.font.descender, 15, 15);
				[s appendAttributedString:[NSAttributedString attributedStringWithAttachment:icon]];
				[s appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ + ", [self.dpsNumberFormatter stringFromNumber:@(launchersDPS)]] attributes:nil]];
				
				icon = [NSTextAttachment new];
				icon.image = [UIImage imageNamed:@"drone"];
				icon.bounds = CGRectMake(0, -7 -self.dpsLabel.font.descender, 15, 15);
				[s appendAttributedString:[NSAttributedString attributedStringWithAttachment:icon]];
				//[s appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@) %.0f%%", [self.dpsNumberFormatter stringFromNumber:@(droneDPS)], optimalDPS ? dps / optimalDPS * 100 : 100.0f] attributes:nil]];
				[s appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@)", [self.dpsNumberFormatter stringFromNumber:@(droneDPS)]] attributes:nil]];
				self.dpsTitleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"DPS %.0f%%", nil), optimalDPS ? dps / optimalDPS * 100 : 100.0f];
				
				
				//self.dpsLabel.text = [NSNumberFormatter neocomLocalizedStringFromNumber:@(dps)];
				self.dpsLabel.attributedText = s;
				
				self.velocityLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ m/s", nil), [NSNumberFormatter neocomLocalizedStringFromInteger:self.velocitySlider.value]];
				
				self.updatingReport = NO;
				if (self.needsUpdateReport) {
					[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateReport) object:nil];
					[self performSelector:@selector(updateReport) withObject:nil afterDelay:0];
				}
			});
		}];
	}
}

- (void) setNeedsUpdateState {
	self.needsUpdateState = YES;
	if (self.updatingState)
		return;
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateState) object:nil];
	[self performSelector:@selector(updateState) withObject:nil afterDelay:0];
}

- (void) setNeedsUpdateReport {
	self.needsUpdateReport = YES;
	if (self.updatingReport)
		return;
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateReport) object:nil];
	[self performSelector:@selector(updateReport) withObject:nil afterDelay:0];
}


@end
