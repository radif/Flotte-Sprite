//
//  FlotteSprite.m
//  FlotteSprite
//
//  Created by Radif Sharafullin on 12/27/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "FlotteSprite.h"
#include "flotte.h"

dmFlotte *gFlotte = NULL;


void DrawCube(long int Width, long int Height, unsigned char *bmpImage, unsigned char *bmpImage2)
{
	
	GLuint tex[2];
    glGenTextures(2, tex);
	
	
    /* Zbuff on ... */
	
	
    glEnable(GL_DEPTH_TEST);
    glDepthFunc(GL_LESS);
	
    // no face culling to have recto-verso
	
    
    //FIXME: this one causes artifacts on the texture
    //glShadeModel(GL_SMOOTH); // shading Gouraud
	
    glBindTexture(GL_TEXTURE_2D, 2);
    glPixelStorei(GL_UNPACK_ALIGNMENT,1);

    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, Width, Height, 0, GL_RGB, GL_UNSIGNED_BYTE, bmpImage2);
	
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	
	
    glBindTexture(GL_TEXTURE_2D, 1);
    glPixelStorei(GL_UNPACK_ALIGNMENT,1);

    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, Width, Height, 0, GL_RGB, GL_UNSIGNED_BYTE, bmpImage);
	
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	
}


@implementation FlotteSprite
-(id)init{
	self=[super init];
	[[CCTouchDispatcher sharedDispatcher] addTargetedDelegate:self priority:0 swallowsTouches:YES];

	FILE *file = NULL;
    FILE *file2 = NULL;
    unsigned short int bitCount = 3;
    unsigned long int sizeImage;
	
    imageWidth = 512;
    imageHeight = 512;
    sizeImage = imageHeight * imageWidth * bitCount;
	
	if (!gFlotte)
    {
        gFlotte = new dmFlotte(FLOT_MEDIUMRES);
    }
	
	NSString *skyPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"sky.raw"];
	NSString *stonePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"stone3.raw"];
    file = fopen([skyPath cStringUsingEncoding:NSUTF8StringEncoding] ,"rb");
    file2 = fopen([stonePath cStringUsingEncoding:NSUTF8StringEncoding] ,"rb");
	
    if (!file || !file2)
    {
        printf("\nCouldn't open files");
        return self;
    }
	
    _bmpImage = (unsigned char *) malloc(sizeImage);
    _bmpImage2 = (unsigned char *) malloc(sizeImage);
	
    if (!_bmpImage || !_bmpImage2)
    {
        printf("\nFailed to alloc memory for bmpImage data");
        fclose(file);
        return self;
    }
	
    if ( (fread(_bmpImage, 1, sizeImage, file) != sizeImage)  || (fread(_bmpImage2, 1, sizeImage, file2) != sizeImage))
    {
        printf("\nFile doesn't look like a bmp data");
        fclose(file);
        return self;
    }
	
    fclose(file);
    
	return self;

}

-(void)draw{
	[super draw];
	//return;
	glPushMatrix();
	glScalef(50, 80, 0);
	//glScalef(100, 160, 0);
	//glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
   // glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);
	//glEnable(GL_DEPTH_TEST);
	
    DrawCube(imageWidth, imageHeight, _bmpImage, _bmpImage2);
	
    
    
    if (gFlotte)
    {
        gFlotte->runWave(0.0f, 2.0f, 4.0f, 32);
        gFlotte->runWave(400.0f, 5.0f, 3.0f, 32);
        gFlotte->runWave(800.0f, 3.0f, 2.0f, 32);
        gFlotte->runWave(1000.0f, 4.0f, 3.0f, 32);
		
        gFlotte->update();
        gFlotte->build();
        
        //glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        
        gFlotte->display();
        
        //glFlush();
		
    }
    
    glPopMatrix();
    return;
    
	glPopMatrix();
	/*
	GLenum err = glGetError();
	if(err) NSLog(@"%x error", err);
	*/
	/*
	 //restore gl states?
	glColorMask(TRUE,TRUE,TRUE,TRUE);
	glBlendFunc( CC_BLEND_SRC, CC_BLEND_DST );
	glTexEnvi (GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
	
	glBindBuffer(GL_ARRAY_BUFFER, 0);
    */
    
    // restore default GL states
	glEnable(GL_TEXTURE_2D);
	glEnableClientState(GL_COLOR_ARRAY);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
	
	
}
-(void)dealloc{
	[[CCTouchDispatcher sharedDispatcher] removeDelegate:self];

    if (gFlotte) {
		delete(gFlotte);
		gFlotte=NULL;
	}
	[super dealloc];
}

- (BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event {
	if (gFlotte)
    {
		//CGPoint location = [self convertTouchToNodeSpace: touch];
		CGPoint location=[touch locationInView:touch.view];
		location=[[CCDirector sharedDirector] convertToGL:location];
		
		CGSize winSize=[[CCDirector sharedDirector] winSize];
		location.x/=winSize.width;
		
		//square it away:
//		location.y-=winSize.width/2;
		
		location.y/=winSize.height;
		
		NSLog(@"%@",NSStringFromCGPoint(location));
		  gFlotte->setWave(location.x, location.y, 1000);
    }
	
	
	return YES;
}
-(void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event{
	if (gFlotte)
    {
		//CGPoint location = [self convertTouchToNodeSpace: touch];
		CGPoint location=[touch locationInView:touch.view];
		location=[[CCDirector sharedDirector] convertToGL:location];
		
		CGSize winSize=[[CCDirector sharedDirector] winSize];
		location.x/=winSize.width;
		
		//square it away:
		//		location.y-=winSize.width/2;
		
		location.y/=winSize.height;
		
		NSLog(@"%@",NSStringFromCGPoint(location));
		gFlotte->setWave(location.x, location.y, 500);
    }
	
	
}

@end
