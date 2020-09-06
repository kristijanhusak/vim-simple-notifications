" Author: Kristijan Husak
" Github: http://github.com/kristijanhusak
" Original: http://github.com/kristijanhusak/vim-simple-notifications
" LICENSE: MIT

" Default options, overrideable via second argument to functions
let s:delay = 7000     "Hide after this number of milliseconds
let s:width = 40       "Default notification width
let s:pos = 'topright' "Default position for notification

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                  Public API, adapt names to your needs                      "
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function notifications#info(msg, ...) abort
  return s:notification(a:msg, get(a:, 1, {}))
endfunction

function notifications#error(msg, ...) abort
  return s:notification(a:msg, extend({'type': 'error'}, get(a:, 1, {})))
endfunction

function notifications#warning(msg, ...) abort
  return s:notification(a:msg, extend({'type': 'warning'}, get(a:, 1, {})))
endfunction

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                               Implementation                                "
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let s:win = -1
let s:timer = -1
let s:neovim_float = has('nvim') && exists('*nvim_open_win')
let s:vim_popup = exists('*popup_create')

function! s:notification(msg, opts) abort
  if empty(trim(a:msg))
    return
  endif
  call s:setup_colors()

  if s:neovim_float
    return s:notification_nvim(a:msg, a:opts)
  endif

  if s:vim_popup
    return s:notification_vim(a:msg, a:opts)
  endif

  return s:notification_echo(a:msg, a:opts)
endfunction

let s:hl_by_type = {
      \ 'info': 'NotificationInfo',
      \ 'error': 'NotificationError',
      \ 'warning': 'NotificationWarning',
      \ }

function! s:notification_nvim(msg, opts) abort
  let width = get(a:opts, 'width', s:width)
  let height = len(split(a:msg,'.\{'.width.'}\zs'))
  let delay = get(a:opts, 'delay', s:delay)
  let type = get(a:opts, 'type', 'info')
  let pos = get(a:opts, 'pos', s:pos)
  let pos_map = {'topleft': 'NW', 'topright': 'NE', 'botleft': 'SW', 'botright': 'SE'}

  let pos_opts = s:get_pos(pos)
  let pos_opts.anchor = pos_map[pos]
  let opts = extend(pos_opts, {
        \ 'relative': 'editor',
        \ 'width': width,
        \ 'height': height,
        \ 'style': 'minimal',
        \ })

  silent! call nvim_win_close(s:win, v:true)
  let buf = nvim_create_buf(v:false, v:true)
  silent! exe 'autocmd BufEnter <buffer='.buf.'> :bw!'
  call nvim_buf_set_lines(buf, 0, -1, v:false, [a:msg])

  let s:win = nvim_open_win(buf, v:false, opts)
  call nvim_win_set_option(s:win, 'wrap', v:true)
  call nvim_win_set_option(s:win, 'signcolumn', 'yes') "simulate left padding
  call nvim_win_set_option(s:win, 'winhl', 'Normal:'.s:hl_by_type[type])
  call timer_stop(s:timer)
  let s:timer = timer_start(delay, {-> nvim_win_close(s:win, v:true)})
endfunction

function! s:notification_vim(msg, opts) abort
  let width = get(a:opts, 'width', s:width)
  let delay = get(a:opts, 'delay', s:delay)
  let type = get(a:opts, 'type', 'info')
  let pos = get(a:opts, 'pos', s:pos)
  let pos_opts = s:get_pos(pos)
  let pos_opts.line = pos_opts.row
  unlet! pos_opts.row
  let opts = extend(pos_opts, {
        \ 'pos': pos,
        \ 'minwidth': width,
        \ 'maxwidth': width,
        \ 'time': delay,
        \ 'close': 'click',
        \ 'padding': [0, 0, 0, 1],
        \ })

  let opts.highlight = s:hl_by_type[type]
  call popup_hide(s:win)
  let s:win = popup_create(a:msg, opts)
endfunction

function! s:notification_echo(msg, opts) abort
  let type = get(a:opts, 'type', 'info')
  silent! exe 'echohl '.s:hl_by_type[type]
  let msg = type(a:msg) ==? type('') ? a:msg : string(a:msg)
  redraw!
  echom msg
  echohl None
endfunction

function! s:setup_colors() abort
  let warning_fg = ''
  let warning_bg = ''
  let error_fg = ''
  let error_bg = ''
  let normal_fg = ''
  let normal_bg = ''
  let warning_bg = synIDattr(hlID('WarningMsg'), 'bg')
  let warning_fg = synIDattr(hlID('WarningMsg'), 'fg')
  if empty(warning_bg)
    let warning_bg = warning_fg
    let warning_fg = '#FFFFFF'
  endif

  let error_bg = synIDattr(hlID('Error'), 'bg')
  let error_fg = synIDattr(hlID('Error'), 'fg')
  if empty(error_bg)
    let error_bg = error_fg
    let error_fg = '#FFFFFF'
  endif

  let normal_bg = synIDattr(hlID('Normal'), 'fg')
  let normal_fg = synIDattr(hlID('Normal'), 'bg')
  if empty(normal_bg)
    let normal_bg = normal_fg
    let normal_fg = '#FFFFFF'
  endif

  if s:neovim_float || s:vim_popup
    silent! exe 'hi NotificationInfo guifg='.normal_fg.' guibg='.normal_bg
    silent! exe 'hi NotificationError guifg='.error_fg.' guibg='.error_bg
    silent! exe 'hi NotificationWarning guifg='.warning_fg.' guibg='.warning_bg
  else
    silent! exe 'hi NotificationInfo guifg='.normal_fg.' guibg=NONE'
    silent! exe 'hi NotificationError guifg='.error_bg.' guibg=NONE'
    silent! exe 'hi NotificationWarning guifg='.warning_bg.' guibg=NONE'
  endif
endfunction

function! s:get_pos(pos) abort
  let min_col = s:neovim_float ? 1 : 2
  let min_row = s:neovim_float ? 0 : 1
  let max_col = &columns - 1
  let max_lines = &lines - 3
  let pos_data = {'col': min_col, 'row': min_row}

  if a:pos ==? 'topright'
    let pos_data.col = max_col
    let pos_data.row = min_row
  endif

  if a:pos ==? 'botleft'
    let pos_data.col = min_col
    let pos_data.row = max_lines
  endif

  if a:pos ==? 'botright'
    let pos_data.col = max_col
    let pos_data.row = max_lines
  endif

  return pos_data
endfunction
