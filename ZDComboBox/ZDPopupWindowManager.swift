//
//  ZDPopupWindowManager.swift
//  MyFina
//
//  Created by Dmitriy Zakharkin on 3/7/15.
//  Copyright (c) 2015 ZDima. All rights reserved.
//

import Cocoa

extension NSView {

	func flippedRect( _ rect: NSRect ) -> NSRect {
		var rectRet: NSRect = rect
		if self.superview != nil {
			if !self.superview!.isFlipped {
				rectRet.origin.y = self.superview!.frame.size.height - rectRet.origin.y - rectRet.size.height
			}
		}
		return rectRet
	}
}

class ZDPopupWindowManager: NSObject {

    fileprivate var control: NSControl? = nil
    fileprivate var popupWindow: ZDPopupWindow? = nil
	fileprivate var dropDownButtonObject: NSButton?
    fileprivate var originalHeight: CGFloat = 0
    
    static var popupManager = ZDPopupWindowManager()
    
    override init() {
        super.init()

        var contentRect: NSRect = NSZeroRect
        contentRect.size.height = 200

        popupWindow = ZDPopupWindow(contentRect: contentRect,
			styleMask: NSBorderlessWindowMask,
			backing: NSBackingStoreType.buffered,
			defer: false, screen: nil)

        popupWindow!.isMovableByWindowBackground = false
        popupWindow!.isExcludedFromWindowsMenu = true
        popupWindow!.hasShadow = true
        popupWindow!.titleVisibility = NSWindowTitleVisibility.hidden
    }

    /// Will close previously open drop down list associated with another userControl.
    /// Open drop down list if not open and associated with userControl.
    ///
    /// - parameter userControl: ZDComboBox instance
    /// - parameter content:     NSView representing the drop down list
    ///
    /// - returns: true when drop down list successfully opened. False when can't asscociate userControl with drop down list.
    func showPopupForControl(_ userControl: NSControl?, withContent content: NSView?) -> PopupOpenStatus
    {
        if control == userControl {
            // already open
            return PopupOpenStatus.BeenOpen
        }

        if control != nil {
            // close another drop down list
            hidePopup()
            control = nil
        }

		if let ctrl = userControl as? ZDComboBox, let pWindow = popupWindow, let window = ctrl.window {

            control = userControl
            
			originalHeight = content!.bounds.size.height

			pWindow.contentView = content!
			do {
				try layoutPopupWindow()
			} catch let error as NSError {
				print("can't layout the popup \(error.localizedDescription)")
			} catch {
			}
			window.addChildWindow(pWindow, ordered: NSWindowOrderingMode.above)

			NotificationCenter.default.addObserver(self,
				selector: #selector(NSWindowDelegate.windowDidResize(_:)),
				name: NSNotification.Name.NSApplicationDidResignActive,
				object: ctrl.window )

			NotificationCenter.default.addObserver(self,
				selector: #selector(NSApplicationDelegate.applicationDidResignActive(_:)),
				name: NSNotification.Name.NSWindowDidResize,
				object: NSApplication.shared() )

			ctrl.buttonState = NSOnState
			return PopupOpenStatus.Created
		}

        return PopupOpenStatus.NA
    }

    func hidePopup()
    {
		if let ctrl = control as? ZDComboBox,
			let ctrlWindow = ctrl.window,
			let pWindow = popupWindow {
				if pWindow.isVisible {
					pWindow.orderOut(self)
					ctrlWindow.removeChildWindow(pWindow)
					NotificationCenter.default.removeObserver(self)
				}
				ctrl.buttonState = NSOffState
        }
        control = nil
    }

    func applicationDidResignActive(_ node: Notification?) {
        hidePopup()
    }

    func layoutPopupWindow() throws {
        if let ctrl = control, let pWindow = popupWindow {
            var screenFrame: NSRect
			if let screen = pWindow.screen {
                screenFrame = screen.visibleFrame
            } else if let screen = NSScreen.main() {
                screenFrame = screen.visibleFrame
			} else {
				throw NSError(domain: "runtime", code: 1, userInfo: ["reason" : "no screen"])
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

	func adjustToScreen(_ srcFrame: NSRect, _ screenFrame: NSRect, _ ctrl: NSControl) -> NSRect {
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

    func windowDidResignKey(_ note: Notification?) {
        hidePopup()
    }

    func windowDidResize(_ note: Notification?) {
		do { try layoutPopupWindow() }
		catch let error as NSError {
			print("can't layout the popup \(error.localizedDescription)")
		}
    }
}

@objc(ZDPopupWindow)
class ZDPopupWindow: NSWindow {
    override var canBecomeKey: Bool { get { return false } }
}

@objc enum PopupOpenStatus: Int {
    case Created
    case BeenOpen
    case NA
}

@objc protocol ZDPopupContentDelegate {

    
    func selectionDidChange( _ selector: AnyObject?, fromUpDown updown: Bool, userInput: String? );
	func updateBindingProperty();
	func showPopupForControl(_ control: NSControl?) -> PopupOpenStatus;
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
    func moveSelectionUp(_ up: Bool) {}
    func moveSelectionTo(_ string: String?, filtered: Bool ) -> NSString? {
        return nil
    }
	func selectedObjects() -> [AnyObject] {
		return []
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
