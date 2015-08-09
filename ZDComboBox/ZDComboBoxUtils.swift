//
//  ZDComboBoxUtils.swift
//  combobox
//
//  Created by Dmitriy Zakharkin on 8/9/15.
//  Copyright (c) 2015 ZDima. All rights reserved.
//

import Cocoa

class ZDComboBoxItem: NSObject {

	var title: String = ""
	var childs: [ZDComboBoxItem] = []
	var representedObject: AnyObject!

	class func itemWith( obj: NSObject,
		hierarchical: Bool,
		displayKey: String,
		childsKey: String? ) -> ZDComboBoxItem? {
			if let title = obj.valueForKey(displayKey) as? String {

				if hierarchical {
					var childs: [ZDComboBoxItem] = []
					if let key = childsKey,
						let objChilds = obj.valueForKey(key) as? [NSObject] {
							for obj in objChilds {
								if let item = ZDComboBoxItem.itemWith( obj,
									hierarchical: hierarchical,
									displayKey: displayKey,
									childsKey: childsKey) {
										childs.append(item)
								}
							}
					}
					return ZDComboBoxItem(title: title, childs: childs, object: obj)
				} else {
					return ZDComboBoxItem(title: title, childs: [], object: obj)
				}
			}
			return nil
	}

	init(title inTitle: String,
		childs inChilds: [AnyObject],
		object inObject: AnyObject ) {
			title = inTitle
			if let items = inChilds as? [ZDComboBoxItem] {
				childs = items
			} else {
				childs = []
			}
			representedObject = inObject
			super.init()
	}

	func selfOrHasChildWithKey( key: String ) -> ZDComboBoxItem? {
		if childs.count > 0 {
			var filtered: [ZDComboBoxItem] = []

			for child in childs {
				if let filteredChild = child.selfOrHasChildWithKey(key) {
					filtered.append(filteredChild)
				}
			}

			if filtered.count > 0 {
				return ZDComboBoxItem(title: title, childs: filtered, object: representedObject! )
			} else if title.lowercaseString.rangeOfString(key) != nil {
				return ZDComboBoxItem(title: title, childs: [], object: representedObject! )
			}
		} else {
			if title.lowercaseString.rangeOfString(key) != nil {
				return self
			}
		}
		return nil
	}
}

class ZDComboBoxCell: NSTextFieldCell {

	static let buttonAspect: CGFloat = 0.63

	override func drawingRectForBounds(theRect: NSRect) -> NSRect {
		var textRect = super.drawingRectForBounds(theRect)
		textRect.size.width -= (3 + textRect.size.height*ZDComboBoxCell.buttonAspect)
		return textRect
	}

	override func selectWithFrame(aRect: NSRect,
		inView controlView: NSView,
		editor textObj: NSText,
		delegate anObject: AnyObject?,
		start selStart: Int,
		length selLength: Int) {

			var selectFrame = aRect;
			selectFrame.size.width -= (3 + selectFrame.size.height*ZDComboBoxCell.buttonAspect)

			NSNotificationCenter.defaultCenter().addObserver(
				self, selector: "__textChanged:",
				name: NSTextDidChangeNotification, object: textObj)

			super.selectWithFrame(aRect,
				inView: controlView,
				editor: textObj, delegate: anObject,
				start: selStart, length: selLength)
	}

	override func endEditing(textObj: NSText) {
		NSNotificationCenter.defaultCenter().removeObserver(
			self, name: NSTextDidChangeNotification,
			object:textObj)
		super.endEditing(textObj)
	}

	func __textChanged(notif: NSNotification) {
		self.controlView!.needsDisplay = true
	}
}


@objc(ZDComboFieldDelegate)
class ZDComboFieldDelegate: NSObject, NSTextFieldDelegate, ZDPopupContentDelegate {

	var dontSearch: Bool = false
	var didDelete: Bool = false
	var popupContent: ZDPopupContent? = nil
	var combo: ZDComboBox?

	var mouseDown: Bool = false

	func createPopupContent() -> ZDPopupContent? {
		if let comboBox = combo {
			var content: ZDPopupContent
			if let top = comboBox.topLevelObjects as? NSTreeController {
				content = ZDComboBoxTree(nibName: "ZDComboBoxTree", bundle: nil)!
			} else {
				content = ZDComboBoxList(nibName: "ZDComboBoxList", bundle: nil)!
			}
			content.delegate = self
			let v = content.view
			if let oCtrl = comboBox.topLevelObjects as? NSTreeController {
				content.rootNodes = oCtrl.arrangedObjects.childNodes
			} else if let oCtrl = comboBox.topLevelObjects as? NSArrayController {
				content.rootNodes = oCtrl.arrangedObjects as? [AnyObject]
			} else {
				content.rootNodes = []
			}
			return content
		}
		return nil
	}

	func selectionDidChange(selector: AnyObject?, fromUpDown updown: Bool) {
		if let selection: [AnyObject] = selector as? [AnyObject],
			let o = selection.first as? ZDComboBoxItem,
			let comboBox = combo {
				if updown {
					comboBox.stringValue = o.title
				}
				comboBox.selectedObject = o.representedObject
				if mouseDown {
					ZDPopupWindowManager.popupManager.hidePopup()
				}
		}
	}

	func control(control: NSControl, isValidObject obj: AnyObject) -> Bool {
		return true
	}

	func control(control: NSControl, textShouldBeginEditing fieldEditor: NSText) -> Bool {
		showPopupForControl(control)
		return true
	}

