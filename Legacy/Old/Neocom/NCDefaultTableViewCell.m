//
//  NCDefaultTableViewCell.m
//  Neocom
//
//  Created by Artem Shimanski on 12.02.15.
//  Copyright (c) 2015 Artem Shimanski. All rights reserved.
//

#import "NCDefaultTableViewCell.h"

@interface NCDefaultTableViewCell()
@property (nonatomic, strong) IBOutlet NSLayoutConstraint* imageViewWidthConstraint;
@property (nonatomic, strong) NSLayoutConstraint* imageViewHeightConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint* indentationConstraint;
@end

@implementation NCDefaultTableViewCell

- (void) updateConstraints {
	self.indentationConstraint.constant = self.indentationLevel * self.indentationWidth;
	self.imageViewWidthConstraint.constant = self.iconView.image ? 32.0 : 0;
	[super updateConstraints];
}

- (void) prepareForReuse {
	[super prepareForReuse];
	[self setNeedsUpdateConstraints];
}

- (void) layoutSubviews {
	[super layoutSubviews];
	if ([self respondsToSelector:@selector(setSeparatorInset:)]) {
		CGPoint p = [self.titleLabel convertPoint:CGPointZero toView:self];
		self.separatorInset = UIEdgeInsetsMake(0, p.x, 0, 0);
	}
}

- (void) awakeFromNib {
	NSArray* views = [[UINib nibWithNibName:@"NCDefaultTableViewCell" bundle:nil] instantiateWithOwner:self options:nil];
	self.layoutContentView.translatesAutoresizingMaskIntoConstraints = NO;
	[self.layoutContentView addConstraint:[NSLayoutConstraint constraintWithItem:self.layoutContentView
																	   attribute:NSLayoutAttributeHeight
																	   relatedBy:NSLayoutRelationGreaterThanOrEqual
																		  toItem:nil
																	   attribute:NSLayoutAttributeNotAnAttribute
																	  multiplier:1
																		constant:36]];

	NSLayoutConstraint* constraint = [NSLayoutConstraint constraintWithItem:self.layoutContentView
																  attribute:NSLayoutAttributeHeight
																  relatedBy:NSLayoutRelationEqual
																	 toItem:nil
																  attribute:NSLayoutAttributeNotAnAttribute
																 multiplier:1
																   constant:36];
	constraint.priority = 500;
	[self.layoutContentView addConstraint:constraint];

	
	[self.contentView addSubview:[views lastObject]];
	NSDictionary* bindings = @{@"view": self.layoutContentView};
	
	[self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[view]-0@999-|"
																			 options:0
																			 metrics:nil
																			   views:bindings]];


	[self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[view]-0@999-|"
																			 options:0
																			 metrics:nil
																			   views:bindings]];
	[super awakeFromNib];
}

@end
