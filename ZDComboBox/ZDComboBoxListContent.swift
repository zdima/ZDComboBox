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

	@IBAction func performClick(_ sender: AnyObject?) {
		let sa: NSArray = itemController.selectedObjects as NSArray
		delegate!.selectionDidChange( sa, fromUpDown: true, userInput: filter)
		// hide popup when user select item by click
		ZDPopupWindowManager.popupManager.hidePopup()
	}

	override func invalidateFilter() {
		if !filter.isEmpty {
			var filteredContent: [ZDComboBoxItem] = []

			for item in items {
				if let filtered = item.selfOrHasChildWithKey( filter.lowercased() ) {
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
		table.scrollRowToVisible(table.selectedRow)
	}

	override func moveSelectionUp(_ up: Bool) {
		var i: Int = table!.selectedRow
		while true {
			if up {
				i = i-1
			} else {
				i = i+1
			}
			if i < 0 || i == table!.numberOfRows {
				return
			}
			if !filter.isEmpty {
				if let item = (itemController.content as! NSArray).object(at: i) as? ZDComboBoxItem {
					if item.isMatch(filter: filter) {
						break;
					}
				}
			} else {
				break
			}
		}
		table.selectRowIndexes( IndexSet(integer: i), byExtendingSelection: false)
		makeSelectionVisible()
	}

	func tableView(_ tableView: NSTableView,
	               shouldShowCellExpansionFor tableColumn: NSTableColumn?,
	               row: Int) -> Bool {
		return false
	}

	func childByName(_ name: String, children: [Any],
	                 indexes: NSMutableArray) -> Bool {

		var i: Int = 0
		var ret: Bool = false

		if name.isEmpty {
			return false
		}

		for object in children {
			if let item: ZDComboBoxItem = object as? ZDComboBoxItem {
				indexes.add(NSNumber(value: i as Int))
				if item.title.lowercased().hasPrefix(name.lowercased()) {
					ret = true
					break
				} else {
					ret = childByName(name,
					                  children: (item.childs as NSArray).sortedArray(using: recordSortDescriptors),
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

	override func moveSelectionTo(_ string: String?, filtered: Bool) -> NSString? {

		disableSelectionNotification = true

		let indexes: NSMutableArray = NSMutableArray()

		if filtered {
			if string != nil && !string!.isEmpty {
				filter = string!
			} else {
				filter = ""
			}
		} else {
			filter = ""
		}

		if let children = itemController.content as? NSArray {
			let sortedchildren = children.sortedArray(using: recordSortDescriptors)
			if childByName(string!, children:sortedchildren as [AnyObject], indexes:indexes) {
				var selection: IndexPath? = nil;
				for n in indexes {
					if let num: NSNumber = n as? NSNumber {
						if selection != nil {
							selection = selection!.appending(IndexPath.Element(num.intValue))
						} else {
							selection = IndexPath(index: num.intValue )
						}
					}
				}

				if let stringIdx = selection {
					let idx: Int = stringIdx[0]
					itemController.setSelectionIndex(idx)
				} else {
					itemController.setSelectionIndex(NSNotFound)
				}

				let sa: NSArray = itemController.selectedObjects as NSArray;
				if let c: ZDComboBoxItem = sa.firstObject as? ZDComboBoxItem {
					let s: String = c.title
					disableSelectionNotification = false
					return s as NSString?
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
		return itemController.selectedObjects as [AnyObject]
	}

}
