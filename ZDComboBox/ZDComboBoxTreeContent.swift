//
//  ZDComboBoxTreeContent.swift
//  combobox
//
//  Created by Dmitriy Zakharkin on 8/9/15.
//  Copyright (c) 2015 ZDima. All rights reserved.
//

import Cocoa

class ZDComboBoxTree: ZDPopupContent, NSOutlineViewDelegate {

	var disableSelectionNotification: Bool = false

	@IBOutlet var itemController: NSTreeController!
	@IBOutlet var tree: NSOutlineView!

	let recordSortDescriptors = [
		NSSortDescriptor(key: "title", ascending: true)
	]

	@IBAction func performClick(sender: AnyObject) {
		// hide popup when user select item by click
		ZDPopupWindowManager.popupManager.hidePopup()
	}

	override func invalidateFilter() {
		if !filter.isEmpty {
			var filteredContent: [ZDComboBoxItem] = []

			for item in items {
				if let filtered = item.selfOrHasChildWithKey( filter.lowercaseString ) {
					filteredContent.append(filtered)
				}
			}
			itemController.content = filteredContent
		} else {
			itemController.content = items
		}
		tree.expandItem(nil, expandChildren: true)
	}

	override func viewWillAppear() {
		invalidateFilter()
		tree.expandItem( nil, expandChildren: true)
		super.viewWillAppear()
	}

	func makeSelectionVisible() {
		var selRect: NSRect = tree!.rectOfRow( tree!.selectedRow )
		tree.scrollRectToVisible( selRect )
	}

	override func moveSelectionUp(up: Bool) {
		var i: Int = tree!.selectedRow
		if up {
			i = i-1
		} else {
			i = i+1
		}
		if i < 0 {
			return
		}
		tree.selectRowIndexes( NSIndexSet(index: i), byExtendingSelection: false)
		makeSelectionVisible()
	}

	func outlineViewSelectionDidChange(notification: NSNotification) {
		if disableSelectionNotification == false {
			let sa: NSArray = itemController.selectedObjects
			delegate!.selectionDidChange( sa, fromUpDown: true)
		}
	}

	func outlineView(outlineView: NSOutlineView,
		shouldShowOutlineCellForItem item: AnyObject) -> Bool {
			return true
	}

	func outlineView(outlineView: NSOutlineView,
		shouldShowCellExpansionForTableColumn tableColumn: NSTableColumn?, item: AnyObject) -> Bool {
			return false
	}

	func childByName(name: String, children: [AnyObject],
		indexes: NSMutableArray) -> Bool {

			var i: Int = 0
			var ret: Bool = false
			let maxCount: Int = children.count
			let stringLength: Int = count(name) as Int
			let stringRange: NSRange = NSRange(location: 0, length:stringLength)
			for object in children {
				if let item: ZDComboBoxItem = object as? ZDComboBoxItem {
					indexes.addObject(NSNumber(integer: i))
					if item.title.lowercaseString.hasPrefix(name.lowercaseString) {
						ret = true
						break
					} else {
						ret = childByName(name,
							children: (item.childs as NSArray).sortedArrayUsingDescriptors(recordSortDescriptors),
							indexes: indexes)
						if ret == true {
							break
						}
						indexes.removeLastObject()
					}
				}
				i = i+1
			}
			return ret
	}

	override func moveSelectionTo(string: String?, filtered: Bool) -> NSString? {

		disableSelectionNotification = true

		var indexes: NSMutableArray = NSMutableArray()

		if filtered {
			if string != nil {
				filter = string!
			} else {
				filter = ""
			}
		} else {
			filter = ""
		}

		if let children = itemController.content as? NSArray {
			let sortedchildren = children.sortedArrayUsingDescriptors(recordSortDescriptors)
			if childByName(string!, children:sortedchildren, indexes:indexes) {
				var selection: NSIndexPath? = nil;
				for n in indexes {
					if let num: NSNumber = n as? NSNumber {
						if selection != nil {
							selection = selection!.indexPathByAddingIndex(num.integerValue)
						} else {
							selection = NSIndexPath(index: num.integerValue )
						}
					}
				}

				itemController.setSelectionIndexPath( selection )

				var sa: NSArray = itemController.selectedObjects;
				if let c: ZDComboBoxItem = sa.firstObject as? ZDComboBoxItem {
					var s: String = c.title
					disableSelectionNotification = false
					return s;
				}
			}
		}
		disableSelectionNotification = false
		makeSelectionVisible()
		return nil;//i != self.tree.selectedRow;
	}

	override func convertUserObjectToItems() {
		super.convertUserObjectToItems()
		itemController.content = items
	}
}
