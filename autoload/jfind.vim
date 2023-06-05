let s:plugindir = expand('<sfile>:p:h:h')

function! jfind#onExit(window, status)
    call nvim_win_close(a:window, 0)
    if a:status == 0
        try
            let l:contents = readfile($HOME . "/.cache/jfind_out")
            exe 'edit ' . l:contents[0]
        catch
            return
        endtry
    endif
endfunction

function! jfind#findFile()
    let max_width = 118
    let max_height = 26

    let border = "none"
    let col = 0
    let row = 0

    let buf = nvim_create_buf(v:false, v:true)
    let ui = nvim_list_uis()[0]

    if &columns > max_width
        let width = &columns % 2 ? max_width - 1 : max_width
        if &lines > max_height
            let height = &lines % 2 ? max_height - 1 : max_height
            let border = "rounded"
            let col = (ui.width/2) - (width/2) - 1
            let row = (ui.height/2) - (height/2) - 1
        else
            let width = 1000
            let height = 1000
        endif
    else
        let width = 1000
        let height = 1000
    endif

    let opts = {'relative': 'editor',
                \ 'width': width,
                \ 'height': height,
                \ 'col': col,
                \ 'row': row,
                \ 'anchor': 'nw',
                \ 'style': 'minimal',
                \ 'border': border,
                \ }

    let win = nvim_open_win(buf, 1, opts)
    call nvim_win_set_option(win, 'winhl', 'normal:normal')

    let t = termopen(s:plugindir . "/jfind-file.sh",
                \ {'on_exit': {status, data -> jfind#onExit(win, data)}})
    startinsert
endfunction
 
function! jfind#findFileTmux()
    exe "silent! !" . s:plugindir . "/tmux-jfind-file.sh"
    try
        let l:contents = readfile($HOME . "/.cache/jfind_out")
        exe 'edit ' . l:contents[0]
    catch
        return
    endtry
endfunction

if exists('$TMUX')
    nnoremap <silent><c-f> :call jfind#findFile()<cr>
else
    nnoremap <silent><c-f> :call jfind#findFileTmux()<cr>
endif
