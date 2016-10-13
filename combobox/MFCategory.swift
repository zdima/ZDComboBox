//
//  MFCategory.swift
//  combobox
//
//  Created by Dmitriy Zakharkin on 8/8/15.
//  Copyright (c) 2015 ZDima. All rights reserved.
//

import Foundation

@objc(MFCategory)
open class MFCategory: NSObject, NSCopying {

    public override init() {
        name = ""
        categories = []
    }
	public init( name inName: String, categories subs: [AnyObject] ) {
		name = inName
		if let categoryList = subs as? [MFCategory] {
			categories = categoryList
		} else {
			categories = []
		}
	}
    
    required public init( src: MFCategory ) {
        name = src.name
        categories = src.categories
    }
    
    public func copy(with zone: NSZone? = nil) -> Any
    {
        return type(of:self).init(src: self)
    }
    
	open var name: String = ""
	open var categories: [MFCategory] = []

	open override func value(forKey key: String) -> Any? {
		switch(key) {
		case "name":
			return name
		case "categories":
			return categories
		default:
			return super.value(forKey: key)
		}
	}
	open override func setValue(_ value: Any?, forKey key: String) {
		switch(key) {
		case "name":
			if let string = value as? String {
				name = string
			}
		case "categories":
			if let categoryList = value as? [MFCategory] {
				categories = categoryList
			}
		default:
			super.setValue(value, forKey: key)
		}
	}

	open func selfOrHasChildWithKey( _ key: String ) -> MFCategory? {
		if categories.count > 0 {
			var filtered: [MFCategory] = []

			for category in categories {
				if let filteredCategory = category.selfOrHasChildWithKey(key) {
					filtered.append(filteredCategory)
				}
			}

			if filtered.count > 0 {
				return MFCategory( name: name, categories: filtered )
			} else if name.lowercased().range(of: key) != nil {
				return MFCategory( name: name, categories: [] )
			}
		} else {
			if name.lowercased().range(of: key) != nil {
				return self
			}
		}
		return nil
	}
}
