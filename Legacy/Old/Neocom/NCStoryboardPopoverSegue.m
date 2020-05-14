//
//  NCStoryboardPopoverSegue.m
//  Neocom
//
//  Created by Артем Шиманский on 03.02.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCStoryboardPopoverSegue.h"
#import "UIColor+Neocom.h"

@implementation NCStoryboardPopoverSegue

- (UIView*) anchorView {
	if (!_anchorView && [self.sourceViewController respondsToSelector:@selector(tableView)]) {
		NSIndexPath* indexPath = [[self.sourceViewController tableView] indexPathForSelectedRow];
		if (indexPath)
			_anchorView = [[self.sourceViewController tableView] cellForRowAtIndexPath:indexPath];
	}
	return _anchorView;
}

- (UIView*) _anchorView {
	return self.anchorView;
}

- (UIBarButtonItem*) _anchorBarButtonItem {
	return self.anchorBarButtonItem;
}

- (CGRect) _anchorRect {
	return self.anchorView.bounds;
}

- (UIPopoverArrowDirection) _permittedArrowDirections {
	return UIPopoverArrowDirectionAny;
}

- (void) perform {
	[super perform];
	if ([self.popoverController respondsToSelector:@selector(setBackgroundColor:)])
		//self.popoverController.backgroundColor = [UIColor blackColor];
		self.popoverController.backgroundColor = [UIColor appearancePopoverBackgroundColor];
}

@end
