// https://github.com/CoderWQYao/WQCharts-iOS
//
// PolygonChartVC.swift
// WQCharts
//
// Created by WQ.Yao on 2020/01/02.
// Copyright (c) 2020年 WQ.Yao All rights reserved.
//

import UIKit

class PolygonChartVC: RadialChartVC<PolygonChartView>, ItemsOptionsDelegate {
    
    var currentColor: UIColor = Color_Blue
    
    override func chartViewDidCreate(_ chartView: PolygonChartView) {
        super.chartViewDidCreate(chartView)
        chartView.chart.paint?.stroke?.color = Color_White
    }
    
    override func configChartOptions() {
        super.configChartOptions()
        
        optionsView.addItem(RadioCell()
            .setTitle("Fill")
            .setOptions(["OFF","ON","Gradient"])
            .setSelection(1)
            .setOnSelectionChange({[weak self](cell, selection) in
                guard let self = self else {
                    return
                }
                let chartView = self.chartView
                guard let paint = chartView.chart.paint?.fill else {
                    return
                }
                switch (selection) {
                case 1:
                    paint.color = self.currentColor
                    paint.shader = nil
                case 2:
                    paint.color = nil
                    let color = self.currentColor
                    paint.shader = ChartRadialGradient(center: CGPoint(x: 0.5, y: 0.5), radius: 1, colors: [color.withAlphaComponent(0.1),color])
                default:
                    paint.color = nil
                    paint.shader = nil
                }
                chartView.redraw()
            })
        )
        
        optionsView.addItem(RadioCell()
            .setTitle("Stoke")
            .setOptions(["OFF","ON","Dash"])
            .setSelection(1)
            .setOnSelectionChange({[weak self](cell, selection) in
                guard let self = self else {
                    return
                }
                let chartView = self.chartView
                
                self.setupStrokePaint(chartView.chart.paint?.stroke, Color_White, selection)
                chartView.redraw()
            })
        )
        
    }
    
    // MARK: - Items
    
    override func configChartItemsOptions() {
        super.configChartItemsOptions()
        
        optionsView.addItem(RadioCell()
            .setTitle("ItemsAxis")
            .setOptions(["OFF","ON","Dash"])
            .setSelection(1)
            .setOnSelectionChange({[weak self](cell, selection) in
                self?.updateItems()
            })
        )
        
        optionsView.addItem(RadioCell()
            .setTitle("ItemsText")
            .setOptions(["OFF","ON"])
            .setSelection(1)
            .setOnSelectionChange({[weak self](cell, selection) in
                self?.updateItems()
            })
        )
    }
    
    var items: NSMutableArray {
        if let items = chartView.chart.items {
            return NSMutableArray.init(array: items)
        } else {
            let items = NSMutableArray()
            for i in 0..<5 {
                let item = createItem(atIndex: i)!
                items.add(item)
            }
            chartView.chart.items = (items as! [PolygonChartItem])
            return items
        }
    }
    
    var itemsOptionTitle: String {
        return "Items"
    }
    
    func createItem(atIndex index: Int) -> Any? {
        let item = PolygonChartItem(0.5)
        
        let text = ChartText()
        text.font = UIFont.systemFont(ofSize: 11)
        text.color = Color_White
        let textBlocks = ChartTextBlocks()
        textBlocks.offsetByAngle = {(text, size, angle) -> CGFloat in
            return 15
        }
        text.delegateUsingBlocks = textBlocks
        item.text = text
        
        updateItem(item)
        return item
    }
    
    func createItemCell(withItem item: Any, atIndex index: Int)  -> UIView {
        return SliderCell()
            .setObject(item)
            .setSliderValue(0,1,(item as! PolygonChartItem).value)
            .setDecimalCount(2)
            .setOnValueChange({[weak self](cell, value) in
                guard let self = self else {
                    return
                }
                let item = cell.object as! PolygonChartItem
                item.value = value
                self.updateItem(item)
                self.chartView.redraw()
            })
    }
    
    func itemsDidChange(_ items: NSMutableArray) {
        chartView.chart.items = (items as! [PolygonChartItem])
        chartView.redraw()
    }
    
    func updateItem(_ item: PolygonChartItem) {
        self.setupStrokePaint(item.axisPaint, Color_White, radioCellSelectionForKey("ItemsAxis"))
        item.text?.hidden = radioCellSelectionForKey("ItemsText") == 0
    }
    
    func updateItems() {
        if let items = chartView.chart.items {
            for item in items {
                updateItem(item)
            }
        }
        chartView.redraw()
    }
    
    // MARK: - ChartViewDrawDelegate
    
    override func chartViewWillDraw(_ chartView: ChartView, inRect rect: CGRect, context: CGContext) {
        super.chartViewWillDraw(chartView, inRect: rect, context: context)
        
        if let items = self.chartView.chart.items {
            for item in items {
                item.text?.string = String(format: "%.2f", item.value)
            }
        }
    }
    
    // MARK: - Animation
    
    override func appendAnimationKeys(_ animationKeys: NSMutableArray) {
        super.appendAnimationKeys(animationKeys)
        animationKeys.add("Color")
        animationKeys.add("Values")
    }
    
    override func prepareAnimationOfChartView(forKeys keys: [String]) {
        super.prepareAnimationOfChartView(forKeys: keys)
        
        let chart = chartView.chart
        
        if keys.contains("Color") {
            let toColor = currentColor.isEqual(Color_Blue) ? Color_Red : Color_Blue
            if let paint = chart.paint?.fill {
                if let color = paint.color {
                    paint.colorTween = ChartUIColorTween(color, toColor)
                }
                if let shader = paint.shader as? ChartGradient {
                    shader.colorsTween = ChartUIColorArrayTween(shader.colors, [toColor.withAlphaComponent(0.1),toColor])
                }
            }
            currentColor = toColor
        }
        
        if keys.contains("Values") {
            chart.items?.forEach({ (item) in
                item.valueTween = ChartCGFloatTween(item.value, CGFloat.random(in: 0...1))
            })
        }
        
    }
    
    // MARK: - AnimationDelegate
    
    override func animation(_ animation: ChartAnimation, progressDidChange progress: CGFloat) {
        super.animation(animation, progressDidChange: progress)
        
        if chartView.isEqual(animation.animatable) {
            chartView.chart.items?.enumerated().forEach { (idx, item) in
                updateSliderValue(item.value, forKey: "Items", atIndex: idx)
            }
        }
        
    }
    
    
    
}
