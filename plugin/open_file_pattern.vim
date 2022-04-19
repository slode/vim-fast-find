
py3 << EOF

import vim
import re
import os

def find_first(name, path):
    """Find first file on path."""
    for root, dirs, files in os.walk(path):
        if name in files:
            return os.path.join(root, name)

regex_matchers = [
    re.compile(r'(?P<file>(\.\/|\/|~\/|\w+/)[\w~\.\/]+[^:[\(\s\n]+)+([^\d])*(?P<lno>\d+)?'),
    re.compile(r'File "(?P<file>[^"]+)", line (?P<lno>\d+)?')
]

def open_file_pattern():
    pattern = vim.eval("l:pat")
    spec = {"lno": 0}
    for rex in regex_matchers:
        match = rex.search(pattern)
        if match is None:
            continue

        spec.update({k: v for k, v in match.groupdict().items() if v is not None})

    if "file" not in spec:
        vim.command("echo 'Unable to find file in pattern \"{}\"'".format(pattern))

    if not os.path.exists(spec["file"]):
        spec["file"] = find_first(spec["file"], ".") or spec["file"]

    vim.command("edit +{lno} {file}".format_map(spec))

EOF


function! OpenFilePattern(...)
  let l:pat = input("Open pattern\:")

  if(empty(l:pat)) | return | endif 
  
  py3 open_file_pattern()

endfunction

nnoremap <leader>o :call OpenFilePattern()<CR>
