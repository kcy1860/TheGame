#import "PlayLayer.h"

@interface PlayLayer()
-(void)afterOneShineTrun: (id) node;

@end

@implementation PlayLayer
@synthesize context = _context;
@synthesize stepCount=_stepCount;
@synthesize box;
int lastHit;
int clickcount;
bool paused;
bool flag;
static PlayLayer* thisLayer;

+(PlayLayer*) sharedInstance:(BOOL) refresh
{
    if(thisLayer!=nil&&refresh)
    {
        //[thisLayer release];
        thisLayer =nil;
    }
    if(thisLayer==nil)
    {
        thisLayer = [PlayLayer node];
    }
    
    return thisLayer;
}


-(id) init{
	self = [super init];
	box = [[Box alloc] initWithSize:CGSizeMake(kBoxWidth,kBoxHeight) factor:6];
	box.holder = self;
	box.lock = YES;
    _stepCount=0;
    self.isTouchEnabled = YES;
    lastHit = 0;
    clickcount=0;
    paused=NO;
    flag = YES;
	return self;
}

-(void) pauseGame{
    paused=YES;
    [self pauseSchedulerAndActions];
    [box setPaused:YES];
}

-(void) resumeGame{
    paused=NO;
    [self resumeSchedulerAndActions];
    [box setPaused:NO];
}

-(void) onEnterTransitionDidFinish{

    [MusicHandler playGameBackground];
    // 统计部分的代码
    GameContext *c = self.context;

    switch(c.type){
        case Poisonous:
        case TimeBomb:
        case Bomb:
            [MobClick beginEvent:@"playInfiniteMode"];
            break;
        case Classic:
            [MobClick event:@"playlevelmode" label:[NSString stringWithFormat:@"%d",c.level]];
            break;
        default:
            break;
    }

    [box fill];
    [box unlock];
}

-(void) onExitTransitionDidStart{
    GameContext *c = self.context;
    switch(c.type){
        case Poisonous:
        case TimeBomb:
        case Bomb:
            [MobClick endEvent:@"playInfiniteMode"];
            break;
        default:
            break;
    }
}

-(void) checkPosition
{
    NSMutableArray *content = [box content];
    for (int i=0; i<[content count]; i++) {
        NSMutableArray *array = [content objectAtIndex:i];
        for(int j =0;j<[array count];j++)
        {
            Germ *g= [array objectAtIndex:j];
            [g.sprite resetPosition:g.pixPosition];
        }
    }
}

-(void) checkPos:(id) sender data: (Germ*) g
{
    [g.sprite resetPosition:g.pixPosition];
}

-(void) checkBox{
    [box check:NO];
}

-(void) resetWithContext:(GameContext *)context refresh:(BOOL) fresh
{
    _context = context;
    [[PlayDisplayLayer sharedInstance:NO] setWithContext:context];

    [box setKind:context.kindCount];
    
}
-(BOOL) hint
{
    CGPoint point = [box haveMore];
    if(point.x<0||point.y<0)
    {
        return NO;
    }
    Germ *tile = [box objectAtX:point.x Y:point.y];
    if(selected == tile)
    {
        return YES;
    }
    selected = tile;
    [self afterOneShineTrun:tile.sprite];
    return YES;
}

-(void) reload
{
    [box fill];
    [box unlock];
}

- (void)ccTouchesBegan:(NSSet*)touches withEvent:(UIEvent*)event{
	if ([box lock]) {
		return;
	}
	
	UITouch* touch = [touches anyObject];
	CGPoint location = [touch locationInView: touch.view];
	location = [[CCDirector sharedDirector] convertToGL: location];
	
    int difX = location.x -kStartX;
    int difY = location.y -kStartY;

    
    if(paused||difY<0)//如果被暂定 就直接返回
    {
        return;
    }
	int x = difX / kTileSize;
	int y = difY / kTileSize;
    
	
	//如果两次选到的是同一个 直接返回
	if (selected && selected.x ==x && selected.y == y) {
        clickcount++;
        if(clickcount==2)
        {
            clickcount=0;
            GermType t = PoisonousGerm;
            [selected transform:t];
            [self afterOneShineTrun:selected.sprite];
        }
		return;
	}
	clickcount=0;
    
	Germ *tile = [box objectAtX:x Y:y];
    [tile.sprite resetPosition:tile.pixPosition];
    
    if(tile.type==FixedGerm){//如果是固定孢子 直接返回
        [MusicHandler playEffect:@"disabled.mp3"];
        return;
    }
    
	if (selected && [selected isNeighbor:tile]) {
		[self changeWithTileA: selected TileB: tile sel: @selector(check:data:)];
		selected = nil;
        firstOne = nil;
	}else {
        //如果选择到的不是neighbor 相当于重新选择
        [selected.sprite stopAllActions];
        [selected.sprite runAction:[CCScaleTo actionWithDuration:0.2f scale:isRetina?1:0.5f]];
		selected = tile;
        firstOne = tile;
		[self afterOneShineTrun:tile.sprite];
	}
}

