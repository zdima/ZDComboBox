//
//  MFCategory.swift
//  combobox
//
//  Created by Dmitriy Zakharkin on 8/8/15.
//  Copyright (c) 2015 ZDima. All rights reserved.
//

import Foundation

public class MFCategory: NSObject {
	public init( name inName: String, categories subs: [AnyObject] ) {
		name = inName
		if let categoryList = subs as? [MFCategory] {
			categories = categoryList
		} else {
			categories = []
		}
	}
	public var name: String = ""
	public var categories: [MFCategory] = []

	public override func valueForKey(key: String) -> AnyObject? {
		switch(key) {
		case "name":
			return name
		case "categories":
			return categories
		default:
			return super.valueForKey(key)
		}
	}
	public override func setValue(value: AnyObject?, forKey key: String) {
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

	public func selfOrHasChildWithKey( key: String ) -> MFCategory? {
		if categories.count > 0 {
			var filtered: [MFCategory] = []

			for category in categories {
				if let filteredCategory = category.selfOrHasChildWithKey(key) {
					filtered.append(filteredCategory)
				}
			}

			if filtered.count > 0 {
				return MFCategory( name: name, categories: filtered )
			} else if name.lowercaseString.rangeOfString(key) != nil {
				return MFCategory( name: name, categories: [] )
			}
		} else {
			if name.lowercaseString.rangeOfString(key) != nil {
				return self
			}
		}
		return nil
	}
}
