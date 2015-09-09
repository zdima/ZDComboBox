//
//  ZDComboBox.swift
//  MyFina
//
//  Created by Dmitriy Zakharkin on 3/7/15.
//  Copyright (c) 2015 ZDima. All rights reserved.
//

import Cocoa

@IBDesignable
public class ZDComboBox: NSTextField {

	/// Define key for display name
	@IBInspectable var displayKey: String!

	/// Define key for child list
	@IBInspectable var childsKey: String?

	/// NSArrayController or NSTreeController for popup items
	@IBOutlet      var topLevelObjects: NSObjectController? {
		didSet {
			onObjectCollectionChange(oldValue,topLevelObjects)
		}
	}

	override public class func cellClass() -> AnyClass? {
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
			let oldValue: AnyClass? = ucoder.classForClassName(superCellClassName)
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
					NSException(name: "Invalid argument", reason: msg, userInfo: nil).raise()
					content.rootNodes = []
				} else {
					content.rootNodes = []
				}
				content.invalidateFilter()
		}
	}

	override public func observeValueForKeyPath( keyPath: String?, ofObject object: AnyObject?,
		change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
			if keyPath == "content" {
				setContentRootNode()
			}
	}

	private var userDelegate: AnyObject?
	private var cbDelegate: ZDComboFieldDelegate = ZDComboFieldDelegate()
	private var dropDownButton: NSButton?

	func setup() {
		if delegate == nil {
			delegate = cbDelegate
		} else if !delegate!.isKindOfClass(ZDComboFieldDelegate.self) {
			userDelegate = delegate
			delegate = cbDelegate
		}
		// setup drop down button
		let buttonHeight = frame.size.height
		let buttonWidth = buttonHeight*ZDComboBoxCell.buttonAspect
		let buttonFrame = NSIntegralRect(
			NSRect(x: frame.size.width-buttonWidth, y: 0,
				width: buttonWidth, height: buttonHeight))
		dropDownButton = NSButton(frame: buttonFrame)
		dropDownButton!.setButtonType(NSButtonType.PushOnPushOffButton)
		dropDownButton!.bezelStyle = NSBezelStyle.ShadowlessSquareBezelStyle
		dropDownButton!.image = NSImage(named: "NSDropDownIndicatorTemplate")
		dropDownButton!.target = self
		dropDownButton!.action = "dropDownButtonClicked:"
		self.addSubview(dropDownButton!)
	}

	override public func resizeSubviewsWithOldSize(oldSize: NSSize) {
		// need to move button if frame of a control changed
		let buttonHeight = frame.size.height
		let buttonWidth = buttonHeight*ZDComboBoxCell.buttonAspect
		dropDownButton!.frame = NSIntegralRect(
			NSRect(x: frame.size.width-buttonWidth, y: 0,
				width: buttonWidth, height: buttonHeight))
		super.resizeSubviewsWithOldSize(oldSize)
	}

	func dropDownButtonClicked(sender: AnyObject) {
		if dropDownButton!.state == NSOffState {
			ZDPopupWindowManager.popupManager.hidePopup()
		} else {
			if self.window!.firstResponder != self {
				self.window!.makeFirstResponder(self)
			}
			if let popupDelegate = delegate as? ZDPopupContentDelegate {
				if !popupDelegate.showPopupForControl(self) {
					dropDownButton!.state = NSOffState
				}
			}
		}
	}

	override public func setValue(value: AnyObject?, forKey key: String) {
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

	dynamic var selectedObject: AnyObject? {
		didSet {
			// TODO set value of the text field
		}
	}

    override public func selectText(sender: AnyObject?) {
        super.selectText(sender)
        let insertionPoint: Int = stringValue.characters.count
        let r: NSRange = NSRange(location: insertionPoint,length: 0)
        if let textEditor = window!.fieldEditor( true, forObject: self) {
            textEditor.selectedRange = r
        }
    }

	public override func textDidBeginEditing(notification: NSNotification) {
	}

    override public func textDidEndEditing(notification: NSNotification) {
        ZDPopupWindowManager.popupManager.hidePopup()
        let insertionPoint: Int = stringValue.characters.count
        let r: NSRange = NSRange(location: insertionPoint,length: 0)
        if let textEditor = window!.fieldEditor( true, forObject: self) {
            textEditor.selectedRange = r
        }
		if let popupDelegate = delegate as? ZDPopupContentDelegate {
			popupDelegate.updateBindingProperty()
		}
        super.textDidEndEditing(notification)
    }

	private func onObjectCollectionChange(
		oldValue: NSObjectController?,
		_ newValue: NSObjectController?) {
			setContentRootNode()
			if let oldController = oldValue {
				oldController.removeObserver(self, forKeyPath: "content")
			}
			if let newController = topLevelObjects {
				let options: NSKeyValueObservingOptions = [NSKeyValueObservingOptions.Old, NSKeyValueObservingOptions.New]
				newController.addObserver( self, forKeyPath: "content",
					options: options, context: nil)
			}
	}
}
