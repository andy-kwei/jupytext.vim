" Name: jupytext.vim
" Last Change: Jul 9, 2019
" Author:  Michael Goerz <https://michaelgoerz.net>
" Plugin Website: https://github.com/goerz/jupytext.vim
" Summary: Vim plugin for editing Jupyter ipynb files via jupytext
" Version: 0.1.1
" License:
"    MIT License
"
"    Copyright (c) 2019 Michael Goerz
"
"    Permission is hereby granted, free of charge, to any person obtaining a
"    copy of this software and associated documentation files (the
"    "Software"), to deal in the Software without restriction, including
"    without limitation the rights to use, copy, modify, merge, publish,
"    distribute, sublicense, and/or sell copies of the Software, and to permit
"    persons to whom the Software is furnished to do so, subject to the
"    following conditions:
"
"    The above copyright notice and this permission notice shall be included
"    in all copies or substantial portions of the Software.
"
"    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
"    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
"    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
"    NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
"    DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
"    OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
"    USE OR OTHER DEALINGS IN THE SOFTWARE.
"
" Installation:
"    1. Make sure that you have the jupytext CLI program installed
"       (`pip install jupytext`).
"    2. Copy the jupytext.vim script to your vim plugin directory (e.g.
"       $HOME/.vim/plugin).  Refer to ':help add-plugin', ':help
"       add-global-plugin' and ':help runtimepath' for more details about Vim
"       plugins.
"    3. Restart Vim.
"
" Usage:
"    When you open a Jupyter Notebook (*.ipynb) file, it is automatically
"    converted from json to markdown or python through the `jupytext` utility
"    (https://github.com/mwouts/jupytext), and the result is loaded into the
"    buffer. Upon saving, the ipynb file is updated with any modifications.
"
"    In more detail, opening a file notebook.ipynb in vim will create a
"    temporary file notebook.md or notebook.py (depending on g:jupytext_fmt).
"    This file is the result of calling e.g.
"
"       jupytext --to=md --output notebook.md notebook.ipynb
"
"    The contents of the file is loaded into the buffer instead of the
"    original notebook.ipynb. When saving the buffer, its contents is written
"    again to notebook.md, and the original notebook.ipynb is updated with
"    a call to
"
"       jupytext --to=ipynb --from=md --update --output notebook.ipynb notebook.md
"
"    The --update flag ensures the output for any cell whose corresponding
"    input in notebook.md is unchanged will be preserved.
"
"    On closing the buffer, the temporary notebook.md will be deleted. If
"    notebook.md already existed when opening notebook.ipynb, the existing
"    file will be used (instead of being generated by jupytext), and it will
"    be preserved when closing the buffer.
"
" Configuration:
"    The plugin has the following settings. If you want to override the
"    default values shown below, you can define the corresponding variables in
"    your ~/.vimrc.
"
"    *  let g:jupytext_enable = 1
"
"       You may disable the automatic conversion of ipynb files (i.e.,
"       deactivate this plugin) by setting this to 0.
"
"    *  let g:jupytext_command = 'jupytext'
"
"       The CLI jupytext command to use. You may include the full path to
"       point to a specific `jupytext` executable not in your default $PATH.
"
"    *  let g:jupytext_fmt = 'md'
"
"       The format to which to convert the ipynb data. This can be any format
"       that the jupytext utility accepts for its `--to` parameter (see
"       `jupytext --help`), except for 'notebook' and 'ipynb'.
"
"    *  let g:jupytext_to_ipynb_opts = '--to=ipynb --update'
"
"       Command line options for the conversion from g:jupytext_fmt back to
"       the notebook format
"
"    *  let g:jupytext_filetype_map = {}
"
"       A mapping of g:jupytext_fmt to the filetype that should be used for
"       the buffer (:help filetype). This determines the syntax highlighting.
"       You may use this setting to override the default filetype. For
"       example, to use the 'pandoc' filetype instead of the default
"       'markdown' for the 'md' format, define
"
"           let g:jupytext_filetype_map = {'md': 'pandoc'}
"
"    *  let g:jupytext_print_debug_msgs = 0
"
"       If set to 1, print debug messages while running the plugin (view with
"       :messages).
"
"   Note:
"   If you are using this plugin as a replacement for the ipynb_notedown.vim
"   plugin (https://www.vim.org/scripts/script.php?script_id=5506), you can
"   use the following options to use notedown instead of jupytext:
"
"       let g:jupytext_command = 'notedown'
"       let g:jupytext_fmt = 'markdown'
"       let g:jupytext_to_ipynb_opts = '--to=notebook'

