-- Bootstrap lazy.nvim
--
--
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	local lazyrepo = "https://github.com/folke/lazy.nvim.git"
	local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
	if vim.v.shell_error ~= 0 then
		vim.api.nvim_echo({
			{ "Failed to clone lazy.nvim:\n", "ErrorMsg" },
			{ out, "WarningMsg" },
			{ "\nPress any key to exit..." },
		}, true, {})
		vim.fn.getchar()
		os.exit(1)
	end
end
vim.opt.rtp:prepend(lazypath)

-- Make sure to setup `mapleader` and `maplocalleader` before
-- loading lazy.nvim so that mappings are correct.
-- This is also a good place to setup other settings (vim.opt)
vim.opt.signcolumn = "yes"
vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.opt.relativenumber = true
vim.opt.number = true
vim.opt.tabstop = 4
vim.opt.expandtab = true
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.clipboard = "unnamedplus"
vim.opt.scrolloff = 10
vim.opt.undofile = true
vim.opt.cursorline = true
vim.opt.hlsearch = true
vim.opt.incsearch = true
vim.opt.termguicolors = true
vim.opt.list = true
local space = "·"
vim.opt.listchars:append({
	tab = "|·",
	multispace = space,
	lead = space,
	trail = space,
	nbsp = space,
})
vim.opt.smartcase = true
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")
-- tree sitter highlighting has priority over semantic tokens
vim.highlight.priorities.semantic_tokens = 95
vim.diagnostic.config({ update_in_insert = true })
vim.keymap.set("n", "<leader>m", ":Neominimap Toggle<CR>")
vim.filetype.add({
	extension = {
		avdl = "avdl",
	},
})

