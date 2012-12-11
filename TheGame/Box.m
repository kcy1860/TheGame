//
//  Box.m
//  TheGame
//
//  Created by kcy1860 on 12/8/12.
//
//

#import "Box.h"

@interface Box()
-(int) repairSingleColumn: (int) columnIndex;
-(void) combine:(NSMutableArray *)array;
-(void) erase:(NSMutableArray*) a1;
-(void) addSpriteToLayer:(id) sender;

@end

@implementation Box
@synthesize holder;
@synthesize size;
@synthesize lock;
@synthesize boarderGerm;

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
    if(array == nil || [array count] ==0 )
    {
        return;
    }
    
    Germ *center = nil;
    for(int i=0;i<[array count];i++)
    {
        Germ *t = [array objectAtIndex:i];
        if( t.centerFlag)
        {
            center = t;
            [t setCenterFlag:NO];
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
        
        if([g sprite]&&g!=center)
        {
            g.value = 0;
            CCAction *action = [CCSequence actions:[CCMoveTo actionWithDuration:kConvergeTime position: centerP],
                                [CCCallFuncN actionWithTarget: self selector:@selector(removeSprite:)],
                                
                                nil];
            [[g sprite] runAction: action];
        }else if(g==center)
        {
            //把center变为超级孢子
            [holder removeChild:center.sprite cleanup:YES];
            [center transform:SuperGerm];
            [holder addChild:center.sprite];
        }
    }
}


//检查并修复
-(BOOL) check{
	//从两个方向上检查
    [self checkWith:OrientationHori];
	[self checkWith:OrientationVert];
	
    /**接下来对要消除的列表进行拆分，顺便统计消除的次数*/
    int countH = [readyToRemoveHori count];
    int countV = [readyToRemoveVerti count];
    if(countH==0&&countV==0)
    {
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
    
    //[readyToRemoveHori removeAllObjects];
    //[readyToRemoveVerti removeAllObjects];
    
    // 修复，此时被消除的孢子应该已经在屏幕上看不到了
	int maxCount = [self repair];
	
    //等修复完成以后，执行afterAllMoveDone的方法
	[holder runAction: [CCSequence actions: [CCDelayTime actionWithDuration: kMoveTileTime * maxCount + 0.03f],
                        [CCCallFunc actionWithTarget:self selector:@selector(afterAllMoveDone)],
                        nil]];
	return YES;
}

-(void) erase:(NSMutableArray *)a1
{
    //如果没有需要移除的则之间返回
	NSArray *objects = [[a1 objectEnumerator] allObjects];
    // 消除
	int count = [objects count];
	for (int i=0; i<count; i++) {
        
		Germ *germ = [objects objectAtIndex:i];
        germ.value = 0;
		if (germ.sprite) {
            //设置被消除的孢子的消除效果
			CCAction *action = [CCSequence actions:[CCFadeOut actionWithDuration:0.3f],
								[CCCallFuncN actionWithTarget: self selector:@selector(removeSprite:)],
								nil];
			[germ.sprite runAction: action];
		}
	}
}

-(void) removeSprite: (id) sender{
	[holder removeChild: sender cleanup:YES];
}

//补全了所有的孢子
-(void) afterAllMoveDone{
    
	if([self check]){//检查补全后是否还有需要消除的
		
	}else {//如果没有
		CGPoint p = [self haveMore];
        
        if (p.x!=-1||p.y!=-1) {//检查是否还有解，如果存在解，那么解锁继续游戏
			[self unlock];
		}else {
            //如果已经无解，那么重新初始化游戏
            [self fill];
            [self check];
		}
	}
}

-(void) unlock{
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
            Germ *destTile = [self objectAtX:columnIndex Y:y-count];
            CCSequence *action = [CCSequence actions:
                                  [CCDelayTime actionWithDuration: kFallDownDelayTime],
                                  [CCMoveBy actionWithDuration:kTileDropTime*count position:ccp(0,-kTileSize*count)],
                                  nil];
            [germ.sprite runAction: action];
            destTile.value = germ.value;
            destTile.sprite = germ.sprite;
        }
	}
    
	//目前所有移动都已经完成， 那么这一列上应该有count个孢子的缺口，下面来补全
	for (int i=0; i<count; i++) {
        // 随机出一种孢子
		int value = (arc4random()%kKindCount+1);
        //从下往上来
		Germ *destGerm = [self objectAtX:columnIndex Y:kBoxHeight-count+i];
		NSString *name = [NSString stringWithFormat:@"q%d.png",value];
		CCSprite *sprite = [CCSprite spriteWithFile:name];
		sprite.position = ccp(kStartX + columnIndex * kTileSize + kTileSize/2, kStartY + (kBoxHeight + i) * kTileSize + kTileSize/2);
		
        CCSequence *action = [CCSequence actions:
                              [CCDelayTime actionWithDuration: kFallDownDelayTime],
							  [CCMoveBy actionWithDuration:kTileDropTime*count position:ccp(0,-kTileSize*count)],
                              [CCCallFuncN actionWithTarget:self selector:@selector(addSpriteToLayer:)],
							  nil];
		[sprite setVisible:NO];
        [holder addChild: sprite];
        
        [sprite runAction: action];
		destGerm.value = value;
		destGerm.sprite = sprite;
	}
	return count;
}

