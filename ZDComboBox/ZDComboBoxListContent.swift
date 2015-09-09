//
//  ZDComboBoxTreeContent.swift
//  combobox
//
//  Created by Dmitriy Zakharkin on 8/9/15.
//  Copyright (c) 2015 ZDima. All rights reserved.
//

import Cocoa

class ZDComboBoxList: ZDPopupContent, NSTableViewDelegate {

	var disableSelectionNotification: Bool = false

	@IBOutlet var itemController: NSArrayController!
	@IBOutlet var table: NSTableView!

	let recordSortDescriptors = [
		NSSortDescriptor(key: "title", ascending: true)
	]

	@IBAction func performClick(sender: AnyObject?) {
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
	}

	override func viewWillAppear() {
		invalidateFilter()
		super.viewWillAppear()
	}

	func makeSelectionVisible() {
		let selRect: NSRect = table!.rectOfRow( table!.selectedRow )
		table.scrollRectToVisible( selRect )
	}

	override func moveSelectionUp(up: Bool) {
		var i: Int = table!.selectedRow
		if up {
			i = i-1
		} else {
			i = i+1
		}
		if i < 0 {
			return
		}
		table.selectRowIndexes( NSIndexSet(index: i), byExtendingSelection: false)
		makeSelectionVisible()
	}

	func tableViewSelectionDidChange(notification: NSNotification) {
		if disableSelectionNotification == false {
			let sa: NSArray = itemController.selectedObjects
			delegate!.selectionDidChange( sa, fromUpDown: true)
		}
	}

	func tableView(tableView: NSTableView,
		shouldShowCellExpansionForTableColumn tableColumn: NSTableColumn?,
		row: Int) -> Bool {
			return false
	}

	func childByName(name: String, children: [AnyObject],
		indexes: NSMutableArray) -> Bool {

			var i: Int = 0
			var ret: Bool = false
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

		let indexes: NSMutableArray = NSMutableArray()

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

				if let stringIdx = selection {
					itemController.setSelectionIndex(stringIdx.indexAtPosition(0))
				} else {
					itemController.setSelectionIndex(NSNotFound)
				}

				let sa: NSArray = itemController.selectedObjects;
				if let c: ZDComboBoxItem = sa.firstObject as? ZDComboBoxItem {
					let s: String = c.title
					disableSelectionNotification = false
					return s
				}
			}
		}
		disableSelectionNotification = false
		makeSelectionVisible()
		return nil
	}

	override func convertUserObjectToItems() {
		super.convertUserObjectToItems()
		itemController.content = items
	}

	override func selectedObjects() -> [AnyObject] {
		return itemController.selectedObjects
	}

}
