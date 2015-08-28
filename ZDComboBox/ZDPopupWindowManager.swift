//
//  ZDPopupWindowManager.swift
//  MyFina
//
//  Created by Dmitriy Zakharkin on 3/7/15.
//  Copyright (c) 2015 ZDima. All rights reserved.
//

import Cocoa

extension NSView {

	func flippedRect( rect: NSRect ) -> NSRect {
		var rectRet: NSRect = rect
		if self.superview != nil {
			if !self.superview!.flipped {
				rectRet.origin.y = self.superview!.frame.size.height - rectRet.origin.y - rectRet.size.height
			}
		}
		return rectRet
	}
}

class ZDPopupWindowManager: NSObject {

    private var control: NSControl? = nil
    private var popupWindow: ZDPopupWindow? = nil
	private var dropDownButtonObject: NSButton?
    private var originalHeight: CGFloat = 0

    static var popupManager = ZDPopupWindowManager()

    override init() {
        super.init()

        var contentRect: NSRect = NSZeroRect
        contentRect.size.height = 200

        popupWindow = ZDPopupWindow(contentRect: contentRect,
			styleMask: NSBorderlessWindowMask,
			backing: NSBackingStoreType.Buffered,
			defer: false, screen: nil)

        popupWindow!.movableByWindowBackground = false
        popupWindow!.excludedFromWindowsMenu = true
        popupWindow!.hasShadow = true
        popupWindow!.titleVisibility = NSWindowTitleVisibility.Hidden
    }

    func showPopupForControl(userControl: NSControl?, withContent content: NSView?) -> Bool
    {
        if control == userControl {
            return true
        }

        if control != nil {
            hidePopup()
        }

        control = userControl

		if let ctrl = control as? ZDComboBox, let pWindow = popupWindow, let window = ctrl.window {

			originalHeight = content!.bounds.size.height

			pWindow.contentView = content!
			layoutPopupWindow()
			window.addChildWindow(pWindow, ordered: NSWindowOrderingMode.Above)

			NSNotificationCenter.defaultCenter().addObserver(self,
				selector: "windowDidResize:",
				name: NSApplicationDidResignActiveNotification,
				object: ctrl.window )

			NSNotificationCenter.defaultCenter().addObserver(self,
				selector: "applicationDidResignActive:",
				name: NSWindowDidResizeNotification,
				object: NSApplication.sharedApplication() )

			ctrl.buttonState = NSOnState
			return true
		}

        return false
    }

    func hidePopup()
    {
		if let ctrl = control as? ZDComboBox,
			let window = ctrl.window,
			let pWindow = popupWindow {
				if popupWindow!.visible {
					popupWindow!.orderOut(self)
					ctrl.window!.removeChildWindow(popupWindow!)
					NSNotificationCenter.defaultCenter().removeObserver(self)
				}
				ctrl.buttonState = NSOffState
        }
        control = nil
    }

    func applicationDidResignActive(node: NSNotification?) {
        hidePopup()
    }

    func layoutPopupWindow() {
        if let ctrl = control, let pWindow = popupWindow {
            var screenFrame: NSRect
			if let screen = pWindow.screen {
                screenFrame = screen.visibleFrame
            } else if let screen = NSScreen.mainScreen() {
                screenFrame = screen.visibleFrame
			} else {
				NSException(name: "runtime", reason: "no screen", userInfo: nil)
				return
			}
			let contentRect: NSRect = ctrl.bounds
			let controlRect: NSRect = ctrl.flippedRect(ctrl.frame)
            var frame = NSRect(
				x: controlRect.origin.x,
				y: controlRect.origin.y + controlRect.size.height-2,
				width: contentRect.size.width,
				height: originalHeight)

			var parentView: NSView? = ctrl.superview
            while parentView != nil {
                let parentFrame: NSRect = parentView!.flippedRect(parentView!.frame)
				frame = NSOffsetRect(frame,
					parentFrame.origin.x - parentView!.bounds.origin.x,
					parentFrame.origin.y - parentView!.bounds.origin.y)
                parentView = parentView!.superview
            }
			frame = adjustToScreen(frame,screenFrame,ctrl)
            pWindow.setFrame(frame, display: false)
        }
    }

	func adjustToScreen(srcFrame: NSRect, _ screenFrame: NSRect, _ ctrl: NSControl) -> NSRect {
		let screenRect = ctrl.window!.frame
		let contentRect: NSRect = ctrl.bounds
		var frame = srcFrame
		frame.origin.x = frame.origin.x + screenRect.origin.x
		frame.origin.y = screenRect.origin.y+screenRect.size.height-frame.origin.y - originalHeight

		let x2: CGFloat = frame.origin.x + frame.size.width
		if frame.origin.x < screenFrame.origin.x {
			frame.origin.x = screenFrame.origin.x
		}
		if frame.origin.y < screenFrame.origin.y {
			frame.origin.y = frame.origin.y + frame.size.height + contentRect.size.height
		}
		if x2 > screenFrame.size.width {
			frame.origin.x -= (x2 - screenFrame.size.width)
		}
		return frame
	}

    func windowDidResignKey(note: NSNotification?) {
        hidePopup()
    }

    func windowDidResize(note: NSNotification?) {
        layoutPopupWindow()
    }
}

@objc(ZDPopupWindow)
class ZDPopupWindow: NSWindow {
    override var canBecomeKeyWindow: Bool { get { return false } }
}

@objc protocol ZDPopupContentDelegate {

    func selectionDidChange( selector: AnyObject?, fromUpDown updown: Bool );
	func updateBindingProperty();
	func showPopupForControl(control: NSControl?) -> Bool;
	var combo: ZDComboBox? { get set }
}

class ZDPopupContent: NSViewController {

    var delegate: ZDPopupContentDelegate?
	var rootNodes: [AnyObject]? {
		didSet { convertUserObjectToItems() }
	}
	var items: [ZDComboBoxItem] = []
	var filter: String = "" {
		didSet {
			if oldValue != filter {
				invalidateFilter()
			}
		}
	}
	/// filter items again
	func invalidateFilter() {}
    func moveSelectionUp(up: Bool) {}
    func moveSelectionTo(string: String?, filtered: Bool ) -> NSString? {
        return nil
    }
	func convertUserObjectToItems() {
		items = []
		if let nodes = rootNodes as? [NSObject], let comboBox = delegate!.combo {
			for child in nodes {
				if let treeNode = child as? NSTreeNode,
					let obj = treeNode.representedObject as? NSObject,
					let item = ZDComboBoxItem.itemWith( obj,
						hierarchical: comboBox.isHierarchical,
						displayKey: comboBox.displayKey,
						childsKey: comboBox.childsKey) {
							items.append(item)
				} else {
					if let item = ZDComboBoxItem.itemWith( child,
						hierarchical: false,
						displayKey: comboBox.displayKey,
						childsKey: comboBox.childsKey) {
							items.append(item)
					}
				}
			}
		}
	}
}
