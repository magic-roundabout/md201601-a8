;
; MD201601
;

; Code and graphics by T.M.R/Cosine
; Music by Miker


; Notes: this source is formatted for the Xasm cross assembler from
; https://github.com/pfusik/xasm
; Compression is handled with Exomizer 2 which can be downloaded at
; http://hem.bredband.net/magli143/exo/

; build.bat will call both to create an assembled file and then the
; crunched release version.


; Include binary data
		org $3400
		opt h-
		ins "data/gerry.xex"
		opt h+


		org $9d00
		ins "data/city_sprites.raw"

		org $a000
character_data	ins "data/characters.chr"

		org $a800
tile_data	ins "data/characters.til"


; Standard A8 register declarations
		icl "includes/registers.asm"


; Page 6 work space
irq_store_1	equ $0600
irq_store_2	equ $0601

cos_at_1	equ $0602
cos_speed_1	equ $0603
cos_offset_1	equ $0604

cos_at_2	equ $0605
cos_speed_2	equ $0606
cos_offset_2	equ $0607

cos_at_3	equ $0608
cos_speed_3	equ $0609
cos_offset_3	equ $060a

cos_at_4	equ $060b
cos_at_5	equ $060c

plot_pst_tmr	equ $060d


gravity_tmr	equ $060e
fwork_tmr	equ $060f
mode_select	equ $0610

tile_cycle	equ $0611
tile_curr	equ $0612
curtile_wd	equ $0613
scroll_x	equ $0614

strobe_tmr	equ $0615
strobe_luma	equ $0616

scroll_ram	equ $0688


; Display list
		org $4e00
dlist		dta $70,$70,$60,$80

		dta $4f,$00,$80
		dta $0f,$0f,$0f,$0f,$0f,$0f,$0f
		dta $0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f
		dta $0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f
		dta $0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f
		dta $0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f
		dta $0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f
		dta $0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f
		dta $0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f

		dta $0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f
		dta $0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f
		dta $0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f
		dta $0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f
		dta $0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f
		dta $0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f
		dta $0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f
		dta $0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f

		dta $4f,$00,$90
		dta $0f,$0f,$0f,$0f,$0f,$0f,$0f
		dta $0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f
		dta $0f,$0f,$0f,$0f,$0f,$0f,$0f,$0f

		dta $70,$70
		dta $52,<scroll_ram,>scroll_ram,$12,$12

		dta $41,<dlist,>dlist


		run $5000
		org $5000


; Clear the workspaces
		ldx #$00
		txa
nuke_page6	sta $0600,x
		inx
		bne nuke_page6

		ldx #$00
nuke_bitmap	sta $8000,x
		inx
		bne nuke_bitmap

		ldy nuke_bitmap+$02
		iny
		sty nuke_bitmap+$02
		cpy #$93
		bcc nuke_bitmap-$02

; Set up RMT music
		lda #$00
		ldx #$00
		ldy #$40
		jsr $3400


; Set up vertical blank interrupt
		lda #$06
		ldx #>vblank
		ldy #<vblank
		jsr $e45c

; Set up display list / DLI
dl_init		lda #<dlist
		sta dlist_vector+$00
		lda #>dlist
		sta dlist_vector+$01

		lda #<dli
		sta dli_vector+$00
		lda #>dli
		sta dli_vector+$01
		lda #$c0
		sta nmi_en

; Video setup
		lda #>character_data
		sta char_base_s

		lda #$00
		sta col_bgnd_s
		lda #$0c
		sta col_pfield1_s

		lda #$2d
		sta dma_ctrl_s
		lda #$9c
		sta pm_base
		lda #$03
		sta gra_ctrl
		lda #$01
		sta priority_s

		lda #$03
		sta pm0_expand
		sta pm1_expand
		sta pm2_expand
		sta pm3_expand

		lda #$40
		sta pm0_xpos
		lda #$60
		sta pm1_xpos
		lda #$80
		sta pm2_xpos
		lda #$a0
		sta pm3_xpos

		lda #$a3
		sta pm4_xpos
		lda #$43
		sta pm5_xpos

		lda #$68
		sta pm6_xpos
		lda #$ab
		sta pm7_xpos


; Reset a few things before we start...
		jsr reset
		jsr fwork_reset

		lda #$e0
		sta fwork_tmr
		lda #$10
		sta strobe_tmr

		lda #$ab
		sta cos_at_4


; Infinite loop
		jmp *



; Vertical blank interrupt
vblank		lda #$00
		sta attract_timer

; Strobe stuff
		ldx strobe_tmr
		lda strobe_table,x
		sta strobe_luma
		inx
		cpx #$11
		bne *+$04
		ldx #$10
		stx strobe_tmr

; Play RMT music
		jsr $3403

		jmp $e45f

; Display list interrupt
dli		pha
		txa
		pha
		tya
		pha

; Split the background colour to make the horizon
		ldx #$00
hz_splitter	lda hz_colours,x
		ora strobe_luma
		ldy hz_gradient,x
		sta wsync
		sta col_pfield2
		sty col_pfield1
		inx
		cpx #$98
		bne hz_splitter

; Scroll colours go here eventually...

		lda #$00
		sta col_pfield2


; "Unplot" the points
		lda #$00
unplot_write_00	sta $06e0
unplot_write_01	sta $06e0
unplot_write_02	sta $06e0
unplot_write_03	sta $06e0
unplot_write_04	sta $06e0
unplot_write_05	sta $06e0
unplot_write_06	sta $06e0
unplot_write_07	sta $06e0

unplot_write_08	sta $06e0
unplot_write_09	sta $06e0
unplot_write_0a	sta $06e0
unplot_write_0b	sta $06e0
unplot_write_0c	sta $06e0
unplot_write_0d	sta $06e0
unplot_write_0e	sta $06e0
unplot_write_0f	sta $06e0

unplot_write_10	sta $06e0
unplot_write_11	sta $06e0
unplot_write_12	sta $06e0
unplot_write_13	sta $06e0
unplot_write_14	sta $06e0
unplot_write_15	sta $06e0
unplot_write_16	sta $06e0
unplot_write_17	sta $06e0

unplot_write_18	sta $06e0
unplot_write_19	sta $06e0
unplot_write_1a	sta $06e0
unplot_write_1b	sta $06e0
unplot_write_1c	sta $06e0
unplot_write_1d	sta $06e0
unplot_write_1e	sta $06e0
unplot_write_1f	sta $06e0

