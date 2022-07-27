.macro RasterWait(line) {
    wait:
        lda #line
        cmp $d012
        bne wait
}
