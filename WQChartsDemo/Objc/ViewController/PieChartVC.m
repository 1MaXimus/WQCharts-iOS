// https://github.com/CoderWQYao/WQCharts-iOS
//
// PieChartVC.m
// WQCharts
//
// Created by WQ.Yao on 2020/01/02.
// Copyright (c) 2020年 WQ.Yao All rights reserved.
//

#import "PieChartVC.h"

@interface PieChartItemTag: NSObject

@property (nonatomic, readonly, nonnull) UIColor* color1;
@property (nonatomic, readonly, nonnull) UIColor* color2;

- (void)swapColor;

@end

@interface PieChartItemTag()

@property (nonatomic, nonnull) UIColor* color1;
@property (nonatomic, nonnull) UIColor* color2;

@end

@implementation PieChartItemTag

- (instancetype)initWithColor1:(UIColor*)color1 color2:(UIColor*)color2 {
    if(self = [super init]) {
        self.color1 = color1;
        self.color2 = color2;
    }
    return self;
}

- (void)swapColor {
    UIColor* tmp = self.color1;
    self.color1 = self.color2;
    self.color2 = tmp;
}

@end


@interface PieChartVC ()

@property (nonatomic, strong) NSArray<UIColor*>* colors;
@property (nonatomic, strong) WQPieChartView* chartView;

@end

@implementation PieChartVC

- (NSArray<UIColor *> *)colors {
    if(!_colors) {
        _colors = Colors;
    }
    return _colors;
}

- (UIView *)createChartView {
    _chartView = [[WQPieChartView alloc] init];
    return _chartView;
}

- (void)chartViewDidCreate:(WQPieChartView *)chartView {
    [super chartViewDidCreate:chartView];
    chartView.graphicItemClickDelegate = self;
}

#pragma mark - Items

- (void)configChartItemsOptions {
    [super configChartItemsOptions];
    
    __weak typeof(self) weakSelf = self;
    
    [self.optionsView addItem:ListCell.new
     .setTitle(@"ItemsArc1Scale")
     .addItem(SliderCell.new
              .setDecimalCount(2)
              .setSliderValue(0,1,1)
              .setOnValueChange(^(SliderCell* cell,float value) {
        [weakSelf updateItems];
    }))];
    
    [self.optionsView addItem:ListCell.new
     .setTitle(@"ItemsArc2Scale")
     .addItem(SliderCell.new
              .setDecimalCount(2)
              .setSliderValue(0,1,0)
              .setOnValueChange(^(SliderCell* cell,float value) {
        [weakSelf updateItems];
    }))];
    
    [self.optionsView addItem:RadioCell.new
     .setTitle(@"ItemsFill")
     .setOptions(@[@"OFF",@"ON",@"Gradient"])
     .setSelection(1)
     .setOnSelectionChange(^(RadioCell* cell, NSInteger selection) {
        [weakSelf updateItems];
    })];
    
    [self.optionsView addItem:RadioCell.new
     .setTitle(@"ItemsStroke")
     .setOptions(@[@"OFF",@"ON",@"Dash"])
     .setSelection(1)
     .setOnSelectionChange(^(RadioCell* cell, NSInteger selection) {
        [weakSelf updateItems];
    })];
    
    [self.optionsView addItem:RadioCell.new
     .setTitle(@"ItemsText")
     .setOptions(@[@"OFF",@"ON"])
     .setSelection(1)
     .setOnSelectionChange(^(RadioCell* cell, NSInteger selection) {
        [weakSelf updateItems];
    })];
    
}

- (NSString*)itemsOptionTitle {
    return @"Items";
}

- (NSMutableArray<WQPieChartItem*>*)items {
    NSArray<WQPieChartItem*>* items = self.chartView.chart.items;
    if (items) {
        return [NSMutableArray arrayWithArray:items];
    } else {
        NSMutableArray<WQPieChartItem*>* items = [NSMutableArray array];
        for (NSInteger i=0; i<4; i++) {
            WQPieChartItem* item = [self createItemAtIndex:i];
            if (item) {
                [items addObject:item];
            }
        }
        self.chartView.chart.items = items;
        return items;
    }
}

