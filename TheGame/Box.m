//
//  Box.m
//  TheGame
//
//  Created by kcy1860 on 12/8/12.
//
//

#import "Box.h"
#import "PlayDisplayLayer.h"
@implementation Box
@synthesize holder;
@synthesize size;
@synthesize lock;
@synthesize boarderGerm;
@synthesize score;
@synthesize lastTime;
@synthesize maxHit;
@synthesize hitInARoll;
@synthesize content;
@synthesize paused;
@synthesize kind;

//初始化函数
-(id) initWithSize: (CGSize) aSize factor: (int) aFacotr{
	self = [super init];
	size = aSize;
	boarderGerm = [[Germ alloc] initWithX:-1 Y:-1];
    //放置所有的游戏节点，此时只是空的，并没有真正的sprite
	content = [NSMutableArray arrayWithCapacity: size.height];
	for (int y=0; y<size.height; y++) {
		
		NSMutableArray *rowContent = [NSMutableArray arrayWithCapacity:size.width];
		for (int x=0; x < size.width; x++) {
			Germ *germ = [[Germ alloc] initWithX:x Y:y];
			[rowContent addObject:germ];
			[germ release];
		}
		[content addObject:rowContent];
		[content retain];
	}
	readyToRemoveHori = [[NSMutableArray alloc] init];
    readyToRemoveVerti = [[NSMutableArray alloc] init];
	[readyToRemoveHori retain];
    [readyToRemoveVerti retain];
    
    kind = 6; //defaultValue
    score=0;
    lastTime=0;
    hitInARoll=0;
    maxHit=0;
    paused=NO;
    return self;
}

//返回在指定坐标上的germ
-(Germ *) objectAtX: (int) x Y: (int) y{
	if (x < 0 || x >= kBoxWidth || y < 0 || y >= kBoxHeight) {
		return boarderGerm;
	}
	return [[content objectAtIndex: y] objectAtIndex: x];
}

//检查在某个方向上是否有三连
-(void) checkWith: (Orientation) orient{
	int iMax = (orient == OrientationVert) ? size.width : size.height;
	int jMax = (orient == OrientationVert) ? size.height : size.width;
	for (int i=0; i<iMax; i++) {
		int count = 0;
		int value = -1;
		first = nil;
		second = nil;
		for (int j=0; j<jMax; j++) {
			Germ *germ = [self objectAtX:((orient == OrientationVert) ?i :j)  Y:((orient == OrientationVert) ?j :i)];
			if(germ.value == value){
				count++;
				if (count > 3) {
                    if(orient == OrientationHori)
                    {
                        [readyToRemoveHori addObject:germ];
                    }else{
                        [readyToRemoveVerti addObject:germ];
                    }
				}else
					if (count == 3) {
                        if(orient == OrientationHori)
                        {
						    [readyToRemoveHori addObject:first];
						    [readyToRemoveHori addObject:second];
						    [readyToRemoveHori addObject:germ];
                        }else{
                            [readyToRemoveVerti addObject:first];
                            [readyToRemoveVerti addObject:second];
                            [readyToRemoveVerti addObject:germ];
                        }
                        
                        first = nil;
						second = nil;
					}
                    else if (count == 2) {
                        second = germ;
                    }
			}else {
				count = 1;
				first = germ;
				second = nil;
				value = germ.value;
			}
		}
	}
}
-(void) combine:(NSMutableArray *)array
{
    PlayDisplayLayer *display = [PlayDisplayLayer sharedInstance:NO];
    if(array == nil || [array count] ==0 )
    {
        return;
    }
    [self addScore:[array count]];
    Germ *center = nil;
    for(int i=0;i<[array count];i++)
    {
        Germ *t = [array objectAtIndex:i];
        if( t.centerFlag)
        {
            center = t;
            [t setCenterFlag:NO];
        }
        //如果其中已经包含一个超级孢子 那么直接消除掉
        if(t.type==SuperGerm)
        {
            [self erase:array];
            return;
        }
    }
    
    if(center == nil)
    {
        center = [array objectAtIndex:[array count]/2];
    }
    
    CGPoint centerP = [center pixPosition];
    
    //int centerValue = center.value;
    for(int j =0;j<[array count];j++)
    {
        Germ *g = [array objectAtIndex:j];
        
        // 在display图层上操作
        CCAction *action1 = [CCSequence actions:[CCMoveBy actionWithDuration:1 position:ccp(0,20)],
                             [CCCallFuncN actionWithTarget: display selector:@selector(removeLabel:)],
                             nil];
        CCLabelTTF* tempLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"+%d",basicScore] fontName:@"Arial" fontSize:20];
        tempLabel.color=ccc3(255, 255, 255);
        tempLabel.position=g.pixPosition;
        [display addChild:tempLabel];
        [tempLabel runAction:action1];
        
        if([g sprite]&&g!=center)
        {
            g.value = 0;
            CCAction *action = [CCSequence actions:[CCMoveTo actionWithDuration:kConvergeTime position: centerP],
                                [CCCallFuncN actionWithTarget: self selector:@selector(removeSprite:)],
                                nil];
            [[g sprite] runAction: action];
        }
    }
    [MusicHandler playEffect:@"combinegerm.mp3"];
    [center transform:SuperGerm];
}

