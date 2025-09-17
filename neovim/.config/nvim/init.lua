-- Leader keys (must be set before plugins)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Set to true if your terminal uses a Nerd Font
vim.g.have_nerd_font = true

-- =========================
-- Core editor preferences
-- =========================
vim.o.number = true
vim.o.relativenumber = true
vim.o.mouse = 'a'
vim.o.showmode = false

-- Share system clipboard (set after UI init to avoid startup delay)
vim.schedule(function()
  vim.o.clipboard = 'unnamedplus'
end)

vim.o.breakindent = true
vim.o.undofile = true
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.signcolumn = 'yes'
vim.o.updatetime = 250
vim.o.timeoutlen = 300
vim.o.splitright = true
vim.o.splitbelow = true
vim.o.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }
vim.o.inccommand = 'split'
vim.o.cursorline = true
vim.o.scrolloff = 10
vim.o.confirm = true

-- =========================
-- Basic keymaps
-- =========================
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

-- Easier terminal escape (fallback: <C-\\><C-n>)
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- Nudge away from arrow keys (training wheels)
vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')

-- Window navigation: Ctrl + h/j/k/l
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus left' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus right' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus down' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus up' })

-- =========================
-- Autocommands
-- =========================
-- Briefly highlight yanked text
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})

-- =========================
-- lazy.nvim bootstrapping
-- =========================
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local out = vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', 'https://github.com/folke/lazy.nvim.git', lazypath }
  if vim.v.shell_error ~= 0 then
    error('Error cloning lazy.nvim:\n' .. out)
  end
end
---@type vim.Option
local rtp = vim.opt.rtp
rtp:prepend(lazypath)

