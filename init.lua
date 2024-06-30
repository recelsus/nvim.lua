-- =====================================================================================================================
-- @@ init
-- =====================================================================================================================

local pluginEnable = true
vim.g.mapleader = ' '

-- =====================================================================================================================
-- @@ Config
-- =====================================================================================================================

local opt = vim.opt
local cmd = vim.cmd

opt.title = true
opt.encoding = 'utf-8'
vim.scriptencoding = 'utf-8'
opt.fileformats = 'unix', 'mac'
opt.mouse = "a"

opt.ambiwidth = "double"
opt.tabstop = 2
opt.softtabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.autoindent = true
opt.smartindent = true

opt.number = true
opt.errorbells = false
opt.cursorline = true

opt.showtabline = 2
opt.cmdheight = 2

opt.writebackup = false
opt.backup = false
opt.wrap = false
opt.matchtime = 0

opt.incsearch = true
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = true
opt.wrapscan = true

opt.showcmd = true
opt.wildmenu = true
opt.clipboard:append('unnamedplus')

opt.ttimeout = true
opt.ttimeoutlen = 50

opt.undofile = true
opt.undodir = vim.fn.stdpath('cache') .. '/undo'
opt.swapfile = false

opt.nrformats = ''
opt.whichwrap = 'h,l,<,>,[,],~'
opt.virtualedit = 'block'

vim.opt.signcolumn = 'yes'

opt.splitbelow = true
opt.splitright = true

opt.syntax = enable

opt.timeoutlen = 300
cmd 'colorscheme slate'

-- =====================================================================================================================
-- @@ Terminal
-- =====================================================================================================================

function OpenTerminal()
  vim.cmd('botright split | resize 10 | terminal')
  vim.cmd('startinsert')
  vim.cmd('setlocal nonumber norelativenumber')
end

vim.api.nvim_exec([[
  augroup TerminalClose
    autocmd!
    autocmd TermClose * if !v:event.status | exe 'bd! ' . expand('<abuf>') | endif
  augroup END
]], false)

-- =====================================================================================================================
-- @@ Preference
-- =====================================================================================================================

