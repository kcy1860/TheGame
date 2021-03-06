#import "PlayBackgroundLayer.h"
#import "Constants.h"

@implementation PlayBackgroundLayer
-(id) init{
	self = [super init];
	if(nil == self){
		return nil;
	}
	
	self.isTouchEnabled = YES;
	
	CCSprite *bg = [CCSprite spriteWithFile: @"background.png"];
    if(!isRetina)
    {
        [bg setScale:0.5f];
    }
    bg.position = ccp(160,240);
    
   
	[self addChild: bg z:0];
	
	return self;
}
@end
