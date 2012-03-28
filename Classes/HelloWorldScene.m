//
//  HelloWorldLayer.m
//  FlotteSprite
//
//  Created by Radif Sharafullin on 12/27/10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

// Import the interfaces
#import "HelloWorldScene.h"
#import "CCParticleExamples.h"

// HelloWorld implementation
@implementation HelloWorld

+(id) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	HelloWorld *layer = [HelloWorld node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	
	CCParticleBubble * bubbles = [[CCParticleBubble alloc]initWithTotalParticles:20];
	[scene addChild:bubbles];
	[bubbles setPosition:ccp(170,208)];
	[bubbles release];
	
	// return the scene
	return scene;
}

// on "init" you need to initialize your instance
-(id) init
{
	// always call "super" init
	// Apple recommends to re-assign "self" with the "super" return value
	if( (self=[super init] )) {
		
		// create and initialize a Label
		FlotteSprite* flotte = [FlotteSprite node];

		// ask director the the window size
		CGSize size = [[CCDirector sharedDirector] winSize];
	
		// position the label on the center of the screen
		flotte.position =  ccp( size.width /2 , size.height/2 );
		
		// add the label as a child to this Layer
		[self addChild: flotte];
	}
	return self;
}

// on "dealloc" you need to release all your retained objects
- (void) dealloc
{
	// in case you have something to dealloc, do it in this method
	// in this particular example nothing needs to be released.
	// cocos2d will automatically release all the children (Label)
	
	// don't forget to call "super dealloc"
	[super dealloc];
}
@end