-- =========================
-- Plugins & configuration
-- =========================
require('lazy').setup({
  -- Auto-detect indentation; apply sensible fallbacks if detection fails
  {
    'NMAC427/guess-indent.nvim',
    opts = {
      auto_cmd = true,
      override_editorconfig = false,
      on_space_options = { expandtab = true, tabstop = 'detected', softtabstop = 'detected', shiftwidth = 'detected' },
      on_tab_options = { expandtab = false },
    },
    config = function(_, opts)
      local guess_indent = require 'guess-indent'
      guess_indent.setup(opts)

      local function no_indentation_found(bufnr, max_lines)
        bufnr = bufnr or 0
        max_lines = max_lines or 500
        local last = math.min(vim.api.nvim_buf_line_count(bufnr), max_lines)
        local has_tabs, has_spaces = false, false
        for _, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, 0, last, false)) do
          local ws = line:match '^%s+'
          if ws then
            if ws:find '\t' then
              has_tabs = true
            end
            if ws:find ' ' then
              has_spaces = true
            end
            if has_tabs or has_spaces then
              break
            end
          end
        end
        return (not has_tabs) and not has_spaces
      end

      -- Only set defaults if detection yields nothing (e.g., new/short files)
      local function apply_fallback_if_needed(ft)
        vim.cmd 'silent! GuessIndent'
        if no_indentation_found(0) then
          if ft == 'markdown' then
            vim.bo.expandtab = false
            vim.bo.tabstop = 4
            vim.bo.shiftwidth = 4
            vim.bo.softtabstop = 0
          else
            vim.bo.expandtab = true
            vim.bo.tabstop = 2
            vim.bo.shiftwidth = 2
            vim.bo.softtabstop = 2
          end
        end
      end

      vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufNewFile' }, {
        callback = function(args)
          apply_fallback_if_needed(vim.bo[args.buf].filetype)
        end,
      })
    end,
  },

  -- Git signs in the gutter
  {
    'lewis6991/gitsigns.nvim',
    opts = {
      signs = {
        add = { text = '+' },
        change = { text = '~' },
        delete = { text = '_' },
        topdelete = { text = '‾' },
        changedelete = { text = '~' },
      },
    },
  },

  -- Which-key: discoverable keymaps
  {
    'folke/which-key.nvim',
    event = 'VimEnter',
    opts = {
      delay = 0,
      icons = {
        mappings = vim.g.have_nerd_font,
        keys = vim.g.have_nerd_font and {} or {
          Up = '<Up> ',
          Down = '<Down> ',
          Left = '<Left> ',
          Right = '<Right> ',
          C = '<C-…> ',
          M = '<M-…> ',
          D = '<D-…> ',
          S = '<S-…> ',
          CR = '<CR> ',
          Esc = '<Esc> ',
          ScrollWheelDown = '<ScrollWheelDown> ',
          ScrollWheelUp = '<ScrollWheelUp> ',
          NL = '<NL> ',
          BS = '<BS> ',
          Space = '<Space> ',
          Tab = '<Tab> ',
          F1 = '<F1>',
          F2 = '<F2>',
          F3 = '<F3>',
          F4 = '<F4>',
          F5 = '<F5>',
          F6 = '<F6>',
          F7 = '<F7>',
          F8 = '<F8>',
          F9 = '<F9>',
          F10 = '<F10>',
          F11 = '<F11>',
          F12 = '<F12>',
        },
      },
      spec = {
        { '<leader>s', group = '[S]earch' },
        { '<leader>t', group = '[T]oggle' },
        { '<leader>h', group = 'Git [H]unk', mode = { 'n', 'v' } },
      },
    },
  },

  -- Telescope: fuzzy finder
  {
    'nvim-telescope/telescope.nvim',
    event = 'VimEnter',
    dependencies = {
      'nvim-lua/plenary.nvim',
      {
        'nvim-telescope/telescope-fzf-native.nvim',
        build = 'make',
        cond = function()
          return vim.fn.executable 'make' == 1
        end,
      },
      { 'nvim-telescope/telescope-ui-select.nvim' },
      { 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font },
    },
    config = function()
      require('telescope').setup {
        extensions = { ['ui-select'] = { require('telescope.themes').get_dropdown() } },
      }
      pcall(require('telescope').load_extension, 'fzf')
      pcall(require('telescope').load_extension, 'ui-select')

      local builtin = require 'telescope.builtin'
      vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
      vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
      vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
      vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = '[S]elect Telescope' })
      vim.keymap.set('n', '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
      vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
      vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
      vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
      vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch Recent Files' })
      vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = 'Find buffers' })

      vim.keymap.set('n', '<leader>/', function()
        builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown { winblend = 10, previewer = false })
      end, { desc = 'Fuzzy search in buffer' })

      vim.keymap.set('n', '<leader>s/', function()
        builtin.live_grep { grep_open_files = true, prompt_title = 'Live Grep in Open Files' }
      end, { desc = '[S]earch [/] in Open Files' })

      vim.keymap.set('n', '<leader>sn', function()
        builtin.find_files { cwd = vim.fn.stdpath 'config' }
      end, { desc = '[S]earch [N]eovim files' })
    end,
  },

  -- LSP core + helpers
  {
    'folke/lazydev.nvim',
    ft = 'lua',
    opts = { library = { { path = '${3rd}/luv/library', words = { 'vim%.uv' } } } },
  },
  {
    'neovim/nvim-lspconfig',
    dependencies = {
      { 'mason-org/mason.nvim', opts = {} },
      'mason-org/mason-lspconfig.nvim',
      'WhoIsSethDaniel/mason-tool-installer.nvim',
      { 'j-hui/fidget.nvim', opts = {} },
      'saghen/blink.cmp',
    },
    config = function()
      -- Per-buffer LSP keymaps + features
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
        callback = function(event)
          local map = function(keys, func, desc, mode)
            mode = mode or 'n'
            vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
          end

          map('grn', vim.lsp.buf.rename, '[R]e[n]ame')
          map('gra', vim.lsp.buf.code_action, '[G]oto Code [A]ction', { 'n', 'x' })
          map('grr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')
          map('gri', require('telescope.builtin').lsp_implementations, '[G]oto [I]mplementation')
          map('grd', require('telescope.builtin').lsp_definitions, '[G]oto [D]efinition')
          map('grD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
          map('gO', require('telescope.builtin').lsp_document_symbols, 'Open Document Symbols')
          map('gW', require('telescope.builtin').lsp_dynamic_workspace_symbols, 'Open Workspace Symbols')
          map('grt', require('telescope.builtin').lsp_type_definitions, '[G]oto [T]ype Definition')

          ---@param client vim.lsp.Client
          ---@param method vim.lsp.protocol.Method
          ---@param bufnr? integer
          local function client_supports_method(client, method, bufnr)
            if vim.fn.has 'nvim-0.11' == 1 then
              return client:supports_method(method, bufnr)
            else
              return client.supports_method(method, { bufnr = bufnr })
            end
          end

          local client = vim.lsp.get_client_by_id(event.data.client_id)

          -- Force LTeX to German defaults (with fine-tuning)
          if client and client.name == 'ltex' then
            client.config.settings = client.config.settings or {}
            client.config.settings.ltex = client.config.settings.ltex or {}

            client.config.settings.ltex.language = 'de-DE'
            local ar = client.config.settings.ltex.additionalRules or {}
            ar.motherTongue = ar.motherTongue or 'de-DE'
            client.config.settings.ltex.additionalRules = ar

            local dr = client.config.settings.ltex.disabledRules or {}
            local function add(lang, rule)
              dr[lang] = dr[lang] or {}
              if not vim.tbl_contains(dr[lang], rule) then
                table.insert(dr[lang], rule)
              end
            end
            add('de', 'DE_CASE')
            add('de-DE', 'DE_CASE')
            add('de-AT', 'DE_CASE')
            add('de-CH', 'DE_CASE')
            add('de-DE-x-simple-language', 'DE_CASE')
            client.config.settings.ltex.disabledRules = dr

            client:notify('workspace/didChangeConfiguration', { settings = client.config.settings })
            vim.defer_fn(function()
              vim.notify('[LTeX] language=' .. tostring(client.config.settings.ltex.language), vim.log.levels.INFO)
            end, 50)
          end

          -- Highlight references on cursor hold
          if client and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_documentHighlight, event.buf) then
            local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
            vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
              buffer = event.buf,
              group = highlight_augroup,
              callback = vim.lsp.buf.document_highlight,
            })
            vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
              buffer = event.buf,
              group = highlight_augroup,
              callback = vim.lsp.buf.clear_references,
            })
            vim.api.nvim_create_autocmd('LspDetach', {
              group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
              callback = function(event2)
                vim.lsp.buf.clear_references()
                vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
              end,
            })
          end

          -- Toggle inlay hints if supported
          if client and client_supports_method(client, vim.lsp.protocol.Methods.textDocument_inlayHint, event.buf) then
            map('<leader>th', function()
              vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
            end, '[T]oggle Inlay [H]ints')
          end
        end,
      })

      -- Diagnostic UI
      vim.diagnostic.config {
        severity_sort = true,
        float = { border = 'rounded', source = 'if_many' },
        underline = { severity = vim.diagnostic.severity.ERROR },
        signs = vim.g.have_nerd_font and {
          text = {
            [vim.diagnostic.severity.ERROR] = '󰅚 ',
            [vim.diagnostic.severity.WARN] = '󰀪 ',
            [vim.diagnostic.severity.INFO] = '󰋽 ',
            [vim.diagnostic.severity.HINT] = '󰌶 ',
          },
        } or {},
        virtual_text = {
          source = 'if_many',
          spacing = 2,
          format = function(d)
            local m = {
              [vim.diagnostic.severity.ERROR] = d.message,
              [vim.diagnostic.severity.WARN] = d.message,
              [vim.diagnostic.severity.INFO] = d.message,
              [vim.diagnostic.severity.HINT] = d.message,
            }
            return m[d.severity]
          end,
        },
      }

      -- Extend LSP capabilities with blink.cmp
      local capabilities = require('blink.cmp').get_lsp_capabilities()

      -- Servers to enable + per-server settings
      local servers = {
        marksman = {},
        ltex = {
          filetypes = {
            'markdown',
            'text',
            'plaintex',
            'tex',
            'bib',
            'gitcommit',
            'org',
            'rst',
            'lua',
            'python',
            'javascript',
            'typescript',
            'javascriptreact',
            'typescriptreact',
            'html',
            'css',
            'scss',
            'json',
            'yaml',
            'toml',
            'c',
            'cpp',
            'rust',
            'go',
            'java',
            'kotlin',
            'swift',
            'php',
            'cs',
            'sh',
            'bash',
            'zsh',
          },
          settings = {
            ltex = {
              language = 'de-DE',
              additionalRules = { motherTongue = 'de-DE' },
              dictionary = {
                ['en-US'] = { 'Staatsoper', 'Riedel', 'Inspizientenanlage' },
                ['de-DE'] = { 'Kündigungsschutz', 'Arbeitszeitbetrug' },
              },
              hiddenFalsePositives = {},
              disabledRules = {
                ['de'] = { 'DE_CASE' },
                ['de-DE'] = { 'DE_CASE' },
                ['de-AT'] = { 'DE_CASE' },
                ['de-CH'] = { 'DE_CASE' },
                ['de-DE-x-simple-language'] = { 'DE_CASE' },
                ['en-US'] = { 'UPPERCASE_SENTENCE_START' },
              },
            },
          },
        },
        lua_ls = {
          settings = {
            Lua = {
              completion = { callSnippet = 'Replace' },
              -- diagnostics = { disable = { 'missing-fields' } },
            },
          },
        },
      }

      -- Helper commands to switch LTeX language on the fly
      local function set_ltex_lang(lang)
        local bufnr = vim.api.nvim_get_current_buf()
        for _, client in pairs(vim.lsp.get_clients { bufnr = bufnr }) do
          if client.name == 'ltex' then
            client.config.settings = client.config.settings or {}
            client.config.settings.ltex = client.config.settings.ltex or {}
            client.config.settings.ltex.language = lang
            client.notify('workspace/didChangeConfiguration', { settings = client.config.settings })
            vim.notify('LTeX language set to ' .. lang, vim.log.levels.INFO)
            return
          end
        end
        vim.notify('LTeX is not attached to this buffer', vim.log.levels.WARN)
      end
      vim.api.nvim_create_user_command('LTeXLang', function(opts)
        set_ltex_lang(opts.args)
      end, {
        nargs = 1,
        complete = function()
          return { 'auto', 'en-US', 'en-GB', 'de-DE', 'de-AT', 'de-CH' }
        end,
      })
      vim.api.nvim_create_user_command('LTeXDe', function()
        set_ltex_lang 'de-DE'
      end, {})
      vim.api.nvim_create_user_command('LTeXEn', function()
        set_ltex_lang 'en-US'
      end, {})

      -- Ensure tools/servers are installed via Mason
      local ensure_installed = vim.tbl_keys(servers or {})
      vim.list_extend(ensure_installed, { 'stylua' })
      require('mason-tool-installer').setup { ensure_installed = ensure_installed }

      require('mason-lspconfig').setup {
        ensure_installed = {},
        automatic_installation = false,
        handlers = {
          function(server_name)
            local server = servers[server_name] or {}
            server.capabilities = vim.tbl_deep_extend('force', {}, capabilities, server.capabilities or {})
            require('lspconfig')[server_name].setup(server)
          end,
        },
      }
    end,
  },

  -- Conform: formatter orchestration
  {
    'stevearc/conform.nvim',
    event = { 'BufWritePre' },
    cmd = { 'ConformInfo' },
    keys = {
      {
        '<leader>f',
        function()
          require('conform').format { async = true, lsp_format = 'fallback' }
        end,
        mode = '',
        desc = '[F]ormat buffer',
      },
    },
    opts = {
      notify_on_error = false,
      format_on_save = function(bufnr)
        local disable_filetypes = { c = true, cpp = true }
        if disable_filetypes[vim.bo[bufnr].filetype] then
          return nil
        end
        return { timeout_ms = 500, lsp_format = 'fallback' }
      end,
      formatters_by_ft = { lua = { 'stylua' } },
    },
  },

  -- Completion (blink.cmp) + LuaSnip
  {
    'saghen/blink.cmp',
    event = 'VimEnter',
    version = '1.*',
    dependencies = {
      {
        'L3MON4D3/LuaSnip',
        version = '2.*',
        build = (function()
          if vim.fn.has 'win32' == 1 or vim.fn.executable 'make' == 0 then
            return
          end
          return 'make install_jsregexp'
        end)(),
        dependencies = {
          -- Optional: friendly-snippets (disabled here)
          -- {
          --   'rafamadriz/friendly-snippets',
          --   config = function() require('luasnip.loaders.from_vscode').lazy_load() end,
          -- },
        },
        opts = {},
      },
      'folke/lazydev.nvim',
    },
    --- @type blink.cmp.Config
    opts = {
      keymap = { preset = 'default' },
      appearance = { nerd_font_variant = 'mono' },
      completion = { documentation = { auto_show = false, auto_show_delay_ms = 500 } },
      sources = {
        default = { 'lsp', 'path', 'snippets', 'lazydev' },
        providers = { lazydev = { module = 'lazydev.integrations.blink', score_offset = 100 } },
      },
      snippets = { preset = 'luasnip' },
      fuzzy = { implementation = 'lua' },
      signature = { enabled = true },
    },
  },

  -- Colorscheme
  {
    'folke/tokyonight.nvim',
    priority = 1000,
    config = function()
      ---@diagnostic disable-next-line: missing-fields
      require('tokyonight').setup { styles = { comments = { italic = false } } }
      vim.cmd.colorscheme 'tokyonight-night'
    end,
  },

  -- TODO/NOTE/FIX highlight in comments
  { 'folke/todo-comments.nvim', event = 'VimEnter', dependencies = { 'nvim-lua/plenary.nvim' }, opts = { signs = false } },

  -- Mini collection: ai/surround/statusline (+indent info)
  {
    'echasnovski/mini.nvim',
    config = function()
      require('mini.ai').setup { n_lines = 500 }
      require('mini.surround').setup()
      local statusline = require 'mini.statusline'
      statusline.setup { use_icons = vim.g.have_nerd_font }
      statusline.section_location = function()
        return '%2l:%-2v'
      end
      do
        local old_fileinfo = statusline.section_fileinfo
        statusline.section_fileinfo = function(...)
          local base = old_fileinfo(...)
          local et = vim.bo.expandtab and '[SPC]' or '[TAB]'
          local ts = vim.bo.tabstop
          local sw = (vim.bo.shiftwidth == 0) and ts or vim.bo.shiftwidth
          local sts = (vim.bo.softtabstop <= 0) and ts or vim.bo.softtabstop
          return string.format('%s %s ts=%d sw=%d sts=%d', base, et, ts, sw, sts)
        end
      end
    end,
  },

  -- Treesitter: syntax highlight/indent
  {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    main = 'nvim-treesitter.configs',
    opts = {
      ensure_installed = { 'bash', 'c', 'diff', 'html', 'lua', 'luadoc', 'markdown', 'markdown_inline', 'query', 'vim', 'vimdoc' },
      auto_install = true,
      highlight = { enable = true, additional_vim_regex_highlighting = { 'ruby' } },
      indent = { enable = true, disable = { 'ruby' } },
    },
  },

  -- (Examples/next steps commented out; enable if you add those files)
  -- require 'kickstart.plugins.debug',
  -- require 'kickstart.plugins.indent_line',
  -- require 'kickstart.plugins.lint',
  -- require 'kickstart.plugins.autopairs',
  -- require 'kickstart.plugins.neo-tree',
  -- require 'kickstart.plugins.gitsigns',
}, {
  ui = {
    icons = vim.g.have_nerd_font and {} or {
      cmd = '⌘',
      config = '🛠',
      event = '📅',
      ft = '📂',
      init = '⚙',
      keys = '🗝',
      plugin = '🔌',
      runtime = '💻',
      require = '🌙',
      source = '📄',
      start = '🚀',
      task = '📌',
      lazy = '💤 ',
    },
  },
})

-- Modeline: see :help modeline
-- vim: ts=2 sts=2 sw=2 et
