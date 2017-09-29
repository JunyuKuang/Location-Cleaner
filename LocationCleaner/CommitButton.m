//
//  CommitButton.m
//  PhotoLocationRemover
//
//  Created by Jonny on 9/28/17.
//  Copyright © 2017 Jonny. All rights reserved.
//

#import "CommitButton.h"

@implementation CommitButton

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    [UIView animateWithDuration:0.2 animations:^{
        self.alpha = !highlighted ? 1.0f : 0.4f;
    }];
}

- (void)setEnabled:(BOOL)enabled
{
    [super setEnabled:enabled];
    self.alpha = enabled ? 1.0f : 0.4f;
}

@end
