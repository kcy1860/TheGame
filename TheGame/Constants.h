//
//  Header.h
//  TheGame
//
//  Created by kcy1860 on 12/6/12.
//
//
#import "Definitions.h"

#ifndef TheGame_Constants_h
#define TheGame_Constants_h

/***这两个参数决定box的位置***/
#define kStartX 10
#define kStartY 112

/**box的大小*/
#define kBoxWidth 7
#define kBoxHeight 7

/**box中每个格子的大小*/
#define kTileSize 43.0f

#define kMoveTileTime 0.3f// 孢子交换的移动的时间
#define kTileDropTime 0.1f// 新孢子产生下落的时间
#define kShineFreq 0.3f//孢子被选中闪烁的速度
#define kConvergeTime 0.2f//孢子合并的时间
#define kFallDownDelayTime 0.3f//孢子下落之前的延迟时间

#define kKindCount 6


/****childtags***/
#define rewardLayerTag 618
#define pauseLayerTag  617
#define giftTag 100
#define menuLayerTag 7
#define mainmenuTag 15
#define continueTag 12
#define likeusTag 22
#define backtomenuTag 32
#define redoTag 42
#define menuTag 52
#define sunTag 220
#define musicTag 99
#define colorEggTag 1314

/*根据num计算分数的规则*/
// 孢子数*基础分
// （连击数-1）*奖励分
#define basicScore 10
#define bonusScore 20

// 基础间隔时间，如果两次消除的时间在这个时间以内那么算一次连击
#define leastTimeInteval 1.5f

// 在经典玩法中， 控制星星出现的动画
// 星星由某个位置先变大，再变小然后镶嵌到该出现的位置
// 这个参数控制变大花费的时间
#define apearspeed 0.8f
// 这个参数控制镶嵌的时间
#define fixspeed 0.8f
// 这个参数控制变大的大小
#define openScale 1.0f

#define stepBombCount 9
#define timeBombCount 25
#define isRetina ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(640,960), [[UIScreen mainScreen] currentMode].size) : NO)

//#define isRetina YES
#endif