	func showPopupForControl(control: NSControl?) -> Bool {
		if popupContent == nil {
			if var control: ZDComboBox = control as? ZDComboBox {
				if combo == nil {
					combo = control
				}
				popupContent = createPopupContent()
				if popupContent == nil {
					return false
				}
				popupContent!.delegate = self
			} else {
				return false
			}
		}
		return ZDPopupWindowManager.popupManager.showPopupForControl(
			control, withContent: popupContent!.view)
	}

	func control(control: NSControl,
		textView: NSTextView,
		completions words: [AnyObject],
		forPartialWordRange charRange: NSRange,
		indexOfSelectedItem index: UnsafeMutablePointer<Int>) -> [AnyObject] {
			return []
	}

	func control(control: NSControl, textShouldEndEditing fieldEditor: NSText) -> Bool {
		updateBindingProperty()
		ZDPopupWindowManager.popupManager.hidePopup()
		return true
	}

	override func controlTextDidChange(obj: NSNotification) {
		combo = nil
		if var control: ZDComboBox = obj.object as? ZDComboBox {
			combo = control
			if dontSearch {
				dontSearch = false
				return
			} else {
				showPopupForControl(combo)
			}
			if var editor: NSTextView = control.currentEditor() as? NSTextView {
				if var s: String = popupContent!.moveSelectionTo(control.stringValue) as? String {
					if !didDelete {
						var insertionPoint: Int = editor.selectedRanges.first!.rangeValue.location
						editor.string = s
						editor.selectedRange = NSRange( location: insertionPoint, length: count(s) - insertionPoint)
					}
				}
			}
		}
	}

	func control(control: NSControl,
		textView: NSTextView,
		doCommandBySelector commandSelector: Selector) -> Bool {

			didDelete = false
			combo = nil
			if control is ZDComboBox {
				combo = control as? ZDComboBox
			}
			if commandSelector == "moveUp:" {
				if showPopupForControl(control) {
					popupContent!.moveSelectionUp(true)
				}
				return true
			}
			if commandSelector == "deleteBackward:" {
				didDelete = true
				return false
			}
			if commandSelector == "moveDown:" {
				if showPopupForControl(control) {
					popupContent!.moveSelectionUp(false)
				} else {
					if var editor: NSTextView = control.currentEditor() as? NSTextView {
						if var s: String = popupContent!.moveSelectionTo(control.stringValue) as? String {
							var insertionPoint: Int = editor.selectedRanges.first!.rangeValue.location
							editor.string = s
							editor.selectedRange = NSRange( location: insertionPoint, length: count(s) - insertionPoint)
						}
					}
					return false
				}
				return true
			}
			if commandSelector == "cancelOperation:" {
				ZDPopupWindowManager.popupManager.hidePopup()
				return true
			}
			return false
	}

	func updateBindingProperty() {
		if let combobox = combo,
			let bindingInfo:[NSObject:AnyObject] = combobox.infoForBinding(NSValueBinding),
			let control: NSObject = bindingInfo[NSObservedObjectKey as NSString] as? NSObject,
			let path = bindingInfo[NSObservedKeyPathKey as NSString] as? String {

				var objectValue: AnyObject? = combobox.stringValue

				let keys = bindingInfo.keys
				if let options:[NSObject:AnyObject] = bindingInfo[NSOptionsKey] as? [NSObject:AnyObject] {

					if let transformer = options[NSValueTransformerBindingOption] as? NSValueTransformer {
						objectValue = transformer.reverseTransformedValue(objectValue)
					}
				}

				// get context of the object refering by path
				let destinationMOC: NSManagedObjectContext? = getManagedObjectContext( control, path: path )
				let sourceMOC: NSManagedObjectContext?
				if let objectValueAsManagedObject = objectValue as? NSManagedObject {
					sourceMOC = objectValueAsManagedObject.managedObjectContext

					if destinationMOC != sourceMOC {
						if let moc = destinationMOC {
							objectValue = moc.objectWithID(objectValueAsManagedObject.objectID)
						}
					}
				}

				control.setValue( objectValue, forKeyPath:path)
		}
	}

	func getManagedObjectContext( target: NSObject, path: String ) -> NSManagedObjectContext? {
		if let control = target as? NSView {
			if let mo = control.valueForKeyPath(path) as? NSManagedObject {
				return mo.managedObjectContext
			}
			var pathComponents = path.componentsSeparatedByString(".")
			if pathComponents.count > 1 {
				pathComponents.removeLast()
				let parent = ".".join(pathComponents)
				return getManagedObjectContext( target, path: parent )
			}
			return nil
		} else if let managedObject = target as? NSManagedObject {
			return managedObject.managedObjectContext
		}
		return nil
	}
}

extension String {
	func localized(#tableName: String?, bundle: NSBundle, comment: String = "") -> String {
		return NSLocalizedString( self, tableName: tableName,
			bundle: bundle, value: self, comment: comment)
	}
	func localized(#tableName: String?, comment: String = "") -> String {
		return NSLocalizedString( self, tableName: tableName,
			bundle: NSBundle.mainBundle(), value: self, comment: comment)
	}
	func localized(#comment: String) -> String {
		return NSLocalizedString( self, tableName: nil,
			bundle: NSBundle.mainBundle(), value: self, comment: comment)
	}
	func localized() -> String {
		return NSLocalizedString( self, tableName: nil,
			bundle: NSBundle.mainBundle(), value: self, comment: "")
	}
}