; Update the self-modifying code for the plot and unplot
		ldy plot_y+$00
		lda plot_x+$00
		lsr @
		lsr @
		lsr @
		clc
		adc scrn_start_lo,y
		sta unplot_write_00+$01
		sta plot_read_00+$01
		sta plot_write_00+$01
		lda scrn_start_hi,y
		sta unplot_write_00+$02
		sta plot_read_00+$02
		sta plot_write_00+$02
		lda plot_x+$00
		and #$07
		tax
		lda plot_decode,x
		sta plot_values+$00

		ldy plot_y+$01
		lda plot_x+$01
		lsr @
		lsr @
		lsr @
		clc
		adc scrn_start_lo,y
		sta unplot_write_01+$01
		sta plot_read_01+$01
		sta plot_write_01+$01
		lda scrn_start_hi,y
		sta unplot_write_01+$02
		sta plot_read_01+$02
		sta plot_write_01+$02
		lda plot_x+$01
		and #$07
		tax
		lda plot_decode,x
		sta plot_values+$01

		ldy plot_y+$02
		lda plot_x+$02
		lsr @
		lsr @
		lsr @
		clc
		adc scrn_start_lo,y
		sta unplot_write_02+$01
		sta plot_read_02+$01
		sta plot_write_02+$01
		lda scrn_start_hi,y
		sta unplot_write_02+$02
		sta plot_read_02+$02
		sta plot_write_02+$02
		lda plot_x+$02
		and #$07
		tax
		lda plot_decode,x
		sta plot_values+$02

		ldy plot_y+$03
		lda plot_x+$03
		lsr @
		lsr @
		lsr @
		clc
		adc scrn_start_lo,y
		sta unplot_write_03+$01
		sta plot_read_03+$01
		sta plot_write_03+$01
		lda scrn_start_hi,y
		sta unplot_write_03+$02
		sta plot_read_03+$02
		sta plot_write_03+$02
		lda plot_x+$03
		and #$07
		tax
		lda plot_decode,x
		sta plot_values+$03

		ldy plot_y+$04
		lda plot_x+$04
		lsr @
		lsr @
		lsr @
		clc
		adc scrn_start_lo,y
		sta unplot_write_04+$01
		sta plot_read_04+$01
		sta plot_write_04+$01
		lda scrn_start_hi,y
		sta unplot_write_04+$02
		sta plot_read_04+$02
		sta plot_write_04+$02
		lda plot_x+$04
		and #$07
		tax
		lda plot_decode,x
		sta plot_values+$04

		ldy plot_y+$05
		lda plot_x+$05
		lsr @
		lsr @
		lsr @
		clc
		adc scrn_start_lo,y
		sta unplot_write_05+$01
		sta plot_read_05+$01
		sta plot_write_05+$01
		lda scrn_start_hi,y
		sta unplot_write_05+$02
		sta plot_read_05+$02
		sta plot_write_05+$02
		lda plot_x+$05
		and #$07
		tax
		lda plot_decode,x
		sta plot_values+$05

		ldy plot_y+$06
		lda plot_x+$06
		lsr @
		lsr @
		lsr @
		clc
		adc scrn_start_lo,y
		sta unplot_write_06+$01
		sta plot_read_06+$01
		sta plot_write_06+$01
		lda scrn_start_hi,y
		sta unplot_write_06+$02
		sta plot_read_06+$02
		sta plot_write_06+$02
		lda plot_x+$06
		and #$07
		tax
		lda plot_decode,x
		sta plot_values+$06

		ldy plot_y+$07
		lda plot_x+$07
		lsr @
		lsr @
		lsr @
		clc
		adc scrn_start_lo,y
		sta unplot_write_07+$01
		sta plot_read_07+$01
		sta plot_write_07+$01
		lda scrn_start_hi,y
		sta unplot_write_07+$02
		sta plot_read_07+$02
		sta plot_write_07+$02
		lda plot_x+$07
		and #$07
		tax
		lda plot_decode,x
		sta plot_values+$07


		ldy plot_y+$08
		lda plot_x+$08
		lsr @
		lsr @
		lsr @
		clc
		adc scrn_start_lo,y
		sta unplot_write_08+$01
		sta plot_read_08+$01
		sta plot_write_08+$01
		lda scrn_start_hi,y
		sta unplot_write_08+$02
		sta plot_read_08+$02
		sta plot_write_08+$02
		lda plot_x+$08
		and #$07
		tax
		lda plot_decode,x
		sta plot_values+$08

		ldy plot_y+$09
		lda plot_x+$09
		lsr @
		lsr @
		lsr @
		clc
		adc scrn_start_lo,y
		sta unplot_write_09+$01
		sta plot_read_09+$01
		sta plot_write_09+$01
		lda scrn_start_hi,y
		sta unplot_write_09+$02
		sta plot_read_09+$02
		sta plot_write_09+$02
		lda plot_x+$09
		and #$07
		tax
		lda plot_decode,x
		sta plot_values+$09

		ldy plot_y+$0a
		lda plot_x+$0a
		lsr @
		lsr @
		lsr @
		clc
		adc scrn_start_lo,y
		sta unplot_write_0a+$01
		sta plot_read_0a+$01
		sta plot_write_0a+$01
		lda scrn_start_hi,y
		sta unplot_write_0a+$02
		sta plot_read_0a+$02
		sta plot_write_0a+$02
		lda plot_x+$0a
		and #$07
		tax
		lda plot_decode,x
		sta plot_values+$0a

		ldy plot_y+$0b
		lda plot_x+$0b
		lsr @
		lsr @
		lsr @
		clc
		adc scrn_start_lo,y
		sta unplot_write_0b+$01
		sta plot_read_0b+$01
		sta plot_write_0b+$01
		lda scrn_start_hi,y
		sta unplot_write_0b+$02
		sta plot_read_0b+$02
		sta plot_write_0b+$02
		lda plot_x+$0b
		and #$07
		tax
		lda plot_decode,x
		sta plot_values+$0b

		ldy plot_y+$0c
		lda plot_x+$0c
		lsr @
		lsr @
		lsr @
		clc
		adc scrn_start_lo,y
		sta unplot_write_0c+$01
		sta plot_read_0c+$01
		sta plot_write_0c+$01
		lda scrn_start_hi,y
		sta unplot_write_0c+$02
		sta plot_read_0c+$02
		sta plot_write_0c+$02
		lda plot_x+$0c
		and #$07
		tax
		lda plot_decode,x
		sta plot_values+$0c

		ldy plot_y+$0d
		lda plot_x+$0d
		lsr @
		lsr @
		lsr @
		clc
		adc scrn_start_lo,y
		sta unplot_write_0d+$01
		sta plot_read_0d+$01
		sta plot_write_0d+$01
		lda scrn_start_hi,y
		sta unplot_write_0d+$02
		sta plot_read_0d+$02
		sta plot_write_0d+$02
		lda plot_x+$0d
		and #$07
		tax
		lda plot_decode,x
		sta plot_values+$0d

		ldy plot_y+$0e
		lda plot_x+$0e
		lsr @
		lsr @
		lsr @
		clc
		adc scrn_start_lo,y
		sta unplot_write_0e+$01
		sta plot_read_0e+$01
		sta plot_write_0e+$01
		lda scrn_start_hi,y
		sta unplot_write_0e+$02
		sta plot_read_0e+$02
		sta plot_write_0e+$02
		lda plot_x+$0e
		and #$07
		tax
		lda plot_decode,x
		sta plot_values+$0e

		ldy plot_y+$0f
		lda plot_x+$0f
		lsr @
		lsr @
		lsr @
		clc
		adc scrn_start_lo,y
		sta unplot_write_0f+$01
		sta plot_read_0f+$01
		sta plot_write_0f+$01
		lda scrn_start_hi,y
		sta unplot_write_0f+$02
		sta plot_read_0f+$02
		sta plot_write_0f+$02
		lda plot_x+$0f
		and #$07
		tax
		lda plot_decode,x
		sta plot_values+$0f


		ldy plot_y+$10
		lda plot_x+$10
		lsr @
		lsr @
		lsr @
		clc
		adc scrn_start_lo,y
		sta unplot_write_10+$01
		sta plot_read_10+$01
		sta plot_write_10+$01
		lda scrn_start_hi,y
		sta unplot_write_10+$02
		sta plot_read_10+$02
		sta plot_write_10+$02
		lda plot_x+$10
		and #$07
		tax
		lda plot_decode,x
		sta plot_values+$10

		ldy plot_y+$11
		lda plot_x+$11
		lsr @
		lsr @
		lsr @
		clc
		adc scrn_start_lo,y
		sta unplot_write_11+$01
		sta plot_read_11+$01
		sta plot_write_11+$01
		lda scrn_start_hi,y
		sta unplot_write_11+$02
		sta plot_read_11+$02
		sta plot_write_11+$02
		lda plot_x+$11
		and #$07
		tax
		lda plot_decode,x
		sta plot_values+$11

		ldy plot_y+$12
		lda plot_x+$12
		lsr @
		lsr @
		lsr @
		clc
		adc scrn_start_lo,y
		sta unplot_write_12+$01
		sta plot_read_12+$01
		sta plot_write_12+$01
		lda scrn_start_hi,y
		sta unplot_write_12+$02
		sta plot_read_12+$02
		sta plot_write_12+$02
		lda plot_x+$12
		and #$07
		tax
		lda plot_decode,x
		sta plot_values+$12

		ldy plot_y+$13
		lda plot_x+$13
		lsr @
		lsr @
		lsr @
		clc
		adc scrn_start_lo,y
		sta unplot_write_13+$01
		sta plot_read_13+$01
		sta plot_write_13+$01
		lda scrn_start_hi,y
		sta unplot_write_13+$02
		sta plot_read_13+$02
		sta plot_write_13+$02
		lda plot_x+$13
		and #$07
		tax
		lda plot_decode,x
		sta plot_values+$13

		ldy plot_y+$14
		lda plot_x+$14
		lsr @
		lsr @
		lsr @
		clc
		adc scrn_start_lo,y
		sta unplot_write_14+$01
		sta plot_read_14+$01
		sta plot_write_14+$01
		lda scrn_start_hi,y
		sta unplot_write_14+$02
		sta plot_read_14+$02
		sta plot_write_14+$02
		lda plot_x+$14
		and #$07
		tax
		lda plot_decode,x
		sta plot_values+$14

		ldy plot_y+$15
		lda plot_x+$15
		lsr @
		lsr @
		lsr @
		clc
		adc scrn_start_lo,y
		sta unplot_write_15+$01
		sta plot_read_15+$01
		sta plot_write_15+$01
		lda scrn_start_hi,y
		sta unplot_write_15+$02
		sta plot_read_15+$02
		sta plot_write_15+$02
		lda plot_x+$15
		and #$07
		tax
		lda plot_decode,x
		sta plot_values+$15


		lda scroll_x
		and #$01
		eor #$01
		asl @
		sta hscroll

		sta wsync

; Split the playfield colour for the scroller
		ldx #$00
scroll_splitter	lda scroll_colours,x
		sta wsync
		sta col_pfield1
		inx
		cpx #$18
		bne scroll_splitter

; Back to updating the self mod
		ldy plot_y+$16
		lda plot_x+$16
		lsr @
		lsr @
		lsr @
		clc
		adc scrn_start_lo,y
		sta unplot_write_16+$01
		sta plot_read_16+$01
		sta plot_write_16+$01
		lda scrn_start_hi,y
		sta unplot_write_16+$02
		sta plot_read_16+$02
		sta plot_write_16+$02
		lda plot_x+$16
		and #$07
		tax
		lda plot_decode,x
		sta plot_values+$16

		ldy plot_y+$17
		lda plot_x+$17
		lsr @
		lsr @
		lsr @
		clc
		adc scrn_start_lo,y
		sta unplot_write_17+$01
		sta plot_read_17+$01
		sta plot_write_17+$01
		lda scrn_start_hi,y
		sta unplot_write_17+$02
		sta plot_read_17+$02
		sta plot_write_17+$02
		lda plot_x+$17
		and #$07
		tax
		lda plot_decode,x
		sta plot_values+$17


		ldy plot_y+$18
		lda plot_x+$18
		lsr @
		lsr @
		lsr @
		clc
		adc scrn_start_lo,y
		sta unplot_write_18+$01
		sta plot_read_18+$01
		sta plot_write_18+$01
		lda scrn_start_hi,y
		sta unplot_write_18+$02
		sta plot_read_18+$02
		sta plot_write_18+$02
		lda plot_x+$18
		and #$07
		tax
		lda plot_decode,x
		sta plot_values+$18

		ldy plot_y+$19
		lda plot_x+$19
		lsr @
		lsr @
		lsr @
		clc
		adc scrn_start_lo,y
		sta unplot_write_19+$01
		sta plot_read_19+$01
		sta plot_write_19+$01
		lda scrn_start_hi,y
		sta unplot_write_19+$02
		sta plot_read_19+$02
		sta plot_write_19+$02
		lda plot_x+$19
		and #$07
		tax
		lda plot_decode,x
		sta plot_values+$19

		ldy plot_y+$1a
		lda plot_x+$1a
		lsr @
		lsr @
		lsr @
		clc
		adc scrn_start_lo,y
		sta unplot_write_1a+$01
		sta plot_read_1a+$01
		sta plot_write_1a+$01
		lda scrn_start_hi,y
		sta unplot_write_1a+$02
		sta plot_read_1a+$02
		sta plot_write_1a+$02
		lda plot_x+$1a
		and #$07
		tax
		lda plot_decode,x
		sta plot_values+$1a

		ldy plot_y+$1b
		lda plot_x+$1b
		lsr @
		lsr @
		lsr @
		clc
		adc scrn_start_lo,y
		sta unplot_write_1b+$01
		sta plot_read_1b+$01
		sta plot_write_1b+$01
		lda scrn_start_hi,y
		sta unplot_write_1b+$02
		sta plot_read_1b+$02
		sta plot_write_1b+$02
		lda plot_x+$1b
		and #$07
		tax
		lda plot_decode,x
		sta plot_values+$1b

		ldy plot_y+$1c
		lda plot_x+$1c
		lsr @
		lsr @
		lsr @
		clc
		adc scrn_start_lo,y
		sta unplot_write_1c+$01
		sta plot_read_1c+$01
		sta plot_write_1c+$01
		lda scrn_start_hi,y
		sta unplot_write_1c+$02
		sta plot_read_1c+$02
		sta plot_write_1c+$02
		lda plot_x+$1c
		and #$07
		tax
		lda plot_decode,x
		sta plot_values+$1c

		ldy plot_y+$1d
		lda plot_x+$1d
		lsr @
		lsr @
		lsr @
		clc
		adc scrn_start_lo,y
		sta unplot_write_1d+$01
		sta plot_read_1d+$01
		sta plot_write_1d+$01
		lda scrn_start_hi,y
		sta unplot_write_1d+$02
		sta plot_read_1d+$02
		sta plot_write_1d+$02
		lda plot_x+$1d
		and #$07
		tax
		lda plot_decode,x
		sta plot_values+$1d

		ldy plot_y+$1e
		lda plot_x+$1e
		lsr @
		lsr @
		lsr @
		clc
		adc scrn_start_lo,y
		sta unplot_write_1e+$01
		sta plot_read_1e+$01
		sta plot_write_1e+$01
		lda scrn_start_hi,y
		sta unplot_write_1e+$02
		sta plot_read_1e+$02
		sta plot_write_1e+$02
		lda plot_x+$1e
		and #$07
		tax
		lda plot_decode,x
		sta plot_values+$1e

		ldy plot_y+$1f
		lda plot_x+$1f
		lsr @
		lsr @
		lsr @
		clc
		adc scrn_start_lo,y
		sta unplot_write_1f+$01
		sta plot_read_1f+$01
		sta plot_write_1f+$01
		lda scrn_start_hi,y
		sta unplot_write_1f+$02
		sta plot_read_1f+$02
		sta plot_write_1f+$02
		lda plot_x+$1f
		and #$07
		tax
		lda plot_decode,x
		sta plot_values+$1f

; Plot the points
		lda plot_values+$00
plot_read_00	ora $06e0
plot_write_00	sta $06e0
		lda plot_values+$01
plot_read_01	ora $06e0
plot_write_01	sta $06e0
		lda plot_values+$02
plot_read_02	ora $06e0
plot_write_02	sta $06e0
		lda plot_values+$03
plot_read_03	ora $06e0
plot_write_03	sta $06e0
		lda plot_values+$04
plot_read_04	ora $06e0
plot_write_04	sta $06e0
		lda plot_values+$05
plot_read_05	ora $06e0
plot_write_05	sta $06e0
		lda plot_values+$06
plot_read_06	ora $06e0
plot_write_06	sta $06e0
		lda plot_values+$07
plot_read_07	ora $06e0
plot_write_07	sta $06e0

		lda plot_values+$08
plot_read_08	ora $0eff
plot_write_08	sta $0eff
		lda plot_values+$09
