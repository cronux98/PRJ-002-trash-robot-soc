/* GENERATED-FROM: memory_map.json — DO NOT HAND-EDIT */
/* IP-005 v6 Trash Robot SoC — PicoRV32 RV32IM */

MEMORY
{
    SRAM (rwx)  : ORIGIN = 0x0000, LENGTH = 512
}

ENTRY(_start)

SECTIONS
{
    . = 0x0000;

    .text : {
        *(.text._start)
        *(.text*)
    } > SRAM

    .rodata : {
        *(.rodata*)
    } > SRAM

    .data : {
        *(.data*)
    } > SRAM

    .bss : {
        _bss_start = .;
        *(.bss*)
        *(COMMON)
        _bss_end = .;
    } > SRAM

    _stack_top = ORIGIN(SRAM) + LENGTH(SRAM);
}