- (WQPieChartItem*)createItemAtIndex:(NSInteger)index {
    if (index >= self.colors.count) {
        return nil;
    }
    
    WQPieChartItem* item = [[WQPieChartItem alloc] initWithValue:1];
    
    item.tag = [[PieChartItemTag alloc] initWithColor1:self.colors[index] color2:self.colors[(index + 1) % self.colors.count]];
    
    WQChartText* text = [[WQChartText alloc] init];
    text.font = [UIFont systemFontOfSize:11];
    text.color = Color_White;
    item.text = text;
    
    [self updateItem:item];
    return item;
}

- (SliderCell*)createItemCellWithItem:(WQPieChartItem*)item atIndex:(NSInteger)index {
    __weak typeof(self) weakSelf = self;
    return SliderCell.new
    .setObject(item)
    .setSliderValue(0,1,item.value)
    .setDecimalCount(2)
    .setOnValueChange(^(SliderCell* cell, float value) {
        WQPieChartItem* item = (WQPieChartItem*)cell.object;
        item.value = value;
        [weakSelf.chartView redraw];
    });
}

- (void)itemsDidChange:(NSMutableArray<WQPieChartItem*>*)items {
    self.chartView.chart.items = items;
    [self.chartView redraw];
}

- (void)updateItem:(WQPieChartItem*)item {
    item.arc1Scale = [self sliderValueForKey:@"ItemsArc1Scale" atIndex:0];
    item.arc2Scale = [self sliderValueForKey:@"ItemsArc2Scale" atIndex:0];
    
    PieChartItemTag* tag = (PieChartItemTag*)item.tag;
    WQChartFillPaint* fillPaint = item.paint.fill;
    switch ([self radioCellSelectionForKey:@"ItemsFill"]) {
        case 1:
            fillPaint.color = tag.color1;
            fillPaint.shader = nil;
            break;
        case 2:
            fillPaint.color = nil;
            fillPaint.shader = [[WQChartRadialGradient alloc] initWithCenter:CGPointMake(0.5, 0.5) radius:1 colors:@[tag.color1,tag.color2]];
            break;
        default:
            fillPaint.color = nil;
            fillPaint.shader = nil;
            break;
    }
    
    [self setupStrokePaint:item.paint.stroke color:Color_White type:[self radioCellSelectionForKey:@"ItemsStroke"]];
    
    item.text.hidden = [self radioCellSelectionForKey:@"ItemsText"] == 0;
}

- (void)updateItems {
    NSArray<WQPieChartItem*>* items = self.chartView.chart.items;
    for (WQPieChartItem* item in items) {
        [self updateItem:item];
    }
    [self.chartView redraw];
}

#pragma mark - ChartViewDrawDelegate

- (void)chartViewWillDraw:(WQChartView *)chartView inRect:(CGRect)rect context:(CGContextRef)context {
    [super chartViewWillDraw:chartView inRect:rect context:context];
    
    NSArray<WQPieChartItem*>* items = self.chartView.chart.items;
    float totalValue = [WQPieChartItem calcTotalValueWithItems:items];
    [items enumerateObjectsUsingBlock:^(WQPieChartItem * _Nonnull item, NSUInteger idx, BOOL * _Nonnull stop) {
        item.text.string = [NSString stringWithFormat:@"%ld%%",(NSInteger)round((totalValue != 0 ? item.value / totalValue : 1) * 100)];
    }];
}

#pragma mark - PieChartViewDrawDelegate

- (void)pieChartView:(WQPieChartView *)pieChartView graphicItemDidClick:(WQPieGraphicItem *)graphicItem {
    WQPieChartItem* item = (WQPieChartItem*)graphicItem.builder;
    item.driftRatio = item.driftRatio == 0 ? 0.3 : 0;
    [pieChartView redraw];
   
    NSUInteger index = [pieChartView.chart.items indexOfObject:item];
    NSLog(@"pieChartView: graphicItemDidClick: %ld", index);
}

#pragma mark - Animation

