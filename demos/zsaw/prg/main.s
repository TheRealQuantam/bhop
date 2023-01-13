        .setcpu "6502"

        .include "../../common/input.inc"
        .include "../../common/nes.inc"
        .include "../../common/player.inc"
        .include "../../common/ppu.inc"
        .include "../../common/word_util.inc"

        .include "../../../bhop/zsaw.inc"

        .zeropage

        .segment "RAM"
nmi_counter: .byte $00

        .segment "PRG0_8000"
        .export start, demo_nmi, bhop_music_data

bhop_music_data:
        .include "../music/zsaw_demo_tracks.asm"

;                   Bank  Track#                         Title                        Artist
;                    ---     ---  ----------------------------  ----------------------------
song_tactus:     
        music_track    0,      0,              "Tactus - Demo",                   "zeta0134"
song_heat_death: 
        music_track    0,      1,        "Heat Death - Smooth",                   "zeta0134"

music_track_table:
        .addr song_tactus
        .addr song_heat_death

; NROM doesn't support banking at all, so stub both of these out
.proc player_bank_music
        rts
.endproc

.proc player_bank_samples
        rts
.endproc

.proc wait_for_nmi
        lda nmi_counter
loop:
        cmp nmi_counter
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

        ; z-saw init
        jsr zsaw_init

        ; player init
        jsr player_init

        ; re-enable graphics and NMI
        lda #$1E
        sta PPUMASK
        lda #(VBLANK_NMI | OBJ_0000 | BG_0000)
        sta PPUCTRL

        ; todo: setup for measuring performance?
        jsr wait_for_nmi ; safety sync

gameloop:
        jsr poll_input
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

        inc nmi_counter

        ; restore registers
        pla
        tay
        pla
        tax
        pla

        ; all done
        rts
.endproc
