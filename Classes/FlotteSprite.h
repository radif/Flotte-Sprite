//
//  FlotteSprite.h
//  FlotteSprite
//
//  Created by Radif Sharafullin on 12/27/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

@interface FlotteSprite : CCSprite <CCTargetedTouchDelegate> {
	@private
	unsigned char *_bmpImage;
	unsigned char *_bmpImage2;
	long int imageWidth;
	long int imageHeight;
}

@end
