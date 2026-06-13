import Foundation
import ZIPFoundation

enum WorkbookWriterError: LocalizedError {
    case cannotCreateArchive
    case cannotEncodeXML

    var errorDescription: String? {
        switch self {
        case .cannotCreateArchive: return "Excelファイルを作れませんでした。"
        case .cannotEncodeXML: return "Excel用のXMLを作れませんでした。"
        }
    }
}

final class XLSXWorkbookWriter {
    func write(document: CellArtDocument, settings: CellArtSettings) throws -> ExportedWorkbook {
        let output = FileManager.default.temporaryDirectory
            .appendingPathComponent("CellArtisan", isDirectory: true)
        try? FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        let fileURL = output.appendingPathComponent("cell-art-\(Int(Date().timeIntervalSince1970 * 1000)).xlsx")
        try? FileManager.default.removeItem(at: fileURL)

        guard let archive = Archive(url: fileURL, accessMode: .create) else {
            throw WorkbookWriterError.cannotCreateArchive
        }

        try add("[Content_Types].xml", to: archive, content: contentTypesXML)
        try add("_rels/.rels", to: archive, content: rootRelationshipsXML)
        try add("xl/workbook.xml", to: archive, content: workbookXML)
        try add("xl/_rels/workbook.xml.rels", to: archive, content: workbookRelationshipsXML)
        try add("xl/styles.xml", to: archive, content: stylesXML(for: document.palette))
        try add("xl/worksheets/sheet1.xml", to: archive, content: sheetXML(for: document, settings: settings))
        try add("docProps/core.xml", to: archive, content: coreXML)
        try add("docProps/app.xml", to: archive, content: appXML)

        return ExportedWorkbook(url: fileURL, cellCount: document.estimatedCellCount, paletteCount: document.palette.count)
    }

    private func add(_ path: String, to archive: Archive, content: String) throws {
        guard let data = content.data(using: .utf8) else {
            throw WorkbookWriterError.cannotEncodeXML
        }
        try archive.addEntry(with: path, type: .file, uncompressedSize: Int64(data.count), provider: { position, size -> Data in
            data.subdata(in: Int(position)..<Int(position) + size)
        })
    }

    private func sheetXML(for document: CellArtDocument, settings: CellArtSettings) -> String {
        let columnWidth = max(2.2, min(6.0, settings.cellSize / 5.5))
        let rowHeight = max(8.0, min(36.0, settings.cellSize))
        let columns = (1...document.width)
            .map { "<col min=\"\($0)\" max=\"\($0)\" width=\"\(format(columnWidth))\" customWidth=\"1\"/>" }
            .joined()

        let grouped = Dictionary(grouping: document.cells, by: \.row)
        let rows = (1...document.height).map { rowIndex in
            let rowCells = (grouped[rowIndex] ?? []).sorted { $0.column < $1.column }
            let cellsXML = rowCells.map { cell in
                let styleIndex = (document.palette.firstIndex(of: cell.color) ?? 0) + 1
                return "<c r=\"\(columnName(cell.column))\(cell.row)\" s=\"\(styleIndex)\"/>"
            }.joined()
            return "<row r=\"\(rowIndex)\" ht=\"\(format(rowHeight))\" customHeight=\"1\">\(cellsXML)</row>"
        }.joined()

        let grid = settings.showGrid ? "1" : "0"
        return """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
          <sheetViews><sheetView showGridLines="\(grid)" workbookViewId="0"/></sheetViews>
          <cols>\(columns)</cols>
          <sheetData>\(rows)</sheetData>
        </worksheet>
        """
    }

    private func stylesXML(for palette: [CellColor]) -> String {
        let fills = ["<fill><patternFill patternType=\"none\"/></fill>", "<fill><patternFill patternType=\"gray125\"/></fill>"]
            + palette.map { "<fill><patternFill patternType=\"solid\"><fgColor rgb=\"FF\($0.hex)\"/><bgColor indexed=\"64\"/></patternFill></fill>" }
        let cellFormats = ["<xf numFmtId=\"0\" fontId=\"0\" fillId=\"0\" borderId=\"0\" xfId=\"0\"/>"]
            + palette.enumerated().map { index, _ in
                "<xf numFmtId=\"0\" fontId=\"0\" fillId=\"\(index + 2)\" borderId=\"0\" xfId=\"0\" applyFill=\"1\"/>"
            }

        return """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
          <fonts count="1"><font><sz val="11"/><color theme="1"/><name val="Calibri"/><family val="2"/></font></fonts>
          <fills count="\(fills.count)">\(fills.joined())</fills>
          <borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders>
          <cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>
          <cellXfs count="\(cellFormats.count)">\(cellFormats.joined())</cellXfs>
          <cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles>
        </styleSheet>
        """
    }

    private func columnName(_ number: Int) -> String {
        var value = number
        var result = ""
        while value > 0 {
            let remainder = (value - 1) % 26
            result = String(UnicodeScalar(65 + remainder)!) + result
            value = (value - 1) / 26
        }
        return result
    }

    private func format(_ value: Double) -> String {
        String(format: "%.2f", value)
    }

    private var contentTypesXML: String {
        """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
          <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
          <Default Extension="xml" ContentType="application/xml"/>
          <Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
          <Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
          <Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>
          <Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>
          <Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>
        </Types>
        """
    }

    private var rootRelationshipsXML: String {
        """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
          <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
          <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>
          <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/>
        </Relationships>
        """
    }

    private var workbookXML: String {
        """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
          <sheets><sheet name="セルアート" sheetId="1" r:id="rId1"/></sheets>
        </workbook>
        """
    }

    private var workbookRelationshipsXML: String {
        """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
          <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>
          <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
        </Relationships>
        """
    }

    private var coreXML: String {
        let date = ISO8601DateFormatter().string(from: Date())
        return """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
          <dc:creator>CellArtisan</dc:creator>
          <cp:lastModifiedBy>CellArtisan</cp:lastModifiedBy>
          <dcterms:created xsi:type="dcterms:W3CDTF">\(date)</dcterms:created>
          <dcterms:modified xsi:type="dcterms:W3CDTF">\(date)</dcterms:modified>
        </cp:coreProperties>
        """
    }

    private var appXML: String {
        """
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties" xmlns:vt="http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes">
          <Application>CellArtisan</Application>
        </Properties>
        """
    }
}
