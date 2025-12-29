//
//  TableViewController.swift
//  DoppelgangersHunter-Cocoa
//
//  Created by imurashov on 23.12.2025.
//

import AppKit
import AVFoundation
import DoppelgangersHunter

protocol DirectoryContentView {
    func open(directory url: URL)
    func deleteSelectedFiles()
}

struct Cell {
    let doppelganger: Doppelganger
    let isFirstInSection: Bool
    let isLastInSection: Bool
}

final class TableViewController: NSViewController {
    
    private var directoryName: String!
    private var cells = [Cell]()
    private var previewsCache = NSCache<NSURL, NSImage>()
    private let noSignImage = NSImage(
            systemSymbolName: "nosign",
            accessibilityDescription: NSLocalizedString("image.preview.unavailable", comment: "Accessibility description for unavailable preview")
        )?.withSymbolConfiguration(NSImage.SymbolConfiguration(pointSize: 48, weight: .regular))
    
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.headerView = nil
        tableView.delegate = self
        tableView.dataSource = self
        tableView.allowsMultipleSelection = true
        tableView.usesAlternatingRowBackgroundColors = true
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: NSLocalizedString("menu.open", comment: "Context menu Open"), action: #selector(openFile(_:)), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: NSLocalizedString("menu.delete", comment: "Context menu Delete"), action: #selector(deleteFile(_:)), keyEquivalent: ""))
        
        tableView.menu = menu
    }
    
    private func generateVideoThumbnailAsynchronously(
        url: URL,
        completionHandler: @escaping @Sendable (CGImage?, CMTime, (any Error)?) -> Void
    ) {
        let assetImageGenerator = AVAssetImageGenerator(asset: AVURLAsset(url: url))
        assetImageGenerator.appliesPreferredTrackTransform = true
        assetImageGenerator.requestedTimeToleranceBefore = .zero
        assetImageGenerator.requestedTimeToleranceAfter = .zero
        assetImageGenerator.generateCGImageAsynchronously(
            for: CMTime(seconds: 1, preferredTimescale: 600),
            completionHandler: completionHandler
        )
    }
    
    private func updateCache(
        for url: NSURL,
        with createImage: (@escaping (NSImage?) -> Void) -> Void,
        in view: NSImageView?
    ) {
        if let cachedImage = previewsCache.object(forKey: url) {
            view?.image = cachedImage
        } else {
            createImage { [weak self] image in
                if let image, let previewsCache = self?.previewsCache {
                    previewsCache.setObject(
                        image,
                        forKey: url
                    )
                    DispatchQueue.main.async {
                        if view?.tag == url.hash {
                            view?.image = image
                        }
                    }
                }
            }
        }
    }
    
    @objc func openFile(_ sender: Any) {
        guard tableView.clickedRow >= 0 else { return }
        let index = tableView.clickedRow
        guard FileManager.default.fileExists(atPath: path(for: index)) else {
            cells.remove(at: index)
            tableView.removeRows(at: IndexSet([index]), withAnimation: .slideUp)
            return
        }
        NSWorkspace.shared.open(URL(fileURLWithPath: path(for: index)))
    }
    
    @objc func deleteFile(_ sender: Any) {
        guard tableView.clickedRow >= 0 else { return }
        if tableView.selectedRowIndexes.contains(tableView.clickedRow) {
            deleteFilesAt(selectedRowIndexes: tableView.selectedRowIndexes)
        } else {
            deleteFilesAt(selectedRowIndexes:IndexSet(integer: tableView.clickedRow))
        }
    }
    
    private func deleteFilesAt(selectedRowIndexes: IndexSet) {
        selectedRowIndexes.forEach {
            do {
                try FileManager.default.trashItem(
                    at: URL(fileURLWithPath: path(for: $0)),
                    resultingItemURL: nil
                )
            } catch {
                print(error)
            }
            cells.remove(at: $0)
        }
        tableView.removeRows(at: selectedRowIndexes, withAnimation: .slideUp)
        clearSelectedFile()
    }
    
    
    private func clearSelectedFile() {
        let interactor = parent as! Interactor
        interactor.show(doppelganger: nil)
        interactor.updateSelected(dirName: directoryName, selectedFilesCount: 0)
        tableView.deselectAll(nil)
    }
    
    private func path(for row: Int) -> String {
        cells[row].doppelganger.path
    }
}

extension TableViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        cells.count
    }
}

extension TableViewController: NSTableViewDelegate {
    
    static let previewableContentTypes: [DoppelgangersHunter.ContentType] =  [.image, .video]
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        64
    }
        
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard
            let cell = tableView.makeView(
                withIdentifier: NSUserInterfaceItemIdentifier("TableCell"),
                owner: self
            ) as? NSTableCellView
        else {
            return nil
        }
        
        let url = NSURL(fileURLWithPath: path(for: row))
        cell.textField?.stringValue = url.lastPathComponent ?? ""
        cell.textField?.toolTip = url.absoluteString
        cell.imageView?.tag = url.hash
        cell.imageView?.image = nil
        switch cells[row].doppelganger.contentType {
        case .image:
            updateCache(
                for: url,
                with: { imageReady in
                    DispatchQueue.global(qos: .utility).async {
                        let image = NSImage(contentsOf: url as URL)
                        imageReady(image)
                    }
                },
                in: cell.imageView
            )
        case .video:
            updateCache(
                for: url,
                with: { [weak self] imageReady in
                    self?.generateVideoThumbnailAsynchronously(url: url as URL) {
                        if let image = $0 {
                            imageReady(
                                NSImage(
                                    cgImage: image,
                                    size: NSSize(width: image.width, height: image.height)
                                )
                            )
                        } else if let error = $2 {
                            print(error)
                        }
                    }
                    
                },
                in: cell.imageView
            )
        default:
            cell.imageView?.image = noSignImage
        }
        
        return cell
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        let interactor = parent as! Interactor
        let selectedFilesCount = UInt(tableView.selectedRowIndexes.count)
        if tableView.selectedRow >= 0  {
            if selectedFilesCount <= 1 {
                interactor.show(doppelganger: cells[tableView.selectedRow].doppelganger)
            }
            interactor.updateSelected(
                dirName: path(for: tableView.selectedRow),
                selectedFilesCount: selectedFilesCount
            )
        }
    }
}

extension TableViewController: DirectoryContentView {
    func deleteSelectedFiles() {
        deleteFilesAt(selectedRowIndexes: tableView.selectedRowIndexes)
    }
    
    func open(directory url: URL) {
        directoryName = url.path()
        progressIndicator.startAnimation(self)
        cells.removeAll()
        tableView.reloadData()
        clearSelectedFile()
        Task {
            let doppelgangers = await Hunt().hunt(url: url)
            await MainActor.run {
                doppelgangers.forEach {
                    let files = $0.files
                    files.enumerated().forEach { index, file in
                        self.cells.append(
                            Cell(
                                doppelganger: file,
                                isFirstInSection: index == 0,
                                isLastInSection: index == files.count - 1
                            )
                        )
                    }
                }
                tableView.reloadData()
                progressIndicator.stopAnimation(self)
            }
        }
    }
}