plot_read_09	ora $0eff
plot_write_09	sta $0eff
		lda plot_values+$0a
plot_read_0a	ora $0eff
plot_write_0a	sta $0eff
		lda plot_values+$0b
plot_read_0b	ora $0eff
plot_write_0b	sta $0eff
		lda plot_values+$0c
plot_read_0c	ora $0eff
plot_write_0c	sta $0eff
		lda plot_values+$0d
plot_read_0d	ora $0eff
plot_write_0d	sta $0eff
		lda plot_values+$0e
plot_read_0e	ora $0eff
plot_write_0e	sta $0eff
		lda plot_values+$0f
plot_read_0f	ora $0eff
plot_write_0f	sta $0eff

		lda plot_values+$10
plot_read_10	ora $06e0
plot_write_10	sta $06e0
		lda plot_values+$11
plot_read_11	ora $06e0
plot_write_11	sta $06e0
		lda plot_values+$12
plot_read_12	ora $06e0
plot_write_12	sta $06e0
		lda plot_values+$13
plot_read_13	ora $06e0
plot_write_13	sta $06e0
		lda plot_values+$14
plot_read_14	ora $06e0
plot_write_14	sta $06e0
		lda plot_values+$15
plot_read_15	ora $06e0
plot_write_15	sta $06e0
		lda plot_values+$16
plot_read_16	ora $06e0
plot_write_16	sta $06e0
		lda plot_values+$17
plot_read_17	ora $06e0
plot_write_17	sta $06e0

		lda plot_values+$18
plot_read_18	ora $0eff
plot_write_18	sta $0eff
		lda plot_values+$19
plot_read_19	ora $0eff
plot_write_19	sta $0eff
		lda plot_values+$1a
plot_read_1a	ora $0eff
plot_write_1a	sta $0eff
		lda plot_values+$1b
plot_read_1b	ora $0eff
plot_write_1b	sta $0eff
		lda plot_values+$1c
plot_read_1c	ora $0eff
plot_write_1c	sta $0eff
		lda plot_values+$1d
plot_read_1d	ora $0eff
plot_write_1d	sta $0eff
		lda plot_values+$1e
plot_read_1e	ora $0eff
plot_write_1e	sta $0eff
		lda plot_values+$1f
plot_read_1f	ora $0eff
plot_write_1f	sta $0eff

		lda mode_select
		beq *+$05
		jmp cosinus_mode

; Firework mode - update plotter positions
		ldx #$00
firework_upd	lda plot_y,x
		cmp #$c0
		bcs fupd_skip
		clc
		adc plot_y_spd,x
		sta plot_y,x

		lda plot_x_spd,x
		cmp #$80
		bcc fw_right

fw_left		lda plot_x,x
		clc
		adc plot_x_spd,x
		bcs fw_store

		lda #$d0
		sta plot_y,x
		jmp fw_store

fw_right	lda plot_x,x
		clc
		adc plot_x_spd,x
		bcc fw_store

		lda #$d0
		sta plot_y,x
fw_store	sta plot_x,x

fupd_skip	inx
		cpx #$20
		bne firework_upd

; See of the gravity wants updating
		ldx gravity_tmr
		inx
		cpx #$05
		bcc gt_xb

		ldx #$00
grav_update	inc plot_y_spd,x
		inx
		cpx #$20
		bne grav_update

		ldx #$00
gt_xb		stx gravity_tmr


		ldx fwork_tmr
		dex
		cpx #$ff
		bne fwt_xb

fwork_fetch_lp	jsr fwork_mread

; $fe means "small strobe of the colours"
		cmp #$fe
		bne fwflp_okay_1

		lda #$06
		sta strobe_tmr
		jmp fwork_fetch_lp

; $fd means "big strobe of the colours"
fwflp_okay_1	cmp #$fd
		bne fwflp_okay_2

		lda #$00
		sta strobe_tmr
		jmp fwork_fetch_lp

; $ff marks the end of the firework data
fwflp_okay_2	cmp #$ff
		bne get_new_fwork
		lda #$01
		sta mode_select

		jsr preset_fetch

		jmp fwork_done


get_new_fwork	tay
		jsr fwork_mread
		sta plot_x,y
		jsr fwork_mread
		sta plot_y,y
		jsr fwork_mread
		sta plot_x_spd,y
		jsr fwork_mread
		sta plot_y_spd,y

		jsr fwork_mread
		cmp #$f0
		beq fwork_fetch_lp
		tax
fwt_xb		stx fwork_tmr


fwork_done	jmp scroll_update

; Cosinus mode - update the X positions
cosinus_mode	lda cos_at_1
		clc
		adc cos_speed_1
		sta cos_at_1
		tax
		lda cos_at_2
		clc
		adc cos_speed_2
		sta cos_at_2
		tay
		lda plot_x_cosinus,x
		clc
		adc plot_x_cosinus,y
		sta plot_x+$00

		txa
		clc
		adc cos_offset_1
		tax
		tya
		clc
		adc cos_offset_2
		tay
		lda plot_x_cosinus,x
		clc
		adc plot_x_cosinus,y
		sta plot_x+$01

		txa
		clc
		adc cos_offset_1
		tax
		tya
		clc
		adc cos_offset_2
		tay
		lda plot_x_cosinus,x
		clc
		adc plot_x_cosinus,y
		sta plot_x+$02

		txa
		clc
		adc cos_offset_1
		tax
		tya
		clc
		adc cos_offset_2
		tay
		lda plot_x_cosinus,x
		clc
		adc plot_x_cosinus,y
		sta plot_x+$03

		txa
		clc
		adc cos_offset_1
		tax
		tya
		clc
		adc cos_offset_2
		tay
		lda plot_x_cosinus,x
		clc
		adc plot_x_cosinus,y
		sta plot_x+$04

		txa
		clc
		adc cos_offset_1
		tax
		tya
		clc
		adc cos_offset_2
		tay
		lda plot_x_cosinus,x
		clc
		adc plot_x_cosinus,y
		sta plot_x+$05

		txa
		clc
		adc cos_offset_1
		tax
		tya
		clc
		adc cos_offset_2
		tay
		lda plot_x_cosinus,x
		clc
		adc plot_x_cosinus,y
		sta plot_x+$06

		txa
		clc
		adc cos_offset_1
		tax
		tya
		clc
		adc cos_offset_2
		tay
		lda plot_x_cosinus,x
		clc
		adc plot_x_cosinus,y
		sta plot_x+$07

		txa
		clc
		adc cos_offset_1
		tax
		tya
		clc
		adc cos_offset_2
		tay
		lda plot_x_cosinus,x
		clc
		adc plot_x_cosinus,y
		sta plot_x+$08

		txa
		clc
		adc cos_offset_1
		tax
		tya
		clc
		adc cos_offset_2
		tay
		lda plot_x_cosinus,x
		clc
		adc plot_x_cosinus,y
		sta plot_x+$09

		txa
		clc
		adc cos_offset_1
		tax
		tya
		clc
		adc cos_offset_2
		tay
		lda plot_x_cosinus,x
		clc
		adc plot_x_cosinus,y
		sta plot_x+$0a

		txa
		clc
		adc cos_offset_1
		tax
		tya
		clc
		adc cos_offset_2
		tay
		lda plot_x_cosinus,x
		clc
		adc plot_x_cosinus,y
		sta plot_x+$0b

		txa
		clc
		adc cos_offset_1
		tax
		tya
		clc
		adc cos_offset_2
		tay
		lda plot_x_cosinus,x
		clc
		adc plot_x_cosinus,y
		sta plot_x+$0c

		txa
		clc
		adc cos_offset_1
		tax
		tya
		clc
		adc cos_offset_2
		tay
		lda plot_x_cosinus,x
		clc
		adc plot_x_cosinus,y
		sta plot_x+$0d

		txa
		clc
		adc cos_offset_1
		tax
		tya
		clc
		adc cos_offset_2
		tay
		lda plot_x_cosinus,x
		clc
		adc plot_x_cosinus,y
		sta plot_x+$0e

		txa
		clc
		adc cos_offset_1
		tax
		tya
		clc
		adc cos_offset_2
		tay
		lda plot_x_cosinus,x
		clc
		adc plot_x_cosinus,y
		sta plot_x+$0f

		txa
		clc
		adc cos_offset_1
		tax
		tya
		clc
		adc cos_offset_2
		tay
		lda plot_x_cosinus,x
		clc
		adc plot_x_cosinus,y
		sta plot_x+$10

		txa
		clc
		adc cos_offset_1
		tax
		tya
		clc
		adc cos_offset_2
		tay
		lda plot_x_cosinus,x
		clc
		adc plot_x_cosinus,y
		sta plot_x+$11

		txa
		clc
		adc cos_offset_1
		tax
		tya
		clc
		adc cos_offset_2
		tay
		lda plot_x_cosinus,x
		clc
		adc plot_x_cosinus,y
		sta plot_x+$12

		txa
		clc
		adc cos_offset_1
		tax
		tya
		clc
		adc cos_offset_2
		tay
		lda plot_x_cosinus,x
		clc
		adc plot_x_cosinus,y
		sta plot_x+$13

		txa
		clc
		adc cos_offset_1
		tax
		tya
		clc
		adc cos_offset_2
		tay
		lda plot_x_cosinus,x
		clc
		adc plot_x_cosinus,y
		sta plot_x+$14

		txa
		clc
		adc cos_offset_1
		tax
		tya
		clc
		adc cos_offset_2
		tay
		lda plot_x_cosinus,x
		clc
		adc plot_x_cosinus,y
		sta plot_x+$15

		txa
		clc
		adc cos_offset_1
		tax
		tya
		clc
		adc cos_offset_2
		tay
		lda plot_x_cosinus,x
		clc
		adc plot_x_cosinus,y
		sta plot_x+$16

		txa
		clc
		adc cos_offset_1
		tax
		tya
		clc
		adc cos_offset_2
		tay
		lda plot_x_cosinus,x
		clc
		adc plot_x_cosinus,y
		sta plot_x+$17

		txa
		clc
		adc cos_offset_1
		tax
		tya
		clc
		adc cos_offset_2
		tay
		lda plot_x_cosinus,x
		clc
		adc plot_x_cosinus,y
		sta plot_x+$18

		txa
		clc
		adc cos_offset_1
		tax
		tya
		clc
		adc cos_offset_2
		tay
		lda plot_x_cosinus,x
		clc
		adc plot_x_cosinus,y
		sta plot_x+$19

		txa
		clc
		adc cos_offset_1
		tax
		tya
		clc
		adc cos_offset_2
		tay
		lda plot_x_cosinus,x
		clc
		adc plot_x_cosinus,y
		sta plot_x+$1a

		txa
		clc
		adc cos_offset_1
		tax
		tya
		clc
		adc cos_offset_2
		tay
		lda plot_x_cosinus,x
		clc
		adc plot_x_cosinus,y
		sta plot_x+$1b

		txa
		clc
		adc cos_offset_1
		tax
		tya
		clc
		adc cos_offset_2
		tay
		lda plot_x_cosinus,x
		clc
		adc plot_x_cosinus,y
		sta plot_x+$1c

		txa
		clc
		adc cos_offset_1
		tax
		tya
		clc
		adc cos_offset_2
		tay
		lda plot_x_cosinus,x
		clc
		adc plot_x_cosinus,y
		sta plot_x+$1d

		txa
		clc
		adc cos_offset_1
		tax
		tya
		clc
		adc cos_offset_2
		tay
		lda plot_x_cosinus,x
		clc
		adc plot_x_cosinus,y
		sta plot_x+$1e

		txa
		clc
		adc cos_offset_1
		tax
		tya
		clc
		adc cos_offset_2
		tay
		lda plot_x_cosinus,x
		clc
		adc plot_x_cosinus,y
		sta plot_x+$1f

