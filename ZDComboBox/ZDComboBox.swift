//
//  ZDComboBox.swift
//  MyFina
//
//  Created by Dmitriy Zakharkin on 3/7/15.
//  Copyright (c) 2015 ZDima. All rights reserved.
//

import Cocoa

/**
 *  HasRefresh protocol can be used with NSArrayController or NSTreeController to
 *  trigger a refresh when NSManagedObject has been insered.
 */
@objc
public protocol HasRefresh {
	@objc optional func refreshData();
}

@objc
public protocol ZDComboBoxDelegate {
    func getTopLevelObjects() -> NSObjectController?;
}

@IBDesignable
open class ZDComboBox: NSTextField {

	/// Define key for display name
	@IBInspectable var displayKey: String!

	/// Define key for child list
	@IBInspectable var childsKey: String?

	/// When underlineField set to true the text field will be shown with underline line
	@IBInspectable var underlineField: Bool = false
	/// Color of the underline line
	@IBInspectable var underlineColor: NSColor? = nil

	/// NSArrayController or NSTreeController for popup items
	@IBOutlet      var topLevelObjects: NSObjectController? {
		didSet {
			onObjectCollectionChange(oldValue,topLevelObjects)
		}
	}

	@IBOutlet var comboboxDelegate: ZDComboBoxDelegate? {
		didSet {
			if comboboxDelegate != nil {
				if let ctrl = comboboxDelegate!.getTopLevelObjects() {
				    self.topLevelObjects = ctrl
				}
			}
		}
	}
    
	override open class func cellClass() -> AnyClass? {
		return ZDComboBoxCell.self
	}

	init(frame frameRect: NSRect, displayKey dkey: String) {
		displayKey = dkey
		super.init(frame: frameRect)
		setup()
	}

	required public init?(coder: NSCoder) {
		if let ucoder = coder as? NSKeyedUnarchiver {
			// replace class for NSTextFieldCell to use cell object for ZDComboBox
			let superCellClassName = "NSTextFieldCell"
			let oldValue: AnyClass? = ucoder.class(forClassName: superCellClassName)
			ucoder.setClass(ZDComboBox.cellClass(), forClassName: superCellClassName)
			super.init(coder: coder)
			// restore previous setting
			ucoder.setClass(oldValue, forClassName: superCellClassName)
		} else {
			super.init(coder: coder)
		}
		setup()
	}

	deinit {
		if let oldController = topLevelObjects {
			oldController.removeObserver(self, forKeyPath: "content")
		}
	}

	var buttonState: Int {
		get {
			if let btn = dropDownButton { return btn.state }
			return 0
		}
		set {
			if let btn = dropDownButton { btn.state = newValue }
		}
	}

	var isHierarchical: Bool {
		if topLevelObjects is NSTreeController {
			return true
		}
		return false
	}

	func setContentRootNode() {
		if let cbDelegate = delegate as? ZDComboFieldDelegate,
			let content = cbDelegate.popupContent {
				if let oCtrl = topLevelObjects as? NSTreeController {
					content.rootNodes = oCtrl.arrangedObjects as? [AnyObject]
				} else if let oCtrl = topLevelObjects as? NSArrayController {
					content.rootNodes = oCtrl.arrangedObjects as? [AnyObject]
				} else if topLevelObjects != nil {
					let msg = "ControllerTypeError".localized(tableName: "ZDComboBox")
					NSException(name: NSExceptionName(rawValue: "Invalid argument"), reason: msg, userInfo: nil).raise()
					content.rootNodes = []
				} else {
					content.rootNodes = []
				}
				content.invalidateFilter()
		}
	}

	override open func observeValue( forKeyPath keyPath: String?, of object: Any?,
		change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
			if keyPath == "content" {
				setContentRootNode()
			}
	}

	fileprivate var userDelegate: AnyObject?
	fileprivate var cbDelegate: ZDComboFieldDelegate = ZDComboFieldDelegate()
	fileprivate var dropDownButton: NSButton?

