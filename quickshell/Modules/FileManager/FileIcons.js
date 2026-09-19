.pragma library

// Material Symbols names for file kinds, matching the icons used in the
// "Dank Material File Manager" design canvas.
const BY_EXTENSION = {
    "ts": "code", "tsx": "code", "js": "code", "jsx": "code", "mjs": "code",
    "qml": "code", "py": "code", "go": "code", "rs": "code", "c": "code",
    "h": "code", "cpp": "code", "hpp": "code", "java": "code", "kt": "code",
    "rb": "code", "php": "code", "lua": "code", "vim": "code",
    "sh": "terminal", "bash": "terminal", "zsh": "terminal", "fish": "terminal",
    "json": "data_object", "yaml": "data_object", "yml": "data_object",
    "toml": "data_object", "xml": "data_object", "kdl": "data_object",
    "ini": "settings", "conf": "settings", "cfg": "settings",
    "md": "description", "txt": "description", "rst": "description",
    "pdf": "picture_as_pdf",
    "png": "image", "jpg": "image", "jpeg": "image", "gif": "image",
    "bmp": "image", "webp": "image", "svg": "image", "avif": "image",
    "mp4": "movie", "mkv": "movie", "webm": "movie", "mov": "movie",
    "mp3": "music_note", "flac": "music_note", "ogg": "music_note", "wav": "music_note",
    "zip": "folder_zip", "tar": "folder_zip", "gz": "folder_zip",
    "xz": "folder_zip", "zst": "folder_zip", "7z": "folder_zip",
    "css": "css", "html": "html",
    "lock": "lock"
};

const BY_NAME = {
    ".git": "account_tree",
    "dockerfile": "deployed_code",
    "makefile": "construction",
    "license": "gavel",
    "readme.md": "menu_book"
};

function forEntry(fileName, isDir) {
    if (!fileName)
        return isDir ? "folder" : "file_present";

    const lower = fileName.toLowerCase();

    if (BY_NAME[lower])
        return BY_NAME[lower];

    if (isDir)
        return "folder";

    if (lower.endsWith(".test.ts") || lower.endsWith(".test.js") || lower.endsWith("_test.go"))
        return "bug_report";

    const dot = lower.lastIndexOf(".");
    if (dot <= 0)
        return "file_present";

    return BY_EXTENSION[lower.slice(dot + 1)] || "file_present";
}

function isImage(fileName) {
    if (!fileName)
        return false;
    const ext = fileName.toLowerCase().split(".").pop();
    return ["jpg", "jpeg", "png", "gif", "bmp", "webp", "svg", "avif"].includes(ext);
}

function isText(fileName) {
    if (!fileName)
        return false;
    const lower = fileName.toLowerCase();
    const ext = lower.split(".").pop();
    const textExt = [
        "ts", "tsx", "js", "jsx", "mjs", "cjs", "qml", "py", "go", "rs", "c", "h",
        "cpp", "hpp", "cc", "hh", "java", "kt", "rb", "php", "lua", "vim", "sh",
        "bash", "zsh", "fish", "json", "yaml", "yml", "toml", "xml", "kdl", "ini",
        "conf", "cfg", "md", "txt", "rst", "css", "html", "htm", "diff", "patch",
        "log", "csv", "env", "lock"
    ];
    if (textExt.indexOf(ext) !== -1)
        return true;
    const names = ["makefile", "dockerfile", "license", "copying", "readme", "readme.md", "changelog", "cmakelists.txt", "pkgbuild"];
    return names.indexOf(lower) !== -1;
}

function formatSize(bytes) {
    if (bytes === undefined || bytes === null || bytes < 0)
        return "";
    if (bytes < 1024)
        return bytes + " B";
    const units = ["KB", "MB", "GB", "TB"];
    let value = bytes / 1024;
    let unit = 0;
    while (value >= 1024 && unit < units.length - 1) {
        value /= 1024;
        unit++;
    }
    return (value < 10 ? value.toFixed(1) : Math.round(value)) + " " + units[unit];
}