; Cosinus mode - update the Y positions
		lda cos_at_3
		clc
		adc cos_speed_3
		sta cos_at_3
		tay

		ldx #$00
cos_up_test	lda plot_y_cosinus,y
		sta plot_y,x
		tya
		clc
		adc cos_offset_3
		tay
		inx
		cpx #$20
		bne cos_up_test

; Check to see if a new preset is due
		inc plot_pst_tmr
		bne scroll_update

		jsr preset_fetch


; Update the scrolling message
scroll_update	ldx scroll_x
		inx
		cpx #$02
		bne scr_xb

		ldx #$00
mover		lda scroll_ram+$01,x
		sta scroll_ram+$00,x
		lda scroll_ram+$29,x
		sta scroll_ram+$28,x
		lda scroll_ram+$51,x
		sta scroll_ram+$50,x
		inx
		cpx #$24
		bne mover

; Fetch a new column from the tiles and grab a new tile if need be!
		ldx tile_curr
		ldy tile_cycle
		bne *+$05
		jsr tile_clm_1
		cpy #$01
		bne *+$05
		jsr tile_clm_2
		cpy #$02
		bne *+$05
		jsr tile_clm_3
		cpy #$03
		bne *+$05
		jsr tile_clm_4
		iny
		cpy curtile_wd
		bcc tc_xb

mread		ldy scroll_text
		cpy #$ff
		bne okay
		jsr reset
		jmp mread

okay		sty tile_curr
		lda tile_width,y
		sta curtile_wd

		inc mread+$01
		bne *+$05
		inc mread+$02

		ldy #$00
tc_xb		sty tile_cycle

		ldx #$00
scr_xb		stx scroll_x

; Update the scroller's colour effect
		lda cos_at_4
		clc
		adc #$01
		sta cos_at_4

		lda cos_at_5
		clc
		adc #$fe
		sta cos_at_5

		ldx #$00
		ldy cos_at_4
scroll_wv_gen1	lda scroll_cosinus,y
		sta scroll_colours,x
		tya
		clc
		adc #$03
		tay
		inx
		cpx #$18
		bne scroll_wv_gen1

		ldx #$00
		ldy cos_at_5
scroll_wv_gen2	lda scroll_cosinus,y
		clc
		adc scroll_colours,x
		sta scroll_colours,x
		tya
		clc
		adc #$02
		tay
		inx
		cpx #$18
		bne scroll_wv_gen2

		ldx #$00
scroll_wv_gen3	ldy scroll_colours,x
		lda scroll_wv_cols,y
		sta scroll_colours,x
		inx
		cpx #$18
		bne scroll_wv_gen3

		pla
		tay
		pla
		tax
		pla
		rti


; Self mod and reset for the firework spawner
fwork_mread	lda fwork_data
		inc fwork_mread+$01
		bne *+$05
		inc fwork_mread+$02
		rts

fwork_reset	lda #<fwork_data
		sta fwork_mread+$01
		lda #>fwork_data
		sta fwork_mread+$02
		rts

; Grab some new preset data for the plotter
preset_fetch	jsr preset_mread
		sta cos_at_1
		jsr preset_mread
		sta cos_speed_1
		jsr preset_mread
		sta cos_offset_1

		jsr preset_mread
		sta cos_at_2
		jsr preset_mread
		sta cos_speed_2
		jsr preset_mread
		sta cos_offset_2

		jsr preset_mread
		sta cos_at_3
		jsr preset_mread
		sta cos_speed_3
		jsr preset_mread
		sta cos_offset_3

		lda #$00
		sta strobe_tmr
		rts

; Plotter self mod read and reset
preset_mread	lda plot_presets
		cmp #$80
		bne pmread_okay
		jsr preset_reset
		jmp preset_mread

pmread_okay	inc preset_mread+$01
		bne *+$05
		inc preset_mread+$02
		rts

preset_reset	lda #<plot_presets
		sta preset_mread+$01
		lda #>plot_presets
		sta preset_mread+$02
		rts

; Self mod reset for the scroller
reset		lda #<scroll_text
		sta mread+$01
		lda #>scroll_text
		sta mread+$02
		rts

; The tile columns for the scroller
tile_clm_1	lda tile_data+$000,x
		sta scroll_ram+$24
		lda tile_data+$100,x
		sta scroll_ram+$4c
		lda tile_data+$200,x
		sta scroll_ram+$74
		rts

tile_clm_2	lda tile_data+$040,x
		sta scroll_ram+$24
		lda tile_data+$140,x
		sta scroll_ram+$4c
		lda tile_data+$240,x
		sta scroll_ram+$74
		rts

tile_clm_3	lda tile_data+$080,x
		sta scroll_ram+$24
		lda tile_data+$180,x
		sta scroll_ram+$4c
		lda tile_data+$280,x
		sta scroll_ram+$74
		rts

tile_clm_4	lda tile_data+$0c0,x
		sta scroll_ram+$24
		lda tile_data+$1c0,x
		sta scroll_ram+$4c
		lda tile_data+$2c0,x
		sta scroll_ram+$74
		rts


; Plotter stuffs
plot_x		dta $10,$20,$30,$40,$50,$60,$70,$80
		dta $10,$24,$34,$44,$54,$64,$74,$84
		dta $10,$28,$38,$48,$58,$68,$78,$88
		dta $1c,$2c,$3c,$4c,$5c,$6c,$7c,$8c

plot_y		dta $c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0
		dta $c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0
		dta $c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0
		dta $c0,$c0,$c0,$c0,$c0,$c0,$c0,$c0

plot_values	dta $00,$00,$00,$00,$00,$00,$00,$00
		dta $00,$00,$00,$00,$00,$00,$00,$00
		dta $00,$00,$00,$00,$00,$00,$00,$00
		dta $00,$00,$00,$00,$00,$00,$00,$00

plot_decode	dta $80,$40,$20,$10,$08,$04,$02,$01

; Firework stuffs
plot_x_spd	dta $00,$00,$00,$00,$00,$00,$00,$00
		dta $00,$00,$00,$00,$00,$00,$00,$00
		dta $00,$00,$00,$00,$00,$00,$00,$00
		dta $00,$00,$00,$00,$00,$00,$00,$00

plot_y_spd	dta $00,$00,$00,$00,$00,$00,$00,$00
		dta $00,$00,$00,$00,$00,$00,$00,$00
		dta $00,$00,$00,$00,$00,$00,$00,$00
		dta $00,$00,$00,$00,$00,$00,$00,$00

		org $6000
; Start of each scanline, low bytes first then high
scrn_start_lo	dta $00,$20,$40,$60,$80,$a0,$c0,$e0
		dta $00,$20,$40,$60,$80,$a0,$c0,$e0
		dta $00,$20,$40,$60,$80,$a0,$c0,$e0
		dta $00,$20,$40,$60,$80,$a0,$c0,$e0
		dta $00,$20,$40,$60,$80,$a0,$c0,$e0
		dta $00,$20,$40,$60,$80,$a0,$c0,$e0
		dta $00,$20,$40,$60,$80,$a0,$c0,$e0
		dta $00,$20,$40,$60,$80,$a0,$c0,$e0

		dta $00,$20,$40,$60,$80,$a0,$c0,$e0
		dta $00,$20,$40,$60,$80,$a0,$c0,$e0
		dta $00,$20,$40,$60,$80,$a0,$c0,$e0
		dta $00,$20,$40,$60,$80,$a0,$c0,$e0
		dta $00,$20,$40,$60,$80,$a0,$c0,$e0
		dta $00,$20,$40,$60,$80,$a0,$c0,$e0
		dta $00,$20,$40,$60,$80,$a0,$c0,$e0
		dta $00,$20,$40,$60,$80,$a0,$c0,$e0

		dta $00,$20,$40,$60,$80,$a0,$c0,$e0
		dta $00,$20,$40,$60,$80,$a0,$c0,$e0
		dta $00,$20,$40,$60,$80,$a0,$c0,$e0
		dta $00,$20,$40,$60,$80,$a0,$c0,$e0
		dta $00,$20,$40,$60,$80,$a0,$c0,$e0
		dta $00,$20,$40,$60,$80,$a0,$c0,$e0
		dta $00,$20,$40,$60,$80,$a0,$c0,$e0
		dta $00,$20,$40,$60,$80,$a0,$c0,$e0

		dta $e0,$e0,$e0,$e0,$e0,$e0,$e0,$e0
		dta $e0,$e0,$e0,$e0,$e0,$e0,$e0,$e0
		dta $e0,$e0,$e0,$e0,$e0,$e0,$e0,$e0
		dta $e0,$e0,$e0,$e0,$e0,$e0,$e0,$e0
		dta $e0,$e0,$e0,$e0,$e0,$e0,$e0,$e0
		dta $e0,$e0,$e0,$e0,$e0,$e0,$e0,$e0
		dta $e0,$e0,$e0,$e0,$e0,$e0,$e0,$e0
		dta $e0,$e0,$e0,$e0,$e0,$e0,$e0,$e0

scrn_start_hi	dta $80,$80,$80,$80,$80,$80,$80,$80
		dta $81,$81,$81,$81,$81,$81,$81,$81
		dta $82,$82,$82,$82,$82,$82,$82,$82
		dta $83,$83,$83,$83,$83,$83,$83,$83
		dta $84,$84,$84,$84,$84,$84,$84,$84
		dta $85,$85,$85,$85,$85,$85,$85,$85
		dta $86,$86,$86,$86,$86,$86,$86,$86
		dta $87,$87,$87,$87,$87,$87,$87,$87

		dta $88,$88,$88,$88,$88,$88,$88,$88
		dta $89,$89,$89,$89,$89,$89,$89,$89
		dta $8a,$8a,$8a,$8a,$8a,$8a,$8a,$8a
		dta $8b,$8b,$8b,$8b,$8b,$8b,$8b,$8b
		dta $8c,$8c,$8c,$8c,$8c,$8c,$8c,$8c
		dta $8d,$8d,$8d,$8d,$8d,$8d,$8d,$8d
		dta $8e,$8e,$8e,$8e,$8e,$8e,$8e,$8e
		dta $8f,$8f,$8f,$8f,$8f,$8f,$8f,$8f

		dta $90,$90,$90,$90,$90,$90,$90,$90
		dta $91,$91,$91,$91,$91,$91,$91,$91
		dta $92,$92,$92,$92,$92,$92,$92,$92
		dta $93,$93,$93,$93,$93,$93,$93,$93
		dta $94,$94,$94,$94,$94,$94,$94,$94
		dta $95,$95,$95,$95,$95,$95,$95,$95
		dta $96,$96,$96,$96,$96,$96,$96,$96
		dta $97,$97,$97,$97,$97,$97,$97,$97

		dta $97,$97,$97,$97,$97,$97,$97,$97
		dta $97,$97,$97,$97,$97,$97,$97,$97
		dta $97,$97,$97,$97,$97,$97,$97,$97
		dta $97,$97,$97,$97,$97,$97,$97,$97
		dta $97,$97,$97,$97,$97,$97,$97,$97
		dta $97,$97,$97,$97,$97,$97,$97,$97
		dta $97,$97,$97,$97,$97,$97,$97,$97
		dta $97,$97,$97,$97,$97,$97,$97,$97