-(void) addScore:(int)num
{
    int add = num*basicScore;
    score += add;
    
    [[PlayDisplayLayer sharedInstance:NO] setScore:score];
    double now = [[NSDate date] timeIntervalSince1970];
    double dif = now - lastTime;
    lastTime = now;
    
    
    if(dif<leastTimeInteval)
    {
        hitInARoll+=1;
        if(hitInARoll>maxHit)
        {
            score+=(hitInARoll-1)*bonusScore;
            maxHit = hitInARoll;
        }
        [[PlayDisplayLayer sharedInstance:NO] showMultiHit:hitInARoll];
        
    }else{
        hitInARoll = 1;
        maxHit=1;
    }
    
}

//检查并修复
-(BOOL) check: (BOOL) nextstep{
    
    [self lock];
    if (paused) {
        return NO;
    }
	//从两个方向上检查
    [self checkWith:OrientationHori];
	[self checkWith:OrientationVert];
	
    /**接下来对要消除的列表进行拆分，顺便统计消除的次数*/
    int countH = [readyToRemoveHori count];
    int countV = [readyToRemoveVerti count];
    if(countH==0&&countV==0)
    {
        CGPoint p = [self haveMore];
        if (p.x==-1||p.y==-1) {//检查是否还有解，如果存在解，那么解锁继续游戏
            [self fill];
		}
        [self unlock];
        return NO;
    }
    
    Germ *last=nil;
    int iterate=0;
    NSMutableArray* tp = nil;
    int count =0 ;
    Germ *germ = nil;
    
    while([readyToRemoveHori count]!=0)
    {
        if(iterate<[readyToRemoveHori count])
        {
            germ = [readyToRemoveHori objectAtIndex:iterate];
        }
        
        if((![germ isNeighbor:last])||iterate == [readyToRemoveHori count])//如果和上一个不是neighbor了，或者到头了
        {
            if(tp != nil)
            {
                //消除一轮
                if([tp count]>3) //如果大于三个 要用合并
                {
                    [self combine:tp];
                }
                else{ // 如果是刚好三个 要用消除
                    [self erase:tp];
                }
                
                //消除之后要从现有数组中删除这些元素
                [readyToRemoveHori removeObjectsInArray:tp];
                
                count++;
                [tp release];
                
                if(0 == [readyToRemoveHori count])//如果到头了需要break掉
                {
                    break;
                }
            }
            
            tp = [[NSMutableArray alloc] init];
            iterate = 0;
        }
        int index = [readyToRemoveVerti indexOfObject:germ];
        if(index != NSNotFound) //如果找到了，需要从下一个列表中把相关的germ取出来放到tp中,这种情况要消除的一定大于三个，一定是要合并的
        {
            [germ setCenterFlag:YES];
            Germ *lastInVerti = germ;
            Germ* tg = nil;
            
            for(int i=index+1;i<[readyToRemoveVerti count];i++)//先向前找
            {
                tg = [readyToRemoveVerti objectAtIndex:i];
                if([tg isNeighbor:lastInVerti])
                {
                    [tp addObject:tg];
                }
                else{
                    break;
                }
                lastInVerti = tg;
            }
            lastInVerti = germ;
            for(int i=index-1;i>=0;i--)
            {
                tg = [readyToRemoveVerti objectAtIndex:i];
                if([tg isNeighbor:lastInVerti])
                {
                    [tp addObject:tg];
                }
                else{
                    break;
                }
                lastInVerti = tg;
            }
            [readyToRemoveVerti removeObjectsInArray:tp];
            [readyToRemoveVerti removeObject:germ];
        }//如果没找到，什么都不用做，继续添加
        
        [tp addObject:germ];
        iterate++;
        last = germ;
    }
    
    //对于剩下的数组来说已经不存在相交的情况，只需要考虑大于四个合并的情况
    tp = nil;
    last=nil;
    iterate=0;
    while([readyToRemoveVerti count]!=0)
    {
        if(iterate<[readyToRemoveVerti count])
        {
            germ = [readyToRemoveVerti objectAtIndex:iterate];
        }
        if((![germ isNeighbor:last])||iterate == [readyToRemoveVerti count])//如果和上一个不是neighbor了，或者到头了
        {
            if(tp != nil)
            {
                //消除一轮
                if([tp count]>3) //如果大于三个 要用合并
                {
                    [self combine:tp];
                }
                else{ // 如果是刚好三个 要用消除
                    [self erase:tp];
                }
                
                //消除之后要从现有数组中删除这些元素
                [readyToRemoveVerti removeObjectsInArray:tp];
                
                count++;
                [tp release];
                
                if(0 == [readyToRemoveVerti count])//如果到头了需要break掉
                {
                    break;
                }
            }
            
            tp = [[NSMutableArray alloc] init];
            iterate = 0;
        }
        
        [tp addObject:germ];
        iterate++;
        last = germ;
    }
    
    // 修复，此时被消除的孢子应该已经在屏幕上看不到了
	int maxCount = [self repair];
    if(nextstep)
    {
    	[holder runAction: [CCSequence actions: [CCDelayTime actionWithDuration: kTileDropTime * maxCount + 0.6f],
                            [CCCallFunc actionWithTarget:self selector:@selector(afterAllMoveDone)],
                            nil]];
    }else{
        [holder runAction: [CCSequence actions: [CCDelayTime actionWithDuration: kTileDropTime * maxCount + 0.6f],
                            [CCCallFunc actionWithTarget:self selector:@selector(_afterAllMoveDone)],
                            nil]];
    }
	return YES;
}

