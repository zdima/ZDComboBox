//
//  AppDelegate.swift
//  combobox
//
//  Created by Dmitriy Zakharkin on 8/8/15.
//  Copyright (c) 2015 ZDima. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

	@IBOutlet weak var window: NSWindow!
	@IBOutlet var data: NSTreeController!
	@IBOutlet var dataList: NSArrayController!
    @IBOutlet weak var dataA: NSObjectController!
    @IBOutlet weak var dataB: NSObjectController!

	func applicationDidFinishLaunching(_ aNotification: Notification) {
		// Insert code here to initialize your application
		loadCategories()
	}

	func applicationWillTerminate(_ aNotification: Notification) {
		// Insert code here to tear down your application
	}

	func loadCategories() {
		let rootNodes: [MFCategory] = [
			categoryAuto,
			categoryBills,
			categoryHouse,
			categoryFood,
			categoryIncome
			]
		data.content = rootNodes

		dataList.content = categoryBills.categories
	}

	var categoryAuto: MFCategory {
		return MFCategory(name: "Auto", categories: [
			MFCategory(name: "Gas & Fuel", categories:[] ),
			MFCategory(name: "Parking", categories:[] ),
			MFCategory(name: "Service", categories:[] ),
			MFCategory(name: "Repair", categories:[] ),
			MFCategory(name: "Roadside assistance", categories:[] ),
			MFCategory(name: "Registration fees", categories:[] )
			] )
	}
	var categoryBills: MFCategory {
		return MFCategory(name: "Bills & Utilities", categories: [
			MFCategory(name: "Phone", categories:[] ),
			MFCategory(name: "Internet", categories:[] ),
			MFCategory(name: "Electricity", categories:[] ),
			MFCategory(name: "TV", categories:[] ),
			MFCategory(name: "Water", categories:[] ),
			MFCategory(name: "Sewer", categories:[] ),
			MFCategory(name: "Gas", categories:[] ),
			MFCategory(name: "Garbage and recycling", categories:[] )
			] )
	}
	var categoryHouse: MFCategory {
		return MFCategory(name: "House", categories: [
			MFCategory(name: "Association dues", categories:[] ),
			MFCategory(name: "Furniture", categories:[] ),
			MFCategory(name: "Supplies", categories:[] ),
			MFCategory(name: "Decorating", categories:[] ),
			MFCategory(name: "Tools", categories:[] ),
			MFCategory(name: "Home repair", categories:[] ),
			MFCategory(name: "Home improvement", categories:[] )
			] )
	}
	var categoryFood: MFCategory {
		return MFCategory(name: "Food", categories: [
			MFCategory(name: "Groceries", categories:[] ),
			MFCategory(name: "Dining out", categories:[] ),
			MFCategory(name: "Vending machines", categories:[] ),
			MFCategory(name: "Coffee house", categories:[] )
			] )
	}
	var categoryIncome: MFCategory {
		return MFCategory(name: "Income", categories: [
			MFCategory(name: "Paycheck", categories:[] ),
			MFCategory(name: "Bonus", categories:[] ),
			MFCategory(name: "Expense reimbursements", categories:[] ),
			MFCategory(name: "Investment", categories:[] ),
			MFCategory(name: "Rental income", categories:[] ),
			MFCategory(name: "Interest earned", categories:[] ),
			MFCategory(name: "Dividends and capital gains", categories:[] ),
			MFCategory(name: "Misc.", categories:[] ),
			MFCategory(name: "Lottery / gambling", categories:[] ),
			MFCategory(name: "Tax refund", categories: [
				MFCategory(name: "Federal", categories:[] ),
				MFCategory(name: "State", categories:[] ),
				MFCategory(name: "Local", categories:[] )
				] )
			])
	}
