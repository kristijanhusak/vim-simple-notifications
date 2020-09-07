# vim-simple-notifications
Simple notification plugin to be used mostly by plugin developers.
Uses floating/popup window if available, and falls back to `echo` if popups are not available.

Can be used as a standalone plugin:
```vimL
" Vim packager
call packager#add('kristijanhusak/vim-simple-notifications')
" Vim Plug
Plug 'kristijanhusak/vim-simple-notifications'
```

or just copy `autoload/notifications.vim` file to your `autoload` folder, adapt public function names and you're good to go.

## Example usage
All options provided via 2nd argument have default options. Check [autoload/notifications.vim](autoload/notifications.vim#L7)

### notifications#info(msg: [List|String], opts: Dictionary)
```vimL
call notifications#info(['This is an info notification', 'that spans multiple lines'])
```
![screenshot-info](https://i.imgur.com/7dstZFc.png)

### notifications#warning(msg: [List|String], opts: Dictionary)
```vimL
call notifications#warning(['This is a warning', 'in the top left corner'], {'pos': 'topleft'})
```
![screenshot-warning](https://i.imgur.com/hN47hhx.png)

### notifications#error(msg: [List|String], opts: Dictionary)
```vimL
call notifications#error(['Something went wrong', 'Please check your logs'], {'pos': 'top', 'width': 30, 'delay': 10000 })
```
![screenshot-error](https://i.imgur.com/3cQJiiB.png)

With title
```vimL
call notifications#error(['Something went wrong', 'Please check your logs'], {'title': '[MyAwesomePlugin]'})
```
![screenshot-error-title](https://i.imgur.com/BxegSKz.png)