-- Setup lazy.nvim
require("lazy").setup({
	-- add your plugins here
	{
		"williamboman/mason.nvim",
		config = function()
			require("mason").setup()
		end,
	},
	{
		"neovim/nvim-lspconfig",
		version = "*",
		config = function()
			local capabilities = require("cmp_nvim_lsp").default_capabilities()

			local function setupServer(server_name)
				require("lspconfig")[server_name].setup({ capabilities = capabilities })
			end

			setupServer("ts_ls")
			setupServer("tailwindcss")
			setupServer("eslint")
			setupServer("jsonls")

			local cmp = require("cmp")

			cmp.setup({
				mapping = {
					["<C-n>"] = cmp.mapping.select_next_item({
						behavior = cmp.SelectBehavior.Select,
					}),
					["<C-p>"] = cmp.mapping.select_prev_item({
						behavior = cmp.SelectBehavior.Select,
					}),
					["<Tab>"] = cmp.mapping.confirm({ select = true }),
					["<C-space>"] = cmp.mapping.complete(),
				},
				sources = {
					{ name = "nvim_lsp" },
					{ name = "nvim_lsp_signature_help" },
				},
				window = {
					completion = cmp.config.window.bordered(),
					documentation = cmp.config.window.bordered(),
				},
			})
		end,
		dependencies = { "hrsh7th/nvim-cmp", "hrsh7th/cmp-nvim-lsp", "hrsh7th/cmp-nvim-lsp-signature-help" },
	},
	{
		"lewis6991/gitsigns.nvim",
		opts = {
			current_line_blame = true,
		},
	},
	{
		"nvim-treesitter/nvim-treesitter-context",
		opts = {
			max_lines = 3,
			multiline_threshold = 1,
		},
	},
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		main = "nvim-treesitter.configs",
		opts = {
			-- these are usually embedded, so auto_install won't work
			ensure_installed = { "markdown_inline", "markdown", "diff", "vim", "vimdoc" },
			sync_install = false,
			auto_install = true,
			highlight = {
				enable = true,
				additional_vim_regex_highlighting = false,
			},
			indent = {
				enable = true,
			},
		},
	},
	{
		"nvim-telescope/telescope.nvim",
		branch = "0.1.x",
		config = function()
			local actions = require("telescope.actions")
			require("telescope").setup({
				pickers = {
					find_files = {
						hidden = true,
					},
					oldfiles = {
						cwd_only = true,
					},
				},
				defaults = {
					file_ignore_patterns = {
						".git/",
					},
					mappings = {
						i = {
							["<esc>"] = actions.close,
						},
					},
				},
			})
			require("telescope").load_extension("fzf")
			require("telescope").load_extension("live_grep_args")
			local builtin = require("telescope.builtin")
			vim.keymap.set("n", "<leader>p", builtin.find_files)
			vim.keymap.set("n", "<leader>ht", builtin.help_tags)
			-- vim.keymap.set('n', '<a-p>', ":Telescope find_files" )
			-- vim.keymap.set("n", "<leader><s-g>", builtin.git_status)
			vim.keymap.set("n", "<leader>o", builtin.oldfiles)
			-- vim.keymap.set("n", "<leader><s-f>", builtin.live_grep)
			vim.keymap.set(
				"n",
				"<leader><s-f>",
				":lua require('telescope').extensions.live_grep_args.live_grep_args()<CR>"
			)
			vim.keymap.set("n", "<leader>sx", builtin.resume, {
				noremap = true,
				silent = true,
				desc = "Resume",
			})
			vim.api.nvim_create_autocmd("LspAttach", {
				callback = function(args)
					local bufnr = args.buf
					local opts = { buffer = bufnr }
					vim.keymap.set("n", "gr", builtin.lsp_references, opts)
					vim.keymap.set("n", "gd", builtin.lsp_definitions, opts)
					vim.keymap.set("n", "gi", builtin.lsp_implementations, opts)
					vim.keymap.set("n", "<leader>@", builtin.lsp_document_symbols, opts)
					vim.keymap.set("n", "<leader>a", vim.lsp.buf.code_action)
					vim.keymap.set("n", "ge", vim.diagnostic.open_float)
					vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename)
					vim.keymap.set("n", "gh", vim.lsp.buf.hover)
				end,
			})
		end,
		dependencies = {
			"nvim-lua/plenary.nvim",
			{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
			{
				"nvim-telescope/telescope-live-grep-args.nvim",
				-- This will not install any breaking changes.
				-- For major updates, this must be adjusted manually.
				version = "^1.0.0",
			},
		},
	},
	{
		"nvim-neo-tree/neo-tree.nvim",
		branch = "v3.x",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
			"MunifTanjim/nui.nvim",
			-- "3rd/image.nvim", -- Optional image support in preview window: See `# Preview Mode` for more information
		},
		config = function()
			local events = require("neo-tree.events")
			---@class FileMovedArgs
			---@field source string
			---@field destination string

			---@param args FileMovedArgs
			local function on_file_remove(args)
				local ts_clients = vim.lsp.get_active_clients({ name = "ts_ls" })
				for _, ts_client in ipairs(ts_clients) do
					ts_client.request("workspace/executeCommand", {
						command = "_typescript.applyRenameFile",
						arguments = {
							{
								sourceUri = vim.uri_from_fname(args.source),
								targetUri = vim.uri_from_fname(args.destination),
							},
						},
					})
				end
			end

			require("neo-tree").setup({
				filesystem = {
					filtered_items = { hide_dotfiles = false, hide_gitignored = false, visible = true },
					follow_current_file = { enabled = true, leave_dirs_open = false },
					use_libuv_file_watcher = true,
				},
				event_handlers = {
					{
						event = events.NEO_TREE_BUFFER_ENTER,
						handler = function()
							vim.wo.number = true
							vim.wo.relativenumber = true
						end,
					},
					{
						event = events.FILE_MOVED,
						handler = on_file_remove,
					},
					{
						event = events.FILE_RENAMED,
						handler = on_file_remove,
					},
				},
			})

			vim.keymap.set("n", "<leader>b", ":Neotree toggle<CR>")

			vim.api.nvim_create_autocmd({ "BufLeave" }, {
				pattern = { "*lazygit*" },
				group = vim.api.nvim_create_augroup("neovim_update_tree", { clear = true }),
				callback = function()
					require("neo-tree.sources.filesystem.commands").refresh(
						require("neo-tree.sources.manager").get_state("filesystem")
					)
				end,
			})
		end,
	},
	{ "windwp/nvim-autopairs", opts = { disable_filetype = { "TelescopePrompt", "vim" }, check_ts = true } },
	{
		"stevearc/conform.nvim",
		opts = {
			format_on_save = { timeout_ms = 2500, lsp_format = "fallback" },
			formatters_by_ft = {
				lua = { "stylua" },
				javascript = { "prettier" },
				typescript = { "prettier" },
				typescriptreact = { "prettier" },
			},
		},
	},
	{
		"lukas-reineke/indent-blankline.nvim",
		event = "VeryLazy",
		main = "ibl",
		opts = {
			scope = {
				show_start = false,
				show_end = false,
			},
		},
	},
	{
		"tpope/vim-sleuth",
	},
	{
		"tronikelis/ts-autotag.nvim",
		opts = {
			auto_rename = {
				enabled = true,
			},
		},
		-- ft = {}, optionally you can load it only in jsx/html
		event = "VeryLazy",
	},
	{
		"nvim-lualine/lualine.nvim",
		opts = {},
		dependencies = { "nvim-tree/nvim-web-devicons" },
	},
	{

		"tronikelis/conflict-marker.nvim",
		opts = {},
	},
	{
		"folke/ts-comments.nvim",
		opts = {},
		event = "VeryLazy",
		enabled = vim.fn.has("nvim-0.10.0") == 1,
	},
	{
		"scottmckendry/cyberdream.nvim",
		lazy = false,
		priority = 1000,
	},
	{
		"kdheepak/lazygit.nvim",
		cmd = {
			"LazyGit",
			"LazyGitConfig",
			"LazyGitCurrentFile",
			"LazyGitFilter",
			"LazyGitFilterCurrentFile",
		},
		-- optional for floating window border decoration
		dependencies = {
			"nvim-lua/plenary.nvim",
		},
		-- setting the keybinding for LazyGit with 'keys' is recommended in
		-- order to load the plugin when the command is run for the first time
		keys = {
			{ "<leader><S-g>", "<cmd>LazyGit<cr>", desc = "Open lazy git" },
		},
	},
	{
		"github/copilot.vim",
		init = function()
			vim.keymap.set("i", "<leader><Tab>", 'copilot#Accept("")', {
				expr = true,
				silent = true,
				replace_keycodes = false,
				desc = "Accept Copilot suggestion",
			})
			vim.g.copilot_no_tab_map = true
		end,
	},
	{
		"Isrothy/neominimap.nvim",
		version = "v3.x.x",
		lazy = false, -- NOTE: NO NEED to Lazy load
		init = function()
			vim.opt.wrap = false
			vim.opt.sidescrolloff = 36
			vim.cmd([[
				highlight NeominimapGitAddLine guifg=#00ff00 guibg=#004d00  " Bright green on dark green
				highlight NeominimapGitChangeLine guifg=#ffff00 guibg=#4d4d00 " Bright yellow on dark yellow
				highlight NeominimapGitDeleteLine guifg=#ff3333 guibg=#4d0000 " Bright red on dark red

				highlight NeominimapGitAddIcon guifg=#00ff00 guibg=NONE      " Bright green
				highlight NeominimapGitChangeIcon guifg=#ffff00 guibg=NONE   " Bright yellow
				highlight NeominimapGitDeleteIcon guifg=#ff3333 guibg=NONE   " Bright red
			]])

			vim.g.neominimap = {
				auto_enable = true,
				layout = "split",
				split = {
					minimap_width = 16,
				},
				git = {
					enabled = true,
					mode = "line",
					priority = 6,
					icon = {
						add = "+ ",
						change = "~ ",
						delete = "- ",
					},
				},
			}
		end,
	},
})

vim.cmd("colorscheme cyberdream")