vim.api.nvim_set_keymap('n', '<C-t>', ':lua OpenTerminal()<CR>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('t', '<ESC>', '<C-\\><C-n>', { noremap = true, silent = true })

local function ReplaceColours()
  vim.cmd('highlight User1 cterm=bold ctermfg=015 ctermbg=057') -- Insert
  vim.cmd('highlight User2 cterm=bold ctermfg=015 ctermbg=125') -- Normal
  vim.cmd('highlight User3 cterm=bold ctermfg=015 ctermbg=172') -- Terminal
  vim.cmd('highlight User4 cterm=bold ctermfg=015 ctermbg=011') -- Visual
  vim.cmd('highlight User5 cterm=bold ctermfg=015 ctermbg=175') -- Default

  local modes = {
    ['i'] = '1* INSERT',
    ['n'] = '2* NORMAL',
    ['R'] = '4* REPLACE',
    ['c'] = '3* COMMAND',
    ['t'] = '3* TERMIAL',
    ['v'] = '4* VISUAL',
    ['V'] = '4* VISUAL',
    [vim.api.nvim_replace_termcodes('<C-v>', true, true, true)] = '4* VISUAL'
  }

  local current_mode = vim.fn.mode()
  local mode_display = modes[current_mode] or '5* Another'

  return '%' .. mode_display .. ' %*' .. ' %<%F ' .. '%m%h%w' .. '%=' .. '%l/%L %c [%p%%]'
end

vim.cmd([[
  augroup StatusLineColors
    autocmd!
    autocmd VimEnter,ColorScheme * highlight MatchParen ctermfg=white ctermbg=red
    autocmd VimEnter,ColorScheme * highlight Comment ctermfg=175
    autocmd VimEnter,ColorScheme * highlight StatusLine cterm=NONE ctermfg=15 ctermbg=175
    autocmd VimEnter,ColorScheme * highlight StatusLineNC cterm=NONE ctermfg=7 ctermbg=0
    autocmd VimEnter,ColorScheme * highlight Normal ctermbg=none
    autocmd VimEnter,ColorScheme * set statusline=%!v:lua.ReplaceColours()
  augroup END
]])

_G.ReplaceColours = ReplaceColours

-- =====================================================================================================================
-- @@ Plugin-Manager Lazy.nvim
-- =====================================================================================================================

vim.api.nvim_set_keymap('i', '<C-s>', '<Nop>', { noremap = true, silent = true })
if pluginEnable then

local lazypath = vim.fn.expand("~/.config/nvim/plugins/lazy.nvim")
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end

vim.opt.runtimepath:prepend("~/.config/nvim/plugins/lazy.nvim")

local function is_fcitx5_installed()
  local handle = io.popen("command -v fcitx5")
  local result = handle:read("*a")
  handle:close()
  return result ~= ""
end

require("lazy").setup({
  spec = {
  ------- LSP Settings -------------------------------------------------------------------
    {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      local lspconfig = require("lspconfig")
      local util = require("lspconfig/util")

      local root_pattern = util.root_pattern("compile_commands.json", "compile_flags.txt", ".git")

      local on_attach = function(client, bufnr)
        local bufopts = { noremap=true, silent=true, buffer=bufnr }
        vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')
      end

      lspconfig.clangd.setup {
        cmd = { "clangd", "--background-index", "--log=verbose", "--clang-tidy", "--completion-style=detailed", "--all-scopes-completion" },
        filetypes = { "c", "cpp", "objc", "objcpp" },
        root_dir = function(fname)
          local filename = util.path.is_absolute(fname) and fname
            or util.path.join(vim.loop.cwd(), fname)
          return root_pattern(filename) or util.path.dirname(filename)
        end,
        init_options = {
          compilationDatabasePath = "compile_flags.txt",
        },
        on_attach = on_attach,
        capabilities = vim.lsp.protocol.make_client_capabilities(),
        flags = {
          debounce_text_changes = 150,
        },
        on_new_config = function(new_config, new_root_dir)
     
          local status_ok, clangd_extensions = pcall(require, "clangd_extensions")
          if status_ok then
            clangd_extensions.setup({
              server = {
                capabilities = vim.lsp.protocol.make_client_capabilities(),
              }
            })
          end
	end,
	}
      lspconfig.bashls.setup { on_attach = on_attach }
      lspconfig.tsserver.setup { on_attach = on_attach }
    end,
    },
  ------- LSP cmd Settings ---------------------------------------------------------------
    {
    "hrsh7th/nvim-cmp",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-cmdline",
      "L3MON4D3/LuaSnip",
    },
    config = function()
      local lspconfig = require("lspconfig")
      local cmp = require'cmp'
      local luasnip = require'luasnip'

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = {
          ['<C-d>'] = cmp.mapping.scroll_docs(-4),
          ['<C-f>'] = cmp.mapping.scroll_docs(4),
          ['<C-Space>'] = cmp.mapping.complete(),
          ['<C-e>'] = cmp.mapping.close(),
          ['<C-c>'] = cmp.mapping.abort(),
          ['<ESC>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.abort()
              vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<ESC>', true, false, true), 'n', true)
            else
              fallback()
            end
          end, { 'i', 's' }),
          ['<CR>'] = cmp.mapping.confirm({
            behavior = cmp.ConfirmBehavior.Replace,
            select = true,
          }),
          ['<Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { 'i', 's' }),
          ['<S-Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { 'i', 's' }),
          ['<C-j>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { 'i', 's' }),
          ['<C-k>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { 'i', 's' }),
        },
        sources = cmp.config.sources({
          { name = 'nvim_lsp' },
          { name = 'luasnip' },
        }, {
          { name = 'buffer' },
        })
      })

      cmp.setup.cmdline('/', {
        sources = {
          { name = 'buffer' }
        }
      })

      cmp.setup.cmdline(':', {
        sources = cmp.config.sources({
          { name = 'path' }
        }, {
          { name = 'cmdline' }
        })
      })

      local capabilities = require('cmp_nvim_lsp').default_capabilities(vim.lsp.protocol.make_client_capabilities())
      lspconfig.clangd.setup {
        capabilities = capabilities,
        on_attach = on_attach
      }
      lspconfig.bashls.setup {
        capabilities = capabilities,
        on_attach = on_attach
      }
      lspconfig.tsserver.setup {
        capabilities = capabilities,
        on_attach = on_attach
      }
    end
    },
  ------- Nvim-tree Settings -------------------------------------------------------------
    {
      "nvim-tree/nvim-tree.lua",
      dependencies = { "nvim-tree/nvim-web-devicons" },
      lazy = false,
      keys = {
        { mode = "n", "<C-n>", "<cmd>:Ex<cr>", desc = "Toggle Nvim-Tree Window on Left" },
      },
      config = function()
        require('nvim-tree').setup({

        })
        vim.api.nvim_set_var('loaded_netrw', 1)
        vim.api.nvim_set_var('loaded_netrwPlugin', 1)
        vim.cmd.colorscheme "slate"
        vim.api.nvim_create_user_command('Ex', function ()
        vim.cmd('NvimTreeToggle')
        end, {})
      end
    },
  ------- Nvim-autopairs Settings --------------------------------------------------------
    {
      "windwp/nvim-autopairs",
      event = "InsertEnter",
      config = true
	  },
  ------- Nvim-Telescope Settings --------------------------------------------------------
    {
      "nvim-telescope/telescope.nvim",
      dependencies = {
        "nvim-lua/plenary.nvim",
        { "nvim-telescope/telescope-fzf-native.nvim", 
          build = function()
            local install_path = vim.fn.stdpath('config') .. '/plugins/telescope-fzf-native.nvim'
            vim.notify(install_path)
            vim.fn.system({'make', '-C', install_path})
          end,
        },
      },
      config = function()
        require('telescope').setup{
          defaults = {
            file_ignore_patterns = {"node_modules", ".git"},
            mappings = {
              i = {
                ["<C-j>"] = require('telescope.actions').move_selection_next,
                ["<C-k>"] = require('telescope.actions').move_selection_previous,
              },
              n = {
                ["<C-j>"] = require('telescope.actions').move_selection_next,
                ["<C-k>"] = require('telescope.actions').move_selection_previous,
              },
            },
          },
          pickers = {
            find_files = {
              theme = "dropdown",
            }
          },
          extensions = {
            fzf = {
              fuzzy = true,
              override_generic_sorter = true,
              override_file_sorter = true,
              case_mode = "smart_case",
            }
          }
        }
        require('telescope').load_extension('fzf')
        vim.api.nvim_set_keymap('n', '<leader>ff', ':Telescope find_files<cr>', { noremap = true, silent = true })
        vim.api.nvim_set_keymap('n', '<leader>fg', ':Telescope live_grep<cr>', { noremap = true, silent = true })
        vim.api.nvim_set_keymap('n', '<leader>fb', ':Telescope buffers<cr>', { noremap = true, silent = true })
        vim.api.nvim_set_keymap('n', '<leader>fh', ':Telescope help_tags<cr>', { noremap = true, silent = true })
      end
    },
  ------- IM-select Settings --------------------------------------------------------
    (function()
      if vim.loop.os_uname().sysname == "Linux" and not is_fcitx5_installed() then
        return nil
      else
        return {
          "keaising/im-select.nvim",
          event = "InsertEnter",
          config = function()
            local im_select_config = {
              default_im_select  = "com.apple.keylayout.US", -- or "com.apple.keylayout.ABC"
              set_default_events = {"VimEnter", "InsertEnter", "InsertLeave"},
              set_previous_events = {},
            }

            if vim.loop.os_uname().sysname == "Linux" then
              im_select_config.default_im_select = "keyboard-us"
            end
            require("im_select").setup(im_select_config)
          end,
        }
      end
    end)(),
    {
      "iamcco/markdown-preview.nvim",
      cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
      ft = { "markdown" },
      build = function() vim.fn["mkdp#util#install"]() end,    
    },
  },
  root = vim.fn.stdpath("config") .. "/plugins",
})
end
