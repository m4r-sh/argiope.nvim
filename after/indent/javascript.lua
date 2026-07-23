-- Run after Neovim's JavaScript indent script so argiope can retain it as the
-- host-language fallback outside tagged template bodies.
require("argiope").attach(0)