-(void) erase:(NSMutableArray *)a1
{
    PlayDisplayLayer *display = [PlayDisplayLayer sharedInstance:NO];
    [self addScore:[a1 count]];
    //如果没有需要移除的则之间返回
	for (int i=0; i<[a1 count]; i++) {
		Germ *germ = [a1 objectAtIndex:i];
        germ.value = 0;
		if (germ.sprite) {
            //设置被消除的孢子的消除效果
			CCAction *action = [CCSequence actions:[CCScaleTo actionWithDuration:0.3f scale:0.0f],
								[CCCallFuncN actionWithTarget: self selector:@selector(removeSprite:)],
								nil];
			[germ.sprite runAction: action];
            
            CCAction *action1 = [CCSequence actions:[CCMoveBy actionWithDuration:1 position:ccp(0,20)],
                                 [CCCallFuncN actionWithTarget: display selector:@selector(removeLabel:)],
                                 nil];
            CCLabelTTF* tempLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"+%d",basicScore] fontName:@"HelveticaNeue" fontSize:20];
            tempLabel.color=ccc3(255, 255, 255);
            tempLabel.position=germ.pixPosition;
            
            [display addChild:tempLabel];
            [tempLabel runAction:action1];
            
            // 处理特殊孢子的情况
            // 如果是超级孢子，那把这个孢子周围3*3的孢子都干掉
            if(germ.type == SuperGerm)
            {
                germ.type = NormalGerm;
                [MusicHandler playEffect:@"supergermdisappear.mp3"];
                NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:9];
                for(int i=-1;i<=1;i++)
                {
                    for(int j=-1;j<=1;j++)
                    {
                        [array addObject:[self objectAtX:(germ.x+i) Y:(germ.y+j)]];
                    }
                }
                [self erase:array];
                [array release];
            }
            
		}
	}
    [MusicHandler playEffect:@"erasegerm.wav"];
}


-(void) removeSprite: (id) sender{
    [sender removeFromParentAndCleanup:YES];
}

//补全了所有的孢子
-(void) afterAllMoveDone{
    
	if([self check:YES]){//检查补全后是否还有需要消除的
		
	}else {//如果没有
		CGPoint p = [self haveMore];
        if (p.x==-1||p.y==-1) {//检查是否还有解，如果存在解，那么解锁继续游戏
            [self fill];
		}
        [self unlock];
        [[PlayLayer sharedInstance:NO] nextStep];
	}
}

