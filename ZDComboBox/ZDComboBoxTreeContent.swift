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

	@IBAction func performClick(_ sender: AnyObject) {
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
		tree.expandItem(nil, expandChildren: true)
	}

	override func viewWillAppear() {
		invalidateFilter()
		tree.expandItem( nil, expandChildren: true)
		super.viewWillAppear()
	}

	func makeSelectionVisible() {
		//let selRect: NSRect = tree!.rect( ofRow: tree!.selectedRow )
		tree.scrollRowToVisible(tree!.selectedRow)
	}

	override func moveSelectionUp(_ up: Bool) {
		var i: Int = tree!.selectedRow
        while true {
            if up {
                i = i-1
            } else {
                i = i+1
            }
            if i < 0 || i == tree!.numberOfRows {
                return
            }
            if !filter.isEmpty {
                if let item = (tree.item(atRow: i) as! NSTreeNode).representedObject as? ZDComboBoxItem {
                    if item.isMatch(filter: filter) {
                        break;
                    }
                }
            } else {
                break
            }
        }
        tree.selectRowIndexes( IndexSet(integer: i), byExtendingSelection: false)
		makeSelectionVisible()
	}

	func outlineViewSelectionDidChange(_ notification: Notification) {
		if disableSelectionNotification == false {
			let sa: NSArray = itemController.selectedObjects as NSArray
			delegate!.selectionDidChange( sa, fromUpDown: true, userInput: filter )
		}
	}

	func outlineView(_ outlineView: NSOutlineView,
		shouldShowOutlineCellForItem item: Any) -> Bool {
			return true
	}

	func outlineView(_ outlineView: NSOutlineView,
		shouldShowCellExpansionFor tableColumn: NSTableColumn?, item: Any) -> Bool {
			return false
	}

	func childByName(_ name: String, children: [Any],
		indexes: NSMutableArray) -> Bool {

			var i: Int = 0
			var ret: Bool = false
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
			if string != nil {
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
							selection = IndexPath(index:IndexPath.Element(num.intValue))
						}
					}
				}

				itemController.setSelectionIndexPath( selection )

				let sa: NSArray = itemController.selectedObjects as NSArray;
				if let c: ZDComboBoxItem = sa.firstObject as? ZDComboBoxItem {
					let s: String = c.title
					disableSelectionNotification = false
					return s as NSString?;
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

	override func selectedObjects() -> [AnyObject] {
		return itemController.selectedObjects as [AnyObject]
	}

}