; Split colours for the horizon
hz_colours	dta $30,$30,$30,$30,$30,$30,$30,$30

		dta $30,$30,$30,$30,$30,$30,$30,$30
		dta $40,$30,$30,$30,$40,$30,$30,$40
		dta $30,$40,$40,$30,$40,$40,$40,$30

		dta $40,$40,$40,$40,$40,$40,$40,$40
		dta $50,$40,$40,$40,$50,$40,$40,$50
		dta $40,$50,$50,$40,$50,$50,$50,$40

		dta $50,$50,$50,$50,$50,$50,$50,$50
		dta $60,$50,$50,$50,$60,$50,$50,$60
		dta $50,$60,$60,$50,$60,$60,$60,$50

		dta $60,$60,$60,$60,$60,$60,$60,$60
		dta $70,$60,$60,$60,$70,$60,$60,$70
		dta $60,$70,$70,$60,$70,$70,$70,$60

		dta $70,$70,$70,$70,$70,$70,$70,$70
		dta $80,$70,$70,$70,$80,$70,$70,$80
		dta $70,$80,$80,$70,$80,$80,$80,$70

		dta $80,$80,$80,$80,$80,$80,$80,$80
		dta $90,$80,$80,$80,$90,$80,$80,$90
		dta $80,$90,$90,$80,$90,$90,$90,$80

hz_gradient	dta $02,$02,$02,$04,$02,$04,$04,$04
		dta $06,$04,$06,$06,$06,$08,$06,$08
		dta $08,$08,$0a,$08,$0a,$0a,$0a,$0c
		dta $0a,$0c,$0c,$0c,$0e,$0c,$0e,$0e
		dta $0e,$0e,$0e,$0e,$0e,$0e,$0e,$0e
		dta $0e,$0e,$0e,$0e,$0e,$0e,$0e,$0e
		dta $0e,$0e,$0e,$0e,$0e,$0e,$0e,$0e
		dta $0e,$0e,$0e,$0e,$0e,$0e,$0e,$0e

		dta $0e,$0e,$0e,$0e,$0e,$0e,$0e,$0e
		dta $0e,$0e,$0e,$0e,$0e,$0e,$0e,$0e
		dta $0e,$0e,$0e,$0e,$0e,$0e,$0e,$0e
		dta $0e,$0e,$0e,$0e,$0e,$0e,$0e,$0e
		dta $0e,$0e,$0e,$0e,$0e,$0e,$0e,$0e
		dta $0e,$0e,$0e,$0e,$0e,$0e,$0e,$0e
		dta $0e,$0e,$0e,$0e,$0e,$0e,$0e,$0e
		dta $0e,$0e,$0e,$0e,$0c,$0e,$0c,$0c

		dta $0c,$0a,$0c,$0a,$0a,$0a,$08,$0a
		dta $08,$08,$08,$06,$08,$06,$06,$06
		dta $04,$06,$04,$04,$04,$02,$04,$02

; Colour work spaces and tables for the scroller
scroll_colours	dta $00,$00,$00,$00,$00,$00,$00,$00
		dta $00,$00,$00,$00,$00,$00,$00,$00
		dta $00,$00,$00,$00,$00,$00,$00,$00

scroll_wv_cols	dta $00,$00,$02,$02,$04,$04,$06,$06
		dta $08,$08,$0a,$0a,$0c,$0c,$0e,$0e
		dta $0c,$0c,$0a,$0a,$08,$08,$06,$06
		dta $04,$04,$02,$02

		dta $00,$00,$02,$02,$04,$04,$06,$06
		dta $08,$08,$0a,$0a,$0c,$0c,$0e,$0e
		dta $0c,$0c,$0a,$0a,$08,$08,$06,$06
		dta $04,$04,$02,$02

		dta $00,$00,$02,$02,$04,$04,$06,$06
		dta $08,$08,$0a,$0a,$0c,$0c,$0e,$0e
		dta $0c,$0c,$0a,$0a,$08,$08,$06,$06
		dta $04,$04,$02,$02

		dta $00,$00,$02,$02,$04,$04,$06,$06
		dta $08,$08,$0a,$0a,$0c,$0c,$0e,$0e
		dta $0c,$0c,$0a,$0a,$08,$08,$06,$06
		dta $04,$04,$02,$02

		dta $00,$00,$02,$02,$04,$04,$06,$06
		dta $08,$08,$0a,$0a,$0c,$0c,$0e,$0e
		dta $0c,$0c,$0a,$0a,$08,$08,$06,$06
		dta $04,$04,$02,$02

scroll_cosinus	dta $2f,$2f,$2f,$2f,$2f,$2f,$2f,$2f
		dta $2f,$2f,$2f,$2f,$2e,$2e,$2e,$2e
		dta $2e,$2d,$2d,$2d,$2d,$2c,$2c,$2c
		dta $2b,$2b,$2b,$2a,$2a,$2a,$29,$29
		dta $28,$28,$28,$27,$27,$26,$26,$25
		dta $25,$24,$24,$23,$23,$22,$22,$21
		dta $21,$20,$20,$1f,$1e,$1e,$1d,$1d
		dta $1c,$1c,$1b,$1a,$1a,$19,$19,$18

		dta $17,$17,$16,$16,$15,$15,$14,$13
		dta $13,$12,$12,$11,$10,$10,$0f,$0f
		dta $0e,$0e,$0d,$0d,$0c,$0c,$0b,$0b
		dta $0a,$0a,$09,$09,$08,$08,$07,$07
		dta $06,$06,$06,$05,$05,$05,$04,$04
		dta $04,$03,$03,$03,$02,$02,$02,$02
		dta $01,$01,$01,$01,$01,$00,$00,$00
		dta $00,$00,$00,$00,$00,$00,$00,$00

		dta $00,$00,$00,$00,$00,$00,$00,$00
		dta $00,$00,$00,$00,$01,$01,$01,$01
		dta $01,$02,$02,$02,$02,$03,$03,$03
		dta $04,$04,$04,$05,$05,$05,$06,$06
		dta $07,$07,$07,$08,$08,$09,$09,$0a
		dta $0a,$0b,$0b,$0c,$0c,$0d,$0d,$0e
		dta $0e,$0f,$10,$10,$11,$11,$12,$12
		dta $13,$14,$14,$15,$15,$16,$16,$17

		dta $18,$18,$19,$19,$1a,$1b,$1b,$1c
		dta $1c,$1d,$1d,$1e,$1f,$1f,$20,$20
		dta $21,$21,$22,$22,$23,$23,$24,$24
		dta $25,$25,$26,$26,$27,$27,$28,$28
		dta $29,$29,$29,$2a,$2a,$2b,$2b,$2b
		dta $2c,$2c,$2c,$2c,$2d,$2d,$2d,$2e
		dta $2e,$2e,$2e,$2e,$2f,$2f,$2f,$2f
		dta $2f,$2f,$2f,$2f,$2f,$2f,$2f,$2f

; Plotter tables
plot_x_cosinus	dta $7f,$7f,$7f,$7f,$7f,$7f,$7f,$7f
		dta $7e,$7e,$7e,$7d,$7d,$7c,$7c,$7b
		dta $7b,$7a,$79,$79,$78,$77,$76,$76
		dta $75,$74,$73,$72,$71,$70,$6f,$6e
		dta $6d,$6c,$6a,$69,$68,$67,$66,$64
		dta $63,$62,$60,$5f,$5e,$5c,$5b,$59
		dta $58,$56,$55,$53,$52,$50,$4f,$4d
		dta $4c,$4a,$49,$47,$46,$44,$43,$41

		dta $3f,$3e,$3c,$3b,$39,$38,$36,$34
		dta $33,$31,$30,$2e,$2d,$2b,$2a,$28
		dta $27,$25,$24,$23,$21,$20,$1e,$1d
		dta $1c,$1b,$19,$18,$17,$16,$14,$13
		dta $12,$11,$10,$0f,$0e,$0d,$0c,$0b
		dta $0a,$09,$09,$08,$07,$06,$06,$05
		dta $04,$04,$03,$03,$02,$02,$01,$01
		dta $01,$00,$00,$00,$00,$00,$00,$00

		dta $00,$00,$00,$00,$00,$00,$00,$00
		dta $01,$01,$01,$02,$02,$03,$03,$04
		dta $04,$05,$06,$06,$07,$08,$09,$0a
		dta $0a,$0b,$0c,$0d,$0e,$0f,$10,$11
		dta $12,$14,$15,$16,$17,$18,$1a,$1b
		dta $1c,$1e,$1f,$20,$22,$23,$24,$26
		dta $27,$29,$2a,$2c,$2d,$2f,$30,$32
		dta $33,$35,$36,$38,$3a,$3b,$3d,$3e

		dta $40,$41,$43,$45,$46,$48,$49,$4b
		dta $4c,$4e,$4f,$51,$52,$54,$55,$57
		dta $58,$5a,$5b,$5d,$5e,$5f,$61,$62
		dta $63,$65,$66,$67,$68,$6a,$6b,$6c
		dta $6d,$6e,$6f,$70,$71,$72,$73,$74
		dta $75,$76,$77,$77,$78,$79,$7a,$7a
		dta $7b,$7b,$7c,$7c,$7d,$7d,$7e,$7e
		dta $7e,$7f,$7f,$7f,$7f,$7f,$7f,$7f

plot_y_cosinus	dta $8f,$8f,$8f,$8f,$8f,$8f,$8f,$8e
		dta $8e,$8e,$8d,$8d,$8d,$8c,$8c,$8b
		dta $8a,$8a,$89,$88,$87,$87,$86,$85
		dta $84,$83,$82,$81,$80,$7f,$7e,$7d
		dta $7c,$7a,$79,$78,$77,$75,$74,$73
		dta $71,$70,$6e,$6d,$6b,$6a,$68,$67
		dta $65,$64,$62,$61,$5f,$5e,$5c,$5a
		dta $59,$57,$55,$54,$52,$50,$4f,$4d

		dta $4b,$4a,$48,$46,$45,$43,$41,$40
		dta $3e,$3c,$3b,$39,$38,$36,$34,$33
		dta $31,$30,$2e,$2d,$2b,$2a,$28,$27
		dta $26,$24,$23,$22,$20,$1f,$1e,$1c
		dta $1b,$1a,$19,$18,$17,$16,$15,$14
		dta $13,$12,$11,$10,$0f,$0f,$0e,$0d
		dta $0d,$0c,$0b,$0b,$0a,$0a,$09,$09
		dta $09,$08,$08,$08,$08,$08,$08,$08

		dta $08,$08,$08,$08,$08,$08,$08,$09
		dta $09,$09,$0a,$0a,$0b,$0b,$0c,$0c
		dta $0d,$0d,$0e,$0f,$10,$10,$11,$12
		dta $13,$14,$15,$16,$17,$18,$19,$1a
		dta $1c,$1d,$1e,$1f,$21,$22,$23,$25
		dta $26,$27,$29,$2a,$2c,$2d,$2f,$30
		dta $32,$33,$35,$36,$38,$3a,$3b,$3d
		dta $3f,$40,$42,$44,$45,$47,$49,$4a

		dta $4c,$4e,$4f,$51,$53,$54,$56,$57
		dta $59,$5b,$5c,$5e,$60,$61,$63,$64
		dta $66,$67,$69,$6a,$6c,$6d,$6f,$70
		dta $72,$73,$74,$76,$77,$78,$79,$7b
		dta $7c,$7d,$7e,$7f,$80,$81,$82,$83
		dta $84,$85,$86,$87,$88,$88,$89,$8a
		dta $8a,$8b,$8c,$8c,$8d,$8d,$8e,$8e
		dta $8e,$8f,$8f,$8f,$8f,$8f,$8f,$8f

