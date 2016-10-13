		//
//  ZDComboBoxUtils.swift
//  combobox
//
//  Created by Dmitriy Zakharkin on 8/9/15.
//  Copyright (c) 2015 ZDima. All rights reserved.
//

import Cocoa

extension String {
    func nsRange(from range: Range<String.Index>) -> NSRange {
        let from = range.lowerBound.samePosition(in: utf16)
        let to = range.upperBound.samePosition(in: utf16)
        return NSRange(location: utf16.distance(from: utf16.startIndex, to: from),
                       length: utf16.distance(from: from, to: to))
    }

    func range(from nsRange: NSRange) -> Range<String.Index>? {
        guard
            let from16 = utf16.index(utf16.startIndex, offsetBy: nsRange.location, limitedBy: utf16.endIndex),
            let to16 = utf16.index(from16, offsetBy: nsRange.length, limitedBy: utf16.endIndex),
            let from = String.Index(from16, within: self),
            let to = String.Index(to16, within: self)
            else { return nil }
        return from ..< to
    }
}
class ZDComboBoxItem: NSObject {

	var title: String = ""
	var childs: [ZDComboBoxItem] = []
	var representedObject: Any!

	class func itemWith( _ obj: Any,
		hierarchical: Bool,
		displayKey: String,
		childsKey: String? ) -> ZDComboBoxItem? {
			if let title = (obj as AnyObject).value(forKey: displayKey) as? String {

				if hierarchical {
					var childs: [ZDComboBoxItem] = []
					if let key = childsKey,
						let childObjs = (obj as AnyObject).value(forKey: key) {

							var objChilds: [AnyObject]!

							if let set = childObjs as? NSSet {
								objChilds = set.allObjects as [AnyObject]!
							} else if let array = childObjs as? NSArray {
								objChilds = array as [AnyObject]
							} else {
								objChilds = []
							}

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
		childs inChilds: [Any],
		object inObject: Any ) {
			title = inTitle
			if let items = inChilds as? [ZDComboBoxItem] {
				childs = items
			} else {
				childs = []
			}
			representedObject = inObject
			super.init()
	}

	func selfOrHasChildWithKey( _ key: String ) -> ZDComboBoxItem? {
		if childs.count > 0 {
			var filtered: [ZDComboBoxItem] = []

			for child in childs {
				if let filteredChild = child.selfOrHasChildWithKey(key) {
					filtered.append(filteredChild)
				}
			}

			if filtered.count > 0 {
				return ZDComboBoxItem(title: title, childs: filtered, object: representedObject! )
			} else if title.lowercased().range(of: key) != nil {
				return ZDComboBoxItem(title: title, childs: [], object: representedObject! )
			}
		} else {
			if title.lowercased().range(of: key) != nil {
				return self
			}
		}
		return nil
	}
    
    func isMatch( filter: String) -> Bool {
        if title.lowercased().range(of: filter.lowercased()) != nil {
            return true
        }
        return false
    }
}

class ZDComboBoxCell: NSTextFieldCell {

	static let buttonAspect: CGFloat = 0.63

	override func drawingRect(forBounds theRect: NSRect) -> NSRect {
		if controlView is ZDComboBox {
			var textRect = super.drawingRect(forBounds: theRect)
			textRect.size.width -= (3 + textRect.size.height*ZDComboBoxCell.buttonAspect)
			return textRect
		}
		return super.drawingRect(forBounds: theRect)
	}

	override func select(withFrame aRect: NSRect,
		in controlView: NSView,
		editor textObj: NSText,
		delegate anObject: Any?,
		start selStart: Int,
		length selLength: Int) {
			if controlView is ZDComboBox {

				var selectFrame = aRect;
				selectFrame.size.width -= (3 + selectFrame.size.height*ZDComboBoxCell.buttonAspect)

				NotificationCenter.default.addObserver(
					self, selector: #selector(ZDComboBoxCell.__textChanged(_:)),
					name: NSNotification.Name.NSTextDidChange, object: textObj)
			}
			super.select(withFrame: aRect,
				in: controlView,
				editor: textObj, delegate: anObject,
				start: selStart, length: selLength)
	}

	override func endEditing(_ textObj: NSText) {
		if controlView is ZDComboBox {
			NotificationCenter.default.removeObserver(
				self, name: NSNotification.Name.NSTextDidChange,
				object:textObj)
		}
		super.endEditing(textObj)
	}

	func __textChanged(_ notif: Notification) {
		self.controlView!.needsDisplay = true
	}
}


@objc(ZDComboFieldDelegate)
class ZDComboFieldDelegate: NSObject, NSTextFieldDelegate, ZDPopupContentDelegate {

	var dontSearch: Bool = false
	var didDelete: Bool = false
	var popupContent: ZDPopupContent? = nil
	var combo: ZDComboBox?
	var allowSelectionUpdate: Bool = true
	var mouseDown: Bool = false
	var comboBoxBundle: Bundle? = {
			return Bundle(for: ZDComboBoxTree.self)
		}()

	func createPopupContent() -> ZDPopupContent? {
		if let comboBox = combo {
			var content: ZDPopupContent
			if comboBox.topLevelObjects is NSTreeController {
				content = ZDComboBoxTree(nibName: "ZDComboBoxTree", bundle: comboBoxBundle)!
			} else {
				content = ZDComboBoxList(nibName: "ZDComboBoxList", bundle: comboBoxBundle)!
			}
			content.delegate = self
			let _ = content.view
			if let oCtrl = comboBox.topLevelObjects as? NSTreeController {
				content.rootNodes = (oCtrl.arrangedObjects as AnyObject).children as [NSTreeNode]?
			} else if let oCtrl = comboBox.topLevelObjects as? NSArrayController {
				content.rootNodes = oCtrl.arrangedObjects as? [AnyObject]
			} else {
				content.rootNodes = []
			}
			return content
		}
		return nil
	}

	func selectionDidChange(_ selector: AnyObject?, fromUpDown updown: Bool, userInput: String?) {
		guard allowSelectionUpdate else {return}
		if let selection: [AnyObject] = selector as? [AnyObject],
			let o = selection.first as? ZDComboBoxItem,
			let comboBox = combo,
            let editor: NSTextView = combo!.currentEditor() as? NSTextView
            {
				if updown {
					comboBox.stringValue = o.title
				}
                if userInput != nil && !userInput!.isEmpty {
                    if let r = o.title.lowercased().range(of: userInput!.lowercased() ) {
                        let nsrange = o.title.nsRange(from: r)
                        let remainRange = NSMakeRange( nsrange.location+nsrange.length, o.title.characters.count-(nsrange.location+nsrange.length))
                        editor.setSelectedRange(remainRange)
                    }
                } else {
                    editor.selectedRanges = [NSMakeRange(0,o.title.characters.count) as NSValue]
                }
				comboBox.selectedObject = o.representedObject
				if mouseDown {
					ZDPopupWindowManager.popupManager.hidePopup()
				}
		}
	}

	func control(_ control: NSControl, isValidObject obj: Any?) -> Bool {
		return true
	}

	func control(_ control: NSControl, textShouldBeginEditing fieldEditor: NSText) -> Bool {
		let _ = showPopupForControl(control)
		return true
	}

	func showPopupForControl(_ control: NSControl?) -> PopupOpenStatus {
		if popupContent == nil {
			allowSelectionUpdate = false
			defer { allowSelectionUpdate = true }
			if let control: ZDComboBox = control as? ZDComboBox {
				if combo == nil {
					combo = control
				}
				popupContent = createPopupContent()
				if popupContent == nil {
					return PopupOpenStatus.NA
				}
				popupContent!.delegate = self
			} else {
				return PopupOpenStatus.NA
			}
		}
		let rc = ZDPopupWindowManager.popupManager.showPopupForControl(
			control, withContent: popupContent!.view)

		if rc != .BeenOpen, let control: ZDComboBox = control as? ZDComboBox {
			if let editor: NSTextView = control.currentEditor() as? NSTextView {
                var selectionString = control.stringValue
                if editor.selectedRanges.count > 0 {
                    if editor.selectedRanges.first!.rangeValue.location > 0 {
                        let idx = selectionString.index(selectionString.startIndex, offsetBy:editor.selectedRanges.first!.rangeValue.location)
                        selectionString = selectionString.substring(to: idx)
                    }
                }
				if let s: String = popupContent!.moveSelectionTo(selectionString, filtered: rc == .BeenOpen) as? String {
					if !didDelete {
						let insertionPoint: Int = editor.selectedRanges.first!.rangeValue.location
						editor.string = s
						editor.selectedRange = NSRange( location: insertionPoint, length: s.characters.count - insertionPoint)
					}
				}
			}
		}

		return rc
	}

	func control(_ control: NSControl,
		textView: NSTextView,
		completions words: [String],
		forPartialWordRange charRange: NSRange,
		indexOfSelectedItem index: UnsafeMutablePointer<Int>) -> [String] {
			return []
	}

	func control(_ control: NSControl, textShouldEndEditing fieldEditor: NSText) -> Bool {
		updateBindingProperty()
		ZDPopupWindowManager.popupManager.hidePopup()
		return true
	}

	override func controlTextDidChange(_ obj: Notification) {
		combo = nil
		if let control: ZDComboBox = obj.object as? ZDComboBox {
			combo = control
			if dontSearch {
				dontSearch = false
				return
			}
			let _ = showPopupForControl(combo)
			if let editor: NSTextView = control.currentEditor() as? NSTextView {
				if let s: String = popupContent!.moveSelectionTo(control.stringValue, filtered: true) as? String {
					if !didDelete {
						let insertionPoint: Int = editor.selectedRanges.first!.rangeValue.location
						editor.string = s
						editor.selectedRange = NSRange( location: insertionPoint, length: s.characters.count - insertionPoint)
					}
				}
			}
		}
	}

	func control(_ control: NSControl,
		textView: NSTextView,
		doCommandBy commandSelector: Selector) -> Bool {

			didDelete = false

			if commandSelector == #selector(NSResponder.moveUp(_:)) {
				if showPopupForControl(control) != .NA {
					popupContent!.moveSelectionUp(true)
				}
				return true
			}
			if commandSelector == #selector(NSResponder.deleteBackward(_:)) {
				didDelete = true
				return false
			}
			if commandSelector == #selector(NSResponder.moveDown(_:)) {
                switch(showPopupForControl(control))
                {
                case .BeenOpen:
					popupContent!.moveSelectionUp(false)
                case .NA:
					if let editor: NSTextView = control.currentEditor() as? NSTextView {
						if let s: String = popupContent!.moveSelectionTo(control.stringValue, filtered: false) as? String {
							let insertionPoint: Int = editor.selectedRanges.first!.rangeValue.location
							editor.string = s
							editor.selectedRange = NSRange( location: insertionPoint, length: s.characters.count - insertionPoint)
						}
					}
					return false
                default: break
				}
				return true
			}
			if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
                if popupContent != nil {
                    if popupContent!.filter.isEmpty {
                        ZDPopupWindowManager.popupManager.hidePopup()
                    } else {
                        let selection = popupContent!.selectedObjects()
                        if selection.count > 0 {
                            if let item = selection[0] as? ZDComboBoxItem {
                                let s = popupContent!.moveSelectionTo(item.title, filtered: false) as? String
                                if let editor: NSTextView = control.currentEditor() as? NSTextView {
                                    editor.string = s
                                    editor.selectedRanges = [NSMakeRange(0,editor.string!.characters.count) as NSValue]
                                }
                            }
                        }
                        popupContent!.filter = ""
                        popupContent!.invalidateFilter()
                    }
                }
				return true
			}
			if commandSelector == #selector(NSResponder.insertTab(_:)) {
				guard let selection = popupContent?.selectedObjects() else { return false }
				guard let field = combo else { return false }
				if field.stringValue.characters.count == 0 { return false }
				if selection.count == 0 { return false }
                var filter: String?
                if let cb = popupContent as? ZDComboBoxTree {
                    filter = cb.filter
                } else {
                    filter = nil
                }
				selectionDidChange(selection as AnyObject?, fromUpDown: true, userInput: filter )
				ZDPopupWindowManager.popupManager.hidePopup()
			}
			return false
	}
    
    func classTypeFromString( name: String? ) -> AnyClass? {
        if name == nil {
            return nil
        }
        guard let classType = NSClassFromString(name!) else {
            let appName = Bundle.main.infoDictionary!["CFBundleName"] as! String
            return NSClassFromString(appName + "." + name!)
        }
        return classType
    }

	func updateBindingProperty() {
		if let combobox = combo,
			let bindingInfo:[AnyHashable: Any] = combobox.infoForBinding(NSValueBinding),
			let control: NSObject = bindingInfo[NSObservedObjectKey as NSString] as? NSObject,
			let path = bindingInfo[NSObservedKeyPathKey as NSString] as? String {

            // var objectValue: AnyObject? = combobox.stringValue as AnyObject?
            if combobox.stringValue.isEmpty {
                control.setValue( nil, forKeyPath:path)
                return
            }
            var objectValue: Any?
            let stringValue = combobox.stringValue

            if let options:[AnyHashable: Any] = bindingInfo[NSOptionsKey] as? [AnyHashable: Any] {
                
                if let transformer = options[NSValueTransformerBindingOption] as? ValueTransformer {
                    objectValue = transformer.reverseTransformedValue(stringValue) as AnyObject?
                    if objectValue == nil {
                        combobox.stringValue = ""
                        control.setValue( nil, forKeyPath:path)
                    } else {
                        if let managedObject = objectValue as? NSManagedObject {
                            if managedObject.isInserted {
                                if let refreshable = combo!.topLevelObjects as? HasRefresh {
                                    refreshable.refreshData!()
                                }
                                // we have to update the content of the popup if this object was added
                                if let oCtrl = combo!.topLevelObjects as? NSTreeController {
                                    popupContent!.rootNodes = (oCtrl.arrangedObjects as AnyObject).children as [NSTreeNode]?
                                } else if let oCtrl = combo?.topLevelObjects as? NSArrayController {
                                    popupContent!.rootNodes = oCtrl.arrangedObjects as? [AnyObject]
                                } else {
                                    popupContent!.rootNodes = []
                                }
                            }
                        }
                    }
                    // get context of the object refering by path
                    let destinationMOC: NSManagedObjectContext? = getManagedObjectContext( control, path: path )
                    let sourceMOC: NSManagedObjectContext?
                    if let objectValueAsManagedObject = objectValue as? NSManagedObject {
                        sourceMOC = objectValueAsManagedObject.managedObjectContext
                        
                        if destinationMOC != sourceMOC {
                            if let moc = destinationMOC {
                                objectValue = moc.object(with: objectValueAsManagedObject.objectID)
                            }
                        }
                    }
                } else if let valueType = combobox.valueType {
                    if let valueClass = classTypeFromString(name: valueType) {
                        if valueClass.isSubclass(of: NSManagedObject.self) {
                            // managed object
                            print("control instance of managed object must have transformer optoin set")
                        } else {
                            // if valueClass.isSubclass(of: NSString.self) {
                            objectValue = stringValue
//                            } else {
//                                print("control instance with type \(valueType) not supported")
//                                objectValue = nil
                        }
                        if objectValue != nil {
                            var nodes: [AnyObject]?
                            if let oCtrl = combobox.topLevelObjects as? NSTreeController {
                                nodes = oCtrl.arrangedObjects as? [AnyObject]
                            } else if let oCtrl = combobox.topLevelObjects as? NSArrayController {
                                nodes = oCtrl.arrangedObjects as? [AnyObject]
                            } else if combobox.topLevelObjects != nil {
                                let msg = "ControllerTypeError".localized(tableName: "ZDComboBox")
                                NSException(name: NSExceptionName(rawValue: "Invalid argument"), reason: msg, userInfo: nil).raise()
                            }
                            if nodes != nil {
                                for node in nodes! {
                                    if let nodeValue = node.value(forKey: combobox.displayKey) as? String {
                                        if nodeValue == objectValue as! String {
                                            objectValue = node
                                            break
                                        }
                                    }
                                }
                            }
                        }
                    }
                } else {
                    // direct binding to an object
                    // find item with exact name as text field
                    if let oCtrl = combobox.topLevelObjects as? NSTreeController {
                        var nodes: [NSTreeNode]?
                        nodes = (oCtrl.arrangedObjects as AnyObject).children
                        objectValue = objectWith(displayKey: combobox.displayKey, equal: stringValue, in: nodes )
                    } else if let oCtrl = combobox.topLevelObjects as? NSArrayController {
                        for item in (oCtrl.arrangedObjects as? [NSObject])! {
                            if item.value(forKey: combobox.displayKey) as? String == stringValue {
                                objectValue = item
                                break
                            }
                        }
                    } else if combobox.topLevelObjects != nil {
                        let msg = "ControllerTypeError".localized(tableName: "ZDComboBox")
                        NSException(name: NSExceptionName(rawValue: "Invalid argument"), reason: msg, userInfo: nil).raise()
                    }
                }
            }
            if let obj = objectValue as? NSTreeNode {
                control.setValue( obj.representedObject, forKey: path)
            } else {
                control.setValue( objectValue, forKeyPath:path)
            }
		}
	}
    
    func objectWith( displayKey: String, equal searchTerm: String, in nodes: [NSTreeNode]? ) -> AnyObject? {
        if nodes == nil {
            return nil
        }
        for node in nodes! {
            if let obj: AnyObject = node.representedObject as AnyObject? {
                if let nodeValue = obj.value(forKey: displayKey) as? String {
                    if nodeValue == searchTerm {
                        return node
                    }
                }
            }
            let obj = objectWith(displayKey: displayKey, equal: searchTerm, in: node.children)
            if obj != nil {
                return obj
            }
        }
        return nil
    }

	func getManagedObjectContext( _ target: NSObject, path: String ) -> NSManagedObjectContext? {
		if let control = target as? NSView {
			if let mo = control.value(forKeyPath: path) as? NSManagedObject {
				return mo.managedObjectContext
			}
			var pathComponents = path.components(separatedBy: ".")
			if pathComponents.count > 1 {
				pathComponents.removeLast()
				let parent = pathComponents.joined(separator: ".")
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
	func localized(tableName: String?, bundle: Bundle, comment: String = "") -> String {
		return NSLocalizedString( self, tableName: tableName,
			bundle: bundle, value: self, comment: comment)
	}
	func localized(tableName: String?, comment: String = "") -> String {
		return NSLocalizedString( self, tableName: tableName,
			bundle: Bundle.main, value: self, comment: comment)
	}
	func localized(comment: String) -> String {
		return NSLocalizedString( self, tableName: nil,
			bundle: Bundle.main, value: self, comment: comment)
	}
	func localized() -> String {
		return NSLocalizedString( self, tableName: nil,
			bundle: Bundle.main, value: self, comment: "")
	}
}
