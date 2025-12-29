//
//  SplitViewController.swift
//  DoppelgangersHunter-Cocoa
//
//  Created by imurashov on 17.12.2025.
//

import AppKit
import DoppelgangersHunter

protocol Interactor: DirectoryContentView, FileContentView, SelectedItemsCounterView { }

final class SplitViewController: NSSplitViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        splitView.setPosition(320, ofDividerAt: 0)
    }
}

extension SplitViewController: Interactor {
    func open(directory url: URL) {
        (splitViewItems.first!.viewController as! DirectoryContentView).open(directory: url)
    }
    
    func deleteSelectedFiles() {
        (splitViewItems.first!.viewController as! DirectoryContentView).deleteSelectedFiles()
    }
    
    func show(doppelganger: DoppelgangersHunter.Doppelganger?) {
        (splitViewItems.last!.viewController as! FileContentView).show(doppelganger: doppelganger)
    }
    
    func updateSelected(dirName: String, selectedFilesCount: UInt) {
        let itemsCounterView = self.view.window!.windowController as! SelectedItemsCounterView
        itemsCounterView.updateSelected(dirName: dirName, selectedFilesCount: selectedFilesCount)
    }
}
