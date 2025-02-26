        .setcpu "6502"

        .include "../../common/charmap.inc"
        .include "../../common/nes.inc"
        .include "../../common/player.inc"
        .include "../../common/ppu.inc"
        .include "../../common/word_util.inc"
        .include "../../common/vram_buffer.inc"

        .include "../../../bhop/zsaw.inc"

        .include "mmc3.inc"

        .zeropage

        .segment "RAM"
NmiCounter: .byte $00

        .segment "CHR0"
        .incbin "../../common/bnuuy_bg.chr"
        .segment "CHR1"
        .incbin "../../common/bnuuy_obj.chr"

        .export start, demo_nmi, bhop_music_data
        
bhop_music_data = $A000

        .segment "MUSIC_0"
        .scope MODULE_0
        .include "../music/heatdeath.asm"
        .endscope

        .segment "MUSIC_1"
        .scope MODULE_1
        .include "../music/tactus.asm"
        .endscope

        .segment "MUSIC_2"
        .scope MODULE_2
        .include "../music/tcg.asm"
        .endscope

        .segment "MUSIC_3"
        .scope MODULE_3
        .include "../music/mimiga.asm"
        .endscope

        .segment "MUSIC_4"
        .scope MODULE_4
        .include "../music/in_another_world.asm"
        .endscope

        .segment "CODE"

;                            Bank  Track#                         Title                        Artist
;                             ---     ---  ----------------------------  ----------------------------
song_heat_death: music_track    0,      0,        "Heat Death - Smooth",                   "zeta0134"
song_tactus:     music_track    1,      0,              "Tactus - Demo",                   "zeta0134"
song_tcg:        music_track    2,      0,        "Pokemon TCG - Diary",           "Ichiro Shimakura"
song_mimiga:     music_track    3,      0,   "Cave Story - Mimiga Town",              "Daisuke Amaya"
song_iaw:        music_track    4,      1,           "in another world",                    "Persune"

music_track_table:
        .addr song_heat_death
        .addr song_tactus
        .addr song_tcg
        .addr song_mimiga
        .addr song_iaw

music_track_count: .byte 5

.proc player_bank_music
        pha ; preserve bank number on the stack
        lda #(MMC3_BANKING_MODE + $7)
        sta MMC3_BANK_SELECT
        pla ; restore bank number
        sta MMC3_BANK_DATA
        rts
.endproc

.proc player_bank_samples
        pha ; preserve bank number on the stack
        lda #(MMC3_BANKING_MODE + $6)
        sta MMC3_BANK_SELECT
        pla ; restore bank number
        sta MMC3_BANK_DATA
        rts
.endproc

.proc wait_for_nmi
        lda NmiCounter
loop:
        cmp NmiCounter
        beq loop
        rts
.endproc        

.proc start
        lda #$00
        sta PPUMASK ; disable rendering
        sta PPUCTRL ; and NMI

        ; disable unusual IRQ sources
        lda #%01000000
        sta $4017 ; APU frame counter
        lda #0
        sta $4010 ; DMC DMA

        jsr initialize_mmc3

        ; player init
        jsr player_init

        ; re-enable graphics and NMI
        lda #$1E
        sta PPUMASK
        lda #(VBLANK_NMI | OBJ_1000 | BG_0000)
        sta PPUCTRL

        jsr wait_for_nmi ; safety sync

gameloop:
        jsr player_update
        jsr wait_for_nmi ; safety sync
        jmp gameloop ; forever

.endproc

.proc demo_nmi
        ; preserve registers
        pha
        txa
        pha
        tya
        pha

        inc NmiCounter

        jsr vram_zipper

        lda #(VBLANK_NMI | OBJ_1000 | BG_0000)
        sta PPUCTRL

        lda PPUSTATUS
        lda #0
        sta PPUSCROLL
        sta PPUSCROLL

        ; restore registers
        pla
        tay
        pla
        tax
        pla

        ; all done
        rts
.endproc
