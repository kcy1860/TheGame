#import "MainMenuLayer.h"


@implementation MainMenuLayer

int clickCount;
-(id) init{
	self = [super init];
	CGSize winSize = [CCDirector sharedDirector].winSize;
    CCSprite* background = [CCSprite spriteWithFile:@"start_bg.png"];
    background.position=ccp(winSize.width*0.5f,winSize.height*0.5f);
    
    CCSprite *sun = [CCSprite spriteWithFile:@"sun.png"];
    CCSprite *sunray = [CCSprite spriteWithFile:@"sun_ray.png"];
    sun.position = ccp(winSize.width*0.23,winSize.height*0.822);
    sunray.position = ccp(winSize.width*0.23,winSize.height*0.82);
    
    CCAction *rotate = [CCRepeatForever actionWithAction:[CCRotateBy actionWithDuration:5 angle:180]];
    [self addChild:sunray z:1];
    [self addChild:sun z:1 tag:colorEggTag];
    [sunray runAction:rotate];
    
    
    UserProfile *pro = [UserProfile sharedInstance];
    CCSprite *music=nil;
    if(pro.silence){
        [MusicHandler setSilence:YES];
        music = [CCSprite spriteWithFile:@"sounddown_bt.png"];
    }else{
        music = [CCSprite spriteWithFile:@"sound_bt.png"];
    }
    music.position = ccp(winSize.width*0.27f,winSize.height*0.21f);
    [self addChild:music z:1 tag:musicTag];
    
    CCSprite* like = [CCSprite spriteWithFile:@"likeus_bt.png"];
    like.position = ccp(winSize.width*0.73f,winSize.height*0.21f);
    [self addChild:like z:1 tag:likeusTag];
    CCSprite *title = [CCSprite spriteWithFile:@"title.png"];
    title.scale=0;
    
    [self addChild:background];
    
	
    CCSprite *l = [CCSprite spriteWithFile:@"mn_level.png"];
    CCSprite *ls = [CCSprite spriteWithFile:@"mn_level.png"];
    
    CCSprite *i = [CCSprite spriteWithFile:@"mn_endless.png"];
    CCSprite *is = [CCSprite spriteWithFile:@"mn_endless.png"];
    
    CCSprite *m = [CCSprite spriteWithFile:@"mn_moregame.png"];
    CCSprite *ms = [CCSprite spriteWithFile:@"mn_moregame.png"];
    
    CCSprite *h = [CCSprite spriteWithFile:@"mn_help.png"];
    CCSprite *hs = [CCSprite spriteWithFile:@"mn_help.png"];

    ls.color=ccc3(80,80,80);
    is.color=ccc3(80,80,80);
    ms.color=ccc3(80,80,80);
    hs.color=ccc3(80,80,80);

    CCMenuItemSprite *startNew = [CCMenuItemSprite  itemWithNormalSprite:l selectedSprite:ls target:self selector:@selector(onStartNew:)];
    CCMenuItemSprite *resume = [CCMenuItemSprite  itemWithNormalSprite:i selectedSprite:is target:self selector:@selector(onInfiniteMode:)];
    CCMenuItemSprite *highscores = [CCMenuItemSprite  itemWithNormalSprite:m selectedSprite:ms target:self selector:@selector(onOtherGames:)];
    CCMenuItemSprite *mygerms = [CCMenuItemSprite  itemWithNormalSprite:h selectedSprite:hs target:self selector:@selector(onHelp:)];

    if(!isRetina)
    {
        startNew.scale=0.5f;
        resume.scale=0.5f;
        highscores.scale=0.5f;
        mygerms.scale=0.5;
        
        background.scale=0.5f;
        music.scale=0.5f;
        like.scale=0.5f;
        sun.scale=0.5f;
        sunray.scale=0.5f;
    }
	menu = [CCMenu menuWithItems:startNew, resume, highscores, mygerms, nil];
    
    
    title.position = ccp(winSize.width*0.5, winSize.height*0.78);
	CCAction *titleAction = [CCSequence actions:
                             [CCDelayTime actionWithDuration: 0.3f],
                             [CCScaleTo actionWithDuration: 0.5 scale:isRetina?1:0.5f],
                             nil];
	
    [self addChild: title z:3];
    [title runAction:titleAction];
    
    float delayTime = 0.3f;
	for (CCMenuItemFont *each in [menu children]) {
		each.scale=0;
        CCAction *action = [CCSequence actions:
                            [CCDelayTime actionWithDuration: delayTime],
                            [CCScaleTo actionWithDuration:0.5F scale:isRetina?1:0.5],
                            nil];
		delayTime += 0.2f;
		[each runAction: action];
	}
	menu.position = ccp(winSize.width*0.5, winSize.height*0.49);
    [menu alignItemsVerticallyWithPadding: 50.0f];
	[self addChild:menu z:1 tag:mainmenuTag];
	
    self.isTouchEnabled = YES;
	return self;
    
}