; Firework spawn positions
fwork_data	dta $fd				; new burst
		dta $00,$a1,$67,$fe,$01,$f0
		dta $02,$a1,$67,$fd,$fe,$00
		dta $04,$a1,$67,$03,$fe,$f0
		dta $06,$a1,$67,$fc,$ff,$00
		dta $08,$a1,$67,$03,$00,$f0
		dta $0a,$a1,$67,$02,$01,$00
		dta $0c,$a1,$67,$fe,$fd,$f0
		dta $0e,$a1,$67,$fd,$00,$00
		dta $01,$a1,$67,$01,$02,$f0
		dta $03,$a1,$67,$01,$fc,$00
		dta $05,$a1,$67,$04,$ff,$f0
		dta $07,$a1,$67,$00,$fb,$00
		dta $09,$a1,$67,$ff,$fc,$f0
		dta $0b,$a1,$67,$ff,$02,$00
		dta $0d,$a1,$67,$02,$fd,$f0
		dta $0f,$a1,$67,$00,$03,$50

		dta $fd
		dta $10,$40,$50,$fe,$01,$f0
		dta $11,$40,$50,$01,$02,$f0
		dta $12,$40,$50,$fd,$fe,$00
		dta $13,$40,$50,$01,$fc,$f0
		dta $14,$40,$50,$03,$fe,$f0
		dta $15,$40,$50,$04,$ff,$00
		dta $16,$40,$50,$fc,$ff,$f0
		dta $17,$40,$50,$00,$fb,$f0
		dta $18,$40,$50,$03,$00,$00
		dta $19,$40,$50,$ff,$fc,$f0
		dta $1a,$40,$50,$02,$01,$f0
		dta $1b,$40,$50,$ff,$02,$00
		dta $1c,$40,$50,$fe,$fd,$f0
		dta $1d,$40,$50,$02,$fd,$f0
		dta $1e,$40,$50,$fd,$00,$00
		dta $1f,$40,$50,$00,$03,$18

		dta $fd
		dta $00,$dc,$7d,$fe,$01,$f0
		dta $01,$dc,$7d,$01,$02,$f0
		dta $02,$dc,$7d,$fd,$fe,$f0
		dta $04,$dc,$7d,$03,$fe,$00
		dta $05,$dc,$7d,$04,$ff,$f0
		dta $06,$dc,$7d,$fc,$ff,$f0
		dta $08,$dc,$7d,$03,$00,$f0
		dta $09,$dc,$7d,$ff,$fc,$00
		dta $0a,$dc,$7d,$02,$01,$f0
		dta $0c,$dc,$7d,$fe,$fd,$f0
		dta $0d,$dc,$7d,$02,$fd,$f0
		dta $0e,$dc,$7d,$fd,$00,$00
		dta $03,$dc,$7d,$01,$fc,$f0
		dta $07,$dc,$7d,$00,$fb,$f0
		dta $0b,$dc,$7d,$ff,$02,$f0
		dta $0f,$dc,$7d,$00,$03,$80


		dta $fe				; new burst
		dta $00,$a8,$26,$03,$fd,$00
		dta $01,$a8,$26,$fe,$fe,$00
		dta $02,$a8,$26,$01,$ff,$00
		dta $03,$a8,$26,$00,$00,$00
		dta $04,$a8,$26,$ff,$01,$00
		dta $05,$a8,$26,$02,$02,$00
		dta $06,$a8,$26,$fd,$03,$00
		dta $07,$a8,$26,$ff,$fc,$08

		dta $fe
		dta $08,$b9,$67,$03,$fd,$00
		dta $09,$b9,$67,$fe,$fe,$00
		dta $0a,$b9,$67,$01,$ff,$00
		dta $0b,$b9,$67,$00,$00,$00
		dta $0c,$b9,$67,$ff,$01,$00
		dta $0d,$b9,$67,$02,$02,$00
		dta $0e,$b9,$67,$fd,$03,$00
		dta $0f,$b9,$67,$ff,$fc,$08

		dta $fe
		dta $10,$49,$55,$03,$fd,$00
		dta $11,$49,$55,$fe,$fe,$00
		dta $12,$49,$55,$01,$ff,$00
		dta $13,$49,$55,$00,$00,$00
		dta $14,$49,$55,$ff,$01,$00
		dta $15,$49,$55,$02,$02,$00
		dta $16,$49,$55,$fd,$03,$00
		dta $17,$49,$55,$ff,$fc,$1c

		dta $fe
		dta $18,$d2,$74,$03,$fd,$00
		dta $19,$d2,$74,$fe,$fe,$00
		dta $1a,$d2,$74,$01,$ff,$00
		dta $1b,$d2,$74,$00,$00,$00
		dta $1c,$d2,$74,$ff,$01,$00
		dta $1d,$d2,$74,$02,$02,$00
		dta $1e,$d2,$74,$fd,$03,$00
		dta $1f,$d2,$74,$ff,$fc,$04

		dta $fe
		dta $00,$88,$41,$03,$fd,$00
		dta $01,$88,$41,$fe,$fe,$00
		dta $02,$88,$41,$01,$ff,$00
		dta $03,$88,$41,$00,$00,$00
		dta $04,$88,$41,$ff,$01,$00
		dta $05,$88,$41,$02,$02,$00
		dta $06,$88,$41,$fd,$03,$00
		dta $07,$88,$41,$ff,$fc,$80


		dta $fd				; new burst
		dta $00,$60,$60,$fe,$01,$f0
		dta $01,$60,$60,$01,$02,$f0
		dta $02,$60,$60,$fd,$fe,$00
		dta $03,$60,$60,$01,$fc,$f0
		dta $04,$60,$60,$03,$fe,$f0
		dta $05,$60,$60,$04,$ff,$00
		dta $06,$60,$60,$fc,$ff,$f0
		dta $07,$60,$60,$00,$fb,$f0
		dta $08,$60,$60,$03,$00,$00
		dta $09,$60,$60,$ff,$fc,$f0
		dta $0a,$60,$60,$02,$01,$f0
		dta $0b,$60,$60,$ff,$02,$00
		dta $0c,$60,$60,$fe,$fd,$f0
		dta $0d,$60,$60,$02,$fd,$f0
		dta $0e,$60,$60,$fd,$00,$00
		dta $0f,$60,$60,$00,$03,$40

		dta $fe
		dta $00,$cc,$28,$fe,$01,$f0
		dta $01,$cc,$28,$01,$02,$f0
		dta $02,$cc,$28,$fd,$fe,$f0
		dta $04,$cc,$28,$03,$fe,$00
		dta $05,$cc,$28,$04,$ff,$f0
		dta $06,$cc,$28,$fc,$ff,$f0
		dta $08,$cc,$28,$03,$00,$f0
		dta $09,$cc,$28,$ff,$fc,$00
		dta $0a,$cc,$28,$02,$01,$f0
		dta $0c,$cc,$28,$fe,$fd,$f0
		dta $0d,$cc,$28,$02,$fd,$f0
		dta $0e,$cc,$28,$fd,$00,$00
		dta $03,$cc,$28,$01,$fc,$f0
		dta $07,$cc,$28,$00,$fb,$f0
		dta $0b,$cc,$28,$ff,$02,$f0
		dta $0f,$cc,$28,$00,$03,$20

		dta $fd
		dta $10,$87,$55,$fe,$01,$f0
		dta $12,$87,$55,$fd,$fe,$00
		dta $14,$87,$55,$03,$fe,$f0
		dta $16,$87,$55,$fc,$ff,$00
		dta $18,$87,$55,$03,$00,$f0
		dta $1a,$87,$55,$02,$01,$00
		dta $1c,$87,$55,$fe,$fd,$f0
		dta $1e,$87,$55,$fd,$00,$00
		dta $11,$87,$55,$01,$02,$f0
		dta $13,$87,$55,$01,$fc,$00
		dta $15,$87,$55,$04,$ff,$f0
		dta $17,$87,$55,$00,$fb,$00
		dta $19,$87,$55,$ff,$fc,$f0
		dta $1b,$87,$55,$ff,$02,$00
		dta $1d,$87,$55,$02,$fd,$f0
		dta $1f,$87,$55,$00,$03,$38

		dta $fe
		dta $00,$a7,$79,$fe,$01,$f0
		dta $01,$a7,$79,$01,$02,$f0
		dta $02,$a7,$79,$fd,$fe,$f0
		dta $04,$a7,$79,$03,$fe,$00
		dta $05,$a7,$79,$04,$ff,$f0
		dta $06,$a7,$79,$fc,$ff,$f0
		dta $08,$a7,$79,$03,$00,$f0
		dta $09,$a7,$79,$ff,$fc,$00
		dta $0a,$a7,$79,$02,$01,$f0
		dta $0c,$a7,$79,$fe,$fd,$f0
		dta $0d,$a7,$79,$02,$fd,$f0
		dta $0e,$a7,$79,$fd,$00,$00
		dta $03,$a7,$79,$01,$fc,$f0
		dta $07,$a7,$79,$00,$fb,$f0
		dta $0b,$a7,$79,$ff,$02,$f0
		dta $0f,$a7,$79,$00,$03,$90


		dta $fe				; new burst
		dta $00,$3f,$9b,$03,$fd,$00
		dta $01,$3f,$9b,$fe,$fe,$00
		dta $02,$3f,$9b,$01,$ff,$00
		dta $03,$3f,$9b,$00,$00,$00
		dta $04,$3f,$9b,$ff,$01,$00
		dta $05,$3f,$9b,$02,$02,$00
		dta $06,$3f,$9b,$fd,$03,$00
		dta $07,$3f,$9b,$ff,$fc,$0c

		dta $fe
		dta $08,$52,$39,$03,$fd,$00
		dta $09,$52,$39,$fe,$fe,$00
		dta $0a,$52,$39,$01,$ff,$00
		dta $0b,$52,$39,$00,$00,$00
		dta $0c,$52,$39,$ff,$01,$00
		dta $0d,$52,$39,$02,$02,$00
		dta $0e,$52,$39,$fd,$03,$00
		dta $0f,$52,$39,$ff,$fc,$0c

		dta $fe
		dta $10,$93,$4d,$03,$fd,$00
		dta $11,$93,$4d,$fe,$fe,$00
		dta $12,$93,$4d,$01,$ff,$00
		dta $13,$93,$4d,$00,$00,$00
		dta $14,$93,$4d,$ff,$01,$00
		dta $15,$93,$4d,$02,$02,$00
		dta $16,$93,$4d,$fd,$03,$00
		dta $17,$93,$4d,$ff,$fc,$0c

		dta $fe
		dta $18,$60,$65,$03,$fd,$00
		dta $19,$60,$65,$fe,$fe,$00
		dta $1a,$60,$65,$01,$ff,$00
		dta $1b,$60,$65,$00,$00,$00
		dta $1c,$60,$65,$ff,$01,$00
		dta $1d,$60,$65,$02,$02,$00
		dta $1e,$60,$65,$fd,$03,$00
		dta $1f,$60,$65,$ff,$fc,$0c

		dta $fe
		dta $00,$98,$8c,$03,$fd,$00
		dta $01,$98,$8c,$fe,$fe,$00
		dta $02,$98,$8c,$01,$ff,$00
		dta $03,$98,$8c,$00,$00,$00
		dta $04,$98,$8c,$ff,$01,$00
		dta $05,$98,$8c,$02,$02,$00
		dta $06,$98,$8c,$fd,$03,$00
		dta $07,$98,$8c,$ff,$fc,$0c

		dta $fe
		dta $08,$9b,$4a,$03,$fd,$00
		dta $09,$9b,$4a,$fe,$fe,$00
		dta $0a,$9b,$4a,$01,$ff,$00
		dta $0b,$9b,$4a,$00,$00,$00
		dta $0c,$9b,$4a,$ff,$01,$00
		dta $0d,$9b,$4a,$02,$02,$00
		dta $0e,$9b,$4a,$fd,$03,$00
		dta $0f,$9b,$4a,$ff,$fc,$0c

		dta $fe
		dta $10,$c3,$7d,$03,$fd,$00
		dta $11,$c3,$7d,$fe,$fe,$00
		dta $12,$c3,$7d,$01,$ff,$00
		dta $13,$c3,$7d,$00,$00,$00
		dta $14,$c3,$7d,$ff,$01,$00
		dta $15,$c3,$7d,$02,$02,$00
		dta $16,$c3,$7d,$fd,$03,$00
		dta $17,$c3,$7d,$ff,$fc,$0c

		dta $fe
		dta $18,$93,$6b,$03,$fd,$00
		dta $19,$93,$6b,$fe,$fe,$00
		dta $1a,$93,$6b,$01,$ff,$00
		dta $1b,$93,$6b,$00,$00,$00
		dta $1c,$93,$6b,$ff,$01,$00
		dta $1d,$93,$6b,$02,$02,$00
		dta $1e,$93,$6b,$fd,$03,$00
		dta $1f,$93,$6b,$ff,$fc,$1c


		dta $fd				; new burst
		dta $00,$80,$48,$fe,$01,$f0
		dta $02,$80,$48,$fd,$fe,$00
		dta $04,$80,$48,$03,$fe,$f0
		dta $06,$80,$48,$fc,$ff,$00
		dta $08,$80,$48,$03,$00,$f0
		dta $0a,$80,$48,$02,$01,$00
		dta $0c,$80,$48,$fe,$fd,$f0
		dta $0e,$80,$48,$fd,$00,$00
		dta $01,$80,$48,$01,$02,$f0
		dta $03,$80,$48,$01,$fc,$00
		dta $05,$80,$48,$04,$ff,$f0
		dta $07,$80,$48,$00,$fb,$00
		dta $09,$80,$48,$ff,$fc,$f0
		dta $0b,$80,$48,$ff,$02,$00
		dta $0d,$80,$48,$02,$fd,$f0
		dta $0f,$80,$48,$00,$03,$0a

		dta $fd
		dta $10,$80,$48,$fe,$01,$f0
		dta $12,$80,$48,$fd,$fe,$00
		dta $14,$80,$48,$03,$fe,$f0
		dta $16,$80,$48,$fc,$ff,$00
		dta $18,$80,$48,$03,$00,$f0
		dta $1a,$80,$48,$02,$01,$00
		dta $1c,$80,$48,$fe,$fd,$f0
		dta $1e,$80,$48,$fd,$00,$00
		dta $11,$80,$48,$01,$02,$f0
		dta $13,$80,$48,$01,$fc,$00
		dta $15,$80,$48,$04,$ff,$f0
		dta $17,$80,$48,$00,$fb,$00
		dta $19,$80,$48,$ff,$fc,$f0
		dta $1b,$80,$48,$ff,$02,$00
		dta $1d,$80,$48,$02,$fd,$f0
		dta $1f,$80,$48,$00,$03,$90

		dta $fe				; new burst
		dta $00,$50,$80,$03,$fd,$00
		dta $01,$50,$80,$fe,$fe,$01
		dta $02,$50,$80,$01,$ff,$00
		dta $03,$50,$80,$00,$00,$01
		dta $04,$50,$80,$ff,$01,$00
		dta $05,$50,$80,$02,$02,$01
		dta $06,$50,$80,$fd,$03,$00
		dta $06,$50,$80,$ff,$fc,$08

		dta $fe
		dta $08,$60,$70,$03,$fd,$00
		dta $09,$60,$70,$fe,$fe,$01
		dta $0a,$60,$70,$01,$ff,$00
		dta $0b,$60,$70,$00,$00,$01
		dta $0c,$60,$70,$ff,$01,$00
		dta $0d,$60,$70,$02,$02,$01
		dta $0e,$60,$70,$fd,$03,$00
		dta $0f,$60,$70,$ff,$fc,$08

		dta $fe
		dta $10,$70,$60,$03,$fd,$00
		dta $11,$70,$60,$fe,$fe,$01
		dta $12,$70,$60,$01,$ff,$00
		dta $13,$70,$60,$00,$00,$01
		dta $14,$70,$60,$ff,$01,$00
		dta $15,$70,$60,$02,$02,$01
		dta $16,$70,$60,$fd,$03,$00
		dta $17,$70,$60,$ff,$fc,$08

		dta $fd
		dta $18,$80,$50,$03,$fd,$00
		dta $19,$80,$50,$fe,$fe,$01
		dta $1a,$80,$50,$01,$ff,$00
		dta $1b,$80,$50,$00,$00,$01
		dta $1c,$80,$50,$ff,$01,$00
		dta $1d,$80,$50,$02,$02,$01
		dta $1e,$80,$50,$fd,$03,$00
		dta $1f,$80,$50,$ff,$fc,$08

		dta $fe
		dta $00,$90,$40,$03,$fd,$00
		dta $01,$90,$40,$fe,$fe,$01
		dta $02,$90,$40,$01,$ff,$00
		dta $03,$90,$40,$00,$00,$01
		dta $04,$90,$40,$ff,$01,$00
		dta $05,$90,$40,$02,$02,$01
		dta $06,$90,$40,$fd,$03,$00
		dta $07,$90,$40,$ff,$fc,$08

		dta $fe
		dta $08,$a0,$30,$03,$fd,$00
		dta $09,$a0,$30,$fe,$fe,$01
		dta $0a,$a0,$30,$01,$ff,$00
		dta $0b,$a0,$30,$00,$00,$01
		dta $0c,$a0,$30,$ff,$01,$00
		dta $0d,$a0,$30,$02,$02,$01
		dta $0e,$a0,$30,$fd,$03,$00
		dta $0f,$a0,$30,$ff,$fc,$08

		dta $fe
		dta $10,$b0,$20,$03,$fd,$00
		dta $11,$b0,$20,$fe,$fe,$01
		dta $12,$b0,$20,$01,$ff,$00
		dta $13,$b0,$20,$00,$00,$01
		dta $14,$b0,$20,$ff,$01,$00
		dta $15,$b0,$20,$02,$02,$01
		dta $16,$b0,$20,$fd,$03,$00
		dta $17,$b0,$20,$ff,$fc,$50


		dta $fd				; new burst
		dta $00,$3c,$24,$fe,$01,$f0
		dta $01,$3c,$24,$01,$02,$f0
		dta $02,$3c,$24,$fd,$fe,$f0
		dta $04,$3c,$24,$03,$fe,$00
		dta $05,$3c,$24,$04,$ff,$f0
		dta $06,$3c,$24,$fc,$ff,$f0
		dta $08,$3c,$24,$03,$00,$f0
		dta $09,$3c,$24,$ff,$fc,$00
		dta $0a,$3c,$24,$02,$01,$f0
		dta $0c,$3c,$24,$fe,$fd,$f0
		dta $0d,$3c,$24,$02,$fd,$f0
		dta $0e,$3c,$24,$fd,$00,$00
		dta $03,$3c,$24,$01,$fc,$f0
		dta $07,$3c,$24,$00,$fb,$f0
		dta $0b,$3c,$24,$ff,$02,$f0
		dta $0f,$3c,$24,$00,$03,$20

		dta $fe
		dta $10,$5c,$9d,$fe,$01,$f0
		dta $12,$5c,$9d,$fd,$fe,$00
		dta $14,$5c,$9d,$03,$fe,$f0
		dta $16,$5c,$9d,$fc,$ff,$00
		dta $18,$5c,$9d,$03,$00,$f0
		dta $1a,$5c,$9d,$02,$01,$00
		dta $1c,$5c,$9d,$fe,$fd,$f0
		dta $1e,$5c,$9d,$fd,$00,$00
		dta $11,$5c,$9d,$01,$02,$f0
		dta $13,$5c,$9d,$01,$fc,$00
		dta $15,$5c,$9d,$04,$ff,$f0
		dta $17,$5c,$9d,$00,$fb,$00
		dta $19,$5c,$9d,$ff,$fc,$f0
		dta $1b,$5c,$9d,$ff,$02,$00
		dta $1d,$5c,$9d,$02,$fd,$f0
		dta $1f,$5c,$9d,$00,$03,$38

		dta $fd
		dta $00,$c7,$70,$fe,$01,$f0
		dta $01,$c7,$70,$01,$02,$f0
		dta $02,$c7,$70,$fd,$fe,$f0
		dta $04,$c7,$70,$03,$fe,$00
		dta $05,$c7,$70,$04,$ff,$f0
		dta $06,$c7,$70,$fc,$ff,$f0
		dta $08,$c7,$70,$03,$00,$f0
		dta $09,$c7,$70,$ff,$fc,$00
		dta $0a,$c7,$70,$02,$01,$f0
		dta $0c,$c7,$70,$fe,$fd,$f0
		dta $0d,$c7,$70,$02,$fd,$f0
		dta $0e,$c7,$70,$fd,$00,$00
		dta $03,$c7,$70,$01,$fc,$f0
		dta $07,$c7,$70,$00,$fb,$f0
		dta $0b,$c7,$70,$ff,$02,$f0
		dta $0f,$c7,$70,$00,$03,$90


		dta $fe				; new burst
		dta $00,$b0,$80,$03,$fd,$00
		dta $01,$b0,$80,$fe,$fe,$01
		dta $02,$b0,$80,$01,$ff,$00
		dta $03,$b0,$80,$00,$00,$01
		dta $04,$b0,$80,$ff,$01,$00
		dta $05,$b0,$80,$02,$02,$01
		dta $06,$b0,$80,$fd,$03,$00
		dta $06,$b0,$80,$ff,$fc,$08

		dta $fe
		dta $08,$a0,$70,$03,$fd,$00
		dta $09,$a0,$70,$fe,$fe,$01
		dta $0a,$a0,$70,$01,$ff,$00
		dta $0b,$a0,$70,$00,$00,$01
		dta $0c,$a0,$70,$ff,$01,$00
		dta $0d,$a0,$70,$02,$02,$01
		dta $0e,$a0,$70,$fd,$03,$00
		dta $0f,$a0,$70,$ff,$fc,$08

		dta $fe
		dta $10,$90,$60,$03,$fd,$00
		dta $11,$90,$60,$fe,$fe,$01
		dta $12,$90,$60,$01,$ff,$00
		dta $13,$90,$60,$00,$00,$01
		dta $14,$90,$60,$ff,$01,$00
		dta $15,$90,$60,$02,$02,$01
		dta $16,$90,$60,$fd,$03,$00
		dta $17,$90,$60,$ff,$fc,$08

		dta $fe
		dta $18,$80,$50,$03,$fd,$00
		dta $19,$80,$50,$fe,$fe,$01
		dta $1a,$80,$50,$01,$ff,$00
		dta $1b,$80,$50,$00,$00,$01
		dta $1c,$80,$50,$ff,$01,$00
		dta $1d,$80,$50,$02,$02,$01
		dta $1e,$80,$50,$fd,$03,$00
		dta $1f,$80,$50,$ff,$fc,$08

		dta $fe
		dta $00,$70,$40,$03,$fd,$00
		dta $01,$70,$40,$fe,$fe,$01
		dta $02,$70,$40,$01,$ff,$00
		dta $03,$70,$40,$00,$00,$01
		dta $04,$70,$40,$ff,$01,$00
		dta $05,$70,$40,$02,$02,$01
		dta $06,$70,$40,$fd,$03,$00
		dta $07,$70,$40,$ff,$fc,$08

		dta $fe
		dta $08,$60,$30,$03,$fd,$00
		dta $09,$60,$30,$fe,$fe,$01
		dta $0a,$60,$30,$01,$ff,$00
		dta $0b,$60,$30,$00,$00,$01
		dta $0c,$60,$30,$ff,$01,$00
		dta $0d,$60,$30,$02,$02,$01
		dta $0e,$60,$30,$fd,$03,$00
		dta $0f,$60,$30,$ff,$fc,$08

		dta $fe
		dta $10,$50,$20,$03,$fd,$00
		dta $11,$50,$20,$fe,$fe,$01
		dta $12,$50,$20,$01,$ff,$00
		dta $13,$50,$20,$00,$00,$01
		dta $14,$50,$20,$ff,$01,$00
		dta $15,$50,$20,$02,$02,$01
		dta $16,$50,$20,$fd,$03,$00
		dta $17,$50,$20,$ff,$fc,$48


		dta $fe				; new burst
		dta $00,$80,$58,$fe,$01,$f0
		dta $02,$80,$58,$fd,$fe,$00
		dta $04,$80,$58,$03,$fe,$f0
		dta $06,$80,$58,$fc,$ff,$00
		dta $08,$80,$58,$03,$00,$f0
		dta $0a,$80,$58,$02,$01,$00
		dta $0c,$80,$58,$fe,$fd,$f0
		dta $0e,$80,$58,$fd,$00,$00
		dta $01,$80,$58,$01,$02,$f0
		dta $03,$80,$58,$01,$fc,$00
		dta $05,$80,$58,$04,$ff,$f0
		dta $07,$80,$58,$00,$fb,$00
		dta $09,$80,$58,$ff,$fc,$f0
		dta $0b,$80,$58,$ff,$02,$00
		dta $0d,$80,$58,$02,$fd,$f0
		dta $0f,$80,$58,$00,$03,$06

		dta $fd
		dta $10,$80,$48,$fe,$01,$f0
		dta $12,$80,$48,$fd,$fe,$00
		dta $14,$80,$48,$03,$fe,$f0
		dta $16,$80,$48,$fc,$ff,$00
		dta $18,$80,$48,$03,$00,$f0
		dta $1a,$80,$48,$02,$01,$00
		dta $1c,$80,$48,$fe,$fd,$f0
		dta $1e,$80,$48,$fd,$00,$00
		dta $11,$80,$48,$01,$02,$f0
		dta $13,$80,$48,$01,$fc,$00
		dta $15,$80,$48,$04,$ff,$f0
		dta $17,$80,$48,$00,$fb,$00
		dta $19,$80,$48,$ff,$fc,$f0
		dta $1b,$80,$48,$ff,$02,$00
		dta $1d,$80,$48,$02,$fd,$f0
		dta $1f,$80,$48,$00,$03,$06

		dta $fd
		dta $00,$80,$38,$fe,$01,$f0
		dta $02,$80,$38,$fd,$fe,$00
		dta $04,$80,$38,$03,$fe,$f0
		dta $06,$80,$38,$fc,$ff,$00
		dta $08,$80,$38,$03,$00,$f0
		dta $0a,$80,$38,$02,$01,$00
		dta $0c,$80,$38,$fe,$fd,$f0
		dta $0e,$80,$38,$fd,$00,$00
		dta $01,$80,$38,$01,$02,$f0
		dta $03,$80,$38,$01,$fc,$00
		dta $05,$80,$38,$04,$ff,$f0
		dta $07,$80,$38,$00,$fb,$00
		dta $09,$80,$38,$ff,$fc,$f0
		dta $0b,$80,$38,$ff,$02,$00
		dta $0d,$80,$38,$02,$fd,$f0
		dta $0f,$80,$38,$00,$03,$e0

		dta $ff		; end of data marker


