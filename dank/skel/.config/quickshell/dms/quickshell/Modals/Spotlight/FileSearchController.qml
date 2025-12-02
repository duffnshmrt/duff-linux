import QtQuick
import Quickshell.Io
import qs.Services

Item {
    id: controller

    property string searchQuery: ""
    property alias model: fileModel
    property int selectedIndex: 0
    property bool keyboardNavigationActive: false
    property bool isSearching: false
    property int totalResults: 0
    property string searchField: "filename"

    signal searchCompleted

    ListModel {
        id: fileModel
    }

    function performSearch() {
        if (!DSearchService.dsearchAvailable) {
            model.clear()
            totalResults = 0
            isSearching = false
            return
        }

        if (searchQuery.length === 0) {
            model.clear()
            totalResults = 0
            isSearching = false
            return
        }

        isSearching = true
        const params = {
            "limit": 50,
            "fuzzy": true,
            "sort": "score",
            "desc": true
        }

        if (searchField && searchField !== "all") {
            params.field = searchField
        }

        DSearchService.search(searchQuery, params, response => {
                                  if (response.error) {
                                      model.clear()
                                      totalResults = 0
                                      isSearching = false
                                      return
                                  }

                                  if (response.result) {
                                      updateModel(response.result)
                                  }

                                  isSearching = false
                                  searchCompleted()
                              })
    }

    function updateModel(result) {
        model.clear()
        totalResults = result.total_hits || 0
        selectedIndex = 0
        keyboardNavigationActive = true

        if (!result.hits || result.hits.length === 0) {
            selectedIndex = -1
            keyboardNavigationActive = false
            return
        }

        for (var i = 0; i < result.hits.length; i++) {
            const hit = result.hits[i]
            const filePath = hit.id || ""
            const fileName = getFileName(filePath)
            const fileExt = getFileExtension(fileName)
            const fileType = determineFileType(fileName, filePath)
            const dirPath = getDirPath(filePath)

            model.append({
                             "filePath": filePath,
                             "fileName": fileName,
                             "fileExtension": fileExt,
                             "fileType": fileType,
                             "dirPath": dirPath,
                             "score": hit.score || 0
                         })
        }
    }

    function getFileName(path) {
        const parts = path.split('/')
        return parts[parts.length - 1] || path
    }

    function getFileExtension(fileName) {
        const parts = fileName.split('.')
        if (parts.length > 1) {
            return parts[parts.length - 1].toLowerCase()
        }
        return ""
    }

    function getDirPath(path) {
        const lastSlash = path.lastIndexOf('/')
        if (lastSlash > 0) {
            return path.substring(0, lastSlash)
        }
        return ""
    }

    function determineFileType(fileName, filePath) {
        const ext = getFileExtension(fileName)

        const imageExts = ["png", "jpg", "jpeg", "gif", "bmp", "webp", "svg", "ico"]
        if (imageExts.includes(ext)) {
            return "image"
        }

        const videoExts = ["mp4", "mkv", "avi", "mov", "webm", "flv", "wmv", "m4v"]
        if (videoExts.includes(ext)) {
            return "video"
        }

        const audioExts = ["mp3", "wav", "flac", "ogg", "m4a", "aac", "wma"]
        if (audioExts.includes(ext)) {
            return "audio"
        }

        const codeExts = ["js", "ts", "jsx", "tsx", "py", "go", "rs", "c", "cpp", "h", "java", "kt", "swift", "rb", "php", "html", "css", "scss", "json", "xml", "yaml", "yml", "toml", "sh", "bash", "zsh", "fish", "qml", "vue", "svelte"]
        if (codeExts.includes(ext)) {
            return "code"
        }

        const docExts = ["txt", "md", "pdf", "doc", "docx", "odt", "rtf"]
        if (docExts.includes(ext)) {
            return "document"
        }

        const archiveExts = ["zip", "tar", "gz", "bz2", "xz", "7z", "rar"]
        if (archiveExts.includes(ext)) {
            return "archive"
        }

        if (!ext || fileName.indexOf('.') === -1) {
            return "binary"
        }

        return "file"
    }

    function selectNext() {
        if (model.count === 0) {
            return
        }
        keyboardNavigationActive = true
        selectedIndex = Math.min(selectedIndex + 1, model.count - 1)
    }

    function selectPrevious() {
        if (model.count === 0) {
            return
        }
        keyboardNavigationActive = true
        selectedIndex = Math.max(selectedIndex - 1, 0)
    }

    signal fileOpened

    function openFile(filePath) {
        if (!filePath || filePath.length === 0) {
            return
        }

        let url = filePath
        if (!url.startsWith("file://")) {
            url = "file://" + filePath
        }

        Qt.openUrlExternally(url)
        fileOpened()
    }

    function openFolder(filePath) {
        if (!filePath || filePath.length === 0) {
            return
        }

        const lastSlash = filePath.lastIndexOf('/')
        if (lastSlash <= 0) {
            return
        }

        const dirPath = filePath.substring(0, lastSlash)
        let url = dirPath
        if (!url.startsWith("file://")) {
            url = "file://" + dirPath
        }

        Qt.openUrlExternally(url)
        fileOpened()
    }

    function openSelected() {
        if (model.count === 0 || selectedIndex < 0 || selectedIndex >= model.count) {
            return
        }

        const item = model.get(selectedIndex)
        if (item && item.filePath) {
            openFile(item.filePath)
        }
    }

    function reset() {
        searchQuery = ""
        model.clear()
        selectedIndex = -1
        keyboardNavigationActive = false
        isSearching = false
        totalResults = 0
    }

    onSearchQueryChanged: {
        performSearch()
    }

    onSearchFieldChanged: {
        performSearch()
    }
}
