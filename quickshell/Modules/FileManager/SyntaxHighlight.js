.pragma library

// Line-oriented highlighter for the preview pane and the git diff dialog.
// Languages are detected from the file name. Diffs are a first-class mode so
// `git diff` output and .patch files colour the same way.

const KEYWORDS = {
    "js": "async await break case catch class const continue debugger default delete do else export extends false finally for function if import in instanceof let new null of return static super switch this throw true try typeof var void while with yield from as",
    "ts": "abstract as async await break case catch class const continue declare default delete do else enum export extends false finally for function if implements import in infer instanceof interface keyof let module namespace new null of private protected public readonly return static super switch this throw true try type typeof var void while with yield from",
    "qml": "alias as boolean break case continue default else false for function id if import let null number pragma property readonly required return signal string switch this true undefined var while",
    "py": "and as assert async await break class continue def del elif else except False finally for from global if import in is lambda None nonlocal not or pass raise return True try while with yield",
    "go": "break case chan const continue default defer else fallthrough for func go goto if import interface map package range return select struct switch type var true false nil iota",
    "rs": "as async await break const continue crate dyn else enum extern false fn for if impl in let loop match mod move mut pub ref return self Self static struct super trait true type unsafe use where while",
    "c": "auto bool break case char const continue default do double else enum extern float for goto if inline int long nullptr register return short signed sizeof static struct switch typedef union unsigned void volatile while true false",
    "sh": "alias break case continue do done elif else esac export fi for function if in return select then time until while true false",
    "json": "",
    "yaml": "true false null yes no on off",
    "toml": "true false",
    "css": "important from to"
};

const EXT_LANG = {
    "js": "js", "mjs": "js", "cjs": "js", "jsx": "js",
    "ts": "ts", "tsx": "ts",
    "qml": "qml",
    "json": "json",
    "py": "py",
    "go": "go",
    "rs": "rs",
    "c": "c", "h": "c", "cc": "c", "cpp": "c", "cxx": "c", "hpp": "c", "hh": "c",
    "sh": "sh", "bash": "sh", "zsh": "sh", "fish": "sh",
    "md": "md", "markdown": "md",
    "yaml": "yaml", "yml": "yaml",
    "toml": "toml",
    "css": "css",
    "html": "html", "htm": "html",
    "xml": "xml",
    "diff": "diff", "patch": "diff",
    "txt": "text", "log": "text", "csv": "text",
    "ini": "sh", "conf": "sh", "cfg": "sh", "env": "sh"
};

function languageFor(fileName) {
    if (!fileName)
        return "text";
    const lower = fileName.toLowerCase();
    if (lower === "makefile" || lower === "dockerfile" || lower === "cmakelists.txt" || lower === "pkgbuild")
        return "sh";
    const dot = lower.lastIndexOf(".");
    if (dot <= 0)
        return "text";
    return EXT_LANG[lower.slice(dot + 1)] || "text";
}

function isTextName(fileName) {
    if (!fileName)
        return false;
    const lower = fileName.toLowerCase();
    if (languageFor(lower) !== "text")
        return true;
    const names = ["license", "copying", "authors", "changelog", "readme", "todo", "gitignore", "dockerignore", "editorconfig", "gitattributes"];
    if (names.indexOf(lower) !== -1)
        return true;
    if (lower.startsWith(".") && lower.indexOf(".") === 0)
        return true;
    const ext = lower.split(".").pop();
    return ["txt", "log", "csv", "svg", "kdl", "lock", "rst"].indexOf(ext) !== -1;
}

function isProbablyText(sample) {
    if (!sample || sample.length === 0)
        return true;
    if (sample.indexOf("\0") !== -1)
        return false;
    let bad = 0;
    const n = Math.min(sample.length, 4096);
    for (let i = 0; i < n; i++) {
        const c = sample.charCodeAt(i);
        if (c === 9 || c === 10 || c === 13)
            continue;
        if (c < 32)
            bad++;
    }
    return bad / n < 0.08;
}

function escapeHtml(s) {
    return s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
}

function paint(color, text) {
    if (!text)
        return "";
    return "<span style=\"color:" + color + "\">" + escapeHtml(text) + "</span>";
}

function keywordSet(lang) {
    const raw = KEYWORDS[lang] || "";
    if (!raw)
        return null;
    const set = {};
    for (const word of raw.split(" "))
        set[word] = true;
    return set;
}