; Preset data for the plotter; position in curve, speed and offset X2 for X
; then position, speed and offset for Y
plot_presets	dta $00,$03,$0c
		dta $bb,$02,$11
		dta $33,$03,$0f

		dta $00,$fd,$1c
		dta $40,$04,$f0
		dta $33,$02,$12

		dta $64,$fc,$7c
		dta $55,$02,$09
		dta $99,$fd,$82

		dta $c0,$01,$10
		dta $c0,$fe,$f0
		dta $33,$02,$10

		dta $00,$fe,$0f
		dta $a9,$fc,$22
		dta $33,$fd,$14

		dta $60,$01,$08
		dta $90,$04,$15
		dta $33,$02,$0f

		dta $00,$02,$0c
		dta $80,$02,$0c
		dta $40,$02,$0c

		dta $48,$03,$f4
		dta $64,$fd,$10
		dta $33,$03,$0f

		dta $33,$02,$12
		dta $00,$fe,$0f

		dta $80		; end of data marker


; Horizon strobe table
strobe_table	dta $0e,$0e,$0e,$0c,$0e,$0e,$0a,$0a
		dta $0a,$08,$08,$08,$06,$06,$06,$04
		dta $02


; Character widths
tile_width	dta $02,$01,$03,$03,$03,$03,$03,$01	; space to apostrophe
		dta $02,$02,$03,$03,$01,$02,$01,$03	; ( to /
		dta $03,$02,$03,$03,$03,$03,$03,$03	; 0 to 7
		dta $03,$03,$01,$01,$03,$03,$03,$03	; 8 to ?

		dta $03,$03,$03,$03,$03,$03,$03,$03	; @ to G
		dta $03,$01,$03,$03,$03,$03,$03,$03	; H to O
		dta $03,$03,$03,$03,$03,$03,$03,$03	; P to W
		dta $03,$03,$03,$03,$03,$03,$03,$03	; X to Z


; Woohoo, words!
scroll_text	dta d"ANOTHER DAY (OR IN THIS CASE, ANOTHER YEAR) AND ANOTHER "
		dta d"SCROLLTEXT...!"
		dta d"          "

		dta d"HAPPY NEW YEAR AND WELCOME TO  --- MD201601 ---  FROM COSINE!"
		dta d"       "

		dta d"CODING AND GRAPHICS BY T.M.R, WITH "
		dta d"MUSIC FROM MIKER (TA VERY MUCH INDEED!)"
		dta d"          "

		dta d"OUR LAST NYD DEMO WAS INC YEAR WHICH WAS BUILT OUT OF "
		dta d"SOME PROTOTYPE CODE I ALREADY HAD HANDY, BUT THIS ONE IS "
		dta d"DIFFERENT BECAUSE IT WAS ACTUALLY PLANNED IN ADVANCE AND "
		dta d"WRITTEN FROM SCRATCH AROUND THE THEME!"
		dta d"       "

		dta d"THERE'S LESS TECHNICAL GUBBINS TO WRITE ABOUT THIS TIME, "
		dta d"BUT THE FIREWORKS AND WHAT FOLLOWS THEM ARE BUILT ON THE "
		dta d"SAME 32 POINT PLOTTER WHICH IN TURN LEANS ON A QUITE "
		dta d"FRANKLY RIDICULOUS AMOUNT OF UNROLLED LOOPS AND "
		dta d"SELF-MODIFYING CODE!"
		dta d"       "

		dta d"THE NARROW PLAYFIELD IS USED MOSTLY BECAUSE I THOUGHT IT WOULD "
		dta d"LOOK QUITE COOL, ALTHOUGH IT DOES MAKE THE PLOTTER A LITTLE "
		dta d"EASIER TOO SINCE IT DOESN'T HAVE TO DEAL WITH ANYTHING GREATER "
		dta d"THAN 8-BIT NUMBERS FOR THE X CO-ORDINATE!"
		dta d"          "

		dta d"2016 SHOULD BE QUITE A BUSY YEAR FOR COSINE AND THERE ARE "
		dta d"PLANS FOR SOME LARGER RELEASES ALONGSIDE THE MONTHLY DEMO "
		dta d"SERIES;  WE'RE ALSO LOOKING FOR NEW MEMBERS, SO IF ANYONE "
		dta d"READING FANCIES SIGNING UP JUST GET IN TOUCH BY EMAILING "
		dta d"TMR(AT)COSINE.ORG.UK - ANYONE WHO CAN DRAW CHARACTER SETS "
		dta d"WITH AN AT SYMBOL IS PARTICULARLY WELCOME TO CONTACT US "
		dta d"BECAUSE I ALWAYS FORGET TO ADD ONE!"
		dta d"          "

		dta d"ANYWAY, SINCE I NEED TO GET THIS FINISHED AND SENT OFF "
		dta d"BEFORE THE DEADLINE (AND NOT JUST BECAUSE I'M RUNNING OUT "
		dta d"OF IDEAS FOR TEXT OR ANYTHING, HONEST!) HERE COME THE "
		dta d"GREETINGS AND THE NOW UBIQUITOUS PLUG FOR THE COSINE "
		dta d"WEBSITE!"
		dta d"       "

		dta d"START-OF-THE-YEAR HELLOS TO OUR FRIENDS IN:   "
		dta d"ABYSS CONNECTION, "
		dta d"ARKANIX LABS, "
		dta d"ARTSTATE, "
		dta d"ATE BIT, "
		dta d"BOOZE DESIGN, "
		dta d"CAMELOT, "
		dta d"CHORUS, "
		dta d"CHROME, "
		dta d"CNCD, "
		dta d"CPU, "
		dta d"CRESCENT, "
		dta d"CREST, "
		dta d"COVERT BITOPS, "
		dta d"DEFENCE FORCE, "
		dta d"DEKADENCE, "
		dta d"DESIRE, "
		dta d"DAC, "
		dta d"DMAGIC, "
		dta d"DUALCREW, "
		dta d"EXCLUSIVE ON, "
		dta d"FAIRLIGHT, "
		dta d"FIRE, "
		dta d"FOCUS, "
		dta d"FRENCH TOUCH, "
		dta d"FUNKSCIENTIST PRODUCTIONS, "
		dta d"GENESIS PROJECT, "
		dta d"GHEYMAID INC., "
		dta d"HITMEN, "
		dta d"HOKUTO FORCE, "
		dta d"LEVEL64, "
		dta d"MANIACS OF NOISE, "
		dta d"MEANTEAM, "
		dta d"METALVOTZE, "
		dta d"NONAME, "
		dta d"NOSTALGIA, "
		dta d"NUANCE, "
		dta d"OFFENCE, "
		dta d"ONSLAUGHT, "
		dta d"ORB, "
		dta d"OXYRON, "
		dta d"PADUA, "
		dta d"PLUSH, "
		dta d"PSYTRONIK, "
		dta d"REPTILIA, "
		dta d"RESOURCE, "
		dta d"RGCD, "
		dta d"SECURE, "
		dta d"SHAPE, "
		dta d"SIDE B, "
		dta d"SLASH, "
		dta d"SLIPSTREAM, "
		dta d"SUCCESS AND TRC, "
		dta d"STYLE, "
		dta d"SUICYCO INDUSTRIES, "
		dta d"TAQUART, "
		dta d"TEMPEST, "
		dta d"TEK, "
		dta d"TRIAD, "
		dta d"TRSI, "
		dta d"VIRUZ, "
		dta d"VISION, "
		dta d"WOW, "
		dta d"WRATH AND "
		dta d"XENON"
		dta d"       "

		dta d"OH, AND HI TO ALL THE NICE PEOPLE CONTRIBUTING TO "
		dta d"THE NEW YEARS DISK AS WELL!"
		dta d"          "

		dta d"AND FINALLY WE GET TO THAT TRULY SHAMELESS PLUG FOR "
		dta d" COSINE.ORG.UK  AND ALL OF THE 8-BIT DELIGHTS IT "
		dta d"CONTAINS AND, WITH THAT SORTED AND THE GREETINGS OUT "
		dta d"OF THE WAY, ALL THAT IS LEFT IS TO SIGN OFF...   "
		dta d"SO THIS WAS T.M.R OF COSINE DOING JUST THAT ON THE "
		dta d"1ST OF JANUARY 2016... "
		dta d".. .  .   ."
		dta d"              "

		dta $ff		; end of text marker