if exists("loaded_jupytext") || &cp || exists("#BufReadCmd#*.ipynb")
    finish
endif


" for all the formates that jupytext takes for --to, the filetype that vim
" should use (this determines syntax highlighting)
let s:jupytext_filetype_map = {
\   'rmarkdown': 'rmarkdown',
\   'markdown': 'markdown',
\   'python': 'python',
\   'R': 'r',
\   'julia': 'julia',
\   'c++': 'cpp',
\   'scheme': 'scheme',
\   'bash': 'sh',
\   'md': 'markdown',
\   'Rmd': 'rmarkdown',
\   'r': 'r',
\   'py': 'python',
\   'jl': 'julia',
\   'cpp': 'cpp',
\   'ss': 'ss',
\   'sh': 'sh',
\   'md:markdown': 'markdown',
\   'Rmd:rmarkdown': 'rmarkdown',
\   'r:spin': 'r',
\   'R:spin': 'r',
\   'py:light': 'python',
\   'R:light': 'r',
\   'r:light': 'r',
\   'jl:light': 'julia',
\   'cpp:light': 'cpp',
\   'ss:light': 'scheme',
\   'sh:light': 'sh',
\   'py:percent': 'python',
\   'R:percent': 'r',
\   'r:percent': 'r',
\   'jl:percent': 'julia',
\   'cpp:percent': 'cpp',
\   'ss:percent': 'scheme',
\   'sh:percent': 'sh',
\   'py:sphinx': 'python',
\   'py:sphinx-rst2md': 'python',
\ }


" for all the formates that jupytext takes for --to, the file extension that
" should be used for the linked file
let s:jupytext_extension_map = {
\   'rmarkdown': 'Rmd',
\   'markdown': 'md',
\   'python': 'py',
\   'julia': 'jl',
\   'c++': 'cpp',
\   'scheme': 'ss',
\   'bash': 'sh',
\   'md': 'md',
\   'Rmd': 'Rmd',
\   'r': 'r',
\   'R': 'r',
\   'py': 'py',
\   'jl': 'jl',
\   'cpp': 'cpp',
\   'ss': 'ss',
\   'sh': 'sh',
\   'md:markdown': 'md',
\   'Rmd:rmarkdown': 'Rmd',
\   'r:spin': 'r',
\   'R:spin': 'r',
\   'py:light': 'py',
\   'R:light': 'r',
\   'r:light': 'r',
\   'jl:light': 'jl',
\   'cpp:light': 'cpp',
\   'ss:light': 'ss',
\   'sh:light': 'sh',
\   'py:percent': 'py',
\   'R:percent': 'R',
\   'r:percent': 'r',
\   'jl:percent': 'jl',
\   'cpp:percent': 'cpp',
\   'ss:percent': 'ss',
\   'sh:percent': 'sh',
\   'py:sphinx': 'py',
\   'py:sphinx-rst2md': 'py',
\ }


if !exists('g:jupytext_print_debug_msgs')
    let g:jupytext_print_debug_msgs = 0
endif
function s:debugmsg(msg)
    if g:jupytext_print_debug_msgs
        echomsg("DBG: ".a:msg)
    endif
endfunction


if !exists('g:jupytext_filetype_map')
    let g:jupytext_filetype_map = s:jupytext_filetype_map
endif


if !exists('g:jupytext_enable')
    let g:jupytext_enable = 1
endif

if !exists('g:jupytext_command')
    let g:jupytext_command = 'jupytext'
endif

if !exists('g:jupytext_fmt')
    let g:jupytext_fmt = 'md'
endif

if !exists('g:jupytext_to_ipynb_opts')
    let g:jupytext_to_ipynb_opts = '--to=ipynb --update'
endif

if !g:jupytext_enable
    finish
endif


augroup ipynb
    " Remove all ipynb autocommands
    au!
    autocmd BufReadCmd *.ipynb  call s:read_from_ipynb()
    autocmd BufWriteCmd,FileWriteCmd *.ipynb call s:write_to_ipynb()
augroup END