-(void) changeWithTileA: (Germ *) a TileB: (Germ *) b sel : (SEL) sel{
    [box setLock:YES];
	CGPoint pa = a.pixPosition;
    CGPoint pb = b.pixPosition;
    int difx = pa.x-pb.x;
    int dify = pa.y-pb.y;

    CCAction *actionA = [CCSequence actions:
						 [CCMoveBy actionWithDuration:kMoveTileTime position:ccp(-difx,-dify)],
						 [CCCallFuncND actionWithTarget:self selector:sel data: a],
						 nil
						 ];
	
	CCAction *actionB = [CCSequence actions:
						 [CCMoveBy actionWithDuration:kMoveTileTime position:ccp(difx,dify)],
						 [CCCallFuncND actionWithTarget:self selector:sel data: b],
						 nil
						 ];
    [MusicHandler playEffect:@"germexchange.mp3"];
    [a.sprite runAction:actionA];
	[b.sprite runAction:actionB];
    [a trade:b];
}

-(void) backCheck: (id) sender data: (id) data{
	if(nil == firstOne){
		firstOne = data;
		return;
	}
	firstOne = nil;
}
// 检查转换是否有效，如果无效则换回来
-(void) check: (id) sender data: (id) data{
	if(nil == firstOne||firstOne==data){
		firstOne = data;
		return;
	}
	BOOL result = [box check:YES];
	if (result) {
	}else {
        Germ * d =(Germ *)data;
		[self changeWithTileA:d TileB:firstOne sel:@selector(backCheck:data:)];
		[self runAction:[CCSequence actions:[CCDelayTime actionWithDuration:kMoveTileTime + 0.03f],
						 [CCCallFunc actionWithTarget:box selector:@selector(unlock)],
						 nil]];
	}
    
	firstOne = nil;
}

-(void) nextStep{
    _stepCount++;
    if(_stepCount==1000) //到达某个数目的时候重置，避免溢出
    {
        _stepCount=1;
    }
    [self checkPosition];
    NSMutableArray *content = [box content];
    BOOL hasBomb = NO;
    int poisonousCount =0 ;
    for (int i=[content count]-1; i>=0; i--) {
        NSMutableArray *array = [content objectAtIndex:i];
        for(int j =0;j<[array count];j++)
        {
            Germ *g= [array objectAtIndex:j];
            if( g.type ==PoisonousGerm )
            {
                if(i==6)
                {
                    [g transform:NormalGerm];
                    [MusicHandler playEffect:@"poisondisappear.mp3"];

                    if([[PlayDisplayLayer sharedInstance:NO] subLife])
                    {
                        [[PlayDisplayLayer sharedInstance:NO] gameOver];
                    }
                }else{
                    [self changeWithTileA:g TileB:[box objectAtX:j Y:(i+1)] sel:@selector(checkPos:data:)];
                }
                poisonousCount++;
            }
            else if(g.type == BombGerm)
            {
                hasBomb=YES;
                int i=[g.sprite nextValue];
                if(i==0)
                {
                    CGPoint pos = [[[g sprite] bomb] position];
                    [g transform:NormalGerm];
                    [MusicHandler playEffect:@"explosion.mp3"];
                    [[PlayDisplayLayer sharedInstance:NO] showExplosion:pos];
                    if([[PlayDisplayLayer sharedInstance:NO] subLife])
                    {
                        [[PlayDisplayLayer sharedInstance:NO] gameOver];
                    }
                }
            }
            
        }
    }
    
    if(poisonousCount>0){
        [self runAction: [CCSequence actions: [CCDelayTime actionWithDuration: kMoveTileTime+0.1*poisonousCount],
                          [CCCallFunc actionWithTarget:self selector:@selector(checkBox)],
                          nil]];
    }

    if(hasBomb)
    {
        [MusicHandler playEffect:@"clockhit.mp3"];
    }
    if(_context.type!=Classic && _context.interval!=0)
    {
        if(_stepCount%_context.interval==0)
        {
            // 刷新孢子
            [self changeOneGermByType:_context.type];
        }
    }
    
    
}

-(void) changeOneGermByType:(GameType) type
{
    int x = arc4random()%7;
    int y = arc4random()%7;
    
    
    GermType t = TimeBombGerm;
    switch (type) {
        case Bomb:
            t=BombGerm;
            break;
        case Poisonous:
            t =PoisonousGerm;
            y=arc4random()%3;
            break;
        default:
            break;
    }
    Germ* g = [box objectAtX:x Y:y];
    [g transform:t];
}


-(void)afterOneShineTrun: (id) node{
	if (selected&&node == selected.sprite) {
		GermFigure *sprite = (GermFigure *)node;
		CCSequence *someAction =    [CCSequence actions:
								  [CCScaleBy actionWithDuration:kShineFreq scale:0.5f],
								  [CCScaleBy actionWithDuration:kShineFreq scale:2],
								  [CCCallFuncN actionWithTarget:self selector:@selector(afterOneShineTrun:)],//重新调用 持续闪烁
                                     nil];
        
		[sprite runAction:someAction];
	}
    
}

-(void) toNextLevel:(BOOL) refresh{
    GameContext *context = [[self context] getNextLevel];
    [self resetWithContext:context refresh:refresh];
}

-(Box*) getBox{
    return box;
}

@end