- (void)appendAnimationKeys:(NSMutableArray<NSString *> *)animationKeys {
    [super appendAnimationKeys:animationKeys];
    [animationKeys addObject:@"Values"];
    [animationKeys addObject:@"Arc1s"];
    [animationKeys addObject:@"Arc2s"];
    [animationKeys addObject:@"Drifts"];
    [animationKeys addObject:@"Colors"];
}

- (void)prepareAnimationOfChartViewForKeys:(NSArray<NSString*>*)keys {
    [super prepareAnimationOfChartViewForKeys:keys];
    
    WQPieChart* chart = self.chartView.chart;
    
    if ([keys containsObject:@"Values"]) {
        [chart.items enumerateObjectsUsingBlock:^(WQPieChartItem * _Nonnull item, NSUInteger idx, BOOL * _Nonnull stop) {
            item.valueTween = [[WQChartCGFloatTween alloc] initWithFrom:item.value to:[NSNumber randomCGFloatFrom:0 to:1]];
        }];
    }
    
    if ([keys containsObject:@"Arc1s"]) {
        CGFloat toArc1Scale = [self sliderValueForKey:@"ItemsArc1Scale" atIndex:0];
        toArc1Scale = toArc1Scale == 1 ? 0.5 : 1;
        [chart.items enumerateObjectsUsingBlock:^(WQPieChartItem * _Nonnull item, NSUInteger idx, BOOL * _Nonnull stop) {
            item.arc1ScaleTween = [[WQChartCGFloatTween alloc] initWithFrom:item.arc1Scale to:toArc1Scale];
        }];
        [self updateSliderValue:toArc1Scale forKey:@"ItemsArc1Scale" atIndex:0];
    }
    
    if ([keys containsObject:@"Arc2s"]) {
        CGFloat toArc2Scale = [self sliderValueForKey:@"ItemsArc2Scale" atIndex:0];
        toArc2Scale = toArc2Scale == 0 ? 0.5 : 0;
        [chart.items enumerateObjectsUsingBlock:^(WQPieChartItem * _Nonnull item, NSUInteger idx, BOOL * _Nonnull stop) {
            item.arc2ScaleTween = [[WQChartCGFloatTween alloc] initWithFrom:item.arc2Scale to:toArc2Scale];
        }];
        [self updateSliderValue:toArc2Scale forKey:@"ItemsArc2Scale" atIndex:0];
    }
    
    if ([keys containsObject:@"Colors"]) {
        [chart.items enumerateObjectsUsingBlock:^(WQPieChartItem * _Nonnull item, NSUInteger idx, BOOL * _Nonnull stop) {
            PieChartItemTag* tag = (PieChartItemTag*)item.tag;
            [tag swapColor];
            WQChartFillPaint* paint = item.paint.fill;
            if (paint.color) {
                paint.colorTween = [[WQChartUIColorTween alloc] initWithFrom:paint.color to:tag.color1];
            }
            if (paint.shader) {
                WQChartRadialGradient* shader = (WQChartRadialGradient*)paint.shader;
                shader.colorsTween = [[WQChartUIColorArrayTween alloc] initWithFrom:shader.colors to:@[tag.color1,tag.color2]];
            }
        }];
        

    }
    
    if ([keys containsObject:@"Drifts"]) {
        for (WQPieChartItem* item in chart.items) {
            item.driftRatioTween = [[WQChartCGFloatTween alloc] initWithFrom:item.driftRatio to:item.driftRatio == 0 ? 0.3 : 0];
        }
    }
    
}

#pragma mark - AnimationDelegate

- (void)animation:(WQChartAnimation *)animation progressDidChange:(CGFloat)progress {
    [super animation:animation progressDidChange:progress];
    
    if (animation.animatable == self.chartView) {
        [self.chartView.chart.items enumerateObjectsUsingBlock:^(WQPieChartItem * _Nonnull item, NSUInteger idx, BOOL * _Nonnull stop) {
            [self updateSliderValue:item.value forKey:@"Items" atIndex:idx];
        }];
    }

}

@end