function highlightDiff(line, colors) {
    if (line.startsWith("diff ") || line.startsWith("index ") || line.startsWith("+++") || line.startsWith("---"))
        return paint(colors.meta, line);
    if (line.startsWith("@@"))
        return paint(colors.hunk, line);
    if (line.startsWith("+"))
        return paint(colors.add, line);
    if (line.startsWith("-"))
        return paint(colors.del, line);
    return paint(colors.text, line);
}

function highlightMd(line, colors) {
    if (/^#{1,6}\s/.test(line))
        return paint(colors.keyword, line);
    if (line.startsWith("```") || line.startsWith("~~~"))
        return paint(colors.meta, line);
    if (line.startsWith(">"))
        return paint(colors.comment, line);
    if (/^\s*([-*+]|\d+\.)\s/.test(line))
        return paint(colors.keyword, line.slice(0, 4)) + paint(colors.text, line.slice(4));
    return paint(colors.text, line);
}

function readString(line, i) {
    const q = line.charAt(i);
    if (q !== "\"" && q !== "'" && q !== "`")
        return null;
    let j = i + 1;
    while (j < line.length) {
        if (line.charAt(j) === "\\") {
            j += 2;
            continue;
        }
        if (line.charAt(j) === q)
            return line.slice(i, j + 1);
        j++;
    }
    return line.slice(i);
}

function highlightCode(line, lang, colors, state) {
    const words = keywordSet(lang);
    const hashComment = lang === "py" || lang === "sh" || lang === "yaml" || lang === "toml";
    let i = 0;
    let out = "";

    if (state.inBlock) {
        const end = line.indexOf("*/");
        if (end === -1)
            return paint(colors.comment, line);
        out += paint(colors.comment, line.slice(0, end + 2));
        state.inBlock = false;
        i = end + 2;
    }

    while (i < line.length) {
        if (hashComment && line.charAt(i) === "#") {
            out += paint(colors.comment, line.slice(i));
            break;
        }
        if (!hashComment && line.startsWith("//", i)) {
            out += paint(colors.comment, line.slice(i));
            break;
        }
        if (!hashComment && line.startsWith("/*", i)) {
            const end = line.indexOf("*/", i + 2);
            if (end === -1) {
                out += paint(colors.comment, line.slice(i));
                state.inBlock = true;
                break;
            }
            out += paint(colors.comment, line.slice(i, end + 2));
            i = end + 2;
            continue;
        }

        const str = readString(line, i);
        if (str) {
            out += paint(colors.string, str);
            i += str.length;
            continue;
        }

        const rest = line.slice(i);
        const num = rest.match(/^[0-9]+(\.[0-9]+)?([eE][+-]?[0-9]+)?/);
        if (num) {
            out += paint(colors.number, num[0]);
            i += num[0].length;
            continue;
        }

        const ident = rest.match(/^[A-Za-z_$][A-Za-z0-9_$-]*/);
        if (ident) {
            const word = ident[0];
            const color = words && words[word] ? colors.keyword : (word.charAt(0) === word.charAt(0).toUpperCase() && word.charAt(0) !== word.charAt(0).toLowerCase() ? colors.type : colors.text);
            out += paint(color, word);
            i += word.length;
            continue;
        }

        out += paint(colors.punct, line.charAt(i));
        i++;
    }
    return out;
}

function highlightJson(line, colors) {
    return highlightCode(line, "js", colors, {
        "inBlock": false
    });
}

function highlightLine(line, lang, colors, state) {
    if (!line)
        return " ";
    switch (lang) {
    case "diff":
        return highlightDiff(line, colors);
    case "md":
        return highlightMd(line, colors);
    case "json":
        return highlightJson(line, colors);
    case "text":
        return paint(colors.text, line);
    default:
        return highlightCode(line, lang, colors, state);
    }
}

function highlightText(text, lang, colors, maxLines) {
    const raw = (text || "").replace(/\r\n/g, "\n").replace(/\r/g, "\n").split("\n");
    const limit = maxLines > 0 ? maxLines : 400;
    const truncated = raw.length > limit;
    const slice = truncated ? raw.slice(0, limit) : raw;
    const state = {
        "inBlock": false
    };
    const lines = [];
    for (let i = 0; i < slice.length; i++)
        lines.push(highlightLine(slice[i], lang, colors, state));
    if (truncated)
        lines.push(paint(colors.meta, "…"));
    return lines;
}
