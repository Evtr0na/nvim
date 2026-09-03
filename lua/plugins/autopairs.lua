return {
    {
        "windwp/nvim-autopairs",
        event = "InsertEnter",

        opts = {
            -- 你的 <CR> 已经由 blink.cmp preset = "enter" 管理
            -- 不让 autopairs 再抢一次 Enter
            map_cr = false,
        },
    },
}
