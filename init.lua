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

-- Setup lazy.nvim
require("lazy").setup({
	-- add your plugins here
	{
		"olimorris/onedarkpro.nvim",
		priority = 1000, -- Ensure it loads first
		opts = {
			options = { cursorline = true },
		},
	},
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

			local cmp = require("cmp")

			cmp.setup({
				mapping = {
					["<C-n>"] = cmp.mapping.select_next_item({
						behavior = cmp.SelectBehavior.Select,
					}),
					["<C-p>"] = cmp.mapping.select_prev_item({
						behavior = cmp.SelectBehavior.Select,
					}),
					["<CR>"] = cmp.mapping.confirm({ select = true }),
					["<C-A-Space>"] = cmp.mapping.complete(),
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
		opts = {},
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
				defaults = {
					mappings = {
						i = {
							["<esc>"] = actions.close,
						},
					},
				},
			})
			require("telescope").load_extension("fzf")
			local builtin = require("telescope.builtin")
			vim.keymap.set("n", "<a-p>", builtin.find_files)
			vim.keymap.set("n", "<leader>ht", builtin.help_tags)
			-- vim.keymap.set('n', '<a-p>', ":Telescope find_files" )
			vim.keymap.set("n", "<a-s-g>", builtin.git_status)
			vim.keymap.set("n", "<a-s-f>", builtin.live_grep)
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
		dependencies = { "nvim-lua/plenary.nvim", { "nvim-telescope/telescope-fzf-native.nvim", build = "make" } },
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
			require("neo-tree").setup({
				filesystem = {
					filtered_items = { hide_dotfiles = false, hide_gitignored = false, visible = true },
					follow_current_file = { enabled = true, leave_dirs_open = false },
				},
			})
			vim.keymap.set("n", "<a-b>", ":Neotree toggle<CR>")
		end,
	},
	{ "windwp/nvim-autopairs", opts = { disable_filetype = { "TelescopePrompt", "vim" }, check_ts = true } },
	{
		"stevearc/conform.nvim",
		opts = {
			format_on_save = { timeout_ms = 500, lsp_format = "fallback" },
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
		opts = {},
		-- ft = {}, optionally you can load it only in jsx/html
		event = "VeryLazy",
	},
	{
		"nvim-lualine/lualine.nvim",
		opts = {},
		dependencies = { "nvim-tree/nvim-web-devicons" },
	},
})

vim.cmd("colorscheme onedark")