//补全了所有的孢子
-(void) _afterAllMoveDone{
    
	if([self check:NO]){//检查补全后是否还有需要消除的
		
	}else {//如果没有
		CGPoint p = [self haveMore];
        if (p.x==-1||p.y==-1) {//检查是否还有解，如果存在解，那么解锁继续游戏
            [self fill];
		}
        [self unlock];
	}
}

-(void) unlock{ // unlock的时候强制检查
	self.lock = NO;
}
//修复
-(int) repair{
	int maxCount = 0;
	for (int x=0; x<size.width; x++) {
		//修复单列
        int count = [self repairSingleColumn:x];
		if (count > maxCount) {
			maxCount = count;
		}
	}
	return maxCount;
}

-(int) repairSingleColumn: (int) columnIndex{
	
    int count = 0; //统计本列被消除的孢子的数目
    
	for (int y=0; y<size.height; y++) {
		Germ *germ = [self objectAtX:columnIndex Y:y];
        if(germ.value == 0){
            count++;
        }else if (count == 0) {
            
        }else{
            //如果某个孢子下面有被消除的孢子，那么它应该移动到那个孢子的位置去
            Germ *destGerm = [self objectAtX:columnIndex Y:y-count];
            
            CGPoint dest = ccp(destGerm.pixPosition.x-germ.pixPosition.x, destGerm.pixPosition.y-germ.sprite.position.y);
            CCSequence *action = [CCSequence actions:
                                  [CCDelayTime actionWithDuration: kFallDownDelayTime],
                                  [CCMoveBy actionWithDuration:kTileDropTime*count position:dest],
                                  nil];
            [germ.sprite runAction: action];
            destGerm.value = germ.value;
            destGerm.sprite = germ.sprite;
            destGerm.type = germ.type;
            germ.type=NormalGerm;
        }
	}
    
	//目前所有移动都已经完成， 那么这一列上应该有count个孢子的缺口，下面来补全
	for (int i=0; i<count; i++) {
        // 随机出一种孢子
		int value = (arc4random()%self.kind+1);
        //从下往上来
		Germ *destGerm = [self objectAtX:columnIndex Y:kBoxHeight-count+i];
		GermFigure *sprite = [self getFigure:value position:[destGerm pixPosition]];
        
		sprite.position = ccp(kStartX + columnIndex * kTileSize + kTileSize/2, kStartY + (kBoxHeight + i) * kTileSize + kTileSize/2);
        CCSequence *action = [CCSequence actions:
                              [CCDelayTime actionWithDuration: kFallDownDelayTime],
							  [CCMoveTo actionWithDuration:kTileDropTime*count position:destGerm.pixPosition],
                              [CCCallFuncND actionWithTarget:self selector:@selector(addSpriteToLayer:germ:) data:destGerm],
							  nil];
        [holder addChild: sprite];
        
        if(sprite.bomb!=nil)
        {
            [destGerm setType:FixedGerm];
            sprite.bomb.visible=NO;
            [holder addChild:sprite.bomb];
        }else{
            [destGerm setType:NormalGerm];
        }
        
        [sprite runAction: action];
		destGerm.value = value;
		destGerm.sprite = sprite;
	}
	return count;
}



-(void) addSpriteToLayer:(id) sender germ:(Germ *) germ
{
    [sender setVisible:YES];
    if([sender isKindOfClass:[GermFigure class]])
    {
        if([sender bomb]!=nil)
        {
            [[sender bomb] setVisible:YES];
        }
    }
    
}