//			MFCategory(name: "Insurance", categories: [
//				MFCategory(name: "Automobile", categories:[] ),
//				MFCategory(name: "Health", categories:[] ),
//				MFCategory(name: "Life", categories:[] ),
//				MFCategory(name: "Disability", categories:[] ),
//				MFCategory(name: "Long term care", categories:[] )
//				] ),
//			MFCategory(name: "Fees & Charges", categories: [
//				MFCategory(name: "Bank", categories: [
//					MFCategory(name: "Check orders", categories:[] ),
//					MFCategory(name: "Service fees", categories:[] ),
//					MFCategory(name: "Insufficient funds fee", categories:[] ),
//					MFCategory(name: "Minimum balance fee", categories:[] ),
//					MFCategory(name: "ATM fees", categories:[] )
//					] ),
//				MFCategory(name: "Credit Card Fees", categories: [
//					MFCategory(name: "Annual fee", categories:[] ),
//					MFCategory(name: "Finance charge", categories:[] ),
//					MFCategory(name: "Over the limit fee", categories:[] ),
//					MFCategory(name: "Minimum usage fee", categories:[] ),
//					MFCategory(name: "Cash advance fee", categories:[] ),
//					MFCategory(name: "Late fee", categories:[] ),
//					MFCategory(name: "Rewards programs", categories:[] )
//					] ),
//				MFCategory(name: "Loans", categories: [
//					MFCategory(name: "Finance charge / Interest", categories:[] ),
//					MFCategory(name: "Late fee", categories:[] )
//					] )
//				] ),
//			MFCategory(name: "Gifts", categories: [
//				MFCategory(name: "Birthday", categories:[] ),
//				MFCategory(name: "Wedding", categories:[] ),
//				MFCategory(name: "Baby shower", categories:[] ),
//				MFCategory(name: "Holiday", categories:[] ),
//				MFCategory(name: "Anniversary", categories:[] ),
//				MFCategory(name: "Just because", categories:[] )
//				] ),
//			MFCategory(name: "Health", categories: [
//				MFCategory(name: "Dental", categories:[] ),
//				MFCategory(name: "Vision", categories:[] ),
//				MFCategory(name: "Physician", categories:[] ),
//				MFCategory(name: "Hospital", categories:[] ),
//				MFCategory(name: "Prescriptions", categories:[] ),
//				MFCategory(name: "Over the counter medication", categories:[] ),
//				MFCategory(name: "Vitamins", categories:[] )
//				] ),
//			MFCategory(name: "Other", categories:[] ),
//			MFCategory(name: "Pets", categories: [
//				MFCategory(name: "Food", categories:[] ),
//				MFCategory(name: "Supplies", categories:[] ),
//				MFCategory(name: "Veterinarian", categories:[] ),
//				MFCategory(name: "Hospital", categories:[] )
//				] ),
//			MFCategory(name: "Shopping", categories: [
//				MFCategory(name: "Clothing", categories:[] )
//				] ),
//			MFCategory(name: "Taxes", categories: [
//				MFCategory(name: "Federal", categories:[] ),
//				MFCategory(name: "State", categories:[] ),
//				MFCategory(name: "Local", categories:[] )
//				] ),
//			MFCategory(name: "Transfer", categories: [
//				MFCategory(name: "Loan Payment", categories:[] ),
//				MFCategory(name: "Mortgage Payment", categories:[] ),
//				MFCategory(name: "Credit Card Payment", categories:[] ),
//				MFCategory(name: "Savings", categories: [
//					MFCategory(name: "Retirement", categories:[] ),
//					MFCategory(name: "Investments", categories:[] ),
//					MFCategory(name: "Emergency fund", categories:[] ),
//					MFCategory(name: "Reserve funds (to set aside for planned expenses)", categories:[] )
//					] )
//				]),
//			MFCategory(name: "Travel", categories: [
//				MFCategory(name: "Day trips", categories:[] ),
//				MFCategory(name: "Transportation", categories:[] ),
//				MFCategory(name: "Lodging", categories:[] ),
//				MFCategory(name: "Entertainment", categories:[] ),
//				MFCategory(name: "Tourist attractions (e.g. amusement parks, museums, zoos, etc.)",
//					categories:[] )
//				] ),
//			MFCategory(name: "Childcare", categories: [
//				MFCategory(name: "Babysitting", categories:[] ),
//				MFCategory(name: "Child support", categories:[] )
//				] ),
//			MFCategory(name: "Education", categories: [
//				MFCategory(name: "Tuition", categories:[] ),
//				MFCategory(name: "Books", categories:[] ),
//				MFCategory(name: "School supplies", categories:[] ),
//				MFCategory(name: "Field trips", categories:[] ),
//				MFCategory(name: "Misc. fees", categories:[] ),
//				MFCategory(name: "Student loan payment", categories:[] )
//				] ),
//			MFCategory(name: "Job expenses", categories: [
//				MFCategory(name: "Reimbursed", categories:[] ),
//				MFCategory(name: "Clothing", categories:[] ),
//				MFCategory(name: "Professional dues", categories:[] )
//				] ),
//			MFCategory(name: "Leisure", categories: [
//				MFCategory(name: "Books", categories:[] ),
//				MFCategory(name: "Magazines", categories:[] ),
//				MFCategory(name: "Movie theater", categories:[] ),
//				MFCategory(name: "Video rental / Pay per view", categories:[] ),
//				MFCategory(name: "Sporting events", categories:[] ),
//				MFCategory(name: "Sporting goods", categories:[] )
//				] ),
//			MFCategory(name: "Hobbies", categories: [
//				MFCategory(name: "Cultural events (e.g. parades, carnivals, etc.)", categories:[] ),
//				MFCategory(name: "CD’s", categories:[] ),
//				MFCategory(name: "Video games", categories:[] ),
//				MFCategory(name: "Toys", categories:[] )
//				] )
//		]
//		data.content = rootNodes
//	}
}