-(void) onEnterTransitionDidFinish{
    [MusicHandler playMainBackground];
}

- (void)onStartNew:(id)sender{
    [MusicHandler playEffect:@"button.mp3"];
    [SceneManager goLevelChoose];
}
- (void)onInfiniteMode:(id)sender{
    [MusicHandler playEffect:@"button.mp3"];
	[SceneManager goGameModeChoose];
}

- (void)onOtherGames:(id)sender{
    [MusicHandler playEffect:@"button.mp3"];
    [MobClick event:@"clickmoreapp"];
    [SceneManager goRecommand];
}
- (void)onHelp:(id)sender{
    [MusicHandler playEffect:@"button.mp3"];
	[SceneManager goHelp];
}

-(void) enableMenu:(BOOL) flag{
    menu = (CCMenu*)[self getChildByTag:mainmenuTag];
    menu.enabled=flag;
}

-(void) ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    UITouch* touch = [touches anyObject];
	CGPoint location = [touch locationInView: touch.view];
    CGSize winSize = [CCDirector sharedDirector].winSize;

	location = [[CCDirector sharedDirector] convertToGL: location];
    
    CCNode *node = [self getChildByTag:likeusTag];
    
    if(node!=nil&&CGRectContainsPoint([node boundingBox], location))
    {
        [MusicHandler playEffect:@"button.mp3"];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://itunes.apple.com/us/app/napkin-concise-image-annotation/id581789185?mt=12"]];
        
    }
    
    node = [self getChildByTag:musicTag];
    if(node!=nil&&CGRectContainsPoint([node boundingBox], location))
    {
        [MusicHandler playEffect:@"button.mp3"];
        [node removeFromParentAndCleanup:YES];
        UserProfile *pro = [UserProfile sharedInstance];
        CCSprite *music=nil;
        
        if(pro.silence)
        {
            [pro setSilence:NO];
            [MusicHandler setSilence:NO];
            music = [CCSprite spriteWithFile:@"sound_bt.png"];
            
        }else{
            [pro setSilence:YES];
            [MusicHandler setSilence:YES];
            music = [CCSprite spriteWithFile:@"sounddown_bt.png"];
        }
        
     //   [UserProfile writeBackToFile];
        if(!isRetina)
        {
            music.scale=0.5f;
        }
        music.position = ccp(winSize.width*0.27f,winSize.height*0.21f);
        [self addChild:music z:1 tag:musicTag];
    }
    
    node = [self getChildByTag:colorEggTag];
    if(node!=nil&&CGRectContainsPoint([node boundingBox], location))
    {
        clickCount++;
        if(clickCount==3)
        {
            clickCount=0;
            UIAlertView*alert = [[UIAlertView alloc]initWithTitle:@"宅男福利~"
                                                      message:@"主页下面的QQ号是单身大美女哦~~"
                                                     delegate:nil
                                            cancelButtonTitle:@"确定"
                                            otherButtonTitles:nil]; 
            [alert show];
        
            [alert release];
        }
    }else{
        clickCount=0;
    }

}
@end