	func setup() {
		if delegate == nil {
			delegate = cbDelegate
		} else if !delegate!.isKind(of: ZDComboFieldDelegate.self) {
			userDelegate = delegate
			delegate = cbDelegate
		}
		cbDelegate.combo = self
		// setup drop down button
		let buttonHeight = frame.size.height
		let buttonWidth = buttonHeight*ZDComboBoxCell.buttonAspect
		let buttonFrame = NSIntegralRect(
			NSRect(x: frame.size.width-buttonWidth, y: 0,
				width: buttonWidth, height: buttonHeight))
		dropDownButton = NSButton(frame: buttonFrame)
		dropDownButton!.refusesFirstResponder = true
		dropDownButton!.setButtonType(NSButtonType.pushOnPushOff)
		dropDownButton!.bezelStyle = NSBezelStyle.shadowlessSquare
		dropDownButton!.image = NSImage(named: "NSDropDownIndicatorTemplate")
		dropDownButton!.target = self
		dropDownButton!.action = #selector(ZDComboBox.dropDownButtonClicked(_:))
		self.addSubview(dropDownButton!)
		if underlineField == true {
			self.drawsBackground = false
		}
	}

	override open func resizeSubviews(withOldSize oldSize: NSSize) {
		// need to move button if frame of a control changed
		let buttonHeight = frame.size.height
		let buttonWidth = buttonHeight*ZDComboBoxCell.buttonAspect
		dropDownButton!.frame = NSIntegralRect(
			NSRect(x: frame.size.width-buttonWidth, y: 0,
				width: buttonWidth, height: buttonHeight))
		super.resizeSubviews(withOldSize: oldSize)
	}

	func dropDownButtonClicked(_ sender: AnyObject) {
		if dropDownButton!.state == NSOffState {
			ZDPopupWindowManager.popupManager.hidePopup()
		} else {
			if self.window!.firstResponder != self {
				self.window!.makeFirstResponder(self)
			}
			if let popupDelegate = delegate as? ZDPopupContentDelegate {
				if popupDelegate.showPopupForControl(self) == .NA {
					dropDownButton!.state = NSOffState
				}
			}
		}
	}

	override open func setValue(_ value: Any?, forKey key: String) {
		switch(key) {
		case "displayKey":
			if let string = value as? String {
				displayKey = string
			}
		case "childsKey":
			if let string = value as? String {
				childsKey = string
			}
		default:
			super.setValue(value, forKey: key)
		}
	}
    
    var myObjectValue: NSObject?
    
    open override var objectValue: Any? {
        set {
            if newValue == nil {
                super.objectValue = nil
                return
            }
            if let cbdelegate = delegate as? ZDComboFieldDelegate {
                myObjectValue = cbdelegate.objectValue(by: newValue as AnyObject) as! NSObject?
            }
            if myObjectValue != nil {
                super.objectValue = myObjectValue!.value(forKey: displayKey! )
            } else {
                super.objectValue = ""
            }
            return
        }
        get {
            return myObjectValue
        }
    }

	dynamic var selectedObject: Any? {
		didSet {
			// TODO set value of the text field
		}
	}

    override open func selectText(_ sender: Any?) {
        super.selectText(sender)
        let insertionPoint: Int = stringValue.characters.count
        let r: NSRange = NSRange(location: insertionPoint,length: 0)
        if let w = window, let textEditor = w.fieldEditor( true, for: self) {
            textEditor.selectedRange = r
            if underlineField {
                textEditor.drawsBackground = false
            }
        }
    }
    
    override open func textDidEndEditing(_ notification: Notification) {
        ZDPopupWindowManager.popupManager.hidePopup()
        let insertionPoint: Int = stringValue.characters.count
        let r: NSRange = NSRange(location: insertionPoint,length: 0)
        if let textEditor = window!.fieldEditor( true, for: self) {
            textEditor.selectedRange = r
        }
		if let popupDelegate = delegate as? ZDPopupContentDelegate {
			popupDelegate.updateBindingProperty()
		}
        super.textDidEndEditing(notification)
    }

	fileprivate func onObjectCollectionChange(
		_ oldValue: NSObjectController?,
		_ newValue: NSObjectController?) {
			setContentRootNode()
			if let oldController = oldValue {
				oldController.removeObserver(self, forKeyPath: "content")
			}
			if let newController = topLevelObjects {
				let options: NSKeyValueObservingOptions = [NSKeyValueObservingOptions.old, NSKeyValueObservingOptions.new]
				newController.addObserver( self, forKeyPath: "content",
					options: options, context: nil)
			}
	}
}