function s:read_from_ipynb()
    let l:filename = resolve(expand("<afile>:p"))
    let l:fileroot = fnamemodify(l:filename, ':r')
    if get(s:jupytext_extension_map, g:jupytext_fmt, 'none') == 'none'
        echoerr "Invalid jupytext_fmt: ".g:jupytext_fmt
        return
    endif
    let b:jupytext_file = s:get_jupytext_file(l:filename, g:jupytext_fmt)
    let b:jupytext_file_exists = filereadable(b:jupytext_file)
    let l:filename_exists = filereadable(l:filename)
    call s:debugmsg("filename: ".l:filename)
    call s:debugmsg("filename exists: ".l:filename_exists)
    call s:debugmsg("jupytext_file: ".b:jupytext_file)
    call s:debugmsg("jupytext_file exists: ".b:jupytext_file_exists)
    if (l:filename_exists && !b:jupytext_file_exists)
        call s:debugmsg("Generate file ".b:jupytext_file)
        let l:cmd = "!".g:jupytext_command." --to=".g:jupytext_fmt
        \         . " --output=".shellescape(b:jupytext_file) . " "
        \         . shellescape(l:filename)
        call s:debugmsg("cmd: ".l:cmd)
        silent execute l:cmd
        if v:shell_error
            echoerr l:cmd.": ".v:shell_error
            return
        endif
    endif
    if filereadable(b:jupytext_file)
        " jupytext_file does not exist if filename_exists was false, e.g. when
        " we edit a new file (vim new.ipynb)
        call s:debugmsg("read ".fnameescape(b:jupytext_file))
        silent execute "read ".fnameescape(b:jupytext_file)
    endif
    if b:jupytext_file_exists
        let l:register_unload_cmd = "autocmd BufUnload <buffer> call s:cleanup(\"".fnameescape(b:jupytext_file)."\", 0)"

    else
        let l:register_unload_cmd = "autocmd BufUnload <buffer> call s:cleanup(\"".fnameescape(b:jupytext_file)."\", 1)"
    endif
    call s:debugmsg(l:register_unload_cmd)
    silent execute l:register_unload_cmd
    let l:ft = get(g:jupytext_filetype_map, g:jupytext_fmt,
    \              s:jupytext_filetype_map[g:jupytext_fmt])
    call s:debugmsg("filetype: ".l:ft)
    silent execute "set ft=".l:ft
    " In order to make :undo a no-op immediately after the buffer is read,
    " we need to do this dance with 'undolevels'.  Actually discarding the
    " undo history requires performing a change after setting 'undolevels'
    " to -1 and, luckily, we have one we need to do (delete the extra line
    " from the :r command)
    let levels = &undolevels
    set undolevels=-1
    silent 1delete
    let &undolevels = levels
    silent execute "autocmd BufEnter <buffer> redraw | echo fnamemodify(b:jupytext_file, ':.').' via jupytext.'"
endfunction


function s:get_jupytext_file(filename, fmt)
    " strip file extension
    let l:fileroot = fnamemodify(a:filename, ':r')
    " the folder in which filename is
    let l:head = fnamemodify(l:fileroot, ':h')
    " the fileroot without the folder
    let l:tail = fnamemodify(l:fileroot, ':t')
    " file extension from fmt
    let l:extension = s:jupytext_extension_map[a:fmt]
    let l:jupytext_file = l:fileroot . "." . l:extension
    return l:jupytext_file
endfunction


function s:write_to_ipynb() abort
    let filename = resolve(expand("<afile>:p"))
    call s:debugmsg("overwriting ".fnameescape(b:jupytext_file))
    execute "write! ".fnameescape(b:jupytext_file)
    call s:debugmsg("Updating notebook from ".b:jupytext_file)
    let l:cmd = "!".g:jupytext_command." --from=" . g:jupytext_fmt
    \         . " " . g:jupytext_to_ipynb_opts . " "
    \         . shellescape(b:jupytext_file)
    call s:debugmsg("cmd: ".l:cmd)
    silent execute l:cmd
    if v:shell_error
        echoerr l:cmd.": ".v:shell_error
    else
        setlocal nomodified
    endif
endfunction


function s:cleanup(jupytext_file, delete)
    call s:debugmsg("a:jupytext_file:".a:jupytext_file)
    if a:delete
        call s:debugmsg("deleting ".fnameescape(a:jupytext_file))
        call delete(expand(fnameescape(a:jupytext_file)))
    endif
endfunction


let loaded_jupytext = 1
