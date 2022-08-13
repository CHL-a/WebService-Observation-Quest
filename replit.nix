{ pkgs }: {
	deps = [
        pkgs.lua
        pkgs.sumneko-lua-language-server
		pkgs.lua51Packages.luasocket
	];
}