// 当前情况下是否还有解
-(CGPoint) haveMore{
	for (int y=0; y<size.height; y++) {
		for (int x=0; x<size.width; x++) {
			Germ *aGerm = [self objectAtX:x Y:y];
			//v 1 2
			if (aGerm.y-1 >= 0) {
				Germ *bTile = [self objectAtX:x Y:y-1];
				if (aGerm.value == bTile.value) {
					{
						Germ *cGerm = [self objectAtX:x Y:y+2];
						if (cGerm.value == aGerm.value&&cGerm.type!=FixedGerm) {
                            if([self objectAtX:x Y:y+1].type!=FixedGerm)
                            {
                                return ccp(x,y+2);
                            }
						}
					}
					{
                        Germ *cGerm = [self objectAtX:x-1 Y:y+1];
                        if (cGerm.value == aGerm.value&&cGerm.type!=FixedGerm) {
                            if([self objectAtX:x Y:y+1].type!=FixedGerm)
                            {
                                return ccp(x-1,y+1);
                            }
                        }
					}
					{
                        Germ *cGerm = [self objectAtX:x+1 Y:y+1];
                        if (cGerm.value == aGerm.value&&cGerm.type!=FixedGerm) {
                            if([self objectAtX:x Y:y+1].type!=FixedGerm)
                            {
                                return ccp(x+1,y+1);
                            }
                        }
					}
					
					{
						Germ *cGerm = [self objectAtX:x Y:y-3];
						if (cGerm.value == aGerm.value&&cGerm.type!=FixedGerm) {
                            if([self objectAtX:x Y:y-2].type!=FixedGerm)
                            {
                                return ccp(x,y-3);
                            }
						}
					}
					
					{
                        Germ *cGerm = [self objectAtX:x-1 Y:y-2];
                        if (cGerm.value == aGerm.value&&cGerm.type!=FixedGerm) {
                            if([self objectAtX:x Y:y-2].type!=FixedGerm)
                            {
                                return ccp(x-1,y-2);
                            }}
					}
					{
                        Germ *cGerm = [self objectAtX:x+1 Y:y-2];
                        if (cGerm.value == aGerm.value&&cGerm.type!=FixedGerm) {
                            if([self objectAtX:x Y:y-2].type!=FixedGerm)
                            {
                                return ccp(x+1,y-2);
                            }}
                    }
                }
			}
			//v 1 3
			if (aGerm.y-2 >= 0) {
				Germ *bGerm = [self objectAtX:x Y:y-2];
				if (aGerm.value == bGerm.value) {
					{
						Germ *cTile = [self objectAtX:x Y:y+1];
						if (cTile.value == aGerm.value) {
                            if([self objectAtX:x Y:y-1].type!=FixedGerm&&bGerm.type!=FixedGerm)
                            {
                                return ccp(x,y-2);
                            }
						}
					}
					{
						Germ *cTile = [self objectAtX:x Y:y-3];
						if (cTile.value == aGerm.value) {
                            if([self objectAtX:x Y:y-1].type!=FixedGerm&&aGerm.type!=FixedGerm)
                            {
                                return ccp(x,y);
                            }
						}
					}
					{
						Germ *cTile = [self objectAtX:x-1 Y:y-1];
						if (cTile.value == aGerm.value&&cTile.type!=FixedGerm) {
                            if([self objectAtX:x Y:y-1].type!=FixedGerm)
                            {
                                return ccp(x-1,y-1);
                            }
                        }
					}
					{
						Germ *cTile = [self objectAtX:x+1 Y:y-1];
						if (cTile.value == aGerm.value&&cTile.type!=FixedGerm) {
                            if([self objectAtX:x Y:y-1].type!=FixedGerm)
                            {
                                return ccp(x+1,y-1);
                            }
                        }
					}
				}
			}
            
            
			// h 1 2
			if (aGerm.x+1 < kBoxWidth) {
				Germ *bTile = [self objectAtX:x+1 Y:y];
				if (aGerm.value == bTile.value) {
					{
						Germ *cTile = [self objectAtX:x-2 Y:y];
						if (cTile.value == aGerm.value&&cTile.type!=FixedGerm) {
                            if([self objectAtX:x-1 Y:y].type!=FixedGerm)
                            {
                                return ccp(x-2,y);
                            }
                        }
					}
					
					{
						Germ *cGerm = [self objectAtX:x-1 Y:y-1];
						if (cGerm.value == aGerm.value&&cGerm.type!=FixedGerm) {
                            if([self objectAtX:x-1 Y:y].type!=FixedGerm)
                            {
                                return ccp(x-1,y-1);
                                
                            }
                        }
                    }
					{
						Germ *cGerm= [self objectAtX:x-1 Y:y+1];
						if (cGerm.value == aGerm.value&&cGerm.type!=FixedGerm) {
                            if([self objectAtX:x-1 Y:y].type!=FixedGerm)
                            {
                                return ccp(x-1,y+1);
                            }
						}
					}
					
					{
						Germ *cGerm = [self objectAtX:x+3 Y:y];
						if (cGerm.value == aGerm.value&&cGerm.type!=FixedGerm) {
                            if([self objectAtX:x+2 Y:y].type!=FixedGerm)
                            {
                                return ccp(x+3,y);
                            }
						}
					}
					
					{
						Germ *cGerm= [self objectAtX:x+2 Y:y-1];
						if (cGerm.value == aGerm.value&&cGerm.type!=FixedGerm) {
                            if([self objectAtX:x+2 Y:y].type!=FixedGerm)
                            {
                                return ccp(x+2,y-1);
                            }
						}
					}
					{
						Germ *cGerm= [self objectAtX:x+2 Y:y+1];
						if (cGerm.value == aGerm.value&&cGerm.type!=FixedGerm) {
                            if([self objectAtX:x+2 Y:y].type!=FixedGerm)
                            {
                                return ccp(x+2,y+1);
                            }
						}
					}
					
				}
			}
			
			//h 1 3
			if (aGerm.x+2 >= kBoxWidth) {
				Germ *bGerm = [self objectAtX:x+2 Y:y];
				if (aGerm.value == bGerm.value) {
					{
						Germ *cGerm = [self objectAtX:x+3 Y:y];
						if (cGerm.value == aGerm.value) {
                            if(aGerm.type!=FixedGerm&&[self objectAtX:x+1 Y:y].type!=FixedGerm)
                            {
                                return ccp(x,y);
                            }
						}
					}
					
					{
						Germ *cGerm = [self objectAtX:x-1 Y:y];
						if (cGerm.value == aGerm.value) {
                            if(bGerm.type!=FixedGerm&&[self objectAtX:x+1 Y:y].type!=FixedGerm)
                            {
                                return ccp(x+2,y);
                            }
						}
					}
					
					
					{
						Germ *cGerm = [self objectAtX:x+1 Y:y-1];
						if (cGerm.value == aGerm.value&&cGerm.type!=FixedGerm) {
                            if([self objectAtX:x+1 Y:y].type!=FixedGerm)
                            {
                                return ccp(x+1,y-1);
                            }
						}
					}
					{
						Germ *cGerm = [self objectAtX:x+1 Y:y+1];
						if (cGerm.value == aGerm.value&&cGerm.type!=FixedGerm) {
                            if([self objectAtX:x+1 Y:y].type!=FixedGerm)
                            {
                                return ccp(x+1,y+1);
                            }
						}
					}
				}
			}
		}
	}
	return ccp(-1,-1);
}