-(void) addSpriteToLayer:(id) sender
{
    [sender setVisible:YES];
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
						if (cGerm.value == aGerm.value) {
							return ccp(x,y+2);
						}
					}
					{
                        Germ *cGerm = [self objectAtX:x-1 Y:y+1];
                        if (cGerm.value == aGerm.value) {
                            return ccp(x-1,y+1);
                        }
					}
					{
                        Germ *cGerm = [self objectAtX:x+1 Y:y+1];
                        if (cGerm.value == aGerm.value) {
                            return ccp(x+1,y+1);
                        }
					}
					
					{
						Germ *cGerm = [self objectAtX:x Y:y-3];
						if (cGerm.value == aGerm.value) {
							return ccp(x,y-3);
						}
					}
					
					{
                        Germ *cGerm = [self objectAtX:x-1 Y:y-2];
                        if (cGerm.value == aGerm.value) {
                           return ccp(x-1,y-2);
                        }
					}
					{
                        Germ *cGerm = [self objectAtX:x+1 Y:y-2];
                        if (cGerm.value == aGerm.value) {
                            return ccp(x+1,y-2);
                        }
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
							return ccp(x,y+1);
						}
					}
					{
						Germ *cTile = [self objectAtX:x Y:y-3];
						if (cTile.value == aGerm.value) {
							return ccp(x,y-3);
						}
					}
					{
						Germ *cTile = [self objectAtX:x-1 Y:y-1];
						if (cTile.value == aGerm.value) {
							return ccp(x-1,y-1);
						}
					}
					{
						Germ *cTile = [self objectAtX:x+1 Y:y-1];
						if (cTile.value == aGerm.value) {
							return ccp(x+1,y-1);
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
						if (cTile.value == aGerm.value) {
							return ccp(x-2,y);
						}
					}
					
					{
						Germ *cGerm = [self objectAtX:x-1 Y:y-1];
						if (cGerm.value == aGerm.value) {
							return ccp(x-1,y-1);
                        }
                    }
					{
						Germ *cGerm= [self objectAtX:x-1 Y:y+1];
						if (cGerm.value == aGerm.value) {
                            return ccp(x-1,y+1);
						}
					}
					
					{
						Germ *cGerm = [self objectAtX:x+3 Y:y];
						if (cGerm.value == aGerm.value) {
							return ccp(x+3,y);
						}
					}
					
					{
						Germ *cGerm= [self objectAtX:x+2 Y:y-1];
						if (cGerm.value == aGerm.value) {
							return ccp(x+2,y-1);
						}
					}
					{
						Germ *cGerm= [self objectAtX:x+2 Y:y+1];
						if (cGerm.value == aGerm.value) {
							return ccp(x+2,y+1);
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
							return ccp(x+3,y);
						}
					}
					
					{
						Germ *cGerm = [self objectAtX:x-1 Y:y];
						if (cGerm.value == aGerm.value) {
							return ccp(x-1,y);
						}
					}
					
					
					{
						Germ *cGerm = [self objectAtX:x+1 Y:y-1];
						if (cGerm.value == aGerm.value) {
							return ccp(x+1,y-1);
						}
					}
					{
						Germ *cGerm = [self objectAtX:x+1 Y:y+1];
						if (cGerm.value == aGerm.value) {
							return ccp(x+1,y+1);
						}
					}
				}
			}
		}
	}
	return ccp(-1,-1);
}

-(void)fill{
    for (int i=0; i<[content count]; i++) {
        NSMutableArray *array = [content objectAtIndex:i];
        for(int j =0;j<[array count];j++)
        {
            // 随机出一种孢子
            int value = (arc4random()%kKindCount+1);
            //从下往上来
            Germ *destGerm = [self objectAtX:j Y:i];
            if(destGerm.sprite)
            {
                [holder removeChild:destGerm.sprite cleanup:YES];
            }
            NSString *name = [NSString stringWithFormat:@"q%d.png",value];
            CCSprite *sprite = [CCSprite spriteWithFile:name];
            sprite.position = ccp(kStartX + j * kTileSize + kTileSize/2, kStartY +  i * kTileSize + kTileSize/2);
            [holder addChild: sprite];
            destGerm.value = value;
            destGerm.sprite = sprite;
        }
	}
    
    
}

@end
