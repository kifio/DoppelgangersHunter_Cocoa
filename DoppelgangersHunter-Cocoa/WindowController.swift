//
//  WindowController.swift
//  DoppelgangersHunter-Cocoa
//
//  Created by imurashov on 24.12.2025.
//

import AppKit

protocol SelectedItemsCounterView {
    func updateSelected(dirName: String, selectedFilesCount: UInt)
}

final class WindowController: NSWindowController {
    
    @IBOutlet weak var deleteSelectedFiles: NSToolbarItem!
    
    override init(window: NSWindow?) {
        super.init(window: window)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        deleteSelectedFiles.isEnabled = false
    }
    
    @IBAction func deleteDuplicates(_ sender: Any) {
        let alert = NSAlert()
        alert.messageText = NSLocalizedString("alert.moveToTrash.message", comment: "Alert message about moving selected files to trash")
        alert.alertStyle = .warning
        alert.addButton(withTitle: NSLocalizedString("alert.moveToTrash.confirm", comment: "Confirm move to trash"))
        alert.addButton(withTitle: NSLocalizedString("common.cancel", comment: "Cancel"))
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            (window?.contentViewController as? Interactor)?.deleteSelectedFiles()
        }
    }
    
    @IBAction func openDirectoryPicker(_ sender: Any) {
        let panel = NSOpenPanel()
        panel.title = NSLocalizedString("panel.chooseDirectory.title", comment: "Open panel title")
        panel.prompt = NSLocalizedString("panel.chooseDirectory.prompt", comment: "Open panel prompt")
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.resolvesAliases = true
        panel.directoryURL = nil
        guard panel.runModal() == .OK, let url = panel.url else { return }
        (window?.contentViewController as? Interactor)?.open(directory: url)
    }
}

extension WindowController: SelectedItemsCounterView {
    func updateSelected(dirName: String, selectedFilesCount: UInt) {
        deleteSelectedFiles.isEnabled = selectedFilesCount > 0
        window?.title = selectedFilesCount > 1 ? String(format: NSLocalizedString("window.selected.count", comment: "Title when multiple items selected"), selectedFilesCount) : dirName
    }
}

extension WindowController: NSToolbarItemValidation {
    func validateToolbarItem(_ item: NSToolbarItem) -> Bool {
        return switch item.itemIdentifier {
        case .init("deleteFiles"):
            deleteSelectedFiles.isEnabled
        default:
            true
        }
    }
}