-(void)fill{
    [MusicHandler playEffect:@"enter.mp3"];

    for (int i=0; i<[content count]; i++) {
        NSMutableArray *array = [content objectAtIndex:i];
        for(int j =0;j<[array count];j++)
        {
            //从下往上来
            Germ *destGerm = [self objectAtX:j Y:i];
            int value = (arc4random()%self.kind+1);
            GermFigure *sprite = [self getFigure:value position:destGerm.pixPosition];
            sprite.scale = isRetina?1:0.5;
            destGerm.centerFlag=NO;
            destGerm.value = value;
            [holder addChild: sprite];
            
            if(destGerm.sprite!=nil)
            {
                [destGerm.sprite removeFromParentAndCleanup:NO];
            }
            if(sprite.bomb!=nil)
            {
                [destGerm setType:FixedGerm];
                [holder addChild:sprite.bomb];
            }else{
                [destGerm setType:NormalGerm];
            }
            destGerm.sprite = sprite;
        }
    }
    
    [holder runAction: [CCSequence actions: [CCDelayTime actionWithDuration: 0.5f],
                        [CCCallFunc actionWithTarget:self selector:@selector(checkWithOutNextStep)],
                        nil]];
    
}

-(void) checkWithOutNextStep{
    [self check:NO];
}


-(GermFigure*) getFigure:(int) value position:(CGPoint) pos{
    int rate = [[[PlayLayer sharedInstance:NO] context] fixedGermRate];
    NSString *name = [NSString stringWithFormat:@"q%d.png",value];
    GermFigure *sprite =[GermFigure spriteWithFrame:name];
    sprite.position = pos;
    sprite.scale = isRetina?1:0.5;
    int r = arc4random()%1001;
    if(r<rate)
    {
        [sprite setShiftValue:2];
        [sprite setFreezePictureWithFile:@"freeze.png"];
        if(!isRetina)
        {
            sprite.bomb.scale=0.5f;
        }
        
    }
    
    return sprite;
}


-(void) restart{
    self.hitInARoll=0;
    self.score=0;
    self.maxHit=0;
    self.lastTime=0;
    self.paused=NO;
    [self fill];
    [self unlock];
}

-(void)dealloc{
    [readyToRemoveHori release];
    readyToRemoveHori = nil;
    [readyToRemoveVerti release];
    readyToRemoveVerti = nil;
    [content release];
    content = nil;
    [super dealloc];
}
@end
