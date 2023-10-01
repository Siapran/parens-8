parens8[[
(set readrom
     (fn (addr len filename)
         ((fn (target)
              (chr (peek target len)))
          (when filename
            (id 0x8000 (reload 0x8000 addr len filename))
            addr))))
]]
