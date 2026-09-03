return {
    {
        "3rd/image.nvim",

        ft = { "markdown" },

        -- 使用 magick CLI，不让 lazy.nvim 构建 luarocks
        build = false,

        opts = {
            ------------------------------------------------------------
            -- Windows + WezTerm
            ------------------------------------------------------------
            backend = "kitty",

            processor = "magick_cli",

            integrations = {
                markdown = {
                    enabled = true,

                    clear_in_insert_mode = true,

                    download_remote_images = true,

                    ----------------------------------------------------
                    -- 只显示光标所在的图片
                    ----------------------------------------------------
                    only_render_image_at_cursor = true,
                    only_render_image_at_cursor_mode = "popup",

                    floating_windows = false,

                    filetypes = {
                        "markdown",
                    },

                    ----------------------------------------------------
                    -- Obsidian attachment resolver
                    ----------------------------------------------------
                    resolve_image_path = function(
                        document_path,
                        image_path,
                        fallback
                    )
                        local ok, api = pcall(
                            require,
                            "obsidian.api"
                        )

                        if ok and api.path_is_note(document_path) then
                            local resolved =
                                api.resolve_attachment_path(
                                    image_path
                                )

                            if resolved then
                                return tostring(resolved)
                            end
                        end

                        return fallback(
                            document_path,
                            image_path
                        )
                    end,
                },

                neorg = {
                    enabled = false,
                },

                typst = {
                    enabled = false,
                },

                html = {
                    enabled = false,
                },

                css = {
                    enabled = false,
                },
            },

            ------------------------------------------------------------
            -- 图片尺寸
            ------------------------------------------------------------
            max_width_window_percentage = 70,
            max_height_window_percentage = 60,

            hijack_file_patterns = {
                "*.png",
                "*.jpg",
                "*.jpeg",
                "*.webp",
            },
        },
    },
}
