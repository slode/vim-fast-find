let g:ffind_excl_files = ['*.swp', '*~', '*.pyc', '*.so', '*.gif', '*.png', 'tags']
let g:ffind_incl_files = ['*.c', '*.hh', 'scons*', '*.py', '*.cpp', '*.h', '*.hpp', '*.php','*.js','*.css','*.html','*.scss', '*cmake']
let g:ffind_excl_path = ['*/.git/*', '*/build/*', "tags"]
let g:ffind_path = '.'

function! FFind(...)
    " Timing the search
    let l:start=reltime()

    let l:expaths = exists('g:ffind_excl_path') ? "  \\( -path '" . join(g:ffind_excl_path, "' -o -path '")."' \\) -prune -o" : ''
    let l:exfiles = exists('g:ffind_excl_files') ? " -not \\( -iname '".join(g:ffind_excl_files, "' -o -iname '")."'  \\) " : ''

    let l:path=exists('g:ffind_path') ? g:ffind_path : '.'

    if a:0==0
        echohl WarningMsg | 
        \ echomsg 'Find needs path fragment to look for!' | 
        \ echohl None | redraw
        return
    endif

    if a:0==2
      let l:string_pattern=a:2
    endif
    
    if type(a:1)==type([])
      let l:path_pattern = " \\( -iname \"" . join(a:1, "\" -o -iname \"")."\" \\) "
    else
      let l:path_pattern = " -iname \"*" . substitute(a:1, "^\\s\\+\\|\\s\\+$","", "g") . "*\""
    endif

    if strlen(l:path_pattern)==0
        echohl WarningMsg | 
        \ echomsg 'Find needs string fragment to look for!' | 
        \ echohl None | redraw
        return
    endif

    let l:find_cmd = " find . " . l:expaths . " " . l:exfiles . " " . l:path_pattern . " -print "
    let l:xargs_cmd = executable("parallel") ? " parallel -j150% -n 1000 --gnu " : " xargs "  
    let l:grep_cmd = exists('l:string_pattern') ? " | " . l:xargs_cmd . " grep -inHn -d skip -D skip -I -m1 " . l:string_pattern . " \"{}\" " : ""
    let l:sort_cmd = " | sort " 

    let l:tmpfile=tempname()
    let l:redirect  = " > " . l:tmpfile
    
    let l:cmd = l:find_cmd . l:grep_cmd . l:sort_cmd . l:redirect

    echohl WarningMsg | echomsg "..." | echohl None | redraw

    if exists('l:string_pattern')
      echohl WarningMsg | echomsg "Searching for pattern " .  l:string_pattern . "" | echohl None | redraw
    else
      echohl WarningMsg | echomsg "Searching for file " . string(a:1) . "" | echohl None | redraw
    endif

    " launch search
    let l:_tmp=system(l:cmd)

    let old_efm=&efm
    set efm=%f
    if exists('l:string_pattern')
      set efm=%f:%\\s%#%l:%m
    endif
    
    if exists(":lgetfile")
      execute "silent! lgetfile " . tmpfile
    else
      execute "silent! lfile " . tmpfile
    endif

    let &efm=old_efm

    botright lopen

    call delete(tmpfile)
    let l:time=reltimestr(reltime(l:start))

    echohl WarningMsg | echo "Execution took " . l:time . " sec." | echohl None | redraw
    redraw
endfunction


function! RunFFindPattern(...)
  let l:pat = input("Search for pattern\: ")

  if(empty(l:pat)) | return | endif 
  
  call FFind("", l:pat)
endfunction

function! RunFFindFile(...)
  let l:pat = input("Search for file\: ")

  if(empty(l:pat)) | return | endif 
  
  call FFind(l:pat)
endfunction

function! ToggleLoc()
  try
    if exists('t:loc_open') && t:loc_open == 0
      exec('botright lopen')
    else
      exec('lclose')
    endif
    let t:loc_open = exists('t:loc_open') ? !t:loc_open : 0
  catch
    echon "No location list"
  endtry
endfunction

nmap <silent> <leader>g :call RunFFindPattern()<CR> 
nmap <silent> <leader>t :call RunFFindFile()<CR> 
nmap <silent> <leader>l :call ToggleLoc()<CR>

" search for word under cursor
nnoremap <F2> :call FFind("", expand("<cword>"))<CR>
nnoremap <F3> :call FFind(expand("<cword>"))<CR>
nnoremap <F4> :call SwitchSourceHeader()<CR